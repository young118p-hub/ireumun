// 작명 결과 화면
// B 방식: 1개만 공개 + 나머지 블라인드 → 결제 후 전체 공개
// 공유 버튼 (결제 완료 시)

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/purchase_service.dart';
import '../../data/services/share_service.dart';
import '../providers/naming_provider.dart';
import '../widgets/name_card.dart';
import '../widgets/saju_card.dart';
import '../widgets/family_saju_card.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      appBar: AppBar(
        title: const Text('작명 결과'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<NamingProvider>(
            builder: (context, provider, _) {
              if (!provider.isNamingPaid) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _showShareOptions(context, provider),
              );
            },
          ),
        ],
      ),
      body: Consumer<NamingProvider>(
        builder: (context, provider, _) {
          final result = provider.namingResult;
          if (result == null) {
            return const Center(child: Text('결과가 없습니다.'));
          }

          final isPaid = provider.isNamingPaid;
          final isFreeTrial = provider.isFreeTrial;
          final surname = provider.lastFamilyInput?.baby.surname ??
              provider.lastSimpleInput?.surname ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 가족 사주 분석 (유료 결제 후)
                if (isPaid && result.familyAnalysis != null)
                  FamilySajuCard(result: result),

                if (isPaid && result.familyAnalysis != null)
                  const SizedBox(height: 16),

                // 아기 사주 분석 (항상 공개)
                SajuCard(saju: result.babySaju),

                const SizedBox(height: 24),

                // 추천 이름 헤더
                Row(
                  children: [
                    const Text(
                      '추천 이름',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${result.names.length}개',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (!isPaid)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isFreeTrial ? '무료 체험' : '미결제',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isFreeTrial
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFFF6B6B),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // 이름 카드 리스트
                ...List.generate(result.names.length, (index) {
                  final name = result.names[index];
                  // 1번째 이름은 항상 공개, 나머지는 결제 후
                  final isVisible = index == 0 || isPaid;

                  if (isVisible) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: NameCard(
                        name: name,
                        surname: surname,
                        rank: index + 1,
                      ),
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: ImageFiltered(
                              imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: NameCard(
                                name: name,
                                surname: surname,
                                rank: index + 1,
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                              child: const Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.lock_outline, color: Color(0xFF1A1A2E), size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      '결제 후 확인 가능',
                                      style: TextStyle(
                                        color: Color(0xFF1A1A2E),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                }),

                // 결제 배너 (미결제 시)
                if (!isPaid && !isFreeTrial) ...[
                  const SizedBox(height: 16),
                  _buildPaymentBanner(context, provider, result),
                ],

                // 무료 체험 안내 (무료 체험이면서 미결제)
                if (isFreeTrial && !isPaid) ...[
                  const SizedBox(height: 16),
                  _buildFreeTrialUpgradeBanner(context, provider, result),
                ],

                const SizedBox(height: 20),

                // 돌아가기 버튼
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
  // 결제 배너 (유료 작명 미결제 시)
  // ============================================================
  Widget _buildPaymentBanner(BuildContext context, NamingProvider provider, result) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF3A3A5C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1A2E).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '전체 이름 확인하기',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '나머지 ${(result.names.length) - 1}개의 추천 이름과\n가족 오행 분석을 확인하세요',
            style: const TextStyle(fontSize: 13, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                final success = await provider.purchaseProduct(ProductType.naming);
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
                foregroundColor: const Color(0xFF1A1A2E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                '₩11,900 결제하고 전체 보기',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 무료 체험 업그레이드 배너
  // ============================================================
  Widget _buildFreeTrialUpgradeBanner(BuildContext context, NamingProvider provider, result) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            '마음에 드셨나요?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '나머지 ${(result.names.length) - 1}개 이름 + 가족 사주 분석까지!',
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                await provider.purchaseProduct(ProductType.naming);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF4CAF50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                '₩11,900 - 전체 이름 보기',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 공유 옵션
  // ============================================================
  void _showShareOptions(BuildContext context, NamingProvider provider) {
    final result = provider.namingResult;
    if (result == null) return;
    final surname = provider.lastFamilyInput?.baby.surname ??
        provider.lastSimpleInput?.surname ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '결과 공유',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.text_snippet_outlined, color: Color(0xFF1A1A2E)),
                  title: const Text('텍스트로 공유'),
                  subtitle: const Text('카카오톡 등으로 전송'),
                  onTap: () {
                    Navigator.pop(ctx);
                    ShareService.shareText(
                      surname: surname,
                      names: result.names,
                      saju: result.babySaju,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.copy, color: Color(0xFF1A1A2E)),
                  title: const Text('텍스트 복사'),
                  subtitle: const Text('클립보드에 복사'),
                  onTap: () {
                    Navigator.pop(ctx);
                    ShareService.copyResultText(
                      surname: surname,
                      names: result.names,
                      saju: result.babySaju,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('클립보드에 복사되었습니다.'),
                        backgroundColor: Color(0xFF4CAF50),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
