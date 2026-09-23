// 결과 저장 서비스
// Hive를 이용한 기기 저장. 결제한 결과는 전체가 여기 있어서 오프라인으로 다시 볼 수 있다.
// 사용자가 지운 결과는 서버 동기화 때 되살아나지 않도록 따로 기억한다.

import 'package:hive/hive.dart';
import '../models/saved_result.dart';

class ResultStorageService {
  static const String _boxName = 'saved_results';
  static const String _hiddenBoxName = 'hidden_results';
  late Box<String> _box;
  late Box<bool> _hidden;

  /// 초기화 (앱 시작 시 호출)
  Future<void> initialize() async {
    _box = await Hive.openBox<String>(_boxName);
    _hidden = await Hive.openBox<bool>(_hiddenBoxName);
  }

  /// 결과 저장 (같은 id면 덮어씀)
  Future<void> save(SavedResult result) async {
    await _box.put(result.id, result.toJsonString());
  }

  /// 결과 삭제 (서버 동기화로 다시 생기지 않게 기억)
  Future<void> delete(String id) async {
    await _box.delete(id);
    await _hidden.put(id, true);
  }

  bool isHidden(String id) => _hidden.get(id) ?? false;

  /// 전체 결과 조회 (최신순)
  List<SavedResult> getAll() {
    final results = <SavedResult>[];
    for (final jsonStr in _box.values) {
      try {
        results.add(SavedResult.fromJsonString(jsonStr));
      } catch (_) {}
    }
    results.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return results;
  }

  /// 특정 결과 조회
  SavedResult? getById(String id) {
    final jsonStr = _box.get(id);
    if (jsonStr == null) return null;
    try {
      return SavedResult.fromJsonString(jsonStr);
    } catch (_) {
      return null;
    }
  }

  /// 가장 최근의 미결제 결과 (타입별)
  SavedResult? getUnpaid(SavedResultType type) {
    for (final r in getAll()) {
      if (r.type == type && !r.isPaid) return r;
    }
    return null;
  }

  /// 결과 개수
  int get count => _box.length;
}
