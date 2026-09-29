// 케미 결과 화면들이 같이 쓰는 부품 (MBTI 케미, 이름 케미 …): 섹션 제목, 글 카드, 스토리 공유

import 'package:flutter/material.dart';
import '../../core/text/keep_words.dart';
import '../../core/theme/chemi_theme.dart';
import '../../data/chemi_common/improve.dart';
import '../../data/pair_chemi/pair_chemi.dart' show PairPerson;
import '../../data/chemi_common/who.dart';
import '../../data/services/share_service.dart';
import 'beaker.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final String? sub;
  const SectionTitle(this.title, {super.key, this.sub});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: ChemiText.display(20)),
            if (sub != null) Text(sub!, style: ChemiText.body(12, color: ChemiColors.muted)),
          ],
        ),
      );
}

class TextCard extends StatelessWidget {
  final String title;
  final String body;
  const TextCard({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(color: ChemiColors.card, borderRadius: BorderRadius.circular(22)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: ChemiText.display(17)),
            const SizedBox(height: 6),
            Text(keepWords(body), style: ChemiText.body(14, color: const Color(0xFF3A3A44), height: 1.55)),
          ],
        ),
      );
}

/// 9:16 인스타 스토리 카드 (시안 R2). 390 폭 기준으로 그리고 크기에 맞춰 늘린다.
class StoryCard extends StatelessWidget {
  final String label; // "MBTI 케미"
  final String pair; // "INFP × ENTJ"
  final int score;
  final String title;
  final List<String> tags;

  const StoryCard({
    super.key,
    required this.label,
    required this.pair,
    required this.score,
    required this.title,
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final u = box.maxWidth / 390;
      return Container(
        color: ChemiColors.pink,
        padding: EdgeInsets.fromLTRB(28 * u, 32 * u, 28 * u, 28 * u),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('케미연구소', style: ChemiText.display(24 * u)),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 11 * u, vertical: 6 * u),
                  decoration: BoxDecoration(color: ChemiColors.ink, borderRadius: BorderRadius.circular(999)),
                  child: Text(label, style: ChemiText.label(12 * u, color: Colors.white)),
                ),
              ],
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(pair, style: ChemiText.display(36 * u)),
            ),
            Text.rich(TextSpan(children: [
              TextSpan(text: '$score', style: ChemiText.display(140 * u, height: 1.0)),
              TextSpan(text: '점', style: ChemiText.display(40 * u)),
            ])),
            Text(keepWords(title), style: ChemiText.display(28 * u, height: 1.25)),
            SizedBox(height: 14 * u),
            Wrap(
              spacing: 6 * u,
              runSpacing: 6 * u,
              children: [
                for (final (i, t) in tags.indexed)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12 * u, vertical: 6 * u),
                    decoration: BoxDecoration(
                      color: i == 0 ? Colors.white : ChemiColors.ink,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(t, style: ChemiText.label(13 * u, color: i == 0 ? ChemiColors.ink : Colors.white)),
                  ),
              ],
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('너희 케미는 몇 점?', style: ChemiText.label(12 * u)),
                      Text('케미연구소에서 측정하기', style: ChemiText.display(20 * u)),
                    ],
                  ),
                ),
                Beaker(width: 88 * u, face: BeakerFace.wink),
              ],
            ),
          ],
        ),
      );
    });
  }
}

/// 공유 전 미리보기: 카드를 보여 주고, 그 카드를 그대로 이미지로 만들어 공유한다.
/// 공유 창이 뜰 때까지 버튼에 로딩 (느린 폰에서 2초 넘게 걸림), 마치면 이 창도 닫고, 실패하면 안내.
class StoryShareSheet extends StatefulWidget {
  final Widget card;
  final String shareText;
  const StoryShareSheet({super.key, required this.card, required this.shareText});

  @override
  State<StoryShareSheet> createState() => _StoryShareSheetState();
}

class _StoryShareSheetState extends State<StoryShareSheet> {
  final _cardKey = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    setState(() => _busy = true);
    final bytes = await ShareService.captureWidget(_cardKey);
    final shared = bytes != null && await ShareService.shareImage(bytes, text: widget.shareText);
    if (!mounted) return;
    setState(() => _busy = false);
    if (shared) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('공유 창을 열지 못했어요. 다시 시도해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: ChemiColors.disabled, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: RepaintBoundary(key: _cardKey, child: widget.card),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _busy ? null : _share,
                child: _busy
                    ? const SizedBox(
                        width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : Text('공유하기', style: ChemiText.label(16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void openStoryShare(BuildContext context, {required Widget card, required String shareText}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: ChemiColors.chrome,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => StoryShareSheet(card: card, shareText: shareText),
  );
}

/// "생일까지 넣으면 진짜 케미" → 우리 케미 입력 (MBTI·이름 케미 결과 아래)
class PairChemiLink extends StatelessWidget {
  final String lead; // "MBTI는 성격, 사주는 타고난 기운"
  final String headline;
  final VoidCallback onTap;
  const PairChemiLink({super.key, required this.lead, required this.onTap, this.headline = '생일까지 넣으면\n진짜 케미가 나와요'});

  @override
  Widget build(BuildContext context) => Material(
        color: ChemiColors.ink,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Beaker(width: 48, liquid: ChemiColors.pink, line: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lead, style: ChemiText.label(12, color: ChemiColors.pink)),
                      const SizedBox(height: 2),
                      Text(headline, style: ChemiText.display(18, color: Colors.white)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),
      );
}

/// 둘 중 누가? — 이긴 쪽 이름을 크게, 근거를 작게. 비기면 "막상막하"
class WhoSection extends StatelessWidget {
  final List<WhoAnswer> items;
  final String tie; // 비겼을 때 알약 글자
  const WhoSection({super.key, required this.items, this.tie = '막상막하'});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
        child: Column(
          children: [
            for (final (i, w) in items.indexed) ...[
              if (i > 0) const Divider(height: 1, color: ChemiColors.chrome),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(w.question, style: ChemiText.label(14)),
                          const SizedBox(height: 2),
                          Text(keepWords(w.reason), style: ChemiText.body(12, color: ChemiColors.muted)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: w.winner == null ? ChemiColors.chrome : ChemiColors.pink,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(w.winner ?? tie, style: ChemiText.display(16)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
}

/// 케미 올리는 법 — 번호 + 노력할 점 + 이렇게 해 보세요
class ImproveSection extends StatelessWidget {
  final List<Improve> items;
  const ImproveSection({super.key, required this.items});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (final (i, it) in items.indexed) ...[
            if (i > 0) const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: ChemiColors.ink, shape: BoxShape.circle),
                    child: Text('${i + 1}', style: ChemiText.display(15, color: ChemiColors.pink)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(keepWords(it.title), style: ChemiText.display(16)),
                        const SizedBox(height: 4),
                        Text(keepWords(it.action), style: ChemiText.body(14, color: const Color(0xFF3A3A44), height: 1.55)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
}

/// 결제 전: 전체 리포트에 무엇이 있는지 + 결제 버튼
class LockedReport extends StatelessWidget {
  final String sub;
  final List<String> items;
  final String price;
  final bool busy;
  final String? status;
  final VoidCallback onBuy;
  const LockedReport({super.key, required this.sub, required this.items, required this.price, required this.busy, required this.status, required this.onBuy});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: ChemiColors.ink, borderRadius: BorderRadius.circular(24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('전체 리포트', style: ChemiText.display(20, color: Colors.white)),
                const Spacer(),
                const Icon(Icons.lock_outline, color: ChemiColors.pink, size: 20),
              ],
            ),
            const SizedBox(height: 4),
            Text(keepWords(sub),
                style: ChemiText.body(13, color: ChemiColors.mutedOnInk)),
            const SizedBox(height: 12),
            for (final t in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check, size: 16, color: ChemiColors.pink),
                    const SizedBox(width: 8),
                    Text(t, style: ChemiText.label(14, color: Colors.white)),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: busy ? null : onBuy,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ChemiColors.pink,
                  foregroundColor: ChemiColors.ink,
                  disabledBackgroundColor: ChemiColors.inkSoft,
                ),
                child: busy
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.2, color: ChemiColors.pink),
                          ),
                          const SizedBox(width: 10),
                          Text(status ?? '결제 준비 중…', style: ChemiText.label(14, color: Colors.white)),
                        ],
                      )
                    : Text('$price 전체 리포트 열기', style: ChemiText.label(16)),
              ),
            ),
          ],
        ),
      );
}

/// 나는 이런 사람: 일간 성격
class PersonaCard extends StatelessWidget {
  final PairPerson person;
  final String? label; // 위 작은 글씨 (기본: 이름 · 일간)
  final bool dark;
  const PersonaCard({super.key, required this.person, this.dark = false, this.label});

  @override
  Widget build(BuildContext context) {
    final (name, symbol, text) = person.persona;
    final fg = dark ? Colors.white : ChemiColors.ink;
    final sub = dark ? ChemiColors.mutedOnInk : ChemiColors.muted;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: dark ? ChemiColors.ink : Colors.white, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label ?? '${person.name} · $name', style: ChemiText.label(12, color: sub)),
          Text(symbol, style: ChemiText.display(22, color: fg)),
          const SizedBox(height: 6),
          Text(keepWords(text), style: ChemiText.body(14, color: fg, height: 1.55)),
        ],
      ),
    );
  }
}
