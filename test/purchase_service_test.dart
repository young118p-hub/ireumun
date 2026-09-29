// 결제 순서 테스트: 서버 준비 확인 → 결제 → 서버 검증 → 기기 저장 → 소비
// (저장 전에 소비하면 앱이 꺼졌을 때 돈만 나가고 결과를 잃는다)

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:chemilab/data/models/saved_result.dart';
import 'package:chemilab/data/services/api_service.dart';
import 'package:chemilab/data/services/purchase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeBilling implements BillingGateway {
  final controller = StreamController<List<PurchaseDetails>>.broadcast();
  final log = <String>[];
  bool launch = true;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => controller.stream;
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<List<ProductDetails>> queryProducts(Set<String> ids) async => ids
      .map((id) => ProductDetails(
            id: id,
            title: id,
            description: '',
            price: '₩0',
            rawPrice: 0,
            currencyCode: 'KRW',
          ))
      .toList();
  @override
  Future<bool> buy(ProductDetails product, String accountId) async {
    log.add('buy:${product.id}:$accountId');
    return launch;
  }

  @override
  Future<void> finish(PurchaseDetails purchase) async =>
      log.add('finish:${purchase.verificationData.serverVerificationData}');
  @override
  Future<void> dismiss(PurchaseDetails purchase) async =>
      log.add('dismiss:${purchase.productID}');
  @override
  Future<void> restore() async => log.add('restore');
}

class FakeApi implements Api {
  final log = <String>[];
  ApiException? prepareError;
  ApiException? verifyError;
  Completer<void>? verifyGate;

  @override
  String? get userId => 'user-1';
  @override
  Future<void> ensureSignedIn() async {}
  @override
  Future<MeStatus> me() async => const MeStatus(true, 3, []);
  @override
  Future<RemoteResult> generate(Map<String, dynamic> body) =>
      throw UnimplementedError();
  @override
  Future<void> preparePurchase(String productId, List<String> resultIds) async {
    log.add('prepare:$productId:${resultIds.join(',')}');
    if (prepareError != null) throw prepareError!;
  }

  @override
  Future<List<RemoteResult>> verifyPurchase({
    required String productId,
    required String purchaseToken,
    required List<String> resultIds,
  }) async {
    log.add('verify:$productId:$purchaseToken:${resultIds.join(',')}');
    if (verifyGate != null) await verifyGate!.future;
    if (verifyError != null) throw verifyError!;
    return [
      RemoteResult(
        id: resultIds.isEmpty ? 'r-default' : resultIds.first,
        kind: SavedResultType.naming,
        requestType: 'naming_simple',
        input: const {'surname': '김'},
        isFreeTrial: false,
        paidProducts: [productId],
        unlocked: true,
        lockedCount: 0,
        createdAt: DateTime(2026, 9, 23),
        content: const {'babySaju': {}, 'names': []},
      ),
    ];
  }
}

PurchaseDetails purchase(String productId, String token, PurchaseStatus status) =>
    PurchaseDetails(
      purchaseID: 'GPA.$token',
      productID: productId,
      verificationData: PurchaseVerificationData(
        localVerificationData: '',
        serverVerificationData: token,
        source: 'google_play',
      ),
      transactionDate: null,
      status: status,
    )..pendingCompletePurchase = true;

void main() {
  late FakeBilling billing;
  late FakeApi api;
  late PurchaseService service;
  late List<String> order;
  late List<PurchaseEvent> events;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    billing = FakeBilling();
    api = FakeApi();
    service = PurchaseService(billing: billing, api: api);
    order = [];
    events = [];
    service.onDelivered = (type, results) async {
      order.add('saved:${results.map((r) => r.id).join(',')}');
      billing.log.add('saved');
    };
    service.onEvent = events.add;
    await service.initialize();
  });

  test('B-2: 서버가 풀어줄 게 없다고 하면 결제 창을 띄우지 않는다', () async {
    api.prepareError = const ApiException('nothing_to_unlock', '결과 없음');
    await expectLater(service.buy(ProductType.bundle, const []), throwsA(isA<ApiException>()));
    expect(billing.log.where((l) => l.startsWith('buy')), isEmpty);
  });

  test('결제 창에는 계정 ID를 실어 보낸다 (서버가 영수증과 대조)', () async {
    await service.buy(ProductType.naming, ['r1']);
    expect(api.log, ['prepare:naming_new:r1']);
    expect(billing.log, ['buy:naming_new:user-1']);
  });

  test('B-1/B-4: 검증 → 기기 저장 → 소비 순서', () async {
    await service.buy(ProductType.naming, ['r1']);
    await service.handlePurchase(purchase('naming_new', 'tok1', PurchaseStatus.purchased));
    expect(api.log.last, 'verify:naming_new:tok1:r1');
    expect(billing.log.sublist(1), ['saved', 'finish:tok1']);
    expect(order, ['saved:r1']);
    expect(events.last.kind, PurchaseEventKind.delivered);
  });

  test('검증 실패면 소비하지 않는다 (다음 실행 때 재시도, 끝내 안 되면 Play 자동 환불)', () async {
    api.verifyError = const ApiException('verify_unavailable', '지연');
    await service.handlePurchase(purchase('naming_new', 'tok1', PurchaseStatus.purchased));
    expect(billing.log.where((l) => l.startsWith('finish')), isEmpty);
    expect(order, isEmpty);
    expect(events.last.kind, PurchaseEventKind.failed);
  });

  test('기기 저장이 실패해도 소비하지 않는다', () async {
    service.onDelivered = (type, results) async => throw Exception('disk full');
    await service.handlePurchase(purchase('naming_new', 'tok1', PurchaseStatus.purchased));
    expect(billing.log.where((l) => l.startsWith('finish')), isEmpty);
    expect(events.last.kind, PurchaseEventKind.failed);
  });

  test('B-3: 결제 창이 떴다고 완료로 치지 않는다 — 완료 안내는 검증 뒤에만', () async {
    await service.buy(ProductType.naming, ['r1']);
    expect(events.where((e) => e.kind == PurchaseEventKind.delivered), isEmpty);
  });

  test('앱이 결제 중 꺼져도: 다음 실행 때 restore로 받은 구매를 적어 둔 대상으로 검증', () async {
    await service.buy(ProductType.diagnosis, ['d1']);
    // 앱 재시작
    final restarted = PurchaseService(billing: billing, api: api)
      ..onDelivered = (type, results) async => order.add('saved');
    await restarted.initialize();
    await restarted.recoverUnfinished();
    await restarted.handlePurchase(purchase('diagnosis', 'tok9', PurchaseStatus.restored));
    expect(api.log.last, 'verify:diagnosis:tok9:d1');
    expect(billing.log.last, 'finish:tok9');
  });

  test('같은 구매가 겹쳐 들어와도 검증은 한 번', () async {
    api.verifyGate = Completer<void>();
    final p = purchase('naming_new', 'tok1', PurchaseStatus.purchased);
    final first = service.handlePurchase(p);
    await service.handlePurchase(p);
    api.verifyGate!.complete();
    await first;
    expect(api.log.where((l) => l.startsWith('verify')).length, 1);
  });

  test('취소·대기는 검증도 소비도 안 한다', () async {
    await service.buy(ProductType.naming, ['r1']);
    await service.handlePurchase(purchase('naming_new', 't', PurchaseStatus.pending));
    await service.handlePurchase(purchase('naming_new', 't', PurchaseStatus.canceled));
    expect(api.log.where((l) => l.startsWith('verify')), isEmpty);
    expect(billing.log.where((l) => l.startsWith('finish')), isEmpty);
    expect(events.map((e) => e.kind), [PurchaseEventKind.pending, PurchaseEventKind.canceled]);
  });

  test('모르는 상품 ID는 건드리지 않는다', () async {
    await service.handlePurchase(purchase('other_app_item', 't', PurchaseStatus.purchased));
    expect(api.log, isEmpty);
  });

  test('가격은 Prices 한 곳: 스토어 정보 없을 때 작명 ₩7,900, 묶음 할인 ₩1,900', () {
    final s = PurchaseService(billing: billing, api: api);
    expect(s.getProduct(ProductType.naming).priceString, '₩7,900');
    expect(s.bundleDiscount, 1900);
  });
}
