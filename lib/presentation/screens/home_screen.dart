// 홈 화면 - 작명 / 진단 2가지 메뉴 카드
// 무료 체험 배너 + 서비스 선택

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/naming_provider.dart';
import 'naming_input_screen.dart';
import 'diagnosis_input_screen.dart';
import 'paywall_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // 앱 타이틀
              const Text(
                '이름운',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'AI 사주 작명',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8E8E93),
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 16),

              // 무료 체험 배너
              Consumer<NamingProvider>(
                builder: (context, provider, _) {
                  if (!provider.isFreeAvailable) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '무료 체험 1회 가능',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // 신규 작명 카드
              _ServiceCard(
                icon: Icons.auto_awesome,
                title: '신규 작명',
                subtitle: '아기 + 부모 사주 기반\n최적의 이름을 찾아드려요',
                price: '₩11,900',
                color: const Color(0xFF1A1A2E),
                features: const [
                  '가족 오행 균형 분석',
                  '사주 기반 이름 5개 추천',
                  '한자 뜻풀이 & 발음 평가',
                ],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NamingInputScreen()),
                  );
                },
              ),

              const SizedBox(height: 16),

              // 이름 진단 카드
              _ServiceCard(
                icon: Icons.search,
                title: '이름 진단',
                subtitle: '현재 이름의 사주 궁합을\n정밀 분석해드려요',
                price: '₩4,900',
                color: const Color(0xFF0984E3),
                features: const [
                  '현재 이름 오행 적합도',
                  '문제점 & 장점 리포트',
                  '개선 이름 3개 추천',
                ],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DiagnosisInputScreen()),
                  );
                },
              ),

              const SizedBox(height: 24),

              // 묶음 할인 배너
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PaywallScreen()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A1A2E), Color(0xFF3A3A5C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '묶음 할인',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '작명 + 진단 동시 이용 시 ₩1,900 할인',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '₩14,900',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// 서비스 선택 카드 (작명 / 진단)
class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String price;
  final Color color;
  final List<String> features;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.color,
    required this.features,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: color.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: color.withValues(alpha: 0.4)),
              ],
            ),

            const SizedBox(height: 14),

            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
                height: 1.5,
              ),
            ),

            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF0EDE8)),
            const SizedBox(height: 12),

            // 기능 목록
            ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 16, color: color.withValues(alpha: 0.5)),
                  const SizedBox(width: 8),
                  Text(
                    f,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
