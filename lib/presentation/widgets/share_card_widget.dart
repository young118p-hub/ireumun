// 공유 카드 위젯
// 1080x1920 이미지로 캡처 가능한 결과 카드
// RepaintBoundary + GlobalKey로 이미지 캡처

import 'package:flutter/material.dart';
import '../../data/models/naming_result.dart';

class ShareCardWidget extends StatelessWidget {
  final GlobalKey cardKey;
  final SajuAnalysis saju;
  final List<NameSuggestion> names;
  final String surname;

  const ShareCardWidget({
    super.key,
    required this.cardKey,
    required this.saju,
    required this.names,
    required this.surname,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: cardKey,
      child: Container(
        width: 360, // 1080 / 3.0 pixelRatio
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF2D2D4A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 앱 로고
            const Text(
              '이름운',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 4,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'AI 사주 작명',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.6),
                letterSpacing: 2,
                decoration: TextDecoration.none,
              ),
            ),

            const SizedBox(height: 24),

            // 사주 요약
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text(
                    saju.fourPillarsDisplay,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '부족 오행: ${saju.weakElement}  |  강한 오행: ${saju.strongElement}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.7),
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 추천 이름 목록
            ...names.take(5).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final name = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: index == 0 ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.5),
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$surname${name.name} (${name.hanja})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            name.meaning,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.6),
                              decoration: TextDecoration.none,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${name.score}점',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF00B894),
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),

            // 하단 브랜딩
            Text(
              'play.google.com/store/apps/details?id=com.ireumun.ireumun',
              style: TextStyle(
                fontSize: 8,
                color: Colors.white.withValues(alpha: 0.4),
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
