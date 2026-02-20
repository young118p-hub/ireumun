// 크레딧 관리 서비스
// 소모성 인앱결제 + 로컬 크레딧 저장/차감

import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreditPackage {
  final String productId;
  final int credits;
  final String label;
  final String description;
  ProductDetails? storeProduct;

  CreditPackage({
    required this.productId,
    required this.credits,
    required this.label,
    required this.description,
  });

  String get priceString => storeProduct?.price ?? _fallbackPrice;

  String get _fallbackPrice {
    switch (productId) {
      case 'credits_3':
        return '₩1,900';
      case 'credits_10':
        return '₩3,900';
      case 'credits_30':
        return '₩6,900';
      default:
        return '';
    }
  }
}

class CreditService {
  static const String _creditsKey = 'remaining_credits';
  static const String _freeUsedKey = 'free_trial_used';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  int _credits = 0;
  int get credits => _credits;

  bool _freeTrialUsed = false;
  bool get freeTrialUsed => _freeTrialUsed;

  bool get canGenerate => !_freeTrialUsed || _credits > 0;

  // 무료 체험 여부: 아직 안썼으면 무료, 썼으면 크레딧 필요
  bool get isFreeAvailable => !_freeTrialUsed;

  bool _isAvailable = false;
  bool get isStoreAvailable => _isAvailable;

  // 크레딧 패키지 목록
  final List<CreditPackage> packages = [
    CreditPackage(
      productId: 'credits_3',
      credits: 3,
      label: '3회',
      description: '가볍게 시작',
    ),
    CreditPackage(
      productId: 'credits_10',
      credits: 10,
      label: '10회',
      description: '가성비 추천',
    ),
    CreditPackage(
      productId: 'credits_30',
      credits: 30,
      label: '30회',
      description: '대량 할인',
    ),
  ];

  // 상태 변경 콜백
  void Function()? onCreditUpdated;

  /// 초기화
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _credits = prefs.getInt(_creditsKey) ?? 0;
    _freeTrialUsed = prefs.getBool(_freeUsedKey) ?? false;

    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) return;

    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (_) {},
    );

    await _loadProducts();
  }

  /// 스토어 상품 정보 로드
  Future<void> _loadProducts() async {
    final productIds = packages.map((p) => p.productId).toSet();
    final response = await _iap.queryProductDetails(productIds);

    for (final product in response.productDetails) {
      final pkg = packages.firstWhere(
        (p) => p.productId == product.id,
        orElse: () => packages.first,
      );
      pkg.storeProduct = product;
    }
  }

  /// 무료 체험 사용
  Future<void> useFreeTrialCredit() async {
    _freeTrialUsed = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_freeUsedKey, true);
    onCreditUpdated?.call();
  }

  /// 크레딧 1회 차감
  Future<bool> useCredit() async {
    if (_credits <= 0) return false;

    _credits--;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_creditsKey, _credits);
    onCreditUpdated?.call();
    return true;
  }

  /// 크레딧 구매 시작
  Future<bool> purchase(CreditPackage package) async {
    if (package.storeProduct == null) return false;

    final param = PurchaseParam(productDetails: package.storeProduct!);
    try {
      return await _iap.buyConsumable(purchaseParam: param);
    } catch (e) {
      return false;
    }
  }

  /// 구매 업데이트 처리
  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
          await _deliverCredits(purchase);
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

  /// 크레딧 지급
  Future<void> _deliverCredits(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }

    // 구매한 패키지 찾기
    final pkg = packages.firstWhere(
      (p) => p.productId == purchase.productID,
      orElse: () => packages.first,
    );

    _credits += pkg.credits;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_creditsKey, _credits);
    onCreditUpdated?.call();
  }

  void dispose() {
    _subscription?.cancel();
  }
}
