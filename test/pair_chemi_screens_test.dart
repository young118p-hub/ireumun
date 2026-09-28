// 우리 케미 결과 화면을 이미지로 남긴다 (결제 전 / 결제 뒤). 에뮬레이터에 한글 입력이 안 돼서 여기서 본다.
// 이미지 갱신: flutter test --update-goldens test/pair_chemi_screens_test.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chemilab/core/theme/chemi_theme.dart';
import 'package:chemilab/data/mbti/mbti_history.dart';
import 'package:chemilab/data/models/birth_value.dart';
import 'package:chemilab/data/name_chemi/name_chemi_history.dart';
import 'package:chemilab/data/pair_chemi/pair_chemi.dart';
import 'package:chemilab/data/pair_chemi/pair_chemi_history.dart';
import 'package:chemilab/data/services/purchase_service.dart';
import 'package:chemilab/data/services/result_storage_service.dart';
import 'package:chemilab/presentation/providers/chemi_provider.dart';
import 'package:chemilab/presentation/providers/naming_provider.dart';
import 'package:chemilab/presentation/screens/pair_chemi_result_screen.dart';

import 'naming_provider_test.dart' show ServerApi, pairReport;
import 'purchase_service_test.dart' show FakeBilling;

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

final me = PairInput('민서', BirthValue(DateTime(1998, 5, 11), 14));
final you = PairInput('지우', BirthValue(DateTime(1997, 11, 3), 10));

void main() {
  setUpAll(_loadFonts);

  Future<(ChemiProvider, NamingProvider)> providers(WidgetTester tester, {bool paid = false}) async {
    late ChemiProvider chemi;
    late NamingProvider naming;
    await tester.runAsync(() async {
      SharedPreferences.setMockInitialValues({});
      final dir = await Directory.systemTemp.createTemp('pair_golden');
      Hive.init(dir.path);
      final storage = ResultStorageService();
      await storage.initialize();
      final api = ServerApi();
      final purchases = PurchaseService(billing: FakeBilling(), api: api);
      naming = NamingProvider(purchaseService: purchases, storageService: storage, api: api);
      final prefs = await SharedPreferences.getInstance();
      final history = PairChemiHistory(prefs);
      chemi = ChemiProvider(MbtiHistory(prefs), NameChemiHistory(prefs), history, api: api);
      if (paid) {
        await history.add(PairChemiRecord(
          a: me,
          b: you,
          relation: PairRelation.lover,
          at: DateTime(2026, 9, 28),
          remoteId: 'p1',
          paid: true,
          report: Map<String, dynamic>.from(pairReport['report']!),
        ));
      }
    });
    return (chemi, naming);
  }

  Widget app(ChemiProvider chemi, NamingProvider naming) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: chemi),
          ChangeNotifierProvider.value(value: naming),
        ],
        child: MaterialApp(
          theme: chemiTheme(),
          debugShowCheckedModeBanner: false,
          home: PairChemiResultScreen(me: me, you: you, relation: PairRelation.lover, record: false),
        ),
      );

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
  }

  testWidgets('결제 전: 무료 해설 + 잠긴 전체 리포트', (tester) async {
    phone(tester);
    final (chemi, naming) = await providers(tester);
    await tester.pumpWidget(app(chemi, naming));
    await tester.pumpAndSettle();
    expect(find.textContaining('전체 리포트 열기'), findsOneWidget);
    for (var i = 1; i <= 4; i++) {
      await expectLater(find.byType(PairChemiResultScreen), matchesGoldenFile('goldens/pair_free_$i.png'));
      await tester.drag(find.byType(ListView).first, const Offset(0, -760));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('결제 뒤: 리포트가 보이고 결제 버튼은 없다', (tester) async {
    phone(tester);
    final (chemi, naming) = await providers(tester, paid: true);
    await tester.pumpWidget(app(chemi, naming));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -2400));
    await tester.pumpAndSettle();
    expect(find.text('잘 맞는 점 · 좋1'), findsOneWidget);
    expect(find.textContaining('전체 리포트 열기'), findsNothing);
    await expectLater(find.byType(PairChemiResultScreen), matchesGoldenFile('goldens/pair_paid.png'));
  });
}
