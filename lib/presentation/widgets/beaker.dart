// 연구소 마스코트 비커 (시안의 SVG와 같은 모양을 100×112 좌표로 그린다)

import 'package:flutter/material.dart';
import '../../core/theme/chemi_theme.dart';

enum BeakerFace { smile, wink, happy }

class Beaker extends StatelessWidget {
  final double width;
  final Color glass;
  final Color liquid;
  final Color line;
  final BeakerFace face;

  const Beaker({
    super.key,
    this.width = 110,
    this.glass = ChemiColors.chrome,
    this.liquid = ChemiColors.ink,
    this.line = ChemiColors.ink,
    this.face = BeakerFace.smile,
  });

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: width * 1.12,
        child: CustomPaint(painter: _BeakerPainter(glass, liquid, line, face)),
      ),
    );
  }
}

class _BeakerPainter extends CustomPainter {
  final Color glass, liquid, line;
  final BeakerFace face;
  _BeakerPainter(this.glass, this.liquid, this.line, this.face);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 112);

    final body = Path()
      ..moveTo(38, 14)
      ..lineTo(62, 14)
      ..lineTo(62, 38)
      ..lineTo(80, 66)
      ..arcToPoint(const Offset(60, 102), radius: const Radius.circular(24))
      ..lineTo(40, 102)
      ..arcToPoint(const Offset(20, 66), radius: const Radius.circular(24))
      ..lineTo(38, 38)
      ..close();

    canvas.drawPath(body, Paint()..color = glass);

    // 액체: 몸통 안쪽만
    canvas.save();
    canvas.clipPath(body);
    canvas.drawRect(const Rect.fromLTWH(0, 72, 100, 40), Paint()..color = liquid);
    final bubble = Paint()..color = glass.withValues(alpha: 0.8);
    canvas.drawCircle(const Offset(40, 86), 3, bubble);
    canvas.drawCircle(const Offset(60, 92), 2, bubble);
    canvas.restore();

    final stroke = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(body, stroke);
    canvas.drawLine(const Offset(36, 10), const Offset(64, 10), stroke);

    // 반짝임
    canvas.drawLine(const Offset(29, 46), const Offset(37, 41),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round);

    // 얼굴
    final eye = Path();
    switch (face) {
      case BeakerFace.smile:
        eye
          ..moveTo(38, 57)
          ..quadraticBezierTo(42, 53, 46, 57)
          ..moveTo(54, 57)
          ..quadraticBezierTo(58, 53, 62, 57);
      case BeakerFace.wink:
        eye
          ..moveTo(38, 57)
          ..quadraticBezierTo(42, 53, 46, 57)
          ..moveTo(54, 55)
          ..lineTo(62, 58);
      case BeakerFace.happy:
        eye
          ..moveTo(38, 55)
          ..lineTo(44, 58)
          ..lineTo(38, 61)
          ..moveTo(62, 55)
          ..lineTo(56, 58)
          ..lineTo(62, 61);
    }
    eye
      ..moveTo(45, 66)
      ..quadraticBezierTo(50, 70, 55, 66);
    canvas.drawPath(eye, stroke);
  }

  @override
  bool shouldRepaint(_BeakerPainter old) =>
      old.glass != glass || old.liquid != liquid || old.line != line || old.face != face;
}
