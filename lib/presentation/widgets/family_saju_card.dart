// 가족 사주 시각화 위젯
// 아기 + 아빠 + 엄마 오행 균형 종합 분석 카드

import 'package:flutter/material.dart';
import '../../core/theme/chemi_theme.dart';
import '../../data/models/naming_result.dart';

class FamilySajuCard extends StatelessWidget {
  final NamingResult result;

  const FamilySajuCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final family = result.familyAnalysis;
    if (family == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타이틀
          const Row(
            children: [
              Icon(Icons.family_restroom, size: 20, color: ChemiColors.ink),
              SizedBox(width: 8),
              Text(
                '가족 오행 균형 분석',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: ChemiFonts.display,
                  color: ChemiColors.ink,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 가족 3인 사주 요약
          Row(
            children: [
              _buildMemberChip('아기', result.babySaju),
              if (result.fatherSaju != null)
                _buildMemberChip('아빠', result.fatherSaju!),
              if (result.motherSaju != null)
                _buildMemberChip('엄마', result.motherSaju!),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(height: 1, color: ChemiColors.chrome),
          const SizedBox(height: 16),

          // 가족 종합 오행 분포
          const Text(
            '가족 종합 오행 분포',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ChemiColors.muted,
            ),
          ),
          const SizedBox(height: 12),
          _buildCombinedOhengChart(family.combinedBalance),

          const SizedBox(height: 16),

          // 부족/과다 오행
          Row(
            children: [
              _buildTag('부족', family.familyWeakElement, ChemiColors.pinkDeep),
              const SizedBox(width: 10),
              _buildTag('과잉', family.familyStrongElement, const Color(0xFFFF7675)),
            ],
          ),

          // 추천 코멘트
          if (family.recommendation.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: ChemiColors.chrome),
            const SizedBox(height: 14),
            Text(
              family.recommendation,
              style: const TextStyle(
                fontSize: 13,
                color: ChemiColors.muted,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMemberChip(String label, SajuAnalysis saju) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: ChemiColors.chrome,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: ChemiColors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              saju.dayMaster,
              style: const TextStyle(
                fontSize: 18,
                fontFamily: ChemiFonts.display,
                color: ChemiColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${saju.weakElement} 부족',
              style: const TextStyle(
                fontSize: 10,
                color: ChemiColors.pinkDeep,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCombinedOhengChart(Map<String, int> balance) {
    final total = balance.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    const ohengInfo = {
      '목': (Color(0xFF00B894), '木'),
      '화': (Color(0xFFFF6B6B), '火'),
      '토': (Color(0xFFFDAC53), '土'),
      '금': (Color(0xFFB8B8B8), '金'),
      '수': (Color(0xFF0984E3), '水'),
    };

    return Column(
      children: ['목', '화', '토', '금', '수'].map((element) {
        final count = balance[element] ?? 0;
        final ratio = count / total;
        final info = ohengInfo[element]!;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  '${info.$2} $element',
                  style: const TextStyle(fontSize: 11, color: ChemiColors.muted, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 8,
                    backgroundColor: ChemiColors.chrome,
                    valueColor: AlwaysStoppedAnimation(info.$1),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 16,
                child: Text(
                  '$count',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ChemiColors.muted),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTag(String label, String element, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          Text(element, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
