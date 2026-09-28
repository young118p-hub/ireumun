// 케미 기록 상태 (MBTI 케미, 이름 케미). 작명·진단은 NamingProvider가 맡는다.

import 'package:flutter/foundation.dart';
import '../../data/mbti/mbti_history.dart';
import '../../data/name_chemi/name_chemi_history.dart';

class ChemiProvider extends ChangeNotifier {
  final MbtiHistory _history;
  final NameChemiHistory _names;

  ChemiProvider(this._history, this._names);

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

  List<NameChemiRecord> get nameRecords => _names.all();
  String? get myName => _names.myName;

  /// 이름 케미 결과를 봤을 때 기록 + 내 이름 기억
  Future<void> recordName(String me, String you) async {
    await _names.add(me, you);
    await _names.setMyName(me);
    notifyListeners();
  }

  Future<void> deleteName(String id) async {
    await _names.remove(id);
    notifyListeners();
  }
}
