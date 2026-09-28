// 이름 케미 기록 (기기에만 저장, 서버 없음). MBTI 기록과 같은 규칙:
// 결과는 규칙으로 다시 계산되므로 두 이름과 시각만 남기고, 같은 조합은 맨 위로, 최근 30개.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'name_chemi.dart';

class NameChemiRecord {
  final String a;
  final String b;
  final DateTime at;

  const NameChemiRecord({required this.a, required this.b, required this.at});

  String get id => 'name:$a:$b';
  NameChemi get chemi => nameChemi(a, b);

  Map<String, dynamic> toJson() => {'a': a, 'b': b, 'at': at.toIso8601String()};

  static NameChemiRecord? fromJson(Object? j) {
    if (j is! Map) return null;
    final a = j['a'], b = j['b'], at = DateTime.tryParse('${j['at']}');
    if (a is! String || b is! String || at == null || !isHangulName(a) || !isHangulName(b)) return null;
    return NameChemiRecord(a: a, b: b, at: at);
  }
}

class NameChemiHistory {
  static const _historyKey = 'name_chemi_history';
  static const _myNameKey = 'my_name';
  static const maxRecords = 30;

  final SharedPreferences _prefs;
  NameChemiHistory(this._prefs);

  List<NameChemiRecord> all() {
    final raw = _prefs.getString(_historyKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return [];
      return list.map(NameChemiRecord.fromJson).whereType<NameChemiRecord>().toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> add(String a, String b, {DateTime? now}) async {
    final record = NameChemiRecord(a: a, b: b, at: now ?? DateTime.now());
    final next = [record, ...all().where((r) => r.id != record.id)].take(maxRecords).toList();
    await _save(next);
  }

  Future<void> remove(String id) => _save(all().where((r) => r.id != id).toList());

  Future<void> _save(List<NameChemiRecord> records) =>
      _prefs.setString(_historyKey, jsonEncode(records.map((r) => r.toJson()).toList()));

  /// 마지막으로 넣은 내 이름 (다음에 미리 채움)
  String? get myName {
    final n = _prefs.getString(_myNameKey);
    return n != null && isHangulName(n) ? n : null;
  }

  Future<void> setMyName(String name) => _prefs.setString(_myNameKey, name);
}
