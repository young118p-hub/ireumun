// 공유 서비스
// 결과 카드 이미지 생성 + 갤러리 저장 + 공유

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/naming_result.dart';

class ShareService {
  /// GlobalKey를 사용하여 위젯을 이미지로 캡처
  static Future<Uint8List?> captureWidget(GlobalKey key) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  /// 이미지를 갤러리에 저장
  static Future<bool> saveToGallery(Uint8List imageBytes) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/ireumun_card_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(imageBytes);
      final result = await GallerySaver.saveImage(file.path);
      await file.delete();
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// 이미지를 카카오톡 등으로 공유
  static Future<void> shareImage(Uint8List imageBytes) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/ireumun_share_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(imageBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '이름운 앱에서 추천받은 이름이에요 ✨',
      );
    } catch (e) {
      // 공유 실패 시 무시
    }
  }

  /// 텍스트 결과를 클립보드에 복사
  static Future<void> copyResultText({
    required String surname,
    required List<NameSuggestion> names,
    required SajuAnalysis saju,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('🎒 이름운 - AI 사주 작명 결과');
    buffer.writeln('');
    buffer.writeln('📋 사주: ${saju.fourPillarsDisplay}');
    buffer.writeln('⚖️ 부족 오행: ${saju.weakElement} / 강한 오행: ${saju.strongElement}');
    buffer.writeln('');
    buffer.writeln('✨ 추천 이름:');

    for (int i = 0; i < names.length; i++) {
      final name = names[i];
      buffer.writeln(
        '${i + 1}. $surname${name.name} (${name.hanja}) - ${name.score}점',
      );
    }

    buffer.writeln('');
    buffer.writeln('이름운 앱에서 추천받은 이름이에요!');
    buffer.writeln('https://play.google.com/store/apps/details?id=com.ireumun.ireumun');

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
  }

  /// 텍스트 공유 (share_plus)
  static Future<void> shareText({
    required String surname,
    required List<NameSuggestion> names,
    required SajuAnalysis saju,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('이름운 - AI 사주 작명 결과');
    buffer.writeln('');

    for (int i = 0; i < names.length; i++) {
      final name = names[i];
      buffer.writeln('${i + 1}. $surname${name.name} (${name.hanja}) - ${name.score}점');
    }

    buffer.writeln('');
    buffer.writeln('이름운 앱에서 추천받은 이름이에요!');

    await Share.share(buffer.toString());
  }
}
