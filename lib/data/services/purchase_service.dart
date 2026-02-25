// 결제 서비스
// 3티어 일회성 결제: 작명(₩11,900) / 진단(₩4,900) / 묶음(₩14,900)
// + 진단 후 업셀링: 개선 이름 5개 추가(₩9,900)
// 디바이스 ID 기반 무료 체험 1회 제한

import 'dart:async';
import 'dart:convert';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;

/// 상품 타입
enum ProductType { naming, diagnosis, bundle, diagnosisUpgrade }

/// 상품 정보
class PlanProduct {
  final String productId;
  final ProductType type;
  final String label;
  final String subtitle;
  final String price;
  final int nameCount;
  final List<String> features;
  ProductDetails? storeProduct;

  PlanProduct({
    required this.productId,
    required this.type,
    required this.label,
    required this.subtitle,
    required this.price,
    required this.nameCount,
    required this.features,
  });

  String get priceString => storeProduct?.price ?? price;
}

class PurchaseService {
  static const String _freeUsedKey = 'free_trial_used';
  static const String _deviceIdKey = 'device_id';

  static const String _backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://YOUR_PROJECT.supabase.co/functions/v1',
  );
  static const String _apiSecret = String.fromEnvironment(
    'API_SECRET',
    defaultValue: 'ireumun-secret-2024',
  );

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _freeTrialUsed = false;
  bool get freeTrialUsed => _freeTrialUsed;
  bool get isFreeAvailable => !_freeTrialUsed;

  String? _deviceId;
  bool _isAvailable = false;
  bool get isStoreAvailable => _isAvailable;

  // 콜백
  void Function(ProductType type)? onPurchaseCompleted;
  void Function()? onStateUpdated;

  // 상품 목록
  final List<PlanProduct> products = [
    PlanProduct(
      productId: 'naming_new',
      type: ProductType.naming,
      label: '신규 작명',
      subtitle: '아기 + 부모 사주 기반 작명',
      price: '₩11,900',
      nameCount: 5,
      features: [
        '가족 오행 균형 분석',
        '사주 기반 이름 5개 추천',
        '한자 뜻풀이 & 오행 분석',
        '종합 점수 & 발음 평가',
      ],
    ),
    PlanProduct(
      productId: 'diagnosis',
      type: ProductType.diagnosis,
      label: '이름 진단',
      subtitle: '현재 이름의 사주 궁합 분석',
      price: '₩4,900',
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
      subtitle: '작명 + 진단 동시 이용',
      price: '₩14,900',
      nameCount: 8,
      features: [
        '신규 작명 (이름 5개)',
        '이름 진단 (개선 이름 3개)',
        '₩1,900 할인 적용',
      ],
    ),
    PlanProduct(
      productId: 'diagnosis_upgrade',
      type: ProductType.diagnosisUpgrade,
      label: '개선 이름 추가',
      subtitle: '진단 후 개선 이름 5개 더 받기',
      price: '₩9,900',
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

  /// 초기화
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _freeTrialUsed = prefs.getBool(_freeUsedKey) ?? false;

    await _initDeviceId(prefs);
    await _checkFreeTrialFromServer();

    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) return;

    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (_) {},
    );

    await _loadProducts();
  }

  Future<void> _initDeviceId(SharedPreferences prefs) async {
    _deviceId = prefs.getString(_deviceIdKey);
    if (_deviceId == null) {
      try {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        _deviceId = androidInfo.id;
        await prefs.setString(_deviceIdKey, _deviceId!);
      } catch (_) {}
    }
  }

  Future<void> _checkFreeTrialFromServer() async {
    if (_deviceId == null || _freeTrialUsed) return;
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/check-free-trial?deviceId=$_deviceId'),
        headers: {'Authorization': 'Bearer $_apiSecret'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['used'] == true) {
          _freeTrialUsed = true;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_freeUsedKey, true);
        }
      }
    } catch (_) {}
  }

  Future<void> _loadProducts() async {
    final productIds = products.map((p) => p.productId).toSet();
    final response = await _iap.queryProductDetails(productIds);
    for (final product in response.productDetails) {
      final pkg = products.firstWhere(
        (p) => p.productId == product.id,
        orElse: () => products.first,
      );
      pkg.storeProduct = product;
    }
  }

  /// 무료 체험 사용 처리
  Future<void> useFreeTrial() async {
    _freeTrialUsed = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_freeUsedKey, true);
    _registerFreeTrialToServer();
    onStateUpdated?.call();
  }

  Future<void> _registerFreeTrialToServer() async {
    if (_deviceId == null) return;
    try {
      await http.post(
        Uri.parse('$_backendUrl/register-free-trial'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiSecret',
        },
        body: jsonEncode({'deviceId': _deviceId}),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  /// 구매 시작
  Future<bool> purchase(PlanProduct product) async {
    if (product.storeProduct == null) return false;
    try {
      return await _iap.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: product.storeProduct!),
      );
    } catch (e) {
      return false;
    }
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
          await _deliverPurchase(purchase);
          break;
        case PurchaseStatus.error:
        case PurchaseStatus.canceled:
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;
        case PurchaseStatus.pending:
        case PurchaseStatus.restored:
          break;
      }
    }
  }

  Future<void> _deliverPurchase(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
    final product = products.firstWhere(
      (p) => p.productId == purchase.productID,
      orElse: () => products.first,
    );
    onPurchaseCompleted?.call(product.type);
    onStateUpdated?.call();
  }

  void dispose() {
    _subscription?.cancel();
  }
}
