// 저장된 결과 모델
// Hive를 이용한 로컬 저장용
// isPaid: 결제 완료 여부 (미결제 시 1개만 공개)

import 'dart:convert';
import 'saju_input.dart';
import 'naming_result.dart';
import 'diagnosis_result.dart';

/// 결과 타입
enum SavedResultType { naming, diagnosis }

/// 저장된 결과 (Hive에 JSON 문자열로 저장)
class SavedResult {
  final String id;
  final SavedResultType type;
  final DateTime savedAt;
  final bool isPaid; // 결제 완료 여부

  // 작명 결과
  final FamilyNamingInput? familyInput;
  final SajuInput? simpleInput; // 무료 체험용 단일 입력
  final NamingResult? namingResult;

  // 진단 결과
  final DiagnosisInput? diagnosisInput;
  final DiagnosisResult? diagnosisResult;

  const SavedResult({
    required this.id,
    required this.type,
    required this.savedAt,
    this.isPaid = false,
    this.familyInput,
    this.simpleInput,
    this.namingResult,
    this.diagnosisInput,
    this.diagnosisResult,
  });

  /// 결제 완료로 변환
  SavedResult copyWithPaid() {
    return SavedResult(
      id: id,
      type: type,
      savedAt: savedAt,
      isPaid: true,
      familyInput: familyInput,
      simpleInput: simpleInput,
      namingResult: namingResult,
      diagnosisInput: diagnosisInput,
      diagnosisResult: diagnosisResult,
    );
  }

  /// 표시용 제목
  String get displayTitle {
    switch (type) {
      case SavedResultType.naming:
        final surname = familyInput?.baby.surname ?? simpleInput?.surname ?? '';
        final topName = namingResult?.names.isNotEmpty == true
            ? namingResult!.names.first.name
            : '';
        return '$surname$topName 외 ${(namingResult?.names.length ?? 1) - 1}개';
      case SavedResultType.diagnosis:
        return diagnosisInput?.fullName ?? '이름 진단';
    }
  }

  /// 표시용 부제
  String get displaySubtitle {
    switch (type) {
      case SavedResultType.naming:
        return familyInput?.baby.birthDateString ??
            simpleInput?.birthDateString ?? '';
      case SavedResultType.diagnosis:
        return diagnosisInput?.person.birthDateString ?? '';
    }
  }

  /// JSON 직렬화
  String toJsonString() {
    final map = <String, dynamic>{
      'id': id,
      'type': type.name,
      'savedAt': savedAt.toIso8601String(),
      'isPaid': isPaid,
    };

    if (familyInput != null) map['familyInput'] = familyInput!.toJson();
    if (simpleInput != null) map['simpleInput'] = simpleInput!.toJson();
    if (namingResult != null) map['namingResult'] = namingResult!.toJson();
    if (diagnosisInput != null) {
      map['diagnosisInput'] = diagnosisInput!.toJson();
    }
    if (diagnosisResult != null) {
      map['diagnosisResult'] = diagnosisResult!.toJson();
    }

    return jsonEncode(map);
  }

  /// JSON 역직렬화
  factory SavedResult.fromJsonString(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;

    return SavedResult(
      id: map['id'] as String,
      type: SavedResultType.values.byName(map['type'] as String),
      savedAt: DateTime.parse(map['savedAt'] as String),
      isPaid: map['isPaid'] as bool? ?? false,
      familyInput: map['familyInput'] != null
          ? FamilyNamingInput.fromJson(map['familyInput'])
          : null,
      simpleInput: map['simpleInput'] != null
          ? SajuInput.fromJson(map['simpleInput'])
          : null,
      namingResult: map['namingResult'] != null
          ? NamingResult.fromJson(map['namingResult'])
          : null,
      diagnosisInput: map['diagnosisInput'] != null
          ? DiagnosisInput.fromJson(map['diagnosisInput'])
          : null,
      diagnosisResult: map['diagnosisResult'] != null
          ? DiagnosisResult.fromJson(map['diagnosisResult'])
          : null,
    );
  }
}
