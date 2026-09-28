// 작명 결과 화면
// B 방식: 1개만 공개 + 나머지 블라인드 → 결제 후 전체 공개
// 공유 버튼 (결제 완료 시)

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/chemi_theme.dart';
import 'package:provider/provider.dart';
import '../../data/services/purchase_service.dart';
import '../../data/services/share_service.dart';
import '../providers/naming_provider.dart';
import '../../data/models/naming_result.dart';
import '../widgets/name_card.dart';
import '../widgets/saju_card.dart';
import '../widgets/family_saju_card.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('아기 이름 결과'),
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
          final surname = provider.namingSurname;
          // 결제 전에는 서버가 첫 이름만 보낸다. 나머지는 자리만 보여준다.
          final lockedCount = isPaid ? 0 : provider.lockedNamingCount;
          final totalCount = result.names.length + lockedCount;

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
                        fontFamily: ChemiFonts.display,
                        color: ChemiColors.ink,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: ChemiColors.ink,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$totalCount개',
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
                          color: ChemiColors.warn.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isFreeTrial ? '무료 체험' : '미결제',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isFreeTrial
                                ? ChemiColors.good
                                : ChemiColors.warn,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // 이름 카드 리스트
                ...List.generate(totalCount, (index) {
                  // 받은 이름은 공개, 아직 못 받은 이름(결제 전)은 잠금 자리
                  final isVisible = index < result.names.length;
                  final name = isVisible ? result.names[index] : _lockedPlaceholder;

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
                                    Icon(Icons.lock_outline, color: ChemiColors.ink, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      '결제 후 확인 가능',
                                      style: TextStyle(
                                        color: ChemiColors.ink,
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
                      foregroundColor: ChemiColors.ink,
                      side: const BorderSide(color: ChemiColors.ink, width: 1.5),
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
  // 새로 작명하기 (미결제 결과 버리기)
  // ============================================================
  void _confirmDiscard(BuildContext context, NamingProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '결과를 버리시겠어요?',
          style: TextStyle(fontSize: 17, fontFamily: ChemiFonts.display),
        ),
        content: const Text(
          '지금 결과가 지워지고\n처음부터 다시 찾을 수 있어요.',
          style: TextStyle(fontSize: 14, color: ChemiColors.muted, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: ChemiColors.muted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.discardUnpaidNaming();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text(
              '버리고 새로 시작',
              style: TextStyle(color: ChemiColors.warn, fontWeight: FontWeight.w600),
            ),
          ),
        ],
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
        color: ChemiColors.ink,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ChemiColors.ink.withValues(alpha: 0.3),
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
              fontFamily: ChemiFonts.display,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            result.familyAnalysis == null && provider.lastFamilyInput != null
                ? '나머지 ${provider.lockedNamingCount}개의 추천 이름과\n가족 오행 분석을 확인하세요'
                : '나머지 ${provider.lockedNamingCount}개의 추천 이름을 확인하세요',
            style: const TextStyle(fontSize: 13, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              // 결제 결과(완료·취소)는 provider가 안내를 띄운다
              onPressed: provider.purchaseBusy
                  ? null
                  : () => provider.purchase(ProductType.naming),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: ChemiColors.ink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                provider.purchaseStatus ??
                    '${provider.product(ProductType.naming).priceString} 결제하고 전체 보기',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
        color: ChemiColors.ink,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            '마음에 드셨나요?',
            style: TextStyle(
              fontSize: 18,
              fontFamily: ChemiFonts.display,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '나머지 ${provider.lockedNamingCount}개 이름도 확인해 보세요',
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: provider.purchaseBusy
                  ? null
                  : () => provider.purchase(ProductType.naming),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: ChemiColors.pinkDeep,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                provider.purchaseStatus ??
                    '${provider.product(ProductType.naming).priceString} - 전체 이름 보기',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
    final surname = provider.namingSurname;

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
                    fontFamily: ChemiFonts.display,
                    color: ChemiColors.ink,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.text_snippet_outlined, color: ChemiColors.ink),
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
                  leading: const Icon(Icons.copy, color: ChemiColors.ink),
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
                        backgroundColor: ChemiColors.pinkDeep,
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

  /// 결제 전 잠긴 이름 자리 (실제 이름은 서버에만 있다)
  static const _lockedPlaceholder = NameSuggestion(
    name: '○○',
    hanja: '○○',
    reading: '',
    meaning: '결제 후 확인할 수 있어요',
    ohengMatch: '',
    score: 0,
    pronunciation: '',
  );
}
