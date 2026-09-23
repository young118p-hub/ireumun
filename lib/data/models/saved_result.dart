// 저장된 결과 모델
// Hive(기기)에 JSON 문자열로 저장. id는 서버 결과 ID와 같다.
// isPaid: 결제해서 본문이 열렸는지. 결제한 결과는 기기에 전체가 저장돼서 오프라인으로 다시 볼 수 있다.
// 결제 전 결과에는 서버가 보낸 미리보기(첫 이름, 점수·한 줄 요약)만 들어 있다.

import 'dart:convert';
import 'saju_input.dart';
import 'naming_result.dart';
import 'diagnosis_result.dart';

/// 결과 타입
enum SavedResultType { naming, diagnosis }

/// 중첩 Map까지 `Map<String, dynamic>`으로 맞춘다 (모델 fromJson들이 그 타입을 기대함)
Map<String, dynamic> _plainJson(Map<String, dynamic> m) =>
    jsonDecode(jsonEncode(m)) as Map<String, dynamic>;

class SavedResult {
  final String id;
  final SavedResultType type;
  final DateTime savedAt;
  final bool isPaid;
  final List<String> paidProducts;
  final bool isFreeTrial;

  /// 결제 전이라 아직 못 받은 이름 수 (작명: 잠긴 이름, 진단: 개선 이름)
  final int lockedCount;

  // 표시용 (입력 원본이 없는 복원 결과도 제목을 보여줄 수 있게)
  final String surname;
  final String birthLabel;

  // 작명 결과
  final FamilyNamingInput? familyInput;
  final SajuInput? simpleInput;
  final NamingResult? namingResult;

  // 진단 결과
  final DiagnosisInput? diagnosisInput;
  final DiagnosisResult? diagnosisResult;

  const SavedResult({
    required this.id,
    required this.type,
    required this.savedAt,
    this.isPaid = false,
    this.paidProducts = const [],
    this.isFreeTrial = false,
    this.lockedCount = 0,
    this.surname = '',
    this.birthLabel = '',
    this.familyInput,
    this.simpleInput,
    this.namingResult,
    this.diagnosisInput,
    this.diagnosisResult,
  });

  /// 진단 추가 개선 이름을 이미 받았는지
  bool get hasDiagnosisUpgrade => paidProducts.contains('diagnosis_upgrade');

  /// 서버 결과를 기기 저장용으로 바꾼다. 입력 원본(inputs)은 기기에만 있으므로 따로 받는다.
  factory SavedResult.fromRemote({
    required String id,
    required SavedResultType type,
    required DateTime createdAt,
    required bool unlocked,
    required List<String> paidProducts,
    required bool isFreeTrial,
    required int lockedCount,
    required Map<String, dynamic> input,
    required Map<String, dynamic> content,
    FamilyNamingInput? familyInput,
    SajuInput? simpleInput,
    DiagnosisInput? diagnosisInput,
  }) {
    final isNaming = type == SavedResultType.naming;
    final c = _plainJson(content);
    return SavedResult(
      id: id,
      type: type,
      savedAt: createdAt,
      isPaid: unlocked,
      paidProducts: paidProducts,
      isFreeTrial: isFreeTrial,
      lockedCount: lockedCount,
      surname: input['surname'] as String? ?? '',
      birthLabel: (input['babyBirth'] ?? input['birthInfo']) as String? ?? '',
      familyInput: familyInput,
      simpleInput: simpleInput,
      diagnosisInput: diagnosisInput,
      namingResult: isNaming ? NamingResult.fromJson(c) : null,
      diagnosisResult: isNaming ? null : DiagnosisResult.fromJson(c),
    );
  }

  /// 같은 결과의 새 서버 상태로 갱신 (기기에만 있는 입력 원본은 유지)
  SavedResult withRemote({
    required bool unlocked,
    required List<String> paidProducts,
    required int lockedCount,
    required Map<String, dynamic> content,
  }) {
    final isNaming = type == SavedResultType.naming;
    final c = _plainJson(content);
    return SavedResult(
      id: id,
      type: type,
      savedAt: savedAt,
      isPaid: unlocked,
      paidProducts: paidProducts,
      isFreeTrial: isFreeTrial,
      lockedCount: lockedCount,
      surname: surname,
      birthLabel: birthLabel,
      familyInput: familyInput,
      simpleInput: simpleInput,
      diagnosisInput: diagnosisInput,
      namingResult: isNaming ? NamingResult.fromJson(c) : null,
      diagnosisResult: isNaming ? null : DiagnosisResult.fromJson(c),
    );
  }

  /// 표시용 제목
  String get displayTitle {
    switch (type) {
      case SavedResultType.naming:
        final names = namingResult?.names ?? const [];
        final topName = names.isNotEmpty ? names.first.name : '';
        final others = names.length + lockedCount - 1;
        return others > 0 ? '$surname$topName 외 $others개' : '$surname$topName';
      case SavedResultType.diagnosis:
        if (diagnosisInput != null) return diagnosisInput!.fullName;
        final name = diagnosisResult?.diagnosis.currentName ?? '';
        return name.isEmpty ? '이름 진단' : '$surname$name';
    }
  }

  /// 표시용 부제
  String get displaySubtitle {
    switch (type) {
      case SavedResultType.naming:
        return familyInput?.baby.birthDateString ??
            simpleInput?.birthDateString ??
            birthLabel;
      case SavedResultType.diagnosis:
        return diagnosisInput?.person.birthDateString ?? birthLabel;
    }
  }

  /// JSON 직렬화
  String toJsonString() {
    final map = <String, dynamic>{
      'id': id,
      'type': type.name,
      'savedAt': savedAt.toIso8601String(),
      'isPaid': isPaid,
      'paidProducts': paidProducts,
      'isFreeTrial': isFreeTrial,
      'lockedCount': lockedCount,
      'surname': surname,
      'birthLabel': birthLabel,
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
    final familyInput = map['familyInput'] != null
        ? FamilyNamingInput.fromJson(map['familyInput'])
        : null;
    final simpleInput =
        map['simpleInput'] != null ? SajuInput.fromJson(map['simpleInput']) : null;
    final diagnosisInput = map['diagnosisInput'] != null
        ? DiagnosisInput.fromJson(map['diagnosisInput'])
        : null;

    return SavedResult(
      id: map['id'] as String,
      type: SavedResultType.values.byName(map['type'] as String),
      savedAt: DateTime.parse(map['savedAt'] as String),
      isPaid: map['isPaid'] as bool? ?? false,
      paidProducts:
          (map['paidProducts'] as List? ?? []).map((e) => e as String).toList(),
      isFreeTrial: map['isFreeTrial'] as bool? ?? false,
      lockedCount: (map['lockedCount'] as num?)?.toInt() ?? 0,
      surname: map['surname'] as String? ??
          familyInput?.baby.surname ??
          simpleInput?.surname ??
          diagnosisInput?.person.surname ??
          '',
      birthLabel: map['birthLabel'] as String? ?? '',
      familyInput: familyInput,
      simpleInput: simpleInput,
      namingResult: map['namingResult'] != null
          ? NamingResult.fromJson(map['namingResult'])
          : null,
      diagnosisInput: diagnosisInput,
      diagnosisResult: map['diagnosisResult'] != null
          ? DiagnosisResult.fromJson(map['diagnosisResult'])
          : null,
    );
  }
}
