import 'package:flutter_test/flutter_test.dart';
import 'package:chemilab/core/text/keep_words.dart';

void main() {
  test('단어 안 글자 사이에만 보이지 않는 연결 문자, 띄어쓰기는 그대로', () {
    expect(keepWords('있어요 좋아'), '있⁠어⁠요 좋⁠아');
    expect(keepWords('있어요 좋아').replaceAll('⁠', ''), '있어요 좋아');
    expect(keepWords(''), '');
  });
}
