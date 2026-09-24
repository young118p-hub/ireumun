// 결과 보관·재열람: 결제한 결과를 '내 결과'에서 다시 열 수 있어야 한다 (오프라인 포함)
// 묶음 결제 차단(B-2), 지운 결과가 서버 동기화로 되살아나지 않는지

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:chemilab/data/models/saju_input.dart';
import 'package:chemilab/data/models/saved_result.dart';
import 'package:chemilab/data/services/api_service.dart';
import 'package:chemilab/data/services/purchase_service.dart';
import 'package:chemilab/data/services/result_storage_service.dart';
import 'package:chemilab/presentation/providers/naming_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:in_app_purchase/in_app_purchase.dart' show PurchaseStatus;

import 'purchase_service_test.dart' show FakeBilling, purchase;

const _input = SajuInput(year: 2024, month: 2, day: 4, hour: 10, gender: Gender.male, surname: '김');

Map<String, dynamic> _names(int n) => {
      'babySaju': {'yearPillar': '계묘', 'ohengBalance': {'목': 1}},
      'names': List.generate(n, (i) => {'name': '이름$i', 'hanja': '漢字', 'score': 90}),
    };

class ServerApi implements Api {
  final results = <String, RemoteResult>{};
  var seq = 0;
  bool offline = false;

  RemoteResult _view(RemoteResult full) => full.unlocked
      ? full
      : RemoteResult(
          id: full.id,
          kind: full.kind,
          requestType: full.requestType,
          input: full.input,
          isFreeTrial: full.isFreeTrial,
          paidProducts: full.paidProducts,
          unlocked: false,
          lockedCount: full.kind == SavedResultType.naming ? 4 : 3,
          createdAt: full.createdAt,
          content: full.kind == SavedResultType.naming
              ? {..._names(1)}
              : {
                  'saju': {},
                  'diagnosis': {'overallScore': 70, 'summaryOneLine': '한 줄'},
                  'improvementNames': [],
                },
        );

  @override
  String? get userId => 'u1';
  @override
  Future<void> ensureSignedIn() async {
    if (offline) throw const ApiException('network', '인터넷 연결을 확인해 주세요.');
  }

  @override
  Future<MeStatus> me() async {
    await ensureSignedIn();
    return MeStatus(false, 2, results.values.map(_view).toList());
  }

  @override
  Future<RemoteResult> generate(Map<String, dynamic> body) async {
    await ensureSignedIn();
    final isNaming = body['type'] != 'diagnosis';
    final r = RemoteResult(
      id: 'r${seq++}',
      kind: isNaming ? SavedResultType.naming : SavedResultType.diagnosis,
      requestType: body['type'] as String,
      input: {'surname': body['surname'], 'birthInfo': body['birthInfo']},
      isFreeTrial: seq == 1,
      paidProducts: const [],
      unlocked: false,
      lockedCount: 0,
      createdAt: DateTime(2026, 9, 23, 12, seq),
      content: isNaming
          ? _names(5)
          : {
              'saju': {},
              'diagnosis': {'overallScore': 70, 'summaryOneLine': '한 줄', 'detailAnalysis': '상세'},
              'improvementNames': _names(3)['names'],
            },
    );
    results[r.id] = r;
    return _view(r);
  }

  @override
  Future<void> preparePurchase(String productId, List<String> resultIds) async {}

  @override
  Future<List<RemoteResult>> verifyPurchase({
    required String productId,
    required String purchaseToken,
    required List<String> resultIds,
  }) async {
    return [
      for (final id in resultIds)
        results[id] = RemoteResult(
          id: id,
          kind: results[id]!.kind,
          requestType: results[id]!.requestType,
          input: results[id]!.input,
          isFreeTrial: results[id]!.isFreeTrial,
          paidProducts: [productId],
          unlocked: true,
          lockedCount: 0,
          createdAt: results[id]!.createdAt,
          content: results[id]!.content,
        ),
    ];
  }
}

void main() {
  late Directory dir;
  late ServerApi api;
  late ResultStorageService storage;
  late PurchaseService purchases;
  late NamingProvider provider;

  Future<NamingProvider> launch() async {
    storage = ResultStorageService();
    await storage.initialize();
    purchases = PurchaseService(billing: FakeBilling(), api: api);
    await purchases.initialize();
    return NamingProvider(purchaseService: purchases, storageService: storage, api: api);
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('chemilab_test');
    Hive.init(dir.path);
    api = ServerApi();
    provider = await launch();
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  Future<void> pay(ProductType type, String token) async {
    await purchases.buy(type, provider.purchaseTargets(type));
    await purchases.handlePurchase(
      purchase(purchases.getProduct(type).productId, token, PurchaseStatus.purchased),
    );
  }

  test('결제 전: 첫 이름만 있고 나머지는 잠금 자리', () async {
    await provider.generateFreeNames(_input);
    expect(provider.namingResult!.names.length, 1);
    expect(provider.lockedNamingCount, 4);
    expect(provider.isNamingPaid, false);
    expect(provider.isFreeAvailable, false);
  });

  test('결제한 결과는 앱을 다시 켜고 오프라인이어도 내 결과에서 전체가 열린다', () async {
    await provider.generatePaidSimpleNames(_input);
    await pay(ProductType.naming, 'tok1');
    expect(provider.isNamingPaid, true);
    expect(provider.namingResult!.names.length, 5);

    // 재시작 + 오프라인
    await Hive.close();
    Hive.init(dir.path);
    api.offline = true;
    provider = await launch();
    await provider.start();
    final saved = provider.savedResults.single;
    expect(saved.isPaid, true);
    provider.openSaved(saved);
    expect(provider.isNamingPaid, true);
    expect(provider.namingResult!.names.length, 5);
    expect(provider.namingSurname, '김');
  });

  test('B-2: 묶음 할인은 결제 전 작명·진단이 둘 다 있을 때만', () async {
    expect(provider.canPurchase(ProductType.bundle), false);
    await provider.generatePaidSimpleNames(_input);
    expect(provider.canPurchase(ProductType.bundle), false);
    await provider.diagnoseName(const DiagnosisInput(currentName: '민수', person: _input));
    expect(provider.canPurchase(ProductType.bundle), true);
    await pay(ProductType.bundle, 'tokB');
    expect(provider.isNamingPaid, true);
    expect(provider.isDiagnosisPaid, true);
    expect(provider.canPurchase(ProductType.bundle), false);
  });

  test('추가 개선 이름은 진단 결제 뒤에만 살 수 있다', () async {
    await provider.diagnoseName(const DiagnosisInput(currentName: '민수', person: _input));
    expect(provider.canPurchase(ProductType.diagnosisUpgrade), false);
    await pay(ProductType.diagnosis, 'tokD');
    expect(provider.canPurchase(ProductType.diagnosisUpgrade), true);
  });

  test('지운 결과는 서버 동기화로 되살아나지 않는다', () async {
    await provider.generatePaidSimpleNames(_input);
    await provider.deleteSavedResult(provider.savedResults.single.id);
    await provider.start();
    expect(provider.savedResults, isEmpty);
  });

  test('기기에 없던 결과는 서버 동기화로 채워진다 (같은 계정 복원)', () async {
    await provider.generatePaidSimpleNames(_input);
    await pay(ProductType.naming, 'tok1');
    await Hive.deleteBoxFromDisk('saved_results');
    provider = await launch();
    expect(provider.savedResults, isEmpty);
    await provider.start();
    expect(provider.savedResults.single.isPaid, true);
    expect(provider.savedResults.single.namingResult!.names.length, 5);
  });
}
