// AI 작명 결과 모델
// 가족 사주 분석 + 추천 이름 목록

class NamingResult {
  final SajuAnalysis babySaju;
  final SajuAnalysis? fatherSaju;
  final SajuAnalysis? motherSaju;
  final FamilyOhengAnalysis? familyAnalysis;
  final List<NameSuggestion> names;

  const NamingResult({
    required this.babySaju,
    this.fatherSaju,
    this.motherSaju,
    this.familyAnalysis,
    required this.names,
  });

  /// 기존 호환용 (단일 사주)
  SajuAnalysis get saju => babySaju;

  factory NamingResult.fromJson(Map<String, dynamic> json) {
    return NamingResult(
      babySaju: SajuAnalysis.fromJson(
        json['babySaju'] as Map<String, dynamic>? ??
            json['saju'] as Map<String, dynamic>,
      ),
      fatherSaju: json['fatherSaju'] != null
          ? SajuAnalysis.fromJson(json['fatherSaju'])
          : null,
      motherSaju: json['motherSaju'] != null
          ? SajuAnalysis.fromJson(json['motherSaju'])
          : null,
      familyAnalysis: json['familyAnalysis'] != null
          ? FamilyOhengAnalysis.fromJson(json['familyAnalysis'])
          : null,
      names: (json['names'] as List)
          .map((e) => NameSuggestion.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'babySaju': babySaju.toJson(),
        if (fatherSaju != null) 'fatherSaju': fatherSaju!.toJson(),
        if (motherSaju != null) 'motherSaju': motherSaju!.toJson(),
        if (familyAnalysis != null)
          'familyAnalysis': familyAnalysis!.toJson(),
        'names': names.map((e) => e.toJson()).toList(),
      };
}

/// 사주 분석 결과
class SajuAnalysis {
  final String yearPillar;
  final String monthPillar;
  final String dayPillar;
  final String hourPillar;
  final String dayMaster;
  final Map<String, int> ohengBalance;
  final String weakElement;
  final String strongElement;
  final String summary;

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

  String get fourPillarsDisplay =>
      '$yearPillar / $monthPillar / $dayPillar / $hourPillar';
}

/// 가족 오행 균형 분석
class FamilyOhengAnalysis {
  final Map<String, int> combinedBalance; // 가족 전체 오행 합산
  final String familyWeakElement; // 가족 전체 부족 오행
  final String familyStrongElement; // 가족 전체 과잉 오행
  final String recommendation; // AI 추천 코멘트

  const FamilyOhengAnalysis({
    required this.combinedBalance,
    required this.familyWeakElement,
    required this.familyStrongElement,
    required this.recommendation,
  });

  factory FamilyOhengAnalysis.fromJson(Map<String, dynamic> json) {
    final balanceRaw =
        json['combinedBalance'] as Map<String, dynamic>? ?? {};
    return FamilyOhengAnalysis(
      combinedBalance:
          balanceRaw.map((k, v) => MapEntry(k, (v as num).toInt())),
      familyWeakElement: json['familyWeakElement'] as String? ?? '',
      familyStrongElement: json['familyStrongElement'] as String? ?? '',
      recommendation: json['recommendation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'combinedBalance': combinedBalance,
        'familyWeakElement': familyWeakElement,
        'familyStrongElement': familyStrongElement,
        'recommendation': recommendation,
      };
}

/// 추천 이름 하나
class NameSuggestion {
  final String name;
  final String hanja;
  final String reading;
  final String meaning;
  final String ohengMatch;
  final int score;
  final String pronunciation;

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
