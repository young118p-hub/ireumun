// AI 작명 결과 모델
// 사주 분석 + 추천 이름 목록

class NamingResult {
  final SajuAnalysis saju;
  final List<NameSuggestion> names;

  const NamingResult({
    required this.saju,
    required this.names,
  });

  factory NamingResult.fromJson(Map<String, dynamic> json) {
    return NamingResult(
      saju: SajuAnalysis.fromJson(json['saju'] as Map<String, dynamic>),
      names: (json['names'] as List)
          .map((e) => NameSuggestion.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'saju': saju.toJson(),
        'names': names.map((e) => e.toJson()).toList(),
      };
}

/// 사주 분석 결과
class SajuAnalysis {
  final String yearPillar; // 년주 (예: "갑자")
  final String monthPillar; // 월주
  final String dayPillar; // 일주
  final String hourPillar; // 시주 (없으면 "미상")
  final String dayMaster; // 일간 (일주의 천간)
  final Map<String, int> ohengBalance; // 오행 분포 (목:2, 화:1, ...)
  final String weakElement; // 부족한 오행
  final String strongElement; // 강한 오행
  final String summary; // 사주 종합 설명

  const SajuAnalysis({
    required this.yearPillar,
    required this.monthPillar,
    required this.dayPillar,
    required this.hourPillar,
    required this.dayMaster,
    required this.ohengBalance,
    required this.weakElement,
    required this.strongElement,
    required this.summary,
  });

  factory SajuAnalysis.fromJson(Map<String, dynamic> json) {
    final balanceRaw = json['ohengBalance'] as Map<String, dynamic>? ?? {};
    final balance = balanceRaw.map(
      (key, value) => MapEntry(key, (value as num).toInt()),
    );

    return SajuAnalysis(
      yearPillar: json['yearPillar'] as String? ?? '',
      monthPillar: json['monthPillar'] as String? ?? '',
      dayPillar: json['dayPillar'] as String? ?? '',
      hourPillar: json['hourPillar'] as String? ?? '미상',
      dayMaster: json['dayMaster'] as String? ?? '',
      ohengBalance: balance,
      weakElement: json['weakElement'] as String? ?? '',
      strongElement: json['strongElement'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'yearPillar': yearPillar,
        'monthPillar': monthPillar,
        'dayPillar': dayPillar,
        'hourPillar': hourPillar,
        'dayMaster': dayMaster,
        'ohengBalance': ohengBalance,
        'weakElement': weakElement,
        'strongElement': strongElement,
        'summary': summary,
      };

  /// 사주 네 기둥 표시 문자열
  String get fourPillarsDisplay =>
      '$yearPillar / $monthPillar / $dayPillar / $hourPillar';
}

/// 추천 이름 하나
class NameSuggestion {
  final String name; // 한글 이름 (2글자)
  final String hanja; // 한자 이름
  final String reading; // 한자 음독 (예: "民 백성 민, 俊 준걸 준")
  final String meaning; // 이름 뜻 풀이
  final String ohengMatch; // 오행 보완 설명
  final int score; // 추천 점수 (1-100)
  final String pronunciation; // 성+이름 발음 자연스러움 평가

  const NameSuggestion({
    required this.name,
    required this.hanja,
    required this.reading,
    required this.meaning,
    required this.ohengMatch,
    required this.score,
    required this.pronunciation,
  });

  factory NameSuggestion.fromJson(Map<String, dynamic> json) {
    return NameSuggestion(
      name: json['name'] as String? ?? '',
      hanja: json['hanja'] as String? ?? '',
      reading: json['reading'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
      ohengMatch: json['ohengMatch'] as String? ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
      pronunciation: json['pronunciation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'hanja': hanja,
        'reading': reading,
        'meaning': meaning,
        'ohengMatch': ohengMatch,
        'score': score,
        'pronunciation': pronunciation,
      };
}
