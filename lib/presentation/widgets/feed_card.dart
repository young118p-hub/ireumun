// 결과 카드 (홈 가로 목록)
// 예시 카드는 "예시" 표시 + 점선 테두리로, 내 결과와 헷갈리지 않게.
// 점수를 모르면(null) 숫자 대신 "?"를 보여 준다. 지어낸 숫자는 쓰지 않는다.

import 'package:flutter/material.dart';
import '../../core/theme/chemi_theme.dart';
import '../feed.dart';

class FeedCard extends StatelessWidget {
  static const double width = 150;
  static const double height = 176;

  final String label;
  final String headline;
  final int? score;
  final String summary;
  final FeedKind kind;
  final bool isExample;
  final bool isPreview;
  final VoidCallback onTap;

  FeedCard({super.key, required FeedItem item, required this.onTap})
      : label = item.label,
        headline = item.headline,
        score = item.score,
        summary = item.summary,
        kind = item.kind,
        isExample = false,
        isPreview = item.isPreview;

  const FeedCard.example({
    super.key,
    required this.label,
    required this.headline,
    required this.score,
    required this.summary,
    required this.kind,
    required this.onTap,
  })  : isExample = true,
        isPreview = false;

  (Color bg, Color fg, Color sub) get _colors => switch (kind) {
        FeedKind.mbti => (ChemiColors.pink, ChemiColors.ink, ChemiColors.ink),
        FeedKind.nameChemi => (Colors.white, ChemiColors.ink, ChemiColors.muted),
        FeedKind.babyName => (ChemiColors.ink, Colors.white, ChemiColors.mutedOnInk),
      };

  @override
  Widget build(BuildContext context) {
    final (bg, fg, sub) = _colors;
    final tag = isExample ? '예시' : (isPreview ? '미리보기' : null);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(24));
    return Semantics(
      button: true,
      label: [
        if (isExample) '예시',
        label,
        headline,
        if (score != null) '$score점',
        summary,
      ].join(', '),
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        height: height,
        child: Material(
          color: bg,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: CustomPaint(
              foregroundPainter: isExample ? _DashedBorder(fg.withValues(alpha: 0.5)) : null,
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(label, overflow: TextOverflow.ellipsis, style: ChemiText.label(11, color: sub)),
                        ),
                        if (tag != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              border: Border.all(color: sub),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(tag, style: ChemiText.label(10, color: sub)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(headline,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: ChemiText.display(17, color: fg)),
                    const Spacer(),
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(text: score?.toString() ?? '?', style: ChemiText.display(44, color: fg, height: 1)),
                        TextSpan(text: '점', style: ChemiText.display(16, color: fg)),
                      ]),
                    ),
                    const SizedBox(height: 4),
                    Text(summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: ChemiText.label(12, color: fg).copyWith(height: 1.35)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  final Color color;
  _DashedBorder(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(24)).deflate(1);
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}
