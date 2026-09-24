// 내 결과: 받은 결과 전체 (MBTI 케미 + 내 이름 케미 + 아기 이름), 최신순
// 누르면 그 결과, 휴지통은 확인 뒤 삭제. 결제한 작명·진단은 기기에 전체가 있어서 오프라인에서도 열린다.
// 묶음 할인은 쓸 수 있을 때(결제 전 작명·진단이 하나씩)만 위에 배너로 (결제 화면의 유일한 입구).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/chemi_theme.dart';
import '../../data/services/purchase_service.dart';
import '../feed.dart';
import '../providers/chemi_provider.dart';
import '../providers/naming_provider.dart';
import '../widgets/beaker.dart';
import 'paywall_screen.dart';

class MyResultsScreen extends StatelessWidget {
  /// 비어 있을 때 "실험하러 가기" → 홈 탭
  final VoidCallback onGoHome;

  const MyResultsScreen({super.key, required this.onGoHome});

  @override
  Widget build(BuildContext context) {
    final naming = context.watch<NamingProvider>();
    final feed = buildFeed(naming, context.watch<ChemiProvider>());
    final showBundle = naming.canPurchase(ProductType.bundle);

    return Scaffold(
      appBar: AppBar(title: const Text('내 결과'), automaticallyImplyLeading: false),
      body: feed.isEmpty
          ? _Empty(onGoHome: onGoHome)
          : ListView(
              padding: EdgeInsets.fromLTRB(22, 8, 22, MediaQuery.paddingOf(context).bottom + 100),
              children: [
                if (showBundle) ...[
                  _BundleBanner(
                    discount: Prices.format(naming.purchaseService.bundleDiscount),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PaywallScreen(highlightType: ProductType.bundle)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                for (final item in feed) ...[
                  _ResultRow(item: item),
                  const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _Empty extends StatelessWidget {
  final VoidCallback onGoHome;
  const _Empty({required this.onGoHome});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Beaker(width: 90, liquid: ChemiColors.pink),
              const SizedBox(height: 14),
              Text('아직 실험 기록이 없어요', style: ChemiText.display(20)),
              const SizedBox(height: 6),
              Text('MBTI 케미는 무료로 바로 볼 수 있어요', style: ChemiText.body(14, color: ChemiColors.muted)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onGoHome,
                style: ElevatedButton.styleFrom(minimumSize: const Size(160, 48), shape: const StadiumBorder()),
                child: Text('실험하러 가기', style: ChemiText.label(15, color: Colors.white)),
              ),
            ],
          ),
        ),
      );
}

class _ResultRow extends StatelessWidget {
  final FeedItem item;
  const _ResultRow({required this.item});

  Color get _dot => switch (item.kind) {
        FeedKind.mbti => ChemiColors.pink,
        FeedKind.nameChemi => Colors.white,
        FeedKind.babyName => ChemiColors.ink,
      };

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('결과를 지울까요?', style: ChemiText.display(20)),
        content: Text(
          item.isPreview
              ? '${item.headline} 결과가 기기에서 지워져요.\n결제 전 결과라 지우면 다시 받아야 해요.'
              : '${item.headline} 결과가 기기에서 지워져요.',
          style: ChemiText.body(14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('지우기', style: TextStyle(color: ChemiColors.pinkDeep)),
          ),
        ],
      ),
    );
    if (ok == true) await item.delete();
  }

  @override
  Widget build(BuildContext context) {
    final date = item.at;
    final when = '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => item.open(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _dot,
                  borderRadius: BorderRadius.circular(16),
                  border: item.kind == FeedKind.nameChemi ? Border.all(color: ChemiColors.chrome, width: 2) : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  item.score?.toString() ?? '?',
                  style: ChemiText.display(22, color: item.kind == FeedKind.babyName ? Colors.white : ChemiColors.ink),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.label}${item.isPreview ? ' · 미리보기' : ''}',
                      style: ChemiText.label(12, color: ChemiColors.muted),
                    ),
                    Text(item.headline,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: ChemiText.display(18)),
                    if (item.summary.isNotEmpty)
                      Text(item.summary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ChemiText.body(12, color: ChemiColors.muted)),
                    Text(when, style: ChemiText.body(11, color: ChemiColors.muted)),
                  ],
                ),
              ),
              IconButton(
                tooltip: '지우기',
                onPressed: () => _confirmDelete(context),
                icon: const Icon(Icons.delete_outline, color: ChemiColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BundleBanner extends StatelessWidget {
  final String discount;
  final VoidCallback onTap;
  const _BundleBanner({required this.discount, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: ChemiColors.ink,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('묶음 할인', style: ChemiText.display(18, color: Colors.white)),
                      Text('결제 전인 아기 이름 + 내 이름 케미를 함께 열면 $discount 할인',
                          style: ChemiText.body(13, color: ChemiColors.mutedOnInk)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: ChemiColors.pink),
              ],
            ),
          ),
        ),
      );
}
