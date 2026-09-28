// 받침에 따라 조사 고르기 (민서와 / 지훈과, 쥐와 / 용과)

bool hasFinalConsonant(String word) {
  if (word.isEmpty) return false;
  final c = word.runes.last;
  return c >= 0xAC00 && c <= 0xD7A3 && (c - 0xAC00) % 28 != 0;
}

String waGwa(String word) => '$word${hasFinalConsonant(word) ? '과' : '와'}';
String iGa(String word) => '$word${hasFinalConsonant(word) ? '이' : '가'}';
String eunNeun(String word) => '$word${hasFinalConsonant(word) ? '은' : '는'}';
String eulReul(String word) => '$word${hasFinalConsonant(word) ? '을' : '를'}';
String ieyo(String word) => '$word${hasFinalConsonant(word) ? '이에요' : '예요'}';
