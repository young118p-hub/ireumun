// 우리 케미 기록 (기기에만). 결과는 생일로 다시 계산되므로 입력값만 남긴다. 최근 30개.
// 내 정보(부르는 이름·생일)도 기억해서 다음에 미리 채운다.
// 전체 리포트(유료)는 서버 결과 ID(remoteId)로 연결한다 — 결제 흐름에서 채운다.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/birth_value.dart';
import '../services/saju_calculator.dart';
import 'pair_chemi.dart';

class PairInput {
  final String name;
  final BirthValue birth;
  const PairInput(this.name, this.birth);

  PairPerson toPerson() => PairPerson(
        name: name,
        saju: SajuCalculator.calculate(year: birth.date.year, month: birth.date.month, day: birth.date.day, hour: birth.hour),
        hourKnown: birth.hourKnown,
      );

  Map<String, dynamic> toJson() => {'name': name, 'birth': birth.toJson()};

  static PairInput? fromJson(Object? j) {
    if (j is! Map) return null;
    final name = j['name'], birth = BirthValue.fromJson(j['birth']);
    if (name is! String || name.isEmpty || birth == null) return null;
    return PairInput(name, birth);
  }
}

class PairChemiRecord {
  final PairInput a;
  final PairInput b;
  final PairRelation relation;
  final DateTime at;
  final String? remoteId; // 결제하려고 서버에 만든 결과 자리
  final bool paid;
  final Map<String, dynamic>? report; // 결제 뒤 AI 전체 리포트 (기기에 저장 → 오프라인에서도)

  const PairChemiRecord({
    required this.a,
    required this.b,
    required this.relation,
    required this.at,
    this.remoteId,
    this.paid = false,
    this.report,
  });

  PairChemiRecord copyWith({String? remoteId, bool? paid, Map<String, dynamic>? report}) => PairChemiRecord(
        a: a,
        b: b,
        relation: relation,
        at: at,
        remoteId: remoteId ?? this.remoteId,
        paid: paid ?? this.paid,
        report: report ?? this.report,
      );

  String get id => 'pair:${jsonEncode([a.toJson(), b.toJson(), relation.name])}';
  PairChemi get chemi => pairChemi(a.toPerson(), b.toPerson(), relation: relation);

  Map<String, dynamic> toJson() => {
        'a': a.toJson(),
        'b': b.toJson(),
        'rel': relation.name,
        'at': at.toIso8601String(),
        if (remoteId != null) 'remoteId': remoteId,
        'paid': paid,
        if (report != null) 'report': report,
      };

  static PairChemiRecord? fromJson(Object? j) {
    if (j is! Map) return null;
    final a = PairInput.fromJson(j['a']), b = PairInput.fromJson(j['b']);
    final rel = PairRelation.values.where((r) => r.name == j['rel']).firstOrNull;
    final at = DateTime.tryParse('${j['at']}');
    if (a == null || b == null || rel == null || at == null) return null;
    final report = j['report'];
    return PairChemiRecord(
      a: a,
      b: b,
      relation: rel,
      at: at,
      remoteId: j['remoteId'] as String?,
      paid: j['paid'] == true,
      report: report is Map ? Map<String, dynamic>.from(report) : null,
    );
  }
}

class PairChemiHistory {
  static const _historyKey = 'pair_chemi_history';
  static const _meKey = 'my_profile';
  static const maxRecords = 30;

  final SharedPreferences _prefs;
  PairChemiHistory(this._prefs);

  List<PairChemiRecord> all() {
    final raw = _prefs.getString(_historyKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return [];
      return list.map(PairChemiRecord.fromJson).whereType<PairChemiRecord>().toList();
    } catch (_) {
      return [];
    }
  }

  /// 새로 보거나 다시 본 결과: 맨 위로 (서버 ID·결제 상태는 기존 것을 이어받음)
  Future<void> add(PairChemiRecord record) async {
    final old = all().where((r) => r.id == record.id).firstOrNull;
    final merged = old == null
        ? record
        : record.copyWith(remoteId: old.remoteId, paid: old.paid || record.paid, report: old.report ?? record.report);
    final next = [merged, ...all().where((r) => r.id != record.id)].take(maxRecords).toList();
    await _write(next);
  }

  /// 자리는 그대로 두고 내용만 바꾸기 (서버 ID·결제 반영). 없으면 맨 위에 넣는다
  Future<void> save(PairChemiRecord record) async {
    final list = all();
    final i = list.indexWhere((r) => r.id == record.id);
    if (i >= 0) {
      list[i] = record;
    } else {
      list.insert(0, record);
    }
    await _write(list.take(maxRecords).toList());
  }

  Future<void> _write(List<PairChemiRecord> list) =>
      _prefs.setString(_historyKey, jsonEncode(list.map((r) => r.toJson()).toList()));

  Future<void> remove(String id) => _write(all().where((r) => r.id != id).toList());

  PairInput? get me {
    final raw = _prefs.getString(_meKey);
    if (raw == null) return null;
    try {
      return PairInput.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> setMe(PairInput me) => _prefs.setString(_meKey, jsonEncode(me.toJson()));
}
