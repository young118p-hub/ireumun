// AI 결과를 기다리는 전체 화면 (내 이름 케미 약 1분, 아기 이름 약 30초)
// 버튼 안 작은 스피너만으로는 멈춘 줄 알고 나가 버려서(A-5) 무엇을 하는 중인지와 걸리는 시간을 보여 준다.
// 문구는 실제 단계 순서를 따르지만 서버 진행률을 받는 건 아니다 → 시간으로 넘기고 마지막 문구에서 멈춘다.

import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/chemi_theme.dart';
import 'beaker.dart';

class LabLoading extends StatefulWidget {
  final List<String> steps;
  final String eta; // "최대 1분 정도 걸려요"

  const LabLoading({super.key, required this.steps, required this.eta});

  static const nameChemiSteps = [
    '사주 여덟 글자를 펼치는 중',
    '이름 한자의 오행을 보는 중',
    '획수와 발음을 재는 중',
    '케미 점수를 계산하는 중',
    '결과 리포트를 쓰는 중',
  ];

  static const babyNameSteps = [
    '사주 여덟 글자를 펼치는 중',
    '부족한 기운을 찾는 중',
    '어울리는 한자를 고르는 중',
    '이름 후보를 섞어 보는 중',
    '결과 리포트를 쓰는 중',
  ];

  @override
  State<LabLoading> createState() => _LabLoadingState();
}

class _LabLoadingState extends State<LabLoading> with SingleTickerProviderStateMixin {
  late final AnimationController _wobble =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  Timer? _timer;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 9), (_) {
      if (_step < widget.steps.length - 1) setState(() => _step++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _wobble.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // 기다리는 중 뒤로 가기로 결과를 잃지 않게
      child: Material(
        color: ChemiColors.pink,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RotationTransition(
                  turns: Tween(begin: -0.02, end: 0.02).animate(_wobble),
                  child: const Beaker(width: 130, face: BeakerFace.happy),
                ),
                const SizedBox(height: 28),
                Semantics(
                  liveRegion: true,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      widget.steps[_step],
                      key: ValueKey(_step),
                      textAlign: TextAlign.center,
                      style: ChemiText.display(26),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < widget.steps.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _step ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i <= _step ? ChemiColors.ink : ChemiColors.ink.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(widget.eta, style: ChemiText.body(14)),
                Text('화면을 끄지 말고 기다려 주세요', style: ChemiText.body(13, color: ChemiColors.ink.withValues(alpha: 0.7))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
