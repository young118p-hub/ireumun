// 이름 카드 위젯
// 추천 이름 하나의 상세 정보 표시 (모던 디자인)

import 'package:flutter/material.dart';
import '../../data/models/naming_result.dart';

class NameCard extends StatelessWidget {
  final NameSuggestion name;
  final String surname;
  final int rank;

  const NameCard({
    super.key,
    required this.name,
    required this.surname,
    required this.rank,
  });

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
          // 상단: 순위 + 이름 + 점수
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 순위 배지
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: rank <= 3
                      ? const Color(0xFF1A1A2E)
                      : const Color(0xFFE8E4DE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: rank <= 3 ? Colors.white : const Color(0xFF666666),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 한글 이름 (성+이름)
              Text(
                '$surname${name.name}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 10),

              // 한자
              Text(
                '${_getHanjaSurname(surname)}${name.hanja}',
                style: TextStyle(
                  fontSize: 15,
                  color: const Color(0xFF1A1A2E).withValues(alpha: 0.4),
                  fontWeight: FontWeight.w500,
                ),
              ),

              const Spacer(),

              // 점수 뱃지
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _getScoreColor(name.score).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${name.score}점',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _getScoreColor(name.score),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF0EDE8)),
          const SizedBox(height: 14),

          // 한자 음독
          _buildInfoRow('한자', name.reading),
          const SizedBox(height: 10),

          // 뜻 풀이
          _buildInfoRow('의미', name.meaning),
          const SizedBox(height: 10),

          // 오행 보완
          _buildInfoRow('오행', name.ohengMatch),
          const SizedBox(height: 10),

          // 발음 평가
          _buildInfoRow('발음', name.pronunciation),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF999999),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF444444),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return const Color(0xFF00B894);
    if (score >= 80) return const Color(0xFF0984E3);
    if (score >= 70) return const Color(0xFFFDAC53);
    return const Color(0xFFFF7675);
  }

  /// 성씨에 대응하는 대표 한자 (간략 매핑)
  String _getHanjaSurname(String surname) {
    const map = {
      '김': '金', '이': '李', '박': '朴', '최': '崔', '정': '鄭',
      '강': '姜', '조': '趙', '윤': '尹', '장': '張', '임': '林',
      '한': '韓', '오': '吳', '서': '徐', '신': '申', '권': '權',
      '황': '黃', '안': '安', '송': '宋', '류': '柳', '전': '全',
      '홍': '洪', '고': '高', '문': '文', '양': '梁', '손': '孫',
      '배': '裴', '백': '白', '허': '許', '유': '劉', '남': '南',
      '심': '沈', '노': '盧', '하': '河', '곽': '郭', '성': '成',
      '차': '車', '주': '朱', '우': '禹', '구': '具', '민': '閔',
    };
    return map[surname] ?? '';
  }
}
