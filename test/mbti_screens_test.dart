// MBTI 케미 결과 화면을 이미지로 남긴다 (둘 중 누가? · 케미 올리는 법 포함)
// 이미지 갱신: flutter test --update-goldens test/mbti_screens_test.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chemilab/core/theme/chemi_theme.dart';
import 'package:chemilab/data/mbti/mbti_history.dart';
import 'package:chemilab/data/name_chemi/name_chemi_history.dart';
import 'package:chemilab/data/family_chemi/family_chemi_history.dart';
import 'package:chemilab/data/pair_chemi/pair_chemi_history.dart';
import 'package:chemilab/presentation/providers/chemi_provider.dart';
import 'package:chemilab/presentation/screens/mbti_result_screen.dart';

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

void main() {
  setUpAll(_loadFonts);

  testWidgets('결과 화면 (이미지로 남김: test/goldens/mbti_result*.png)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final chemi = ChemiProvider(MbtiHistory(prefs), NameChemiHistory(prefs), PairChemiHistory(prefs), FamilyChemiHistory(prefs));
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: chemi,
      child: MaterialApp(
        theme: chemiTheme(),
        debugShowCheckedModeBanner: false,
        home: const MbtiResultScreen(me: 'ENFP', you: 'ISTJ', record: false),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('둘 중 누가?'), findsOneWidget);
    expect(find.text('케미 올리는 법'), findsOneWidget);
    for (var i = 1; i <= 5; i++) {
      await expectLater(find.byType(MbtiResultScreen), matchesGoldenFile('goldens/mbti_result_$i.png'));
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -760));
      await tester.pumpAndSettle();
    }
  });
}
