// 한국어 줄바꿈을 단어(띄어쓰기) 단위로.
// Flutter는 한글을 글자마다 끊어서 "있어/요."처럼 끝 글자만 다음 줄로 넘어간다.
// 단어 안 글자 사이에 WORD JOINER(U+2060, 보이지 않음)를 넣어 띄어쓰기에서만 끊기게 한다.
// 화면에 보여 줄 문장에만 쓴다 (저장·공유 텍스트에는 쓰지 않는다).

import 'package:flutter/widgets.dart';

String keepWords(String text) =>
    text.split(' ').map((w) => w.characters.join('⁠')).join(' ');
