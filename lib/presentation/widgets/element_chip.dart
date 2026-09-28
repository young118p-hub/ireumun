// 이름 글자 하나와 그 소리 오행 (예: 민 / 水 수)

import 'package:flutter/material.dart';
import '../../core/theme/chemi_theme.dart';

class SyllableChip extends StatelessWidget {
  final String syllable;
  final String element;
  final double size;
  const SyllableChip({super.key, required this.syllable, required this.element, this.size = 52});

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$syllable, $element',
        excludeSemantics: true,
        child: Container(
          width: size,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border(bottom: BorderSide(color: elementColors[element]!, width: 5)),
          ),
          child: Column(
            children: [
              Text(syllable, style: ChemiText.display(size * 0.42)),
              Text('${elementHanja[element]} $element', style: ChemiText.label(11, color: ChemiColors.muted)),
            ],
          ),
        ),
      );
}
