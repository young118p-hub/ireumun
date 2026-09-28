// 스크롤하면 상태 표시줄(시계·배터리) 뒤에 바탕색을 깐다.
// 핑크 머리가 상태 표시줄까지 올라가는 화면에서, 내려 보면 본문 글씨가 시계와 겹쳐 보였음.

import 'package:flutter/material.dart';
import '../../core/theme/chemi_theme.dart';

class StatusScrim extends StatelessWidget {
  final ScrollController controller;
  const StatusScrim({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      height: top,
      child: IgnorePointer(
        child: ListenableBuilder(
          listenable: controller,
          builder: (_, _) {
            final scrolled = controller.hasClients && controller.offset > 0;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              color: scrolled ? ChemiColors.chrome : Colors.transparent,
            );
          },
        ),
      ),
    );
  }
}
