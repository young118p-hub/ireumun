// 홈 (시안 K: 핑크 상단 + 크롬 하단)
// 누르는 곳마다 어디로 가는지는 docs/screen-map.md. 요약:
// - "내 이름 케미부터" → 이름 진단 입력 / MBTI 유형 → MBTI 고르기(나 선택됨)
// - 결과 카드: 기록이 있으면 내 결과(실제 점수), 없으면 "예시" 카드 → 그 검사 시작
// - 아직 없는 기능은 "곧 열려요"로 눌리지 않음 (core/config/features.dart)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/config/features.dart';
import '../../core/theme/chemi_theme.dart';
import '../../data/mbti/mbti_chemi.dart';
import '../feed.dart';
import '../providers/chemi_provider.dart';
import '../providers/naming_provider.dart';
import '../widgets/beaker.dart';
import '../widgets/feed_card.dart';
import '../widgets/status_scrim.dart';
import 'diagnosis_input_screen.dart';
import 'mbti_pick_screen.dart';
import 'name_chemi_input_screen.dart';
import 'pair_chemi_input_screen.dart';
import 'naming_input_screen.dart';

class HomeScreen extends StatefulWidget {
  /// 내 결과 탭으로 (카드 "전체 보기")
  final VoidCallback onOpenAllResults;

  const HomeScreen({super.key, required this.onOpenAllResults});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _feedLimit = 5;
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _push(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final chemi = context.watch<ChemiProvider>();
    final feed = buildFeed(context.watch<NamingProvider>(), chemi);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Stack(
          children: [
            ListView(
              controller: _scroll,
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom + 100,
              ),
              children: [
                _Hero(
                  myMbti: chemi.myMbti,
                  onNameChemi: () =>
                      _push(context, const DiagnosisInputScreen()),
                  onMbti: (type) =>
                      _push(context, MbtiPickScreen(initialMe: type)),
                ),
                _SectionTitle(
                  title: feed.isEmpty ? '이런 결과가 나와요' : '내 실험 기록',
                  action: feed.isEmpty
                      ? null
                      : (label: '전체 보기', onTap: widget.onOpenAllResults),
                ),
                SizedBox(
                  height: FeedCard.height,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    children: [
                      if (feed.isEmpty) ...[
                        _exampleMbti(context),
                        const SizedBox(width: 10),
                        _exampleNameChemi(context),
                      ] else
                        for (final (i, item)
                            in feed.take(_feedLimit).indexed) ...[
                          if (i > 0) const SizedBox(width: 10),
                          FeedCard(item: item, onTap: () => item.open(context)),
                        ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _MenuTile(
                            title: '우리 케미',
                            enabled: Features.pairChemi,
                            onTap: () => _push(context, const PairChemiInputScreen()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MenuTile(
                              title: '가족 케미',
                              enabled: Features.familyChemi,
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _MenuTile(
                              title: '이름 케미',
                              badge: '무료',
                              enabled: Features.nameChemi,
                              onTap: () => _push(context, const NameChemiInputScreen()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MenuTile(
                              title: '아기 이름 찾기',
                              outlined: true,
                              enabled: true,
                              onTap: () =>
                                  _push(context, const NamingInputScreen()),
                            ),
                          ),
                        ],
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
    );
  }

  /// 기록이 없을 때만: 실제 규칙표 점수를 쓰고, 누르면 같은 조합으로 시작
  Widget _exampleMbti(BuildContext context) {
    final c = mbtiChemi('INFP', 'ENTJ');
    return FeedCard.example(
      label: 'MBTI 케미',
      headline: '${c.me} × ${c.you}',
      score: c.score,
      summary: c.title,
      kind: FeedKind.mbti,
      onTap: () => _push(
        context,
        const MbtiPickScreen(initialMe: 'INFP', initialYou: 'ENTJ'),
      ),
    );
  }

  /// 내 이름 케미는 해 보기 전엔 점수를 모르니 숫자 대신 물음표
  Widget _exampleNameChemi(BuildContext context) => FeedCard.example(
    label: '내 이름 케미',
    headline: '내 사주 × 내 이름',
    score: null,
    summary: '몇 점일지 측정해 보기',
    kind: FeedKind.nameChemi,
    onTap: () => _push(context, const DiagnosisInputScreen()),
  );
}

class _Hero extends StatelessWidget {
  final String? myMbti;
  final VoidCallback onNameChemi;
  final ValueChanged<String?> onMbti;

  const _Hero({
    required this.myMbti,
    required this.onNameChemi,
    required this.onMbti,
  });

  /// MBTI 판에 바로 보이는 3개: 내 유형이 있으면 맨 앞
  List<String> get _quickTypes =>
      {?myMbti, 'INFP', 'ENFP', 'INTJ', 'ENTJ'}.take(3).toList();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      padding: EdgeInsets.fromLTRB(22, top + 16, 22, 20),
      decoration: const BoxDecoration(
        color: ChemiColors.pink,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('케미연구소', style: ChemiText.display(28, height: 1)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('너랑 나,\n케미 몇 점?', style: ChemiText.display(38)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: onNameChemi,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        '내 이름 케미부터',
                        style: ChemiText.label(14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const Beaker(width: 118),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ChemiColors.ink,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'MBTI 케미 · 무료',
                      style: ChemiText.display(18, color: Colors.white),
                    ),
                    const Spacer(),
                    Text(
                      myMbti == null ? '내 유형은?' : '내 유형 $myMbti',
                      style: ChemiText.label(12, color: ChemiColors.mutedOnInk),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final t in _quickTypes) ...[
                      Expanded(
                        child: _MbtiCell(
                          text: t,
                          highlighted: t == myMbti,
                          onTap: () => onMbti(t),
                          semantics: '$t로 MBTI 케미 시작',
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: _MbtiCell(
                        text: '+${mbtiTypes.length - 3}',
                        outlined: true,
                        onTap: () => onMbti(null),
                        semantics: '다른 유형 고르기',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MbtiCell extends StatelessWidget {
  final String text;
  final bool highlighted;
  final bool outlined;
  final VoidCallback onTap;
  final String semantics;

  const _MbtiCell({
    required this.text,
    required this.onTap,
    required this.semantics,
    this.highlighted = false,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = highlighted
        ? Colors.white
        : (outlined ? Colors.transparent : ChemiColors.inkSoft);
    final fg = highlighted
        ? ChemiColors.ink
        : (outlined ? ChemiColors.mutedOnInk : Colors.white);
    return Semantics(
      button: true,
      label: semantics,
      excludeSemantics: true,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: outlined
              ? const BorderSide(color: ChemiColors.inkLine)
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(
            height: 44,
            child: Center(
              child: Text(text, style: ChemiText.label(13, color: fg)),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final ({String label, VoidCallback onTap})? action;
  const _SectionTitle({required this.title, this.action});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 18, 12, 6),
    child: Row(
      children: [
        Text(title, style: ChemiText.display(20)),
        const Spacer(),
        if (action != null)
          TextButton(
            onPressed: action!.onTap,
            style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
            child: Text(
              action!.label,
              style: ChemiText.label(13, color: ChemiColors.muted),
            ),
          ),
      ],
    ),
  );
}

class _MenuTile extends StatelessWidget {
  final String title;
  final String? badge;
  final bool enabled;
  final bool outlined;
  final VoidCallback onTap;

  const _MenuTile({
    required this.title,
    required this.enabled,
    required this.onTap,
    this.badge,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: outlined
          ? const BorderSide(color: ChemiColors.disabled, width: 1.5)
          : BorderSide.none,
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: enabled ? title : '$title, 곧 열려요',
      excludeSemantics: true,
      child: Material(
        color: outlined
            ? Colors.transparent
            : (enabled ? Colors.white : Colors.white.withValues(alpha: 0.5)),
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: enabled ? onTap : null,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: ChemiText.label(
                      14,
                      color: enabled ? ChemiColors.ink : ChemiColors.muted,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                if (!enabled)
                  Text(
                    '곧 열려요',
                    style: ChemiText.label(11, color: ChemiColors.muted),
                  )
                else if (badge != null)
                  Text(
                    badge!,
                    style: ChemiText.label(13, color: ChemiColors.pinkDeep),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
