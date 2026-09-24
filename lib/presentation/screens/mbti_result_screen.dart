// MBTI 케미 - 결과 (무료, 규칙표로 계산)
// 들어올 때 기록한다 (내 결과·홈 "내 실험 기록"). 기록에서 다시 열 때는 record: false.
// 공유: 스토리 카드를 먼저 보여 주고, 그 카드를 이미지로 만들어 공유 시트를 연다.
// "생일까지 넣으면 진짜 케미"(우리 케미로 연결) 카드는 우리 케미가 열릴 때 넣는다 (Features.pairChemi).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/chemi_theme.dart';
import '../../data/mbti/mbti_chemi.dart';
import '../../data/services/share_service.dart';
import '../providers/chemi_provider.dart';
import '../widgets/beaker.dart';
import 'mbti_pick_screen.dart';

class MbtiResultScreen extends StatefulWidget {
  final String me;
  final String you;
  final bool record;

  const MbtiResultScreen({super.key, required this.me, required this.you, this.record = true});

  @override
  State<MbtiResultScreen> createState() => _MbtiResultScreenState();
}

class _MbtiResultScreenState extends State<MbtiResultScreen> {
  late final MbtiChemi _chemi = mbtiChemi(widget.me, widget.you);

  @override
  void initState() {
    super.initState();
    if (widget.record) {
      // 첫 프레임 뒤에 (build 중 notifyListeners 방지)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<ChemiProvider>().recordMbti(widget.me, widget.you);
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _ShareSheet(chemi: _chemi),
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
              child: ListView(
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
                            Expanded(child: Center(child: Text('MBTI 케미', style: ChemiText.label(14)))),
                            IconButton(
                              tooltip: '공유',
                              onPressed: _openShare,
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
                                    Wrap(
                                      spacing: 8,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        _TypeTag(c.me, dark: false),
                                        Text('×', style: ChemiText.display(26)),
                                        _TypeTag(c.you, dark: true),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    _Score(score: c.score, size: 88),
                                    Text(c.title, style: ChemiText.display(24, height: 1.25)),
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
                        _TextCard(title: '잘 맞는 점', body: c.strength),
                        const SizedBox(height: 10),
                        _TextCard(title: '부딪히는 순간', body: c.clash),
                        const SizedBox(height: 10),
                        _TextCard(title: '대화 꿀팁', body: c.tip),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: _pickAgain,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: ChemiColors.ink,
                              side: const BorderSide(color: ChemiColors.ink, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            ),
                            child: Text('상대 바꿔서 다시 보기', style: ChemiText.label(15)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'MBTI 케미는 네 가지 성향이 같은지 다른지로 계산한 재미용 결과예요.',
                          textAlign: TextAlign.center,
                          style: ChemiText.body(12, color: ChemiColors.muted),
                        ),
                      ],
                    ),
                  ),
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
        TextSpan(children: [
          TextSpan(text: '$score', style: ChemiText.display(size, height: 1.0)),
          TextSpan(text: '점', style: ChemiText.display(size * 0.32)),
        ]),
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
        child: Text(type, style: ChemiText.display(26, color: dark ? Colors.white : ChemiColors.ink)),
      );
}

class _TextCard extends StatelessWidget {
  final String title;
  final String body;
  const _TextCard({required this.title, required this.body});

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
            Text(body, style: ChemiText.body(14, color: const Color(0xFF3A3A44), height: 1.55)),
          ],
        ),
      );
}

/// 공유 전 미리보기: 이 카드를 그대로 이미지로 만든다
class _ShareSheet extends StatefulWidget {
  final MbtiChemi chemi;
  const _ShareSheet({required this.chemi});

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final _cardKey = GlobalKey();
  bool _busy = false;

  /// 이미지 만들기 → 공유 창이 뜰 때까지 버튼에 로딩 표시 (느린 폰에서 2초 넘게 걸림)
  /// → 공유를 마치면 이 미리보기 창도 닫는다
  Future<void> _share() async {
    setState(() => _busy = true);
    final bytes = await ShareService.captureWidget(_cardKey);
    final shared = bytes != null &&
        await ShareService.shareImage(
          bytes,
          text: '우리 MBTI 케미 ${widget.chemi.score}점! 너희는 몇 점? #케미연구소',
        );
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
    final c = widget.chemi;
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
            // 9:16 스토리 카드
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: RepaintBoundary(
                  key: _cardKey,
                  child: _StoryCard(chemi: c),
                ),
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

class _StoryCard extends StatelessWidget {
  final MbtiChemi chemi;
  const _StoryCard({required this.chemi});

  @override
  Widget build(BuildContext context) {
    final c = chemi;
    return LayoutBuilder(builder: (context, box) {
      final u = box.maxWidth / 390; // 시안(390 폭) 기준 비율
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
                  child: Text('MBTI 케미', style: ChemiText.label(12 * u, color: Colors.white)),
                ),
              ],
            ),
            const Spacer(),
            Text('${c.me} × ${c.you}', style: ChemiText.display(36 * u)),
            Text.rich(TextSpan(children: [
              TextSpan(text: '${c.score}', style: ChemiText.display(140 * u, height: 1.0)),
              TextSpan(text: '점', style: ChemiText.display(40 * u)),
            ])),
            Text(c.title, style: ChemiText.display(28 * u, height: 1.25)),
            SizedBox(height: 14 * u),
            Wrap(
              spacing: 6 * u,
              runSpacing: 6 * u,
              children: [
                for (final (i, t) in c.tags.indexed)
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
