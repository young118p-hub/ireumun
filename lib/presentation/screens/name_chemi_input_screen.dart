// 이름 케미 - 두 이름 넣기 (무료, 서버 없음)
// 입력하는 동안 글자마다 소리 오행을 바로 보여 준다. 둘 다 한글 2~4글자여야 버튼이 눌린다.
// 내 이름은 전에 넣은 걸 미리 채운다.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/chemi_theme.dart';
import '../../data/name_chemi/name_chemi.dart';
import '../providers/chemi_provider.dart';
import '../widgets/element_chip.dart';
import 'name_chemi_result_screen.dart';

class NameChemiInputScreen extends StatefulWidget {
  const NameChemiInputScreen({super.key});

  @override
  State<NameChemiInputScreen> createState() => _NameChemiInputScreenState();
}

class _NameChemiInputScreenState extends State<NameChemiInputScreen> {
  late final _me = TextEditingController(text: context.read<ChemiProvider>().myName ?? '');
  final _you = TextEditingController();

  @override
  void dispose() {
    _me.dispose();
    _you.dispose();
    super.dispose();
  }

  bool get _ready => isHangulName(_me.text.trim()) && isHangulName(_you.text.trim());

  void _go() {
    if (!_ready) return;
    FocusScope.of(context).unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NameChemiResultScreen(me: _me.text.trim(), you: _you.text.trim())),
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
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Container(
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
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                              decoration: BoxDecoration(color: ChemiColors.ink, borderRadius: BorderRadius.circular(999)),
                              child: Text('무료', style: ChemiText.label(12, color: Colors.white)),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('이름 케미', style: ChemiText.display(34)),
                              const SizedBox(height: 4),
                              Text('이름 소리에 담긴 오행으로 두 사람의 기운을 봐요', style: ChemiText.body(14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _NameField(label: '내 이름', controller: _me, onChanged: () => setState(() {})),
                        const SizedBox(height: 20),
                        _NameField(label: '상대 이름', controller: _you, onChanged: () => setState(() {}), onDone: _go),
                        const SizedBox(height: 16),
                        Text('성까지 한글로 넣어 주세요. 외자·두 글자 성도 돼요 (2~4글자).',
                            style: ChemiText.body(12, color: ChemiColors.muted)),
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
                child: ElevatedButton(
                  onPressed: _ready ? _go : null,
                  style: ElevatedButton.styleFrom(disabledBackgroundColor: const Color(0xFFD5D6DC)),
                  child: Text(
                    _ready ? '이름 케미 보기' : '두 이름을 넣어 주세요',
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

class _NameField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final VoidCallback? onDone;

  const _NameField({required this.label, required this.controller, required this.onChanged, this.onDone});

  @override
  Widget build(BuildContext context) {
    final text = controller.text.trim();
    // 완성된 글자만 오행 칩으로 (입력 중인 자모는 건너뜀)
    final syllables = [for (final c in text.characters) if (soundElement(c) != null) c];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: ChemiText.display(18)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: (_) => onChanged(),
          onSubmitted: (_) => onDone?.call(),
          textInputAction: onDone == null ? TextInputAction.next : TextInputAction.done,
          maxLength: 4,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[가-힣ㄱ-ㅎㅏ-ㅣ]'))],
          style: ChemiText.display(22),
          decoration: InputDecoration(
            hintText: '예: 김민서',
            hintStyle: ChemiText.body(18, color: ChemiColors.disabled),
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        if (syllables.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            children: [for (final c in syllables) SyllableChip(syllable: c, element: soundElement(c)!)],
          ),
        ],
      ],
    );
  }
}
