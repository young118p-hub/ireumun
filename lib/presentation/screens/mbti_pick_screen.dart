// MBTI 케미 - 두 유형 고르기 (무료, 서버 없음)
// 홈에서 유형을 눌러 들어오면 "나는"에 그 유형이 선택된 채로 시작한다.
// 둘 다 골라야 버튼이 눌린다. 결과에서 뒤로 오면 선택이 그대로 남아 상대만 바꿔 다시 볼 수 있다.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/chemi_theme.dart';
import '../../data/mbti/mbti_chemi.dart';
import '../providers/chemi_provider.dart';
import 'mbti_result_screen.dart';

class MbtiPickScreen extends StatefulWidget {
  final String? initialMe;
  final String? initialYou;

  const MbtiPickScreen({super.key, this.initialMe, this.initialYou});

  @override
  State<MbtiPickScreen> createState() => _MbtiPickScreenState();
}

class _MbtiPickScreenState extends State<MbtiPickScreen> {
  String? _me;
  String? _you;

  @override
  void initState() {
    super.initState();
    _me = widget.initialMe ?? context.read<ChemiProvider>().myMbti;
    _you = widget.initialYou;
  }

  bool get _ready => _me != null && _you != null;

  void _showResult() {
    if (!_ready) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MbtiResultScreen(me: _me!, you: _you!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(12, top + 4, 22, 22),
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
                      const Spacer(),
                      const _Pill(text: '무료', background: ChemiColors.ink, color: Colors.white),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MBTI 케미', style: ChemiText.display(34)),
                        const SizedBox(height: 4),
                        Text('생일 없이 유형만 골라도 바로 나와요', style: ChemiText.body(14)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _PickedBox(type: _me, hint: '나', dark: false),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('×', style: ChemiText.display(30)),
                            ),
                            _PickedBox(type: _you, hint: '상대', dark: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                children: [
                  Text('나는', style: ChemiText.display(18)),
                  const SizedBox(height: 8),
                  _TypeGrid(
                    selected: _me,
                    selectedColor: ChemiColors.pink,
                    selectedText: ChemiColors.ink,
                    onPick: (t) => setState(() => _me = t),
                  ),
                  if (_me != null) ...[
                    const SizedBox(height: 14),
                    _BestMatches(me: _me!, selected: _you, onPick: (t) => setState(() => _you = t)),
                  ],
                  const SizedBox(height: 18),
                  Text('상대는', style: ChemiText.display(18)),
                  const SizedBox(height: 8),
                  _TypeGrid(
                    selected: _you,
                    selectedColor: ChemiColors.ink,
                    selectedText: Colors.white,
                    onPick: (t) => setState(() => _you = t),
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
                child: ElevatedButton(
                  onPressed: _ready ? _showResult : null,
                  style: ElevatedButton.styleFrom(disabledBackgroundColor: const Color(0xFFD5D6DC)),
                  child: Text(
                    _ready ? '$_me × $_you 케미 보기' : '두 유형을 골라 주세요',
                    style: ChemiText.label(16, color: _ready ? Colors.white : const Color(0xFF3A3A44)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickedBox extends StatelessWidget {
  final String? type;
  final String hint;
  final bool dark;
  const _PickedBox({required this.type, required this.hint, required this.dark});

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : ChemiColors.ink;
    return Container(
      width: 116,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: dark ? ChemiColors.ink : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Text(
        type ?? hint,
        style: ChemiText.display(type == null ? 22 : 32, color: type == null ? fg.withValues(alpha: 0.5) : fg),
      ),
    );
  }
}

class _TypeGrid extends StatelessWidget {
  final String? selected;
  final Color selectedColor;
  final Color selectedText;
  final ValueChanged<String> onPick;

  const _TypeGrid({
    required this.selected,
    required this.selectedColor,
    required this.selectedText,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      padding: EdgeInsets.zero, // 기본값이면 상태 표시줄 높이만큼 위가 비어 버림
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      childAspectRatio: 1.75,
      children: [
        for (final t in mbtiTypes)
          Semantics(
            selected: t == selected,
            button: true,
            child: Material(
              color: t == selected ? selectedColor : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: t == selected ? ChemiColors.ink : Colors.white, width: 2),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onPick(t),
                child: Center(
                  child: Text(t, style: ChemiText.label(14, color: t == selected ? selectedText : ChemiColors.ink)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color background;
  final Color color;
  const _Pill({required this.text, required this.background, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
        child: Text(text, style: ChemiText.label(12, color: color)),
      );
}

/// "나는"을 고르면 바로: 나와 케미가 가장 높은 3유형. 누르면 상대로 선택된다.
class _BestMatches extends StatelessWidget {
  final String me;
  final String? selected;
  final ValueChanged<String> onPick;

  const _BestMatches({required this.me, required this.selected, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final top = bestMatches(me);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(color: ChemiColors.ink, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(TextSpan(children: [
            TextSpan(text: '$me ${mbtiProfiles[me]!.nick}', style: ChemiText.label(12, color: ChemiColors.mutedOnInk)),
            TextSpan(text: '\n나와 최고 케미 TOP 3', style: ChemiText.display(18, color: Colors.white)),
          ])),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final (i, m) in top.indexed) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: m.you == selected,
                    label: '${i + 1}위 ${m.you} ${m.youProfile.nick} ${m.score}점, 상대로 고르기',
                    excludeSemantics: true,
                    child: Material(
                      color: m.you == selected ? ChemiColors.pink : ChemiColors.inkSoft,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => onPick(m.you),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${i + 1}위', style: ChemiText.label(11, color: m.you == selected ? ChemiColors.ink : ChemiColors.mutedOnInk)),
                              Text(m.you, style: ChemiText.display(20, color: m.you == selected ? ChemiColors.ink : Colors.white)),
                              Text(m.youProfile.nick,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: ChemiText.label(11, color: m.you == selected ? ChemiColors.ink : ChemiColors.mutedOnInk)),
                              const SizedBox(height: 2),
                              Text('${m.score}점', style: ChemiText.label(13, color: m.you == selected ? ChemiColors.ink : ChemiColors.pink)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
