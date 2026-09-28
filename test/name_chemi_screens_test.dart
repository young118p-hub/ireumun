// 이름 케미 화면: 입력 → 결과까지 실제로 눌러 보고, 결과 화면을 이미지로 남긴다.
// (에뮬레이터에는 adb로 한글을 넣을 수 없어서 화면 확인을 여기서 한다)
// 이미지 갱신: flutter test --update-goldens test/name_chemi_screens_test.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chemilab/core/theme/chemi_theme.dart';
import 'package:chemilab/data/mbti/mbti_history.dart';
import 'package:chemilab/data/name_chemi/name_chemi_history.dart';
import 'package:chemilab/presentation/providers/chemi_provider.dart';
import 'package:chemilab/presentation/screens/name_chemi_input_screen.dart';
import 'package:chemilab/presentation/screens/name_chemi_result_screen.dart';

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

Future<ChemiProvider> _provider() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ChemiProvider(MbtiHistory(prefs), NameChemiHistory(prefs));
}

Widget _app(ChemiProvider chemi, Widget home) => ChangeNotifierProvider.value(
      value: chemi,
      child: MaterialApp(theme: chemiTheme(), home: home, debugShowCheckedModeBanner: false),
    );

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.75; // 약 393×851 (에뮬레이터와 비슷)
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('두 이름을 넣어야 버튼이 눌리고, 결과로 가면 기록과 내 이름이 남는다', (tester) async {
    _phone(tester);
    final chemi = await _provider();
    await tester.pumpWidget(_app(chemi, const NameChemiInputScreen()));

    expect(find.text('두 이름을 넣어 주세요'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), '김민서');
    await tester.pump();
    expect(find.text('두 이름을 넣어 주세요'), findsOneWidget); // 한 명만으로는 안 됨
    expect(find.text('民'), findsNothing);
    expect(find.text('민'), findsOneWidget); // 입력하는 동안 글자별 오행 칩

    await tester.enterText(find.byType(TextField).at(1), '이지우');
    await tester.pump();
    await tester.tap(find.text('이름 케미 보기'));
    await tester.pumpAndSettle();

    expect(find.byType(NameChemiResultScreen), findsOneWidget);
    expect(chemi.nameRecords.single.a, '김민서');
    expect(chemi.myName, '김민서');

    // 뒤로 오면 입력값이 그대로
    await tester.tap(find.byTooltip('뒤로'));
    await tester.pumpAndSettle();
    expect(find.text('이지우'), findsWidgets);
  });

  testWidgets('결과 화면 (이미지로 남김: test/goldens/name_chemi_result*.png)', (tester) async {
    _phone(tester);
    final chemi = await _provider();
    await tester.pumpWidget(_app(chemi, const NameChemiResultScreen(me: '김민서', you: '이지우', record: false)));
    await tester.pumpAndSettle();
    await expectLater(find.byType(NameChemiResultScreen), matchesGoldenFile('goldens/name_chemi_result_1.png'));
    await tester.drag(find.byType(ListView).first, const Offset(0, -700));
    await tester.pumpAndSettle();
    await expectLater(find.byType(NameChemiResultScreen), matchesGoldenFile('goldens/name_chemi_result_2.png'));
    await tester.drag(find.byType(ListView).first, const Offset(0, -900));
    await tester.pumpAndSettle();
    await expectLater(find.byType(NameChemiResultScreen), matchesGoldenFile('goldens/name_chemi_result_3.png'));
  });
}
