// 이름 진단 결과 화면
// B 방식: 종합 점수 + 1줄 요약 무료 공개
// 상세 분석 + 개선 이름은 결제 후 공개
// 업셀링: 추가 개선 이름 5개 (₩9,900)

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/diagnosis_result.dart';
import '../../data/services/purchase_service.dart';
import '../providers/naming_provider.dart';
import '../widgets/name_card.dart';
import '../widgets/saju_card.dart';

class DiagnosisResultScreen extends StatelessWidget {
  const DiagnosisResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      appBar: AppBar(
        title: const Text('진단 결과'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<NamingProvider>(
        builder: (context, provider, _) {
          final result = provider.diagnosisResult;
          if (result == null) {
            return const Center(child: Text('결과가 없습니다.'));
          }

          final diagnosis = result.diagnosis;
          final input = provider.lastDiagnosisInput;
          final surname = input?.person.surname ?? '';
          final isPaid = provider.isDiagnosisPaid;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 종합 점수 카드 (항상 공개)
                _buildScoreCard(diagnosis, surname),

                const SizedBox(height: 20),

                // 사주 분석 (항상 공개)
                SajuCard(saju: result.saju),

                const SizedBox(height: 20),

                // === 결제 후 공개 영역 ===
                if (isPaid) ...[
                  // 오행 적합도
                  _buildOhengSection(diagnosis),

                  const SizedBox(height: 20),

                  // 장점 & 문제점
                  if (diagnosis.strengths.isNotEmpty)
                    _buildListSection('장점', diagnosis.strengths, const Color(0xFF4CAF50)),

                  if (diagnosis.problems.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildListSection('문제점', diagnosis.problems, const Color(0xFFFF6B6B)),
                  ],

                  const SizedBox(height: 20),

                  // 상세 분석
                  if (diagnosis.detailAnalysis.isNotEmpty)
                    _buildDetailSection(diagnosis),

                  const SizedBox(height: 24),

                  // 개선 이름 추천
                  _buildImprovementSection(result.improvementNames, surname),

                  const SizedBox(height: 20),

                  // 업셀링 배너 (추가 이름 5개)
                  if (result.improvementNames.length <= 3)
                    _buildUpsellBanner(context, provider),
                ] else ...[
                  // 미결제: 블러 처리 + 결제 유도
                  _buildLockedSection(context, provider),
                ],

                const SizedBox(height: 20),

                // 돌아가기
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text(
                      '돌아가기',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A1A2E),
                      side: const BorderSide(color: Color(0xFF1A1A2E), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // 종합 점수 카드 (항상 공개)
  // ============================================================
  Widget _buildScoreCard(NameDiagnosis diagnosis, String surname) {
    final score = diagnosis.overallScore;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getScoreColor(score),
            _getScoreColor(score).withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _getScoreColor(score).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '$surname${diagnosis.currentName}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 4,
            ),
          ),
          if (diagnosis.currentHanja.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              diagnosis.currentHanja,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const Text('점', style: TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            diagnosis.summaryOneLine,
            style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 미결제 잠금 영역
  // ============================================================
  Widget _buildLockedSection(BuildContext context, NamingProvider provider) {
    return Column(
      children: [
        // 블러 처리된 미리보기
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('오행 적합도 분석', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      SizedBox(height: 8),
                      Text('이름의 오행 분포와 사주의 오행 적합도를 상세히 분석합니다...'),
                      SizedBox(height: 16),
                      Text('장점 & 문제점', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      SizedBox(height: 8),
                      Text('현재 이름의 강점과 개선할 점을 알려드립니다...'),
                      SizedBox(height: 16),
                      Text('개선 추천 이름 3개', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      SizedBox(height: 8),
                      Text('사주에 더 잘 맞는 대안 이름을 추천해드립니다...'),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 결제 배너
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0984E3), Color(0xFF6C5CE7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0984E3).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                '상세 분석 확인하기',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                '오행 적합도, 문제점/장점 리포트,\n개선 이름 3개를 확인하세요',
                style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final success = await provider.purchaseProduct(ProductType.diagnosis);
                    if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('결제가 취소되었습니다.'),
                          backgroundColor: Color(0xFF8E8E93),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0984E3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text(
                    '₩4,900 결제하고 전체 보기',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 결제 후 공개 위젯들
  // ============================================================
  Widget _buildOhengSection(NameDiagnosis diagnosis) {
    final compat = diagnosis.ohengCompat;
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
          Row(
            children: [
              const Icon(Icons.balance, size: 18, color: Color(0xFF1A1A2E)),
              const SizedBox(width: 8),
              const Text('오행 적합도', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getScoreColor(compat.matchScore).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${compat.matchScore}점',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _getScoreColor(compat.matchScore)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(compat.matchDescription, style: const TextStyle(fontSize: 13, color: Color(0xFF555555), height: 1.5)),
          if (diagnosis.strokeAnalysis.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildAnalysisRow('획수', diagnosis.strokeAnalysis),
          ],
          if (diagnosis.pronunciationAnalysis.isNotEmpty)
            _buildAnalysisRow('발음', diagnosis.pronunciationAnalysis),
        ],
      ),
    );
  }

  Widget _buildAnalysisRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 36, child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF999999)))),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF555555), height: 1.4))),
        ],
      ),
    );
  }

  Widget _buildListSection(String title, List<String> items, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(title == '장점' ? Icons.thumb_up_outlined : Icons.warning_amber_outlined, size: 16, color: color.withValues(alpha: 0.6)),
                const SizedBox(width: 8),
                Expanded(child: Text(item, style: const TextStyle(fontSize: 13, color: Color(0xFF555555), height: 1.4))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildDetailSection(NameDiagnosis diagnosis) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.article_outlined, size: 18, color: Color(0xFF1A1A2E)),
            SizedBox(width: 8),
            Text('상세 분석', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          ]),
          const SizedBox(height: 12),
          Text(diagnosis.detailAnalysis, style: const TextStyle(fontSize: 13, color: Color(0xFF555555), height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildImprovementSection(List names, String surname) {
    if (names.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text('개선 추천 이름', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF0984E3))),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFF0984E3), borderRadius: BorderRadius.circular(10)),
            child: Text('${names.length}개', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 12),
        ...List.generate(names.length, (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: NameCard(name: names[index], surname: surname, rank: index + 1),
        )),
      ],
    );
  }

  Widget _buildUpsellBanner(BuildContext context, NamingProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0984E3), Color(0xFF6C5CE7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF0984E3).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          const Text('더 많은 개선 이름이 필요하신가요?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 6),
          Text('사주에 맞는 개선 이름 5개를 추가로 받아보세요', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                final purchased = await provider.purchaseProduct(ProductType.diagnosisUpgrade);
                if (purchased) {
                  await provider.upgradeFromDiagnosis();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0984E3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('₩9,900 - 개선 이름 5개 추가', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return const Color(0xFF00B894);
    if (score >= 80) return const Color(0xFF0984E3);
    if (score >= 70) return const Color(0xFFFDAC53);
    return const Color(0xFFFF7675);
  }
}
