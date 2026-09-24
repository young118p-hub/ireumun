// MBTI 케미 기록 (기기에만 저장, 서버 없음)
// 결과는 규칙표로 언제든 다시 계산되므로 조합과 시각만 남긴다.
// 같은 조합을 다시 보면 새로 쌓지 않고 맨 위로 올린다. 최근 30개까지.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'mbti_chemi.dart';

class MbtiRecord {
  final String me;
  final String you;
  final DateTime at;

  const MbtiRecord({required this.me, required this.you, required this.at});

  String get id => 'mbti:$me:$you';
  MbtiChemi get chemi => mbtiChemi(me, you);

  Map<String, dynamic> toJson() => {'me': me, 'you': you, 'at': at.toIso8601String()};

  static MbtiRecord? fromJson(Object? j) {
    if (j is! Map) return null;
    final me = j['me'], you = j['you'], at = DateTime.tryParse('${j['at']}');
    if (me is! String || you is! String || at == null || !isMbti(me) || !isMbti(you)) return null;
    return MbtiRecord(me: me, you: you, at: at);
  }
}

class MbtiHistory {
  static const _historyKey = 'mbti_history';
  static const _myTypeKey = 'my_mbti';
  static const maxRecords = 30;

  final SharedPreferences _prefs;
  MbtiHistory(this._prefs);

  /// 최신순. 깨진 항목은 건너뛴다.
  List<MbtiRecord> all() {
    final raw = _prefs.getString(_historyKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return [];
      return list.map(MbtiRecord.fromJson).whereType<MbtiRecord>().toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> add(String me, String you, {DateTime? now}) async {
    final record = MbtiRecord(me: me, you: you, at: now ?? DateTime.now());
    final next = [record, ...all().where((r) => r.id != record.id)].take(maxRecords).toList();
    await _save(next);
  }

  Future<void> remove(String id) => _save(all().where((r) => r.id != id).toList());

  Future<void> _save(List<MbtiRecord> records) =>
      _prefs.setString(_historyKey, jsonEncode(records.map((r) => r.toJson()).toList()));

  /// "나는"에서 마지막으로 고른 유형 (다음에 미리 선택)
  String? get myType {
    final t = _prefs.getString(_myTypeKey);
    return t != null && isMbti(t) ? t : null;
  }

  Future<void> setMyType(String type) => _prefs.setString(_myTypeKey, type);
}
