// 가족 케미: 입력 화면 → 결과 화면, 결제 흐름(결과 자리 → 결제 → 검증 → 리포트 저장 → 소비), 재설치 복원
// 결과 화면 이미지: flutter test --update-goldens test/family_chemi_flow_test.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:in_app_purchase/in_app_purchase.dart' show PurchaseStatus;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chemilab/core/theme/chemi_theme.dart';
import 'package:chemilab/data/family_chemi/family_chemi.dart';
import 'package:chemilab/data/family_chemi/family_chemi_history.dart';
import 'package:chemilab/data/mbti/mbti_history.dart';
import 'package:chemilab/data/models/birth_value.dart';
import 'package:chemilab/data/name_chemi/name_chemi_history.dart';
import 'package:chemilab/data/pair_chemi/pair_chemi_history.dart';
import 'package:chemilab/data/services/purchase_service.dart';
import 'package:chemilab/data/services/result_storage_service.dart';
import 'package:chemilab/presentation/providers/chemi_provider.dart';
import 'package:chemilab/presentation/providers/naming_provider.dart';
import 'package:chemilab/presentation/screens/family_chemi_input_screen.dart';
import 'package:chemilab/presentation/screens/family_chemi_result_screen.dart';
import 'package:chemilab/presentation/screens/pair_chemi_result_screen.dart';

import 'naming_provider_test.dart' show ServerApi;
import 'purchase_service_test.dart' show FakeBilling, purchase;

Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/$f').readAsBytesSync())));
    }
    await loader.load();
  }

  await load('Jua', ['Jua-Regular.ttf']);
  await load('IBMPlexSansKR', ['IBMPlexSansKR-Medium.ttf', 'IBMPlexSansKR-Bold.ttf']);
}

final members = [
  FamilyInput(FamilyRole.me, '민서', BirthValue(DateTime(1998, 3, 14), 10)),
  FamilyInput(FamilyRole.mom, '엄마', BirthValue(DateTime(1970, 8, 2), -1)),
  FamilyInput(FamilyRole.dad, '아빠', BirthValue(DateTime(1968, 11, 20), 6)),
];

void main() {
  setUpAll(_loadFonts);

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

  Future<void> fresh() async {
    SharedPreferences.setMockInitialValues({});
    final dir = await Directory.systemTemp.createTemp('chemilab_family');
    Hive.init(dir.path);
    api = ServerApi();
    await launch();
  }

  group('결제', () {
    setUp(fresh);
    tearDown(Hive.close);

    test('결과 자리 → 결제 창 → 검증 → 리포트 저장 → 그다음 소비', () async {
      await chemi.recordFamily(members);
      final record = chemi.familyRecords.single;
      expect(chemi.myProfile?.name, '민서'); // "나"는 다음 입력에 미리 채운다

      final id = await chemi.ensureFamilyRemote(record);
      expect(await chemi.ensureFamilyRemote(chemi.familyRecords.single), id);
      await naming.purchaseResults(ProductType.familyChemi, [id]);
      expect(billing.log.first, startsWith('buy:chemi_family:'));

      await purchases.handlePurchase(purchase('chemi_family', 'tokF', PurchaseStatus.purchased));
      final paid = chemi.familyRecords.single;
      expect(paid.paid, isTrue);
      expect((paid.report!['members'] as List).length, 3);
      expect(billing.log.last, 'finish:tokF');
      expect(naming.savedResults, isEmpty);
    });

    test('재설치: 서버에 남은 입력으로 기록과 리포트를 되살린다', () async {
      await chemi.recordFamily(members);
      final id = await chemi.ensureFamilyRemote(chemi.familyRecords.single);
      await naming.purchaseResults(ProductType.familyChemi, [id]);
      await purchases.handlePurchase(purchase('chemi_family', 'tokF', PurchaseStatus.purchased));

      SharedPreferences.setMockInitialValues({}); // 기기 기록이 사라짐
      await launch();
      expect(chemi.familyRecords, isEmpty);
      await naming.start();
      final back = chemi.familyRecords.single;
      expect(back.paid, isTrue);
      expect(back.members.map((m) => m.name), ['민서', '엄마', '아빠']);
      expect(back.chemi.score, FamilyChemiRecord(members: members, at: DateTime(2026)).chemi.score);
    });
  });

  group('화면', () {
    void phone(WidgetTester tester) {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
    }

    Widget app(Widget home) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: chemi),
            ChangeNotifierProvider.value(value: naming),
          ],
          child: MaterialApp(theme: chemiTheme(), debugShowCheckedModeBanner: false, home: home),
        );

    testWidgets('입력: 처음 세 칸, 5명까지 더하고 3명 밑으로는 못 뺀다, 결과로 가면 기록', (tester) async {
      phone(tester);
      await tester.runAsync(fresh);
      await tester.pumpWidget(app(const FamilyChemiInputScreen()));
      expect(find.byTooltip('빼기'), findsNothing); // 3명이면 뺄 수 없음
      for (var i = 0; i < 2; i++) {
        await tester.ensureVisible(find.textContaining('가족 더하기'));
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('가족 더하기'));
        await tester.pump();
      }
      expect(find.textContaining('가족 더하기'), findsNothing); // 5명이면 버튼이 사라짐
      expect(find.byTooltip('빼기'), findsNWidgets(5));

      await tester.tap(find.text('가족 케미 보기'));
      await tester.pumpAndSettle();
      expect(find.byType(FamilyChemiResultScreen), findsOneWidget);
      // 이름을 비운 형제 둘은 형제, 형제2
      expect(chemi.familyRecords.single.members.map((m) => m.name), ['나', '엄마', '아빠', '형제', '형제2']);
    });

    testWidgets('결과 화면 (이미지로 남김) + 두 사람 줄을 누르면 결제 칸 없는 두 사람 케미', (tester) async {
      phone(tester);
      await tester.runAsync(fresh);
      await tester.pumpWidget(app(FamilyChemiResultScreen(members: members, record: false)));
      await tester.pumpAndSettle();
      for (final t in ['우리 집 역할', '우리 가족 중 누가?', '가족 오행 지도', '두 사람씩 케미', '케미 올리는 법']) {
        expect(find.text(t), findsOneWidget);
      }
      for (var i = 1; i <= 5; i++) {
        await expectLater(find.byType(FamilyChemiResultScreen), matchesGoldenFile('goldens/family_$i.png'));
        await tester.drag(find.byType(ListView).first, const Offset(0, -760));
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.text('민서 × 엄마'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('민서 × 엄마'));
      await tester.pumpAndSettle();
      expect(find.byType(PairChemiResultScreen), findsOneWidget);
      expect(find.textContaining('우리 케미 · 가족'), findsOneWidget);
      expect(find.textContaining('전체 리포트 열기'), findsNothing);
      expect(chemi.pairRecords, isEmpty); // 가족 안 두 사람은 우리 케미 기록에 넣지 않음
    });
  });
}
