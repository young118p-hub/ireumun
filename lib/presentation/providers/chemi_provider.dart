// 케미 기록 상태 (MBTI 케미, 이름 케미, 우리 케미, 가족 케미). 작명·진단은 NamingProvider가 맡는다.

import 'package:flutter/foundation.dart';
import '../../data/family_chemi/family_chemi_history.dart';
import '../../data/mbti/mbti_history.dart';
import '../../data/name_chemi/name_chemi_history.dart';
import '../../data/pair_chemi/pair_chemi.dart';
import '../../data/family_chemi/family_chemi.dart';
import '../../data/models/birth_value.dart';
import '../../data/pair_chemi/pair_chemi_history.dart';
import '../../data/services/api_service.dart';

class ChemiProvider extends ChangeNotifier {
  final MbtiHistory _history;
  final NameChemiHistory _names;
  final PairChemiHistory _pairs;
  final FamilyChemiHistory _families;

  /// 우리·가족 케미 결제에만 쓴다 (MBTI·이름 케미는 서버 없음). 테스트에서는 비워도 된다.
  final Api? api;

  ChemiProvider(this._history, this._names, this._pairs, this._families, {this.api});

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

  List<PairChemiRecord> get pairRecords => _pairs.all();
  PairInput? get myProfile => _pairs.me;

  /// 우리 케미 결과를 봤을 때 기록 + 내 정보 기억
  Future<void> recordPair(PairInput me, PairInput you, PairRelation relation) async {
    await _pairs.add(PairChemiRecord(a: me, b: you, relation: relation, at: DateTime.now()));
    await _pairs.setMe(me);
    notifyListeners();
  }

  Future<void> deletePair(String id) async {
    await _pairs.remove(id);
    notifyListeners();
  }

  PairChemiRecord? pairRecord(String id) => _pairs.all().where((r) => r.id == id).firstOrNull;

  /// 결제하기 전: 서버에 결과 자리를 만들고 ID를 기록에 남긴다 (이미 있으면 그대로)
  Future<String> ensurePairRemote(PairChemiRecord record) async {
    final saved = pairRecord(record.id) ?? record;
    if (saved.remoteId != null) return saved.remoteId!;
    final remote = await api!.generate(pairRequest(saved));
    await _pairs.save(saved.copyWith(remoteId: remote.id));
    notifyListeners();
    return remote.id;
  }

  /// 서버 결과를 종류에 맞는 기록에 반영 (NamingProvider.onChemiResult)
  Future<void> applyRemote(RemoteResult r) => r.isFamily ? applyFamilyRemote(r) : applyPairRemote(r);

  /// 서버의 우리 케미 결과 반영 (결제 완료, 앱 시작 때 동기화).
  /// 기기에 기록이 없으면(재설치) 서버에 저장한 입력으로 되살린다.
  Future<void> applyPairRemote(RemoteResult r) async {
    final all = _pairs.all();
    var record = all.where((x) => x.remoteId == r.id).firstOrNull ?? _restore(r);
    if (record == null) return;
    final report = r.content['report'];
    record = record.copyWith(
      remoteId: r.id,
      paid: r.unlocked || record.paid,
      report: report is Map ? Map<String, dynamic>.from(report) : null,
    );
    await _pairs.save(record);
    notifyListeners();
  }

  PairChemiRecord? _restore(RemoteResult r) {
    try {
      final people = (r.input['people'] as List).cast<Map>();
      PairInput person(Map p) {
        final b = BirthValue.fromJson(p['birth']);
        if (b == null) throw const FormatException('birth');
        return PairInput(p['name'] as String, b);
      }

      final rel = PairRelation.values.firstWhere((x) => x.name == r.input['relation']);
      return PairChemiRecord(a: person(people[0]), b: person(people[1]), relation: rel, at: r.createdAt, remoteId: r.id);
    } catch (_) {
      return null; // 예전 형식 등: 되살릴 수 없으면 건너뜀
    }
  }

  // ============================================================
  // 가족 케미
  // ============================================================

  List<FamilyChemiRecord> get familyRecords => _families.all();

  /// 가족 케미 결과를 봤을 때 기록 (+ "나"가 있으면 내 정보 기억)
  Future<void> recordFamily(List<FamilyInput> members) async {
    await _families.add(FamilyChemiRecord(members: members, at: DateTime.now()));
    final me = members.where((m) => m.role == FamilyRole.me).firstOrNull;
    if (me != null) await _pairs.setMe(PairInput(me.name, me.birth));
    notifyListeners();
  }

  Future<void> deleteFamily(String id) async {
    await _families.remove(id);
    notifyListeners();
  }

  FamilyChemiRecord? familyRecord(String id) => _families.all().where((r) => r.id == id).firstOrNull;

  /// 결제하기 전: 서버에 결과 자리를 만들고 ID를 기록에 남긴다 (이미 있으면 그대로)
  Future<String> ensureFamilyRemote(FamilyChemiRecord record) async {
    final saved = familyRecord(record.id) ?? record;
    if (saved.remoteId != null) return saved.remoteId!;
    final remote = await api!.generate(familyRequest(saved));
    await _families.save(saved.copyWith(remoteId: remote.id));
    notifyListeners();
    return remote.id;
  }

  /// 서버의 가족 케미 결과 반영. 기기에 기록이 없으면(재설치) 서버에 저장한 입력으로 되살린다.
  Future<void> applyFamilyRemote(RemoteResult r) async {
    var record = _families.all().where((x) => x.remoteId == r.id).firstOrNull ?? _restoreFamily(r);
    if (record == null) return;
    final report = r.content['report'];
    record = record.copyWith(
      remoteId: r.id,
      paid: r.unlocked || record.paid,
      report: report is Map ? Map<String, dynamic>.from(report) : null,
    );
    await _families.save(record);
    notifyListeners();
  }

  FamilyChemiRecord? _restoreFamily(RemoteResult r) {
    final people = r.input['people'];
    if (people is! List) return null;
    final members = [for (final p in people) FamilyInput.fromJson(p)];
    if (members.length < 2 || members.contains(null)) return null;
    return FamilyChemiRecord(members: members.cast<FamilyInput>(), at: r.createdAt, remoteId: r.id);
  }
}
