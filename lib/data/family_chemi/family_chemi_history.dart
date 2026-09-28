// 가족 케미 기록 (기기에만). 결과는 생일로 다시 계산되므로 입력값만 남긴다. 최근 20개.
// 전체 리포트(유료)는 서버 결과 ID(remoteId)로 연결한다 — 결제 흐름에서 채운다.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/birth_value.dart';
import '../pair_chemi/pair_chemi_history.dart';
import 'family_chemi.dart';

class FamilyInput {
  final FamilyRole role;
  final String name; // 부르는 이름 (비우면 역할 이름)
  final BirthValue birth;
  const FamilyInput(this.role, this.name, this.birth);

  FamilyMember toMember() => FamilyMember(role, PairInput(name, birth).toPerson());

  Map<String, dynamic> toJson() => {'role': role.name, 'name': name, 'birth': birth.toJson()};

  static FamilyInput? fromJson(Object? j) {
    if (j is! Map) return null;
    final role = FamilyRole.values.where((r) => r.name == j['role']).firstOrNull;
    final name = j['name'], birth = BirthValue.fromJson(j['birth']);
    if (role == null || name is! String || name.isEmpty || birth == null) return null;
    return FamilyInput(role, name, birth);
  }
}

class FamilyChemiRecord {
  final List<FamilyInput> members;
  final DateTime at;
  final String? remoteId;
  final bool paid;
  final Map<String, dynamic>? report;

  const FamilyChemiRecord({required this.members, required this.at, this.remoteId, this.paid = false, this.report});

  FamilyChemiRecord copyWith({String? remoteId, bool? paid, Map<String, dynamic>? report}) => FamilyChemiRecord(
    members: members,
    at: at,
    remoteId: remoteId ?? this.remoteId,
    paid: paid ?? this.paid,
    report: report ?? this.report,
  );

  String get id => 'family:${jsonEncode([for (final m in members) m.toJson()])}';
  FamilyChemi get chemi => familyChemi([for (final m in members) m.toMember()]);

  Map<String, dynamic> toJson() => {
    'members': [for (final m in members) m.toJson()],
    'at': at.toIso8601String(),
    if (remoteId != null) 'remoteId': remoteId,
    'paid': paid,
    if (report != null) 'report': report,
  };

  static FamilyChemiRecord? fromJson(Object? j) {
    if (j is! Map || j['members'] is! List) return null;
    final members = (j['members'] as List).map(FamilyInput.fromJson).toList();
    final at = DateTime.tryParse('${j['at']}');
    if (members.length < 2 || members.contains(null) || at == null) return null;
    final report = j['report'];
    return FamilyChemiRecord(
      members: members.cast<FamilyInput>(),
      at: at,
      remoteId: j['remoteId'] as String?,
      paid: j['paid'] == true,
      report: report is Map ? Map<String, dynamic>.from(report) : null,
    );
  }
}

class FamilyChemiHistory {
  static const _key = 'family_chemi_history';
  static const maxRecords = 20;

  final SharedPreferences _prefs;
  FamilyChemiHistory(this._prefs);

  List<FamilyChemiRecord> all() {
    final raw = _prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return [];
      return list.map(FamilyChemiRecord.fromJson).whereType<FamilyChemiRecord>().toList();
    } catch (_) {
      return [];
    }
  }

  /// 새로 보거나 다시 본 결과: 맨 위로 (서버 ID·결제 상태는 기존 것을 이어받음)
  Future<void> add(FamilyChemiRecord record) async {
    final old = all().where((r) => r.id == record.id).firstOrNull;
    final merged = old == null
        ? record
        : record.copyWith(remoteId: old.remoteId, paid: old.paid || record.paid, report: old.report ?? record.report);
    await _write([merged, ...all().where((r) => r.id != record.id)].take(maxRecords).toList());
  }

  /// 자리는 그대로 두고 내용만 바꾸기. 없으면 맨 위에 넣는다
  Future<void> save(FamilyChemiRecord record) async {
    final list = all();
    final i = list.indexWhere((r) => r.id == record.id);
    if (i >= 0) {
      list[i] = record;
    } else {
      list.insert(0, record);
    }
    await _write(list.take(maxRecords).toList());
  }

  Future<void> remove(String id) => _write(all().where((r) => r.id != id).toList());

  Future<void> _write(List<FamilyChemiRecord> list) =>
      _prefs.setString(_key, jsonEncode(list.map((r) => r.toJson()).toList()));
}
