// 가족 케미 - 가족 3~5명 생일 넣기
// 처음엔 나·엄마·아빠 세 칸 (나는 전에 넣은 정보로 미리 채움). 역할은 눌러서 바꾸고, 가족은 5명까지 더한다.
// 이름을 비우면 역할 이름(엄마, 아빠…)으로 부르고, 같은 이름이 겹치면 뒤에 숫자를 붙인다 (엄마, 엄마2).
// 두 사람만 보려면 우리 케미로 안내한다.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/chemi_theme.dart';
import '../../data/family_chemi/family_chemi.dart';
import '../../data/family_chemi/family_chemi_history.dart';
import '../../data/models/birth_value.dart';
import '../providers/chemi_provider.dart';
import '../widgets/birth_input.dart';
import '../widgets/status_scrim.dart';
import 'family_chemi_result_screen.dart';
import 'pair_chemi_input_screen.dart';

class FamilyChemiInputScreen extends StatefulWidget {
  const FamilyChemiInputScreen({super.key});

  static const minMembers = 3;
  static const maxMembers = 5;

  @override
  State<FamilyChemiInputScreen> createState() => _FamilyChemiInputScreenState();
}

class _Slot {
  FamilyRole role;
  final TextEditingController name;
  BirthValue birth;
  bool hourPending = false;
  _Slot(this.role, this.birth, [String name = '']) : name = TextEditingController(text: name);
}

/// 이름을 비웠을 때 부를 이름
String defaultFamilyName(FamilyRole r) => switch (r) {
  FamilyRole.sibling => '형제',
  _ => r.label,
};

class _FamilyChemiInputScreenState extends State<FamilyChemiInputScreen> {
  final _scroll = ScrollController();
  late final List<_Slot> _slots = () {
    final me = context.read<ChemiProvider>().myProfile;
    return [
      _Slot(FamilyRole.me, me?.birth ?? BirthValue(DateTime(2000, 1, 1), -1), me?.name == '나' ? '' : me?.name ?? ''),
      _Slot(FamilyRole.mom, BirthValue(DateTime(1972, 1, 1), -1)),
      _Slot(FamilyRole.dad, BirthValue(DateTime(1970, 1, 1), -1)),
    ];
  }();

  @override
  void dispose() {
    _scroll.dispose();
    for (final s in _slots) {
      s.name.dispose();
    }
    super.dispose();
  }

  bool get _ready => _slots.every((s) => !s.hourPending);

  void _add() {
    if (_slots.length >= FamilyChemiInputScreen.maxMembers) return;
    setState(() => _slots.add(_Slot(FamilyRole.sibling, BirthValue(DateTime(2005, 1, 1), -1))));
  }

  void _remove(int i) {
    if (_slots.length <= FamilyChemiInputScreen.minMembers) return;
    setState(() => _slots.removeAt(i).name.dispose());
  }

  /// 부르는 이름: 비우면 역할 이름, 겹치면 숫자
  List<FamilyInput> _inputs() {
    final used = <String, int>{};
    return [
      for (final s in _slots)
        () {
          final base = s.name.text.trim().isEmpty ? defaultFamilyName(s.role) : s.name.text.trim();
          final n = used.update(base, (v) => v + 1, ifAbsent: () => 1);
          final name = n == 1 ? base : '${base.length > 5 ? base.substring(0, 5) : base}$n';
          return FamilyInput(s.role, name, s.birth);
        }(),
    ];
  }

  void _go() {
    if (!_ready) return;
    FocusScope.of(context).unfocus();
    Navigator.push(context, MaterialPageRoute(builder: (_) => FamilyChemiResultScreen(members: _inputs())));
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
                                  Text('가족 케미', style: ChemiText.display(34)),
                                  const SizedBox(height: 4),
                                  Text('3~5명 가족의 사주로 보는 우리 집 케미', style: ChemiText.body(14)),
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
                            for (final (i, s) in _slots.indexed) ...[
                              if (i > 0) const SizedBox(height: 24),
                              _MemberSection(
                                key: ObjectKey(s),
                                slot: s,
                                index: i,
                                removable: _slots.length > FamilyChemiInputScreen.minMembers,
                                onRemove: () => _remove(i),
                                onChanged: () => setState(() {}),
                              ),
                            ],
                            const SizedBox(height: 20),
                            if (_slots.length < FamilyChemiInputScreen.maxMembers)
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: OutlinedButton.icon(
                                  onPressed: _add,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: ChemiColors.ink,
                                    side: const BorderSide(color: ChemiColors.ink, width: 1.5),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                  ),
                                  icon: const Icon(Icons.add, size: 20),
                                  label: Text(
                                    '가족 더하기 (${_slots.length}/${FamilyChemiInputScreen.maxMembers})',
                                    style: ChemiText.label(15),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 14),
                            Text(
                              '태어난 시간까지 넣으면 더 정확해요. 모르면 "시간 모름"으로 두세요.',
                              style: ChemiText.body(12, color: ChemiColors.muted),
                            ),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const PairChemiInputScreen()),
                              ),
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '두 사람만 보려면 ',
                                      style: ChemiText.body(12, color: ChemiColors.muted),
                                    ),
                                    TextSpan(
                                      text: '우리 케미로 →',
                                      style: ChemiText.label(12, color: ChemiColors.pinkDeep),
                                    ),
                                  ],
                                ),
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
                child: ElevatedButton(
                  onPressed: _ready ? _go : null,
                  style: ElevatedButton.styleFrom(disabledBackgroundColor: const Color(0xFFD5D6DC)),
                  child: Text(
                    _ready ? '가족 케미 보기' : '태어난 시간대를 골라 주세요',
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

class _MemberSection extends StatelessWidget {
  final _Slot slot;
  final int index;
  final bool removable;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _MemberSection({
    super.key,
    required this.slot,
    required this.index,
    required this.removable,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text('${index + 1}', style: ChemiText.display(20, color: ChemiColors.pinkDeep)),
          const SizedBox(width: 8),
          PopupMenuButton<FamilyRole>(
            color: Colors.white,
            tooltip: '역할 바꾸기',
            initialValue: slot.role,
            onSelected: (r) {
              slot.role = r;
              onChanged();
            },
            itemBuilder: (_) => [
              for (final r in FamilyRole.values)
                PopupMenuItem(
                  value: r,
                  child: Text(r.label, style: ChemiText.label(15)),
                ),
            ],
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
              decoration: BoxDecoration(color: ChemiColors.ink, borderRadius: BorderRadius.circular(999)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(slot.role.label, style: ChemiText.display(17, color: Colors.white)),
                  const Icon(Icons.expand_more, size: 20, color: Colors.white),
                ],
              ),
            ),
          ),
          const Spacer(),
          if (removable)
            IconButton(
              tooltip: '빼기',
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 22, color: ChemiColors.muted),
            ),
        ],
      ),
      const SizedBox(height: 8),
      TextField(
        controller: slot.name,
        maxLength: 6,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[가-힣ㄱ-ㅎㅏ-ㅣ]'))],
        style: ChemiText.label(16),
        decoration: InputDecoration(
          hintText: '부르는 이름 (비우면 "${defaultFamilyName(slot.role)}")',
          hintStyle: ChemiText.body(15, color: ChemiColors.disabled),
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
      const SizedBox(height: 8),
      BirthInput(
        value: slot.birth,
        onChanged: (b) {
          slot.birth = b;
          onChanged();
        },
        hourPending: slot.hourPending,
        onHourPendingChanged: (v) {
          slot.hourPending = v;
          onChanged();
        },
      ),
    ],
  );
}
