// 우리 케미 - 두 사람 생일 넣기
// 관계(연인·친구·동료)는 해설 말투만 바꾼다. 이름은 부르는 이름(비우면 "나"/"상대").
// 시간은 알면 넣기(시주 궁합까지), 모르면 "시간 모름". "알고 있음"인데 시진을 안 고르면 버튼이 막힌다.
// 내 정보는 전에 넣은 걸 미리 채운다.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/chemi_theme.dart';
import '../../data/pair_chemi/pair_chemi.dart';
import '../../data/pair_chemi/pair_chemi_history.dart';
import '../providers/chemi_provider.dart';
import '../widgets/birth_input.dart';
import '../widgets/status_scrim.dart';
import 'pair_chemi_result_screen.dart';

class PairChemiInputScreen extends StatefulWidget {
  const PairChemiInputScreen({super.key});

  @override
  State<PairChemiInputScreen> createState() => _PairChemiInputScreenState();
}

class _PairChemiInputScreenState extends State<PairChemiInputScreen> {
  final _scroll = ScrollController();
  PairRelation _relation = PairRelation.lover;
  late final PairInput? _saved = context.read<ChemiProvider>().myProfile;
  late final _meName = TextEditingController(text: _saved?.name == '나' ? '' : _saved?.name ?? '');
  final _youName = TextEditingController();
  late BirthValue _meBirth = _saved?.birth ?? BirthValue(DateTime(2000, 1, 1), -1);
  BirthValue _youBirth = BirthValue(DateTime(2000, 1, 1), -1);
  bool _meHourPending = false;
  bool _youHourPending = false;

  @override
  void dispose() {
    _scroll.dispose();
    _meName.dispose();
    _youName.dispose();
    super.dispose();
  }

  bool get _ready => !_meHourPending && !_youHourPending;

  String _nameOr(TextEditingController c, String fallback) => c.text.trim().isEmpty ? fallback : c.text.trim();

  void _go() {
    if (!_ready) return;
    FocusScope.of(context).unfocus();
    final me = PairInput(_nameOr(_meName, '나'), _meBirth);
    final you = PairInput(_nameOr(_youName, '상대'), _youBirth);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PairChemiResultScreen(me: me, you: you, relation: _relation),
      ),
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
              child: Stack(
                children: [
                  ListView(
                    controller: _scroll,
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
                            IconButton(
                              tooltip: '뒤로',
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_ios_new, size: 22, color: ChemiColors.ink),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('우리 케미', style: ChemiText.display(34)),
                                  const SizedBox(height: 4),
                                  Text('두 사람의 사주로 보는 진짜 케미', style: ChemiText.body(14)),
                                  Text('점수와 해설은 무료, 전체 리포트만 유료예요', style: ChemiText.label(12)),
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
                            Text('어떤 사이예요?', style: ChemiText.display(18)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                for (final (i, r) in PairRelation.pickable.indexed) ...[
                                  if (i > 0) const SizedBox(width: 8),
                                  Expanded(
                                    child: Semantics(
                                      button: true,
                                      selected: r == _relation,
                                      child: Material(
                                        color: r == _relation ? ChemiColors.pink : Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(14),
                                          onTap: () => setState(() => _relation = r),
                                          child: SizedBox(
                                            height: 46,
                                            child: Center(child: Text(r.label, style: ChemiText.label(15))),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 24),
                            _PersonSection(
                              title: '나',
                              nameHint: '부르는 이름 (비우면 "나")',
                              name: _meName,
                              birth: _meBirth,
                              hourPending: _meHourPending,
                              onBirth: (b) => setState(() => _meBirth = b),
                              onHourPending: (v) => setState(() => _meHourPending = v),
                            ),
                            const SizedBox(height: 28),
                            _PersonSection(
                              title: '상대',
                              nameHint: '부르는 이름 (비우면 "상대")',
                              name: _youName,
                              birth: _youBirth,
                              hourPending: _youHourPending,
                              onBirth: (b) => setState(() => _youBirth = b),
                              onHourPending: (v) => setState(() => _youHourPending = v),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              '태어난 시간까지 넣으면 시주 궁합까지 봐서 더 정확해요.',
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
                child: ElevatedButton(
                  onPressed: _ready ? _go : null,
                  style: ElevatedButton.styleFrom(disabledBackgroundColor: const Color(0xFFD5D6DC)),
                  child: Text(
                    _ready ? '우리 케미 보기' : '태어난 시간대를 골라 주세요',
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

class _PersonSection extends StatelessWidget {
  final String title;
  final String nameHint;
  final TextEditingController name;
  final BirthValue birth;
  final bool hourPending;
  final ValueChanged<BirthValue> onBirth;
  final ValueChanged<bool> onHourPending;

  const _PersonSection({
    required this.title,
    required this.nameHint,
    required this.name,
    required this.birth,
    required this.hourPending,
    required this.onBirth,
    required this.onHourPending,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: ChemiText.display(20)),
      const SizedBox(height: 8),
      TextField(
        controller: name,
        maxLength: 6,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[가-힣ㄱ-ㅎㅏ-ㅣ]'))],
        style: ChemiText.label(16),
        decoration: InputDecoration(
          hintText: nameHint,
          hintStyle: ChemiText.body(15, color: ChemiColors.disabled),
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
      const SizedBox(height: 8),
      BirthInput(value: birth, onChanged: onBirth, hourPending: hourPending, onHourPendingChanged: onHourPending),
    ],
  );
}
