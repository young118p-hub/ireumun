// 생일 + 태어난 시간 입력 (우리 케미·가족 케미 공용)
// 시간은 12시진 격자. 모르면 "모름" (시주 없이 계산). 시진을 고르면 그 시간대 가운데 시각을 값으로 쓴다
// (기존 입력 화면과 같은 규칙: 자시 23시, 축시 2시 …).

import 'package:flutter/material.dart';
import '../../core/constants/saju_constants.dart';
import '../../core/theme/chemi_theme.dart';
import '../../data/models/birth_value.dart';

export '../../data/models/birth_value.dart';

class BirthInput extends StatelessWidget {
  final BirthValue value;
  final ValueChanged<BirthValue> onChanged;
  /// 시간을 "알고 있음"으로 켰지만 아직 시진을 안 골랐는지 (부모가 제출을 막는 데 씀)
  final bool hourPending;
  final ValueChanged<bool> onHourPendingChanged;

  const BirthInput({
    super.key,
    required this.value,
    required this.onChanged,
    required this.hourPending,
    required this.onHourPendingChanged,
  });

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value.date,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      locale: const Locale('ko', 'KR'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: ChemiColors.ink, onPrimary: Colors.white, surface: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) onChanged(BirthValue(picked, value.hour));
  }

  @override
  Widget build(BuildContext context) {
    final showGrid = value.hourKnown || hourPending;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _pickDate(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 20, color: ChemiColors.muted),
                  const SizedBox(width: 10),
                  Text(value.dateLabel, style: ChemiText.label(16)),
                  const Spacer(),
                  Text('양력', style: ChemiText.label(12, color: ChemiColors.muted)),
                  const Icon(Icons.chevron_right, color: ChemiColors.muted),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _Toggle(
                label: '시간 모름',
                selected: !showGrid,
                onTap: () {
                  onHourPendingChanged(false);
                  onChanged(BirthValue(value.date, -1));
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Toggle(label: '시간 알고 있음', selected: showGrid, onTap: () => onHourPendingChanged(!value.hourKnown)),
            ),
          ],
        ),
        if (showGrid) ...[
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1.7,
            children: [
              for (var i = 0; i < 12; i++) _hourCell(i),
            ],
          ),
          if (hourPending)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('태어난 시간대를 골라 주세요', style: ChemiText.label(12, color: ChemiColors.pinkDeep)),
            ),
        ],
      ],
    );
  }

  Widget _hourCell(int i) {
    final start = (i * 2 + 23) % 24;
    final hourValue = start == 23 ? 23 : start + 1;
    final jiji = SajuConstants.jiji[i];
    final selected = value.hourKnown && SajuConstants.getJijiForHour(value.hour) == jiji;
    return Semantics(
      button: true,
      selected: selected,
      label: '$jiji시, $start시부터 ${(start + 2) % 24}시',
      excludeSemantics: true,
      child: Material(
        color: selected ? ChemiColors.ink : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            onHourPendingChanged(false);
            onChanged(BirthValue(value.date, hourValue));
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$jiji시', style: ChemiText.label(13, color: selected ? Colors.white : ChemiColors.ink)),
              Text(
                '${start.toString().padLeft(2, '0')}~${((start + 2) % 24).toString().padLeft(2, '0')}',
                style: ChemiText.body(11, color: selected ? ChemiColors.mutedOnInk : ChemiColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Toggle({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        child: Material(
          color: selected ? ChemiColors.ink : Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: SizedBox(
              height: 46,
              child: Center(child: Text(label, style: ChemiText.label(14, color: selected ? Colors.white : ChemiColors.ink))),
            ),
          ),
        ),
      );
}
