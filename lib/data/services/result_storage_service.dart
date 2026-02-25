// 결과 저장 서비스
// Hive를 이용한 로컬 저장 (미결제/결제완료 상태 관리)

import 'package:hive/hive.dart';
import '../models/saved_result.dart';

class ResultStorageService {
  static const String _boxName = 'saved_results';
  late Box<String> _box;

  /// 초기화 (앱 시작 시 호출)
  Future<void> initialize() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  /// 결과 저장
  Future<void> save(SavedResult result) async {
    await _box.put(result.id, result.toJsonString());
  }

  /// 결과 삭제
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

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

  /// 미결제 결과 조회 (타입별)
  SavedResult? getUnpaid(SavedResultType type) {
    final all = getAll();
    try {
      return all.firstWhere((r) => r.type == type && !r.isPaid);
    } catch (_) {
      return null;
    }
  }

  /// 미결제 결과 존재 여부
  bool hasUnpaid(SavedResultType type) {
    return getUnpaid(type) != null;
  }

  /// 결제 완료 처리
  Future<void> markAsPaid(String id) async {
    final result = getById(id);
    if (result == null) return;
    final paid = result.copyWithPaid();
    await _box.put(id, paid.toJsonString());
  }

  /// 결과 개수
  int get count => _box.length;

  /// 타입별 결과 조회
  List<SavedResult> getByType(SavedResultType type) {
    return getAll().where((r) => r.type == type).toList();
  }
}
