// 우리 케미 결제 흐름: 결과 자리(서버, AI 없음) → Play 결제 → 검증 → 리포트를 기기 기록에 저장 → 소비
// 재설치 복원, 모르는 결과 종류가 섞여도 작명·진단 동기화가 멈추지 않는지

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:in_app_purchase/in_app_purchase.dart' show PurchaseStatus;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chemilab/data/mbti/mbti_history.dart';
import 'package:chemilab/data/models/birth_value.dart';
import 'package:chemilab/data/models/saju_input.dart';
import 'package:chemilab/data/name_chemi/name_chemi_history.dart';
import 'package:chemilab/data/pair_chemi/pair_chemi.dart';
import 'package:chemilab/data/family_chemi/family_chemi_history.dart';
import 'package:chemilab/data/pair_chemi/pair_chemi_history.dart';
import 'package:chemilab/data/services/api_service.dart';
import 'package:chemilab/data/services/purchase_service.dart';
import 'package:chemilab/data/services/result_storage_service.dart';
import 'package:chemilab/presentation/providers/chemi_provider.dart';
import 'package:chemilab/presentation/providers/naming_provider.dart';

import 'naming_provider_test.dart' show ServerApi;
import 'purchase_service_test.dart' show FakeBilling, purchase;

final me = PairInput('민서', BirthValue(DateTime(1998, 5, 11), 14));
final you = PairInput('지우', BirthValue(DateTime(1997, 11, 3), -1));

void main() {
  late Directory dir;
  late ServerApi api;
  late FakeBilling billing;
  late PurchaseService purchases;
  late NamingProvider naming;
  late ChemiProvider chemi;

  Future<void> launch() async {
    final storage = ResultStorageService();
    await storage.initialize();
    billing = FakeBilling();
    purchases = PurchaseService(billing: billing, api: api);
    await purchases.initialize();
    naming = NamingProvider(purchaseService: purchases, storageService: storage, api: api);
    final prefs = await SharedPreferences.getInstance();
    chemi = ChemiProvider(MbtiHistory(prefs), NameChemiHistory(prefs), PairChemiHistory(prefs), FamilyChemiHistory(prefs), api: api);
    naming.onChemiResult = chemi.applyRemote;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('chemilab_pair');
    Hive.init(dir.path);
    api = ServerApi();
    await launch();
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  PairChemiRecord record() => chemi.pairRecords.single;

  test('결제: 결과 자리 → 결제 창 → 검증 → 리포트 저장 → 그다음 소비', () async {
    await chemi.recordPair(me, you, PairRelation.lover);
    expect(record().paid, isFalse);

    final id = await chemi.ensurePairRemote(record());
    expect(record().remoteId, id);
    expect(await chemi.ensurePairRemote(record()), id); // 두 번 눌러도 자리는 하나

    await naming.purchaseResults(ProductType.pairChemi, [id]);
    expect(billing.log.first, startsWith('buy:chemi_pair:'));

    await purchases.handlePurchase(purchase('chemi_pair', 'tokP', PurchaseStatus.purchased));
    expect(record().paid, isTrue);
    expect((record().report!['goodPoints'] as List).length, 3);
    expect(billing.log.last, 'finish:tokP'); // 기기 저장 뒤에 소비
    expect(naming.savedResults, isEmpty); // 작명·진단 저장소에는 섞이지 않음
  });

  test('재설치: 기기 기록이 없어도 서버 결과로 되살아나고, 결제한 리포트도 온다', () async {
    await chemi.recordPair(me, you, PairRelation.friend);
    final id = await chemi.ensurePairRemote(record());
    await naming.purchaseResults(ProductType.pairChemi, [id]);
    await purchases.handlePurchase(purchase('chemi_pair', 'tokR', PurchaseStatus.purchased));

    SharedPreferences.setMockInitialValues({}); // 기기 기록 삭제
    await Hive.close();
    Hive.init(dir.path);
    await launch();
    expect(chemi.pairRecords, isEmpty);

    await naming.start();
    final r = record();
    expect(r.a.name, '민서');
    expect(r.b.birth.hourKnown, isFalse);
    expect(r.relation, PairRelation.friend);
    expect(r.paid, isTrue);
    expect(r.report, isNotNull);
    expect(r.chemi.score, pairChemi(me.toPerson(), you.toPerson()).score); // 같은 점수로 다시 계산
  });

  test('모르는 결과 종류가 섞여도 작명 동기화는 그대로 (예전엔 동기화가 통째로 실패)', () async {
    await naming.generatePaidSimpleNames(
      const SajuInput(year: 2024, month: 2, day: 4, hour: 10, gender: Gender.male, surname: '김'),
    );
    api.results['f1'] = RemoteResult(
      id: 'f1',
      kind: null,
      kindName: 'family',
      requestType: 'family',
      input: const {},
      isFreeTrial: false,
      paidProducts: const [],
      unlocked: false,
      lockedCount: 0,
      createdAt: DateTime(2026, 9, 28),
      content: const {},
    );
    await Hive.deleteBoxFromDisk('saved_results');
    await launch();
    await naming.start();
    expect(naming.savedResults.length, 1);
  });
}
