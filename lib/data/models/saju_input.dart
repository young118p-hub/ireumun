// 사주 입력 데이터 모델
// 사용자가 입력하는 생년월일시 + 성별 + 성씨

class SajuInput {
  final int year;
  final int month;
  final int day;
  final int hour; // 0-23 (-1이면 시간 모름)
  final Gender gender;
  final String surname; // 성씨 (한글 1자)

  const SajuInput({
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    required this.gender,
    required this.surname,
  });

  bool get hasHour => hour >= 0;

  String get birthDateString =>
      '$year년 $month월 $day일${hasHour ? ' ${hour.toString().padLeft(2, '0')}시' : ' (시간 미상)'}';

  String get genderString => gender == Gender.male ? '남' : '여';

  Map<String, dynamic> toJson() => {
        'year': year,
        'month': month,
        'day': day,
        'hour': hour,
        'gender': genderString,
        'surname': surname,
      };

  @override
  String toString() =>
      '$surname / $birthDateString / ${genderString}아';
}

enum Gender { male, female }
