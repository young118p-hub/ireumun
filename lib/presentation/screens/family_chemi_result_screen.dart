// 가족 케미 - 결과. 무료: 점수와 근거·우리 집 역할·가족 중 누가?·가족 오행 지도·두 사람씩 케미·케미 올리는 법 (전부 규칙, AI 없음)
// 유료(₩5,900): AI 전체 리포트. 결제 흐름은 우리 케미와 같다: 서버에 결과 자리 → Play 결제 → 검증 뒤 서버가 리포트 생성
// → 기기 기록에 저장. 들어올 때 기록한다 (기록에서 다시 열 때는 record: false).
// 두 사람씩 줄을 누르면 그 두 사람의 우리 케미 화면(가족 관계, 결제 칸 없음)으로 간다.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/text/keep_words.dart';
import '../../core/theme/chemi_theme.dart';
import '../../data/family_chemi/family_chemi.dart';
import '../../data/family_chemi/family_chemi_history.dart';
import '../../data/pair_chemi/pair_chemi.dart';
import '../../data/pair_chemi/pair_chemi_history.dart';
import '../../data/services/api_service.dart';
import '../../data/services/purchase_service.dart';
import '../providers/chemi_provider.dart';
import '../providers/naming_provider.dart';
import '../widgets/beaker.dart';
import '../widgets/result_parts.dart';
import '../widgets/status_scrim.dart';
import 'naming_input_screen.dart';
import 'pair_chemi_result_screen.dart';

class FamilyChemiResultScreen extends StatefulWidget {
  final List<FamilyInput> members;
  final bool record;

  const FamilyChemiResultScreen({super.key, required this.members, this.record = true});

  @override
  State<FamilyChemiResultScreen> createState() => _FamilyChemiResultScreenState();
}

class _FamilyChemiResultScreenState extends State<FamilyChemiResultScreen> {
  late final FamilyChemiRecord _base = FamilyChemiRecord(members: widget.members, at: DateTime.now());
  late final FamilyChemi _c = _base.chemi;
  final _scroll = ScrollController();
  bool _preparing = false;

  @override
  void initState() {
    super.initState();
    if (widget.record) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<ChemiProvider>().recordFamily(widget.members);
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _buy() async {
    final chemi = context.read<ChemiProvider>();
    final naming = context.read<NamingProvider>();
    setState(() => _preparing = true);
    try {
      final id = await chemi.ensureFamilyRemote(chemi.familyRecord(_base.id) ?? _base);
      if (!mounted) return;
      setState(() => _preparing = false);
      await naming.purchaseResults(ProductType.familyChemi, [id]);
    } on ApiException catch (e) {
      _notice(e.message);
    } catch (_) {
      _notice('인터넷 연결을 확인하고 다시 시도해 주세요.');
    } finally {
      if (mounted && _preparing) setState(() => _preparing = false);
    }
  }

  void _notice(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  void _share() => openStoryShare(
    context,
    card: StoryCard(
      label: '가족 케미',
      pair: _c.members.map((m) => m.name).join(' · '),
      score: _c.score,
      title: _c.title,
      tags: _c.tags,
    ),
    shareText: '우리 가족 케미 ${_c.score}점! 너희 집은 몇 점? #케미연구소',
  );

  void _openPair(FamilyPair p) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PairChemiResultScreen(
        me: _pairInput(widget.members[p.i]),
        you: _pairInput(widget.members[p.j]),
        relation: PairRelation.family,
        record: false,
      ),
    ),
  );

  PairInput _pairInput(FamilyInput m) => PairInput(m.name, m.birth);

  @override
  Widget build(BuildContext context) {
    final c = _c;
    final saved = context.watch<ChemiProvider>().familyRecord(_base.id);
    final naming = context.watch<NamingProvider>();
    final busy = _preparing || naming.purchaseBusy;
    final top = MediaQuery.paddingOf(context).top;
    final sorted = [...c.pairs]..sort((x, y) => y.chemi.score.compareTo(x.chemi.score));

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
                      _Hero(chemi: c, top: top, onShare: _share),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
                        child: Column(
                          children: [
                            _Basis(chemi: c),
                            const SizedBox(height: 18),
                            const SectionTitle('우리 집 역할', sub: '태어난 날의 기운(일간)으로 본 가족 안 내 자리'),
                            for (final (i, m) in c.members.indexed) ...[
                              if (i > 0) const SizedBox(height: 8),
                              _RoleCard(member: m, dark: i.isOdd),
                            ],
                            const SizedBox(height: 18),
                            const SectionTitle('우리 가족 중 누가?', sub: '가족 사주의 오행 개수로 맞혀 봤어요'),
                            WhoSection(items: c.who, tie: '공동'),
                            const SizedBox(height: 18),
                            const SectionTitle('가족 오행 지도', sub: '가족 모두의 사주 글자를 모아서'),
                            _OhengMap(chemi: c),
                            const SizedBox(height: 18),
                            const SectionTitle('두 사람씩 케미', sub: '누르면 두 사람의 자세한 케미를 볼 수 있어요'),
                            _PairTable(pairs: sorted, members: c.members, onTap: _openPair),
                            const SizedBox(height: 18),
                            const SectionTitle('케미 올리는 법', sub: '가장 약한 두 사람과 가족에게 부족한 기운부터'),
                            ImproveSection(items: c.improves),
                            const SizedBox(height: 18),
                            if (saved?.paid == true && saved?.report != null)
                              _Report(report: saved!.report!)
                            else
                              LockedReport(
                                sub: '위 해설을 바탕으로 우리 가족만을 위해 더 길게 풀어 드려요',
                                items: const ['우리 가족의 강점 3가지', '주의할 점 2가지와 해결법', '한 사람씩 가족에게 해 주면 좋은 것', '올해 우리 가족 흐름'],
                                price: naming.product(ProductType.familyChemi).priceString,
                                busy: busy,
                                status: naming.purchaseStatus,
                                onBuy: _buy,
                              ),
                            const SizedBox(height: 16),
                            PairChemiLink(
                              lead: '곧 태어날 아기가 있다면',
                              headline: '가족 사주에 맞는\n아기 이름 찾기',
                              onTap: () =>
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NamingInputScreen())),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: ChemiColors.ink,
                                  side: const BorderSide(color: ChemiColors.ink, width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                ),
                                child: Text(widget.record ? '가족 바꿔서 다시 보기' : '돌아가기', style: ChemiText.label(15)),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              keepWords(
                                '가족 케미는 두 사람씩 본 우리 케미 점수와 가족 오행의 고른 정도로 계산했어요. '
                                '궁합 점수는 학파마다 조금씩 달라요.',
                              ),
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

class _Hero extends StatelessWidget {
  final FamilyChemi chemi;
  final double top;
  final VoidCallback onShare;
  const _Hero({required this.chemi, required this.top, required this.onShare});

  @override
  Widget build(BuildContext context) {
    final c = chemi;
    return Container(
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
              Expanded(
                child: Center(child: Text('가족 케미 · ${c.members.length}명', style: ChemiText.label(14))),
              ),
              IconButton(
                tooltip: '공유',
                onPressed: onShare,
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
                        child: Text(c.members.map((m) => m.name).join(' · '), style: ChemiText.display(26)),
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '${c.score}', style: ChemiText.display(88, height: 1.0)),
                            TextSpan(text: '점', style: ChemiText.display(28)),
                          ],
                        ),
                        semanticsLabel: '${c.score}점',
                      ),
                      Text(keepWords(c.title), style: ChemiText.display(24, height: 1.25)),
                      const SizedBox(height: 6),
                      Text(keepWords(c.accuracy), style: ChemiText.label(12)),
                    ],
                  ),
                ),
                const Beaker(width: 76, face: BeakerFace.happy),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 점수는 이렇게 나왔어요 (숫자가 어디서 왔는지 그대로)
class _Basis extends StatelessWidget {
  final FamilyChemi chemi;
  const _Basis({required this.chemi});

  @override
  Widget build(BuildContext context) {
    final c = chemi;
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: ChemiText.body(14, color: const Color(0xFF3A3A44))),
          ),
          Text(value, style: ChemiText.label(14)),
        ],
      ),
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('점수는 이렇게 나왔어요', style: ChemiText.display(17)),
          const SizedBox(height: 8),
          row('두 사람씩 본 케미 평균 (${c.pairs.length}쌍)', '${c.pairAverage}점 × 0.85'),
          row('가족 오행 ${c.coverage}가지 보너스', '+${c.bonus}점'),
          const Divider(height: 16, color: ChemiColors.chrome),
          row('가족 케미', '${c.score}점'),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final FamilyMember member;
  final bool dark;
  const _RoleCard({required this.member, required this.dark});

  @override
  Widget build(BuildContext context) {
    final m = member;
    final pos = familyPositions[m.element]!;
    final (_, symbol, _) = m.person.persona;
    final fg = dark ? Colors.white : ChemiColors.ink;
    final sub = dark ? ChemiColors.mutedOnInk : ChemiColors.muted;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: dark ? ChemiColors.ink : Colors.white, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(m.name == m.role.label ? m.name : '${m.name} · ${m.role.label}', style: ChemiText.label(12, color: sub)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: elementColors[m.element], borderRadius: BorderRadius.circular(999)),
                child: Text('${m.element}${elementHanja[m.element]}', style: ChemiText.label(12)),
              ),
            ],
          ),
          Text(pos.title, style: ChemiText.display(22, color: fg)),
          const SizedBox(height: 6),
          Text(keepWords(pos.text), style: ChemiText.body(14, color: fg, height: 1.55)),
          const SizedBox(height: 4),
          Text(keepWords('타고난 성격: $symbol'), style: ChemiText.label(12, color: sub)),
        ],
      ),
    );
  }
}

class _OhengMap extends StatelessWidget {
  final FamilyChemi chemi;
  const _OhengMap({required this.chemi});

  @override
  Widget build(BuildContext context) {
    final c = chemi;
    final most = FamilyChemi.elements.map((e) => c.oheng[e] ?? 0).reduce((x, y) => x > y ? x : y).clamp(1, 99);
    final note = c.missing.isEmpty
        ? '다섯 기운이 모두 있어요. 서로 부족한 걸 가족 안에서 채울 수 있는 집이에요.'
        : '가족 모두에게 ${c.missing.map((e) => '$e(${elementHanja[e]})').join('·')} 기운이 없어요. 아래 "케미 올리는 법"에서 채우는 법을 알려 드려요.';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final e in FamilyChemi.elements)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Semantics(
                label: '$e ${c.oheng[e] ?? 0}개',
                excludeSemantics: true,
                child: Row(
                  children: [
                    SizedBox(width: 44, child: Text('${elementHanja[e]} $e', style: ChemiText.label(13))),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: (c.oheng[e] ?? 0) / most,
                          minHeight: 10,
                          color: elementColors[e],
                          backgroundColor: ChemiColors.chrome,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        (c.oheng[e] ?? 0) == 0 ? '없음' : '${c.oheng[e]}',
                        textAlign: TextAlign.right,
                        style: ChemiText.label(13, color: (c.oheng[e] ?? 0) == 0 ? ChemiColors.warn : ChemiColors.ink),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(keepWords(note), style: ChemiText.body(13, color: const Color(0xFF3A3A44), height: 1.55)),
        ],
      ),
    );
  }
}

class _PairTable extends StatelessWidget {
  final List<FamilyPair> pairs; // 점수 높은 순
  final List<FamilyMember> members;
  final ValueChanged<FamilyPair> onTap;
  const _PairTable({required this.pairs, required this.members, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bestScore = pairs.first.chemi.score, worstScore = pairs.last.chemi.score;
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (i, p) in pairs.indexed) ...[
            if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16, color: ChemiColors.chrome),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onTap(p),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    '${members[p.i].name} × ${members[p.j].name}',
                                    style: ChemiText.label(15),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (bestScore != worstScore && p.chemi.score == bestScore) ...[
                                  const SizedBox(width: 6),
                                  const _Badge('최고 케미', ChemiColors.pink),
                                ],
                                if (bestScore != worstScore && p.chemi.score == worstScore) ...[
                                  const SizedBox(width: 6),
                                  const _Badge('노력 필요', ChemiColors.chrome),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(keepWords(p.chemi.title), style: ChemiText.body(12, color: ChemiColors.muted)),
                          ],
                        ),
                      ),
                      Text('${p.chemi.score}점', style: ChemiText.display(20)),
                      const Icon(Icons.chevron_right, color: ChemiColors.muted),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
    child: Text(text, style: ChemiText.label(11)),
  );
}

/// 결제 뒤: AI 전체 리포트
class _Report extends StatelessWidget {
  final Map<String, dynamic> report;
  const _Report({required this.report});

  List<Map<String, dynamic>> _items(String key) => [
    for (final x in (report[key] as List? ?? const []))
      if (x is Map) Map<String, dynamic>.from(x),
  ];

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const SectionTitle('전체 리포트'),
      for (final g in _items('strengths')) ...[
        TextCard(title: '우리 가족의 강점 · ${g['title'] ?? ''}', body: '${g['body'] ?? ''}'),
        const SizedBox(height: 8),
      ],
      for (final g in _items('cautions')) ...[
        TextCard(title: '주의할 점 · ${g['title'] ?? ''}', body: '${g['body'] ?? ''}'),
        const SizedBox(height: 8),
      ],
      for (final g in _items('members')) ...[
        TextCard(title: '${g['name'] ?? ''}에게', body: '${g['body'] ?? ''}'),
        const SizedBox(height: 8),
      ],
      if (report['yearFlow'] is String) TextCard(title: '올해 우리 가족의 흐름', body: report['yearFlow'] as String),
    ],
  );
}
