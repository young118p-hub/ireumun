// 생일 + 태어난 시간 (시간 모르면 -1)

import '../../core/constants/saju_constants.dart';

class BirthValue {
  final DateTime date;
  final int hour; // -1: 모름

  const BirthValue(this.date, this.hour);

  bool get hourKnown => hour >= 0;
  String get dateLabel => '${date.year}년 ${date.month}월 ${date.day}일';
  String get hourLabel => hourKnown ? '${SajuConstants.getJijiForHour(hour)}시' : '시간 모름';

  Map<String, dynamic> toJson() => {'y': date.year, 'm': date.month, 'd': date.day, 'h': hour};

  static BirthValue? fromJson(Object? j) {
    if (j is! Map) return null;
    final y = j['y'], m = j['m'], d = j['d'], h = j['h'];
    if (y is! int || m is! int || d is! int || h is! int) return null;
    if (y < 1920 || m < 1 || m > 12 || d < 1 || d > 31 || h < -1 || h > 23) return null;
    return BirthValue(DateTime(y, m, d), h);
  }
}
