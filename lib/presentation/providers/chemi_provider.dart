// 케미 기록 상태 (MBTI 케미). 작명·진단은 NamingProvider가 맡는다.

import 'package:flutter/foundation.dart';
import '../../data/mbti/mbti_history.dart';

class ChemiProvider extends ChangeNotifier {
  final MbtiHistory _history;

  ChemiProvider(this._history);

  List<MbtiRecord> get mbtiRecords => _history.all();
  String? get myMbti => _history.myType;

  /// 결과를 봤을 때 기록 + 내 유형 기억
  Future<void> recordMbti(String me, String you) async {
    await _history.add(me, you);
    await _history.setMyType(me);
    notifyListeners();
  }

  Future<void> deleteMbti(String id) async {
    await _history.remove(id);
    notifyListeners();
  }
}
