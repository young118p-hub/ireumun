// MBTI 케미 - 결과 (무료, 규칙표로 계산)
// 들어올 때 기록한다 (내 결과·홈 "내 실험 기록"). 기록에서 다시 열 때는 record: false.
// 공유: 스토리 카드를 먼저 보여 주고, 그 카드를 이미지로 만들어 공유 시트를 연다.
// "생일까지 넣으면 진짜 케미"(우리 케미로 연결) 카드는 우리 케미가 열릴 때 넣는다 (Features.pairChemi).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/chemi_theme.dart';
import '../../data/mbti/mbti_chemi.dart';
import '../providers/chemi_provider.dart';
import '../../core/text/keep_words.dart';
import '../widgets/beaker.dart';
import '../../core/config/features.dart';
import '../widgets/result_parts.dart';
import 'pair_chemi_input_screen.dart';
import '../widgets/status_scrim.dart';
import 'mbti_pick_screen.dart';

class MbtiResultScreen extends StatefulWidget {
  final String me;
  final String you;
  final bool record;

  const MbtiResultScreen({
    super.key,
    required this.me,
    required this.you,
    this.record = true,
  });

  @override
  State<MbtiResultScreen> createState() => _MbtiResultScreenState();
}

class _MbtiResultScreenState extends State<MbtiResultScreen> {
  late final MbtiChemi _chemi = mbtiChemi(widget.me, widget.you);
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.record) {
      // 첫 프레임 뒤에 (build 중 notifyListeners 방지)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<ChemiProvider>().recordMbti(widget.me, widget.you);
        }
      });
    }
  }

  /// 고르기에서 왔으면 돌아가기 (선택 유지), 기록에서 열었으면 내 유형을 고른 채로 고르기 화면
  void _pickAgain() {
    if (widget.record) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MbtiPickScreen(initialMe: widget.me)),
      );
    }
  }

  void _openShare() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ChemiColors.chrome,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => StoryShareSheet(
        card: StoryCard(
          label: 'MBTI 케미',
          pair: '${_chemi.me} × ${_chemi.you}',
          score: _chemi.score,
          title: _chemi.title,
          tags: _chemi.tags,
        ),
        shareText: '우리 MBTI 케미 ${_chemi.score}점! 너희는 몇 점? #케미연구소',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _chemi;
    final top = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  ListView(
                    controller: _scroll,
                    padding: EdgeInsets.zero,
                    children: [
                      Container(
                        padding: EdgeInsets.fromLTRB(12, top + 4, 12, 22),
                        decoration: const BoxDecoration(
                          color: ChemiColors.pink,
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(36),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  tooltip: '뒤로',
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(
                                    Icons.arrow_back_ios_new,
                                    size: 22,
                                    color: ChemiColors.ink,
                                  ),
                                ),
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      'MBTI 케미',
                                      style: ChemiText.label(14),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: '공유',
                                  onPressed: _openShare,
                                  icon: const Icon(
                                    Icons.ios_share,
                                    size: 22,
                                    color: ChemiColors.ink,
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: 8,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            _TypeTag(c.me, dark: false),
                                            Text(
                                              '×',
                                              style: ChemiText.display(26),
                                            ),
                                            _TypeTag(c.you, dark: true),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        _Score(score: c.score, size: 88),
                                        Text(
                                          c.title,
                                          style: ChemiText.display(
                                            24,
                                            height: 1.25,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${c.meProfile.nick} × ${c.youProfile.nick}',
                                          style: ChemiText.label(13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Beaker(
                                    width: 76,
                                    face: BeakerFace.happy,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
                        child: Column(
                          children: [
                            _People(chemi: c),
                            const SizedBox(height: 18),
                            const SectionTitle(
                              '케미 해부',
                              sub: '네 가지 성향에서 받은 점수를 더하면 케미 점수',
                            ),
                            _Axes(chemi: c),
                            const SizedBox(height: 18),
                            const SectionTitle('상황별 케미'),
                            _Situations(chemi: c),
                            const SizedBox(height: 18),
                            const SectionTitle('둘이 만나면'),
                            TextCard(title: '잘 맞는 점', body: c.strength),
                            const SizedBox(height: 10),
                            TextCard(title: '부딪히는 순간', body: c.clash),
                            const SizedBox(height: 10),
                            const SizedBox(height: 18),
                            const SectionTitle('둘 중 누가?', sub: '네 글자로 맞혀 보는 두 사람의 모습'),
                            WhoSection(items: c.who),
                            const SizedBox(height: 18),
                            const SectionTitle('케미 올리는 법', sub: '점수가 낮은 성향부터'),
                            ImproveSection(items: c.improves),
                            const SizedBox(height: 18),
                            const SectionTitle('서로에게 필요한 한마디'),
                            _Quote(
                              to: c.you,
                              text: c.youProfile.wantsToHear,
                              dark: true,
                            ),
                            const SizedBox(height: 8),
                            _Quote(
                              to: c.me,
                              text: c.meProfile.wantsToHear,
                              dark: false,
                            ),
                            const SizedBox(height: 18),
                            if (Features.pairChemi) ...[
                              PairChemiLink(
                                lead: 'MBTI는 성격, 사주는 타고난 기운',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const PairChemiInputScreen()),
                                ),
                              ),
                              const SizedBox(height: 18),
                            ],
                            SectionTitle(
                              '${c.me}의 최고 케미 TOP 3',
                              sub: '누르면 그 조합으로 볼 수 있어요',
                            ),
                            _TopMatches(
                              me: c.me,
                              current: c.you,
                              onOpen: (you) => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      MbtiResultScreen(me: c.me, you: you),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton(
                                onPressed: _pickAgain,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: ChemiColors.ink,
                                  side: const BorderSide(
                                    color: ChemiColors.ink,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: Text(
                                  '상대 바꿔서 다시 보기',
                                  style: ChemiText.label(15),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'MBTI 케미는 네 가지 성향이 같은지 다른지로 계산한 재미용 결과예요.',
                              textAlign: TextAlign.center,
                              style: ChemiText.body(
                                12,
                                color: ChemiColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  StatusScrim(controller: _scroll),
                ],
              ),
            ),
            SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(22, 8, 22, 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _openShare,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ChemiColors.pink,
                    foregroundColor: ChemiColors.ink,
                  ),
                  icon: const Icon(Icons.ios_share, size: 20),
                  label: Text('스토리에 공유하기', style: ChemiText.label(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Score extends StatelessWidget {
  final int score;
  final double size;
  const _Score({required this.score, required this.size});

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        TextSpan(text: '$score', style: ChemiText.display(size, height: 1.0)),
        TextSpan(text: '점', style: ChemiText.display(size * 0.32)),
      ],
    ),
    semanticsLabel: '$score점',
  );
}

class _TypeTag extends StatelessWidget {
  final String type;
  final bool dark;
  const _TypeTag(this.type, {required this.dark});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: dark ? ChemiColors.ink : Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      type,
      style: ChemiText.display(
        26,
        color: dark ? Colors.white : ChemiColors.ink,
      ),
    ),
  );
}

/// 두 사람 캐릭터: 별명, 한 줄 특징, 연애 스타일
class _People extends StatelessWidget {
  final MbtiChemi chemi;
  const _People({required this.chemi});

  Widget _card(String type, MbtiProfile p, bool dark) {
    final fg = dark ? Colors.white : ChemiColors.ink;
    final sub = dark ? ChemiColors.mutedOnInk : ChemiColors.muted;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? ChemiColors.ink : Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(type, style: ChemiText.label(12, color: sub)),
          Text(p.nick, style: ChemiText.display(19, color: fg)),
          const SizedBox(height: 6),
          Text(
            keepWords(p.vibe),
            style: ChemiText.body(13, color: fg, height: 1.45),
          ),
          const SizedBox(height: 8),
          Text('연애할 땐', style: ChemiText.label(11, color: sub)),
          Text(
            keepWords(p.love),
            style: ChemiText.body(13, color: fg, height: 1.45),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _card(chemi.me, chemi.meProfile, false)),
        const SizedBox(width: 8),
        Expanded(child: _card(chemi.you, chemi.youProfile, true)),
      ],
    ),
  );
}

/// 케미 해부: 축마다 받은 점수 막대 + 판정 + 설명
class _Axes extends StatelessWidget {
  final MbtiChemi chemi;
  const _Axes({required this.chemi});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      children: [
        for (final (i, a) in chemi.axes.indexed) ...[
          if (i > 0) const Divider(height: 1, color: ChemiColors.chrome),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(a.label, style: ChemiText.display(16)),
                    const SizedBox(width: 6),
                    Text(
                      a.letters,
                      style: ChemiText.label(12, color: ChemiColors.muted),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: a.verdict == '찰떡'
                            ? ChemiColors.pink
                            : ChemiColors.chrome,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(a.verdict, style: ChemiText.label(11)),
                    ),
                    const SizedBox(width: 8),
                    Text('+${a.points}', style: ChemiText.label(13)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: a.max == 0 ? 0 : a.points / a.max,
                    minHeight: 8,
                    backgroundColor: ChemiColors.chrome,
                    color: ChemiColors.ink,
                    semanticsLabel: '${a.label} ${a.max}점 중 ${a.points}점',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  keepWords(a.text),
                  style: ChemiText.body(
                    13,
                    color: const Color(0xFF3A3A44),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

/// 상황별 케미: 연애 / 우정 / 일
class _Situations extends StatelessWidget {
  final MbtiChemi chemi;
  const _Situations({required this.chemi});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final (label, text) in [
        ('연애', chemi.love),
        ('우정', chemi.friend),
        ('일', chemi.work),
      ]) ...[
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: ChemiColors.pink,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(label, style: ChemiText.label(12)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  keepWords(text),
                  style: ChemiText.body(14, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    ],
  );
}

/// "ENTJ에게 해 주면 좋은 말" 말풍선
class _Quote extends StatelessWidget {
  final String to;
  final String text;
  final bool dark;
  const _Quote({required this.to, required this.text, required this.dark});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
    decoration: BoxDecoration(
      color: dark ? ChemiColors.ink : Colors.white,
      borderRadius: BorderRadius.circular(
        22,
      ).copyWith(bottomLeft: const Radius.circular(6)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$to에게 해 주면 좋은 말',
          style: ChemiText.label(
            12,
            color: dark ? ChemiColors.mutedOnInk : ChemiColors.muted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '“$text”',
          style: ChemiText.display(
            20,
            color: dark ? Colors.white : ChemiColors.ink,
          ),
        ),
      ],
    ),
  );
}

/// 내 유형의 최고 케미 3개. 지금 보고 있는 조합이면 표시만 하고 누를 수 없다.
class _TopMatches extends StatelessWidget {
  final String me;
  final String current;
  final ValueChanged<String> onOpen;
  const _TopMatches({
    required this.me,
    required this.current,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final top = bestMatches(me);
    return Column(
      children: [
        for (final (i, m) in top.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: m.you == current ? ChemiColors.pink : Colors.white,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: m.you == current ? null : () => onOpen(m.you),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                  child: Row(
                    children: [
                      Text('${i + 1}', style: ChemiText.display(24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${m.you} · ${m.youProfile.nick}',
                              style: ChemiText.display(17),
                            ),
                            Text(
                              m.title,
                              style: ChemiText.body(
                                12,
                                color: m.you == current
                                    ? ChemiColors.ink
                                    : ChemiColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text('${m.score}점', style: ChemiText.display(20)),
                      const SizedBox(width: 4),
                      m.you == current
                          ? Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text('지금', style: ChemiText.label(11)),
                            )
                          : const Icon(
                              Icons.chevron_right,
                              color: ChemiColors.muted,
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
