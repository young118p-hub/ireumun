// 이름 케미 - 결과 (무료, 규칙으로 계산). 들어올 때 기록한다 (기록에서 다시 열 때는 record: false).
// 순서: 점수 → 두 이름(글자별 오행, 대표 기운, 소리 흐름) → 오행 막대·서로 채워 주는 기운
//       → 두 기운이 만나면 → 점수 근거 → 공유 / 다른 이름으로

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/text/keep_words.dart';
import '../../core/theme/chemi_theme.dart';
import '../../data/name_chemi/name_chemi.dart';
import '../providers/chemi_provider.dart';
import '../widgets/beaker.dart';
import '../widgets/element_chip.dart';
import '../widgets/result_parts.dart';
import '../widgets/status_scrim.dart';
import '../../core/config/features.dart';
import 'name_chemi_input_screen.dart';
import 'pair_chemi_input_screen.dart';

class NameChemiResultScreen extends StatefulWidget {
  final String me;
  final String you;
  final bool record;

  const NameChemiResultScreen({super.key, required this.me, required this.you, this.record = true});

  @override
  State<NameChemiResultScreen> createState() => _NameChemiResultScreenState();
}

class _NameChemiResultScreenState extends State<NameChemiResultScreen> {
  late final NameChemi _c = nameChemi(widget.me, widget.you);
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.record) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<ChemiProvider>().recordName(widget.me, widget.you);
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _share() => openStoryShare(
        context,
        card: StoryCard(
          label: '이름 케미',
          pair: '${_c.a.name} × ${_c.b.name}',
          score: _c.score,
          title: _c.title,
          tags: _c.tags,
        ),
        shareText: '우리 이름 케미 ${_c.score}점! 너희 이름은 몇 점? #케미연구소',
      );

  /// 입력에서 왔으면 돌아가기 (이름 유지), 기록에서 열었으면 입력 화면으로 바꿔 끼우기
  void _again() {
    if (widget.record) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const NameChemiInputScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
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
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  tooltip: '뒤로',
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.arrow_back_ios_new, size: 22, color: ChemiColors.ink),
                                ),
                                Expanded(child: Center(child: Text('이름 케미', style: ChemiText.label(14)))),
                                IconButton(
                                  tooltip: '공유',
                                  onPressed: _share,
                                  icon: const Icon(Icons.ios_share, size: 22, color: ChemiColors.ink),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text('${c.a.name} × ${c.b.name}', style: ChemiText.display(28)),
                                        ),
                                        Text.rich(
                                          TextSpan(children: [
                                            TextSpan(text: '${c.score}', style: ChemiText.display(88, height: 1.0)),
                                            TextSpan(text: '점', style: ChemiText.display(28)),
                                          ]),
                                          semanticsLabel: '${c.score}점',
                                        ),
                                        Text(keepWords(c.title), style: ChemiText.display(24, height: 1.25)),
                                        const SizedBox(height: 4),
                                        Text(keepWords(c.direction), style: ChemiText.label(13)),
                                      ],
                                    ),
                                  ),
                                  const Beaker(width: 76, face: BeakerFace.happy),
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
                            _Person(reading: c.a),
                            const SizedBox(height: 8),
                            _Person(reading: c.b, dark: true),
                            const SizedBox(height: 18),
                            const SectionTitle('오행 비교', sub: '이름 글자 소리마다 하나씩'),
                            _ElementBars(chemi: c),
                            const SizedBox(height: 18),
                            const SectionTitle('두 기운이 만나면'),
                            TextCard(title: c.title, body: c.pairText),
                            const SizedBox(height: 18),
                            const SectionTitle('케미 올리는 법'),
                            ImproveSection(items: c.improves),
                            const SizedBox(height: 18),
                            const SectionTitle('점수 근거', sub: '기본 58점에 더해진 점수'),
                            _Parts(chemi: c),
                            if (Features.pairChemi) ...[
                              const SizedBox(height: 18),
                              PairChemiLink(
                                lead: '이름은 소리, 사주는 타고난 기운',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const PairChemiInputScreen()),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton(
                                onPressed: _again,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: ChemiColors.ink,
                                  side: const BorderSide(color: ChemiColors.ink, width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                ),
                                child: Text('다른 이름으로 다시 보기', style: ChemiText.label(15)),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              keepWords('이름 케미는 이름 소리(첫소리)로 보는 음령오행이에요. '
                                  '생일까지 넣어 사주로 보는 궁합은 우리 케미에서 볼 수 있어요.'),
                              textAlign: TextAlign.center,
                              style: ChemiText.body(12, color: ChemiColors.muted),
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
                  onPressed: _share,
                  style: ElevatedButton.styleFrom(backgroundColor: ChemiColors.pink, foregroundColor: ChemiColors.ink),
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

/// 한 사람: 이름 글자별 오행 칩, 대표 기운, 소리 흐름
class _Person extends StatelessWidget {
  final NameReading reading;
  final bool dark;
  const _Person({required this.reading, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final p = personas[reading.dominant]!;
    final fg = dark ? Colors.white : ChemiColors.ink;
    final sub = dark ? ChemiColors.mutedOnInk : ChemiColors.muted;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: dark ? ChemiColors.ink : Colors.white, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(reading.name, style: ChemiText.display(22, color: fg)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: elementColors[reading.dominant], borderRadius: BorderRadius.circular(999)),
                child: Text('${elementHanja[reading.dominant]} ${p.name}', style: ChemiText.label(12)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            children: [for (final (s, e) in reading.syllables) SyllableChip(syllable: s, element: e, size: 48)],
          ),
          const SizedBox(height: 10),
          Text(keepWords(p.desc), style: ChemiText.body(13, color: fg, height: 1.5)),
          const SizedBox(height: 4),
          Text('소리 흐름 · ${reading.flow}', style: ChemiText.label(12, color: sub)),
        ],
      ),
    );
  }
}

/// 오행별 두 사람 글자 수 + 서로 채워 주는 기운
class _ElementBars extends StatelessWidget {
  final NameChemi chemi;
  const _ElementBars({required this.chemi});

  String _fills(String who, String from, List<String> els) => els.isEmpty
      ? ''
      : '$who에게 없는 ${els.map((e) => '${elementHanja[e]}$e').join('·')} 기운을 $from 이름이 채워 줘요.';

  @override
  Widget build(BuildContext context) {
    final a = chemi.a.counts, b = chemi.b.counts;
    final most = [...a.values, ...b.values].reduce((x, y) => x > y ? x : y).clamp(1, 4);
    final notes = [
      _fills(chemi.a.name, chemi.b.name, chemi.aGetsFromB),
      _fills(chemi.b.name, chemi.a.name, chemi.bGetsFromA),
    ].where((t) => t.isNotEmpty).toList();
    Widget bar(int n, Color color) => Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: n / most, minHeight: 8, color: color, backgroundColor: ChemiColors.chrome),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: 44),
              Expanded(child: Text(chemi.a.name, style: ChemiText.label(12, color: ChemiColors.muted))),
              const SizedBox(width: 8),
              Expanded(child: Text(chemi.b.name, style: ChemiText.label(12, color: ChemiColors.pinkDeep))),
            ],
          ),
          const SizedBox(height: 6),
          for (final e in elements)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Semantics(
                label: '$e: ${chemi.a.name} ${a[e]}개, ${chemi.b.name} ${b[e]}개',
                excludeSemantics: true,
                child: Row(
                  children: [
                    SizedBox(width: 44, child: Text('${elementHanja[e]} $e', style: ChemiText.label(13))),
                    bar(a[e]!, ChemiColors.ink),
                    const SizedBox(width: 8),
                    bar(b[e]!, ChemiColors.pink),
                  ],
                ),
              ),
            ),
          if (notes.isNotEmpty) ...[
            const Divider(height: 24, color: ChemiColors.chrome),
            for (final n in notes)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(keepWords(n), style: ChemiText.body(13, height: 1.5)),
              ),
          ],
        ],
      ),
    );
  }
}

/// 점수 근거: 대표 기운 / 오행 다양성 / 소리 흐름
class _Parts extends StatelessWidget {
  final NameChemi chemi;
  const _Parts({required this.chemi});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
        child: Column(
          children: [
            for (final (i, p) in chemi.parts.indexed) ...[
              if (i > 0) const Divider(height: 1, color: ChemiColors.chrome),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(p.label, style: ChemiText.display(16)),
                        const Spacer(),
                        Text('+${p.points}', style: ChemiText.label(13)),
                        Text(' / ${p.max}', style: ChemiText.label(12, color: ChemiColors.muted)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: p.points / p.max,
                        minHeight: 8,
                        color: ChemiColors.ink,
                        backgroundColor: ChemiColors.chrome,
                        semanticsLabel: '${p.label} ${p.max}점 중 ${p.points}점',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(keepWords(p.text), style: ChemiText.body(13, color: const Color(0xFF3A3A44), height: 1.5)),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
}
