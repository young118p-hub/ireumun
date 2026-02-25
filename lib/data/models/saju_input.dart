// 사주 입력 데이터 모델
// 개인 생년월일시 + 가족 작명 입력 + 이름 진단 입력

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

  factory SajuInput.fromJson(Map<String, dynamic> json) {
    return SajuInput(
      year: json['year'] as int,
      month: json['month'] as int,
      day: json['day'] as int,
      hour: json['hour'] as int,
      gender: json['gender'] == '남' ? Gender.male : Gender.female,
      surname: json['surname'] as String,
    );
  }

  @override
  String toString() => '$surname / $birthDateString / $genderString아';
}

enum Gender { male, female }

/// 가족 작명 입력 (아기 + 아빠 + 엄마)
class FamilyNamingInput {
  final SajuInput baby;
  final SajuInput father;
  final SajuInput mother;

  const FamilyNamingInput({
    required this.baby,
    required this.father,
    required this.mother,
  });

  Map<String, dynamic> toJson() => {
        'baby': baby.toJson(),
        'father': father.toJson(),
        'mother': mother.toJson(),
      };

  factory FamilyNamingInput.fromJson(Map<String, dynamic> json) {
    return FamilyNamingInput(
      baby: SajuInput.fromJson(json['baby']),
      father: SajuInput.fromJson(json['father']),
      mother: SajuInput.fromJson(json['mother']),
    );
  }
}

/// 이름 진단 입력
class DiagnosisInput {
  final String currentName; // 현재 이름 (한글 2~3글자, 성씨 제외)
  final String currentHanja; // 현재 이름 한자 (선택)
  final SajuInput person;

  const DiagnosisInput({
    required this.currentName,
    this.currentHanja = '',
    required this.person,
  });

  /// 성+이름 전체
  String get fullName => '${person.surname}$currentName';

  Map<String, dynamic> toJson() => {
        'currentName': currentName,
        'currentHanja': currentHanja,
        'person': person.toJson(),
      };

  factory DiagnosisInput.fromJson(Map<String, dynamic> json) {
    return DiagnosisInput(
      currentName: json['currentName'] as String,
      currentHanja: json['currentHanja'] as String? ?? '',
      person: SajuInput.fromJson(json['person']),
    );
  }
}
