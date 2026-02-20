// 사주 분석 카드 위젯
// 사주 네 기둥 + 오행 분포 시각화 (모던 미니멀 디자인)

import 'package:flutter/material.dart';
import '../../data/models/naming_result.dart';

class SajuCard extends StatelessWidget {
  final SajuAnalysis saju;

  const SajuCard({super.key, required this.saju});

  @override
  Widget build(BuildContext context) {
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
              Icon(Icons.auto_awesome, size: 18, color: Color(0xFF1A1A2E)),
              SizedBox(width: 8),
              Text(
                '사주 분석',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 사주 네 기둥
          Row(
            children: [
              _buildPillar('년주', saju.yearPillar),
              _buildPillar('월주', saju.monthPillar),
              _buildPillar('일주', saju.dayPillar),
              _buildPillar('시주', saju.hourPillar),
            ],
          ),

          const SizedBox(height: 18),

          // 일간 (일주의 천간)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3EE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '일간',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  saju.dayMaster,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFF0EDE8)),
          const SizedBox(height: 16),

          // 오행 분포 바 차트
          const Text(
            '오행 분포',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 12),
          _buildOhengChart(),

          const SizedBox(height: 16),

          // 부족/과다 오행
          Row(
            children: [
              _buildOhengTag('부족', saju.weakElement, const Color(0xFF0984E3)),
              const SizedBox(width: 10),
              _buildOhengTag('강함', saju.strongElement, const Color(0xFFFF7675)),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF0EDE8)),
          const SizedBox(height: 14),

          // 종합 설명
          Text(
            saju.summary,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF555555),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillar(String label, String value) {
    final chars = value.split('');
    final cheongan = chars.isNotEmpty ? chars[0] : '';
    final jiji = chars.length > 1 ? chars[1] : '';

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F3EE),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF999999),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              cheongan,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              jiji,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOhengChart() {
    final total = saju.ohengBalance.values.fold(0, (a, b) => a + b);
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
        final count = saju.ohengBalance[element] ?? 0;
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
                  style: const TextStyle(fontSize: 11, color: Color(0xFF888888), fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFF5F3EE),
                    valueColor: AlwaysStoppedAnimation(info.$1),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 16,
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF555555),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOhengTag(String label, String element, Color color) {
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
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 4),
          Text(
            element,
            style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
