// 우리 케미 - 결과. 무료: 점수·서로에게 어떤 사람(십신)·오행 비교·점수 근거와 해설 (전부 규칙, AI 없음)
// 유료(₩4,900): AI 전체 리포트. 결제 흐름: 서버에 결과 자리 만들기 → Play 결제 → 검증 뒤 서버가 리포트 생성
// → 기기 기록에 저장(오프라인에서도 열림). 들어올 때 기록한다 (기록에서 다시 열 때는 record: false).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/text/keep_words.dart';
import '../../core/theme/chemi_theme.dart';
import '../../data/pair_chemi/pair_chemi.dart';
import '../../data/pair_chemi/pair_chemi_history.dart';
import '../../data/services/api_service.dart';
import '../../data/services/purchase_service.dart';
import '../providers/chemi_provider.dart';
import '../providers/naming_provider.dart';
import '../widgets/beaker.dart';
import '../widgets/result_parts.dart';
import '../widgets/status_scrim.dart';

class PairChemiResultScreen extends StatefulWidget {
  final PairInput me;
  final PairInput you;
  final PairRelation relation;
  final bool record;

  const PairChemiResultScreen({
    super.key,
    required this.me,
    required this.you,
    required this.relation,
    this.record = true,
  });

  @override
  State<PairChemiResultScreen> createState() => _PairChemiResultScreenState();
}

class _PairChemiResultScreenState extends State<PairChemiResultScreen> {
  late final PairChemiRecord _base =
      PairChemiRecord(a: widget.me, b: widget.you, relation: widget.relation, at: DateTime.now());
  late final PairChemi _c = _base.chemi;
  final _scroll = ScrollController();
  bool _preparing = false; // 서버에 결과 자리 만드는 중

  @override
  void initState() {
    super.initState();
    if (widget.record) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<ChemiProvider>().recordPair(widget.me, widget.you, widget.relation);
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
      final id = await chemi.ensurePairRemote(chemi.pairRecord(_base.id) ?? _base);
      if (!mounted) return;
      setState(() => _preparing = false);
      await naming.purchaseResults(ProductType.pairChemi, [id]);
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
          label: '우리 케미',
          pair: '${_c.a.name} × ${_c.b.name}',
          score: _c.score,
          title: _c.title,
          tags: _c.tags,
        ),
        shareText: '우리 케미 ${_c.score}점! 너희는 몇 점? #케미연구소',
      );

  @override
  Widget build(BuildContext context) {
    final c = _c;
    final saved = context.watch<ChemiProvider>().pairRecord(_base.id);
    final naming = context.watch<NamingProvider>();
    final busy = _preparing || naming.purchaseBusy;
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
                      _Hero(chemi: c, top: top, onShare: _share),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
                        child: Column(
                          children: [
                            const SectionTitle('서로에게 어떤 사람일까', sub: '상대의 일간이 나에게 무엇인지 (십신)'),
                            for (final (i, g) in c.tenGods.indexed) ...[
                              if (i > 0) const SizedBox(height: 8),
                              _TenGodCard(view: g, dark: i == 1),
                            ],
                            const SizedBox(height: 18),
                            const SectionTitle('오행 비교', sub: '사주 글자마다 하나씩'),
                            _ElementBars(chemi: c),
                            const SizedBox(height: 18),
                            const SectionTitle('점수 근거와 해설', sub: '기본 45점에 더해진 점수'),
                            for (final p in c.parts) ...[
                              _PartCard(part: p),
                              const SizedBox(height: 8),
                            ],
                            const SizedBox(height: 10),
                            if (saved?.paid == true && saved?.report != null)
                              _Report(report: saved!.report!)
                            else
                              _Locked(
                                price: naming.product(ProductType.pairChemi).priceString,
                                busy: busy,
                                status: naming.purchaseStatus,
                                onBuy: _buy,
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
                                child: Text(widget.record ? '다른 사람과 다시 보기' : '돌아가기', style: ChemiText.label(15)),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              keepWords('궁합 점수는 학파마다 조금씩 달라요. 케미연구소는 일간·일지·띠·시주·오행 보완을 '
                                  '흔히 쓰는 기준으로 점수화했어요.'),
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
  final PairChemi chemi;
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
              Expanded(child: Center(child: Text('우리 케미 · ${c.relation.label}', style: ChemiText.label(14)))),
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
                        child: Text('${c.a.name} × ${c.b.name}', style: ChemiText.display(28)),
                      ),
                      Text('${c.a.animal}띠 · ${c.b.animal}띠', style: ChemiText.label(13)),
                      Text.rich(
                        TextSpan(children: [
                          TextSpan(text: '${c.score}', style: ChemiText.display(88, height: 1.0)),
                          TextSpan(text: '점', style: ChemiText.display(28)),
                        ]),
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

class _TenGodCard extends StatelessWidget {
  final TenGodView view;
  final bool dark;
  const _TenGodCard({required this.view, required this.dark});

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : ChemiColors.ink;
    final sub = dark ? ChemiColors.mutedOnInk : ChemiColors.muted;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: dark ? ChemiColors.ink : Colors.white, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${view.from}에게 ${view.to}는', style: ChemiText.label(12, color: sub)),
          Text(view.title, style: ChemiText.display(22, color: fg)),
          const SizedBox(height: 6),
          Text(keepWords(view.text), style: ChemiText.body(14, color: fg, height: 1.55)),
        ],
      ),
    );
  }
}

class _ElementBars extends StatelessWidget {
  final PairChemi chemi;
  const _ElementBars({required this.chemi});

  static const _els = ['목', '화', '토', '금', '수'];

  @override
  Widget build(BuildContext context) {
    final a = chemi.a.saju.ohengBalance, b = chemi.b.saju.ohengBalance;
    final most = [..._els.map((e) => a[e] ?? 0), ..._els.map((e) => b[e] ?? 0)].reduce((x, y) => x > y ? x : y).clamp(1, 8);
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
          for (final e in _els)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Semantics(
                label: '$e: ${chemi.a.name} ${a[e] ?? 0}개, ${chemi.b.name} ${b[e] ?? 0}개',
                excludeSemantics: true,
                child: Row(
                  children: [
                    SizedBox(width: 44, child: Text('${elementHanja[e]} $e', style: ChemiText.label(13))),
                    bar(a[e] ?? 0, ChemiColors.ink),
                    const SizedBox(width: 8),
                    bar(b[e] ?? 0, ChemiColors.pink),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PartCard extends StatelessWidget {
  final PairPart part;
  const _PartCard({required this.part});

  @override
  Widget build(BuildContext context) {
    final p = part;
    final good = p.points * 10 >= p.max * 8;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(p.label, style: ChemiText.display(17))),
              Text('+${p.points}', style: ChemiText.label(14)),
              Text(' / ${p.max}', style: ChemiText.label(12, color: ChemiColors.muted)),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: !p.known ? ChemiColors.chrome : (good ? ChemiColors.pink : ChemiColors.chrome),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(p.badge, style: ChemiText.label(12)),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: p.points / p.max,
              minHeight: 8,
              color: p.known ? ChemiColors.ink : ChemiColors.disabled,
              backgroundColor: ChemiColors.chrome,
              semanticsLabel: '${p.label} ${p.max}점 중 ${p.points}점',
            ),
          ),
          const SizedBox(height: 10),
          Text(keepWords(p.text),
              style: ChemiText.body(14, color: p.known ? const Color(0xFF3A3A44) : ChemiColors.muted, height: 1.6)),
        ],
      ),
    );
  }
}

/// 결제 전: 전체 리포트에 무엇이 있는지 + 결제 버튼
class _Locked extends StatelessWidget {
  final String price;
  final bool busy;
  final String? status;
  final VoidCallback onBuy;
  const _Locked({required this.price, required this.busy, required this.status, required this.onBuy});

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
            Text('위 해설을 바탕으로 두 사람만을 위해 더 길게 풀어 드려요',
                style: ChemiText.body(13, color: ChemiColors.mutedOnInk)),
            const SizedBox(height: 12),
            for (final t in ['잘 맞는 점 3가지', '부딪히는 점 2가지와 해결법', '올해 두 사람 관계 흐름', '둘을 위한 조언'])
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

/// 결제 뒤: AI 전체 리포트
class _Report extends StatelessWidget {
  final Map<String, dynamic> report;
  const _Report({required this.report});

  List<Map<String, dynamic>> _items(String key) =>
      [for (final x in (report[key] as List? ?? const [])) if (x is Map) Map<String, dynamic>.from(x)];

  @override
  Widget build(BuildContext context) {
    final good = _items('goodPoints'), clash = _items('clashPoints');
    final advice = [for (final x in (report['advice'] as List? ?? const [])) '$x'];
    return Column(
      children: [
        const SectionTitle('전체 리포트'),
        for (final g in good) ...[
          TextCard(title: '잘 맞는 점 · ${g['title'] ?? ''}', body: '${g['body'] ?? ''}'),
          const SizedBox(height: 8),
        ],
        for (final g in clash) ...[
          TextCard(title: '부딪히는 점 · ${g['title'] ?? ''}', body: '${g['body'] ?? ''}'),
          const SizedBox(height: 8),
        ],
        if (report['yearFlow'] is String) ...[
          TextCard(title: '올해 두 사람의 흐름', body: report['yearFlow'] as String),
          const SizedBox(height: 8),
        ],
        if (advice.isNotEmpty) TextCard(title: '둘을 위한 조언', body: advice.map((a) => '· $a').join('\n')),
      ],
    );
  }
}
