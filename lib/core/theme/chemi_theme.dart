// 케미연구소 디자인 토큰 (시안 K: 핑크 상단 + 크롬 하단)
// 제목·숫자는 Jua, 본문은 IBM Plex Sans KR (둘 다 OFL, assets/fonts).
// 색은 여기서만 정한다. 화면에 색 코드를 직접 쓰지 않는다.

import 'package:flutter/material.dart';

class ChemiColors {
  ChemiColors._();

  static const pink = Color(0xFFFF3EA0); // 포인트 (핑크 영역, 강조)
  static const pinkDeep = Color(0xFFC4006A); // 크롬·흰 바탕 위 핑크 글씨 (대비 확보)
  static const chrome = Color(0xFFE8E9EE); // 바탕
  static const ink = Color(0xFF111114); // 글씨, 검은 카드, 주 버튼
  static const inkSoft = Color(0xFF26262D); // 검은 카드 안의 칸
  static const inkLine = Color(0xFF34343C); // 검은 카드 안의 선
  static const card = Colors.white;
  static const muted = Color(0xFF5E5F6B); // 보조 글씨 (크롬 위 4.5:1 이상)
  static const mutedOnInk = Color(0xFFC9CCD6); // 검은 바탕 위 보조 글씨
  static const disabled = Color(0xFF9C9DA8);
}

class ChemiFonts {
  ChemiFonts._();
  static const display = 'Jua';
  static const body = 'IBMPlexSansKR';
}

class ChemiText {
  ChemiText._();

  static TextStyle display(double size, {Color color = ChemiColors.ink, double height = 1.15}) =>
      TextStyle(fontFamily: ChemiFonts.display, fontSize: size, height: height, color: color);

  static TextStyle body(double size,
          {Color color = ChemiColors.ink, FontWeight weight = FontWeight.w500, double height = 1.5}) =>
      TextStyle(fontFamily: ChemiFonts.body, fontSize: size, fontWeight: weight, height: height, color: color);

  static TextStyle label(double size, {Color color = ChemiColors.ink}) =>
      body(size, color: color, weight: FontWeight.w700, height: 1.3);
}

ThemeData chemiTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: ChemiFonts.body,
    colorScheme: ColorScheme.fromSeed(
      seedColor: ChemiColors.pink,
      primary: ChemiColors.ink,
      onPrimary: Colors.white,
      secondary: ChemiColors.pink,
      surface: ChemiColors.chrome,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: ChemiColors.chrome,
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: ChemiColors.chrome,
      foregroundColor: ChemiColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontFamily: ChemiFonts.display, fontSize: 20, color: ChemiColors.ink),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ChemiColors.ink,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontFamily: ChemiFonts.body, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 0,
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: ChemiColors.ink,
      contentTextStyle: TextStyle(fontFamily: ChemiFonts.body, color: Colors.white),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
