import 'package:flutter_test/flutter_test.dart';
import 'package:chemilab/data/models/diagnosis_result.dart';

void main() {
  test('한자 칸: AI가 붙인 설명은 버리고 맨 앞 한자만 (최대 3자)', () {
    expect(onlyHanja("旻 (하늘 민) — 한자 미입력으로 AI 추정: 吉字 선택"), '旻');
    expect(onlyHanja('敏秀'), '敏秀');
    expect(onlyHanja('추정: 敏'), '');
    expect(onlyHanja(''), '');
  });
}
