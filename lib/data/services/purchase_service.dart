// 결제 서비스 (Google Play 인앱결제, 소모성 상품)
//
// 순서: 결제 준비(서버가 풀어줄 결과가 있는지 확인) → Play 결제 → 서버 영수증 검증
//      → 받은 결과를 기기에 저장 → 그다음에 구매 확인·소비
// - 플러그인 기본값(autoConsume)은 결제가 들어오자마자 소비해 버려서, 저장 전에 앱이 꺼지면
//   돈만 나가고 결과는 못 받았다. 그래서 autoConsume을 끄고 저장 뒤에 직접 소비한다.
// - 검증이 실패하면 소비하지 않는다. 다음 실행 때 restorePurchases로 다시 받아 이어서 처리하고,
//   끝내 풀어줄 게 없으면 Play가 3일 뒤 미확인 결제를 자동 환불한다.

import 'dart:async';
import 'dart:convert';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// 상품 타입
enum ProductType { naming, diagnosis, bundle, diagnosisUpgrade }

/// 가격 기본값 — 여기 한 곳에서만 정의한다.
/// 실제 청구 금액은 Play Console 설정값이고, 스토어 정보를 받으면 그 금액을 표시한다.
/// (Play Console 가격도 이 값과 맞춰야 한다)
class Prices {
  Prices._();
  static const naming = 7900;
  static const diagnosis = 4900;
  static const bundle = 10900; // 작명 + 진단 (12,800) - 1,900
  static const diagnosisUpgrade = 9900;

  static String format(int won) => '₩${NumberFormat('#,###').format(won)}';
}

/// 상품 정보
class PlanProduct {
  final String productId;
  final ProductType type;
  final String label;
  final String subtitle;
  final int fallbackPrice;
  final int nameCount;
  final List<String> features;
  ProductDetails? storeProduct;

  PlanProduct({
    required this.productId,
    required this.type,
    required this.label,
    required this.subtitle,
    required this.fallbackPrice,
    required this.nameCount,
    required this.features,
  });

  String get priceString => storeProduct?.price ?? Prices.format(fallbackPrice);

  /// 원 단위 가격 (스토어 정보가 있으면 그 값)
  int get priceWon => storeProduct != null
      ? (storeProduct!.rawPrice).round()
      : fallbackPrice;
}

/// 결제 진행 상황 (화면 안내용)
enum PurchaseEventKind { pending, verifying, delivered, canceled, failed }

class PurchaseEvent {
  final PurchaseEventKind kind;
  final ProductType? type;
  final String message;
  const PurchaseEvent(this.kind, this.type, this.message);
}

/// 결제 실패 (사용자에게 그대로 보여줄 문구)
class PurchaseFlowException implements Exception {
  final String message;
  const PurchaseFlowException(this.message);
  @override
  String toString() => message;
}

/// Play 결제 창구. 테스트에서는 가짜로 바꿔 끼운다.
abstract class BillingGateway {
  Stream<List<PurchaseDetails>> get purchaseStream;
  Future<bool> isAvailable();
  Future<List<ProductDetails>> queryProducts(Set<String> ids);

  /// accountId는 Play 영수증의 obfuscatedAccountId로 들어가서 서버가 대조한다
  Future<bool> buy(ProductDetails product, String accountId);

  /// 결과를 기기에 저장한 뒤에만 부른다: 구매 확인 + 소비 (다시 살 수 있게)
  Future<void> finish(PurchaseDetails purchase);

  /// 취소·오류로 끝난 결제 정리
  Future<void> dismiss(PurchaseDetails purchase);

  /// 아직 소비되지 않은(= 처리가 덜 끝난) 구매를 다시 스트림으로 받는다
  Future<void> restore();
}

class InAppPurchaseGateway implements BillingGateway {
  final InAppPurchase _iap = InAppPurchase.instance;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  @override
  Future<bool> isAvailable() => _iap.isAvailable();

  @override
  Future<List<ProductDetails>> queryProducts(Set<String> ids) async =>
      (await _iap.queryProductDetails(ids)).productDetails;

  @override
  Future<bool> buy(ProductDetails product, String accountId) => _iap.buyConsumable(
        purchaseParam:
            PurchaseParam(productDetails: product, applicationUserName: accountId),
        autoConsume: false,
      );

  @override
  Future<void> finish(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
    final android =
        _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final result = await android.consumePurchase(purchase);
    if (result.responseCode != BillingResponse.ok) {
      // 소비 실패: 다음 실행 때 restore로 다시 들어와 소비를 재시도한다 (서버 검증은 같은 결과)
      throw PurchaseFlowException('consume failed: ${result.responseCode}');
    }
  }

  @override
  Future<void> dismiss(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  @override
  Future<void> restore() => _iap.restorePurchases();
}

class PurchaseService {
  static const _pendingPrefix = 'pending_purchase_';

  final BillingGateway _billing;
  final Api _api;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final Set<String> _inFlight = {};

  bool _isAvailable = false;
  bool get isStoreAvailable => _isAvailable;

  /// 검증된 결과를 받으면 부른다. 여기서 기기에 저장이 끝나야 소비한다.
  Future<void> Function(ProductType type, List<RemoteResult> results)? onDelivered;

  /// 진행 상황 안내
  void Function(PurchaseEvent event)? onEvent;

  PurchaseService({required BillingGateway billing, required Api api})
      : _billing = billing,
        _api = api;

  // 상품 목록 (가격은 Prices에서만)
  final List<PlanProduct> products = [
    PlanProduct(
      productId: 'naming_new',
      type: ProductType.naming,
      label: '신규 작명',
      subtitle: '사주 기반 이름 전체 공개',
      fallbackPrice: Prices.naming,
      nameCount: 5,
      features: [
        '사주 기반 이름 5개 전체 공개',
        '한자 뜻풀이 & 오행 분석',
        '종합 점수 & 발음 평가',
        '부모 사주 포함 시 가족 오행 분석',
      ],
    ),
    PlanProduct(
      productId: 'diagnosis',
      type: ProductType.diagnosis,
      label: '이름 진단',
      subtitle: '현재 이름의 사주 궁합 분석',
      fallbackPrice: Prices.diagnosis,
      nameCount: 3,
      features: [
        '현재 이름 오행 적합도 분석',
        '문제점 & 장점 상세 리포트',
        '개선 이름 3개 추천',
      ],
    ),
    PlanProduct(
      productId: 'bundle',
      type: ProductType.bundle,
      label: '묶음 할인',
      subtitle: '받아 둔 작명 + 진단 결과 함께 열기',
      fallbackPrice: Prices.bundle,
      nameCount: 8,
      features: [
        '작명 결과 전체 (이름 5개)',
        '진단 결과 전체 (개선 이름 3개)',
      ],
    ),
    PlanProduct(
      productId: 'diagnosis_upgrade',
      type: ProductType.diagnosisUpgrade,
      label: '개선 이름 추가',
      subtitle: '진단 후 개선 이름 5개 더 받기',
      fallbackPrice: Prices.diagnosisUpgrade,
      nameCount: 5,
      features: [
        '추가 개선 이름 5개 추천',
        '사주 맞춤 한자 선정',
        '상세 오행 분석 포함',
      ],
    ),
  ];

  PlanProduct getProduct(ProductType type) =>
      products.firstWhere((p) => p.type == type);

  PlanProduct? _byProductId(String id) {
    for (final p in products) {
      if (p.productId == id) return p;
    }
    return null;
  }

  /// 묶음 할인액 (작명 + 진단 - 묶음)
  int get bundleDiscount =>
      getProduct(ProductType.naming).priceWon +
      getProduct(ProductType.diagnosis).priceWon -
      getProduct(ProductType.bundle).priceWon;

  /// 초기화: 스토어 연결 + 상품 정보
  Future<void> initialize() async {
    _isAvailable = await _billing.isAvailable();
    if (!_isAvailable) return;

    _subscription = _billing.purchaseStream.listen(
      _handlePurchases,
      onError: (_) {},
    );

    try {
      for (final details in await _billing.queryProducts(
        products.map((p) => p.productId).toSet(),
      )) {
        _byProductId(details.id)?.storeProduct = details;
      }
    } catch (_) {}
  }

  /// 처리가 덜 끝난 구매 이어받기 (앱 시작 시, 로그인 뒤에)
  Future<void> recoverUnfinished() async {
    if (!_isAvailable) return;
    try {
      await _billing.restore();
    } catch (_) {}
  }

  /// 구매 시작. 결제 창이 뜨면 돌아오고, 결과는 onDelivered / onEvent로 온다.
  /// 풀어줄 결과가 없으면(서버 확인) 결제 창을 띄우지 않는다.
  Future<void> buy(ProductType type, List<String> resultIds) async {
    final product = getProduct(type);
    final store = product.storeProduct;
    if (!_isAvailable || store == null) {
      throw const PurchaseFlowException('스토어에 연결하지 못했어요. 잠시 뒤에 다시 시도해 주세요.');
    }

    // 서버가 먼저 확인 (예: 결과 없이 묶음 할인 결제 → 여기서 막힘)
    await _api.preparePurchase(product.productId, resultIds);

    final accountId = _api.userId;
    if (accountId == null) {
      throw const PurchaseFlowException('서버에 접속하지 못했어요. 잠시 뒤에 다시 시도해 주세요.');
    }

    await _savePending(product.productId, resultIds);
    final launched = await _billing.buy(store, accountId);
    if (!launched) {
      await _clearPending(product.productId);
      throw const PurchaseFlowException('결제 창을 열지 못했어요. 잠시 뒤에 다시 시도해 주세요.');
    }
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      await handlePurchase(purchase);
    }
  }

  /// 구매 한 건 처리 (테스트에서 직접 부를 수 있게 공개)
  Future<void> handlePurchase(PurchaseDetails purchase) async {
    final product = _byProductId(purchase.productID);
    if (product == null) return;

    switch (purchase.status) {
      case PurchaseStatus.pending:
        onEvent?.call(PurchaseEvent(PurchaseEventKind.pending, product.type,
            '결제가 처리 중이에요. 완료되면 자동으로 열려요.'));
        break;
      case PurchaseStatus.canceled:
        await _dismiss(purchase, product);
        onEvent?.call(PurchaseEvent(
            PurchaseEventKind.canceled, product.type, '결제를 취소했어요.'));
        break;
      case PurchaseStatus.error:
        await _dismiss(purchase, product);
        onEvent?.call(PurchaseEvent(PurchaseEventKind.failed, product.type,
            '결제가 완료되지 않았어요. 다시 시도해 주세요.'));
        break;
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        await _verifyAndDeliver(purchase, product);
        break;
    }
  }

  Future<void> _dismiss(PurchaseDetails purchase, PlanProduct product) async {
    try {
      await _billing.dismiss(purchase);
    } catch (_) {}
    await _clearPending(product.productId);
  }

  Future<void> _verifyAndDeliver(PurchaseDetails purchase, PlanProduct product) async {
    final token = purchase.verificationData.serverVerificationData;
    if (!_inFlight.add(token)) return; // 같은 구매가 스트림·복원으로 겹쳐 들어온 경우

    try {
      onEvent?.call(PurchaseEvent(
          PurchaseEventKind.verifying, product.type, '결제를 확인하고 있어요...'));

      final results = await _api.verifyPurchase(
        productId: product.productId,
        purchaseToken: token,
        resultIds: await _loadPending(product.productId),
      );

      // 1) 기기에 저장 → 2) 소비. 순서를 바꾸면 저장 전에 꺼졌을 때 결과를 잃는다.
      await onDelivered?.call(product.type, results);
      await _clearPending(product.productId);
      try {
        await _billing.finish(purchase);
      } catch (_) {
        // 소비 실패는 다음 실행 때 restore로 재시도 (서버는 같은 결과를 다시 준다)
      }

      onEvent?.call(PurchaseEvent(
          PurchaseEventKind.delivered, product.type, '결제가 완료되었어요. 전체 결과를 확인해 보세요.'));
    } on ApiException catch (e) {
      // 소비하지 않는다 → 다음 실행 때 다시 시도, 끝내 안 되면 Play 자동 환불
      onEvent?.call(PurchaseEvent(PurchaseEventKind.failed, product.type,
          e.code == 'purchase_pending'
              ? e.message
              : '${e.message}\n결과를 못 받은 결제는 앱을 다시 열 때 자동으로 확인하고, 끝내 못 받으면 환불돼요.'));
    } catch (_) {
      // 기기 저장 실패 등: 소비하지 않고 다음 실행 때 다시 처리
      onEvent?.call(PurchaseEvent(PurchaseEventKind.failed, product.type,
          '결과를 저장하지 못했어요. 앱을 다시 열면 이어서 받아요.'));
    } finally {
      _inFlight.remove(token);
    }
  }

  // 결제 대상 결과 ID (결제 중 앱이 꺼져도 이어서 처리하려고 기기에 적어 둔다)
  Future<void> _savePending(String productId, List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_pendingPrefix$productId', jsonEncode(ids));
  }

  Future<List<String>> _loadPending(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_pendingPrefix$productId');
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List).map((e) => e as String).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _clearPending(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_pendingPrefix$productId');
  }

  void dispose() {
    _subscription?.cancel();
  }
}
