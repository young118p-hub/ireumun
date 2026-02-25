// 이름 진단 결과 모델
// 현재 이름의 사주 적합도 분석 + 개선 이름 추천

import 'naming_result.dart';

class DiagnosisResult {
  final SajuAnalysis saju;
  final NameDiagnosis diagnosis;
  final List<NameSuggestion> improvementNames; // 개선 이름 3개

  const DiagnosisResult({
    required this.saju,
    required this.diagnosis,
    required this.improvementNames,
  });

  factory DiagnosisResult.fromJson(Map<String, dynamic> json) {
    return DiagnosisResult(
      saju: SajuAnalysis.fromJson(json['saju'] as Map<String, dynamic>),
      diagnosis:
          NameDiagnosis.fromJson(json['diagnosis'] as Map<String, dynamic>),
      improvementNames: (json['improvementNames'] as List? ?? [])
          .map((e) => NameSuggestion.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'saju': saju.toJson(),
        'diagnosis': diagnosis.toJson(),
        'improvementNames':
            improvementNames.map((e) => e.toJson()).toList(),
      };
}

/// 현재 이름 진단 상세
class NameDiagnosis {
  final String currentName; // 현재 이름 (성 제외)
  final String currentHanja; // 현재 이름 한자 (AI 추정 포함)
  final int overallScore; // 종합 점수 (1-100)
  final String summaryOneLine; // 1줄 요약 (무료 공개)
  final OhengCompatibility ohengCompat; // 오행 적합도
  final String strokeAnalysis; // 획수 분석
  final String pronunciationAnalysis; // 발음 분석
  final String detailAnalysis; // 상세 분석 (결제 후 공개)
  final List<String> problems; // 문제점 목록
  final List<String> strengths; // 장점 목록

  const NameDiagnosis({
    required this.currentName,
    required this.currentHanja,
    required this.overallScore,
    required this.summaryOneLine,
    required this.ohengCompat,
    required this.strokeAnalysis,
    required this.pronunciationAnalysis,
    required this.detailAnalysis,
    required this.problems,
    required this.strengths,
  });

  factory NameDiagnosis.fromJson(Map<String, dynamic> json) {
    return NameDiagnosis(
      currentName: json['currentName'] as String? ?? '',
      currentHanja: json['currentHanja'] as String? ?? '',
      overallScore: (json['overallScore'] as num?)?.toInt() ?? 0,
      summaryOneLine: json['summaryOneLine'] as String? ?? '',
      ohengCompat: OhengCompatibility.fromJson(
        json['ohengCompat'] as Map<String, dynamic>? ?? {},
      ),
      strokeAnalysis: json['strokeAnalysis'] as String? ?? '',
      pronunciationAnalysis: json['pronunciationAnalysis'] as String? ?? '',
      detailAnalysis: json['detailAnalysis'] as String? ?? '',
      problems: (json['problems'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      strengths: (json['strengths'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'currentName': currentName,
        'currentHanja': currentHanja,
        'overallScore': overallScore,
        'summaryOneLine': summaryOneLine,
        'ohengCompat': ohengCompat.toJson(),
        'strokeAnalysis': strokeAnalysis,
        'pronunciationAnalysis': pronunciationAnalysis,
        'detailAnalysis': detailAnalysis,
        'problems': problems,
        'strengths': strengths,
      };
}

/// 오행 적합도
class OhengCompatibility {
  final Map<String, int> nameOheng; // 이름 글자별 오행 분포
  final Map<String, int> sajuOheng; // 사주 오행 분포
  final String matchDescription; // 적합도 설명
  final int matchScore; // 오행 적합 점수 (1-100)

  const OhengCompatibility({
    required this.nameOheng,
    required this.sajuOheng,
    required this.matchDescription,
    required this.matchScore,
  });

  factory OhengCompatibility.fromJson(Map<String, dynamic> json) {
    return OhengCompatibility(
      nameOheng: (json['nameOheng'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, (v as num).toInt())),
      sajuOheng: (json['sajuOheng'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, (v as num).toInt())),
      matchDescription: json['matchDescription'] as String? ?? '',
      matchScore: (json['matchScore'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'nameOheng': nameOheng,
        'sajuOheng': sajuOheng,
        'matchDescription': matchDescription,
        'matchScore': matchScore,
      };
}
