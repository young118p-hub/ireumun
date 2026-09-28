// 서버 API (Supabase Edge Functions)
// - 인증: Supabase 익명 계정. 예전 공용 비밀키(API_SECRET)는 앱에서 꺼낼 수 있어서 폐기했다.
// - 사주 계산은 기기에서 하고(SajuCalculator), 서버는 AI 작명·결과 저장·결제 검증을 맡는다.
// - 결제 전 결과는 미리보기만 온다. 나머지 이름·상세 분석은 결제 검증 뒤에 받는다.

import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/saju_input.dart';
import '../models/saved_result.dart';
import '../family_chemi/family_chemi_history.dart';
import '../pair_chemi/pair_chemi.dart';
import '../pair_chemi/pair_chemi_history.dart';
import 'device_id_service.dart';
import 'saju_calculator.dart';

/// 서버 에러. message는 사용자에게 그대로 보여줘도 되는 문구다.
class ApiException implements Exception {
  final String code;
  final String message;
  const ApiException(this.code, this.message);

  @override
  String toString() => message;
}

/// 서버가 돌려주는 결과 한 건
class RemoteResult {
  final String id;
  /// 작명·진단일 때만. 우리 케미 등 다른 종류는 null (kindName으로 구분)
  final SavedResultType? kind;
  final String kindName;
  final String requestType;
  final Map<String, dynamic> input;
  final bool isFreeTrial;
  final List<String> paidProducts;
  final bool unlocked;
  final int lockedCount;
  final DateTime createdAt;
  final Map<String, dynamic> content;

  const RemoteResult({
    required this.id,
    required this.kind,
    String? kindName,
    required this.requestType,
    required this.input,
    required this.isFreeTrial,
    required this.paidProducts,
    required this.unlocked,
    required this.lockedCount,
    required this.createdAt,
    required this.content,
  }) : kindName = kindName ?? (kind == SavedResultType.naming ? 'naming' : 'diagnosis');

  bool get isPair => kindName == 'pair';
  bool get isFamily => kindName == 'family';

  /// 케미 기록이 받는 결과 (우리 케미·가족 케미)
  bool get isChemi => isPair || isFamily;

  /// 모르는 종류(앞으로 추가될 결과)는 kind가 null → 작명·진단 저장소에 넣지 않고 건너뛴다.
  /// 예전엔 byName이 예외를 던져서 동기화(me)가 통째로 실패했다.
  factory RemoteResult.fromJson(Map<String, dynamic> json) => RemoteResult(
        id: json['id'] as String,
        kind: SavedResultType.values.where((t) => t.name == json['kind']).firstOrNull,
        kindName: json['kind'] as String? ?? '',
        requestType: json['requestType'] as String? ?? '',
        input: Map<String, dynamic>.from(json['input'] as Map? ?? {}),
        isFreeTrial: json['isFreeTrial'] as bool? ?? false,
        paidProducts:
            (json['paidProducts'] as List? ?? []).map((e) => e as String).toList(),
        unlocked: json['unlocked'] as bool? ?? false,
        lockedCount: (json['lockedCount'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
        content: Map<String, dynamic>.from(json['content'] as Map? ?? {}),
      );
}

class MeStatus {
  final bool freeTrialAvailable;
  final int previewsLeft;
  final List<RemoteResult> results;
  const MeStatus(this.freeTrialAvailable, this.previewsLeft, this.results);
}

abstract class Api {
  /// 결제할 때 Play에 넘기는 계정 ID (서버가 영수증과 대조)
  String? get userId;
  Future<void> ensureSignedIn();
  Future<MeStatus> me();
  Future<RemoteResult> generate(Map<String, dynamic> body);
  Future<void> preparePurchase(String productId, List<String> resultIds);
  Future<List<RemoteResult>> verifyPurchase({
    required String productId,
    required String purchaseToken,
    required List<String> resultIds,
  });
}

class SupabaseApi implements Api {
  final SupabaseClient _client;
  final DeviceIdService _deviceId;

  SupabaseApi(this._client, this._deviceId);

  @override
  String? get userId => _client.auth.currentUser?.id;

  @override
  Future<void> ensureSignedIn() async {
    if (_client.auth.currentSession != null) return;
    try {
      await _client.auth.signInAnonymously();
    } on AuthException {
      throw const ApiException('unauthorized', '서버에 접속하지 못했어요. 잠시 뒤에 다시 시도해 주세요.');
    } on SocketException {
      throw const ApiException('network', '인터넷 연결을 확인해 주세요.');
    }
  }

  Future<Map<String, dynamic>> _invoke(
    String function,
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    await ensureSignedIn();
    try {
      final res = await _client.functions
          .invoke(function, body: {...body, 'deviceId': await _deviceId.get()})
          .timeout(timeout);
      return Map<String, dynamic>.from(res.data as Map);
    } on FunctionException catch (e) {
      final details = e.details;
      if (details is Map && details['error'] is String) {
        throw ApiException(
          details['error'] as String,
          details['message'] as String? ?? '잠시 문제가 생겼어요. 조금 뒤에 다시 시도해 주세요.',
        );
      }
      throw const ApiException('internal', '잠시 문제가 생겼어요. 조금 뒤에 다시 시도해 주세요.');
    } on TimeoutException {
      throw const ApiException('timeout', '응답이 늦어지고 있어요. 잠시 뒤에 다시 시도해 주세요.');
    } on SocketException {
      throw const ApiException('network', '인터넷 연결을 확인해 주세요.');
    } on http.ClientException {
      throw const ApiException('network', '인터넷 연결을 확인해 주세요.');
    }
  }

  @override
  Future<MeStatus> me() async {
    final data = await _invoke('me', {});
    return MeStatus(
      data['freeTrialAvailable'] as bool? ?? false,
      (data['previewsLeft'] as num?)?.toInt() ?? 0,
      (data['results'] as List? ?? [])
          .map((e) => RemoteResult.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  @override
  Future<RemoteResult> generate(Map<String, dynamic> body) async {
    // AI 생성은 오래 걸린다. 서버가 한 번 재시도하므로 넉넉히 기다린다.
    // 앱은 재시도하지 않는다 (재시도하면 무료 미리보기 한도를 또 쓴다).
    final data = await _invoke('naming', body, timeout: const Duration(seconds: 150));
    return RemoteResult.fromJson(Map<String, dynamic>.from(data['result'] as Map));
  }

  @override
  Future<void> preparePurchase(String productId, List<String> resultIds) async {
    await _invoke('purchase', {
      'action': 'prepare',
      'productId': productId,
      'resultIds': resultIds,
    });
  }

  @override
  Future<List<RemoteResult>> verifyPurchase({
    required String productId,
    required String purchaseToken,
    required List<String> resultIds,
  }) async {
    final data = await _invoke(
      'purchase',
      {
        'action': 'verify',
        'productId': productId,
        'purchaseToken': purchaseToken,
        if (resultIds.isNotEmpty) 'resultIds': resultIds,
      },
      // 추가 개선 이름은 검증 뒤에 AI가 만든다
      timeout: const Duration(seconds: 150),
    );
    return (data['results'] as List)
        .map((e) => RemoteResult.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}

// ============================================================
// 요청 본문 (예전 ClaudeService에서 옮김. 사주는 기기에서 계산)
// ============================================================

Map<String, dynamic> _saju(SajuInput p) => SajuCalculator.calculate(
      year: p.year,
      month: p.month,
      day: p.day,
      hour: p.hour,
    ).toSajuAnalysisJson();

class ApiRequests {
  ApiRequests._();

  /// 본인 사주 작명
  static Map<String, dynamic> simpleNaming(SajuInput input) => {
        'type': 'naming_simple',
        'surname': input.surname,
        'gender': input.genderString,
        'saju': _saju(input),
        'birthInfo': input.birthDateString,
      };

  /// 가족 사주 작명 (아기 + 아빠 + 엄마)
  static Map<String, dynamic> familyNaming(FamilyNamingInput input) => {
        'type': 'naming',
        'surname': input.baby.surname,
        'gender': input.baby.genderString,
        'babySaju': _saju(input.baby),
        'fatherSaju': _saju(input.father),
        'motherSaju': _saju(input.mother),
        'babyBirth': input.baby.birthDateString,
        'fatherBirth': input.father.birthDateString,
        'motherBirth': input.mother.birthDateString,
      };

  /// 이름 진단
  static Map<String, dynamic> diagnosis(DiagnosisInput input) => {
        'type': 'diagnosis',
        'surname': input.person.surname,
        'currentName': input.currentName,
        'currentHanja': input.currentHanja,
        'gender': input.person.genderString,
        'saju': _saju(input.person),
        'birthInfo': input.person.birthDateString,
      };
}

/// 우리 케미: 결제할 결과 자리 만들기 (서버는 AI를 부르지 않는다. 무료 점수·해설은 규칙으로 이미 계산)
Map<String, dynamic> pairRequest(PairChemiRecord record) {
  final c = record.chemi;
  Map<String, dynamic> person(PairInput p, PairPerson pp) => {
        'name': p.name,
        'birthInfo': '${p.birth.date.year}-${p.birth.date.month.toString().padLeft(2, '0')}-'
            '${p.birth.date.day.toString().padLeft(2, '0')} ${p.birth.hourKnown ? '${p.birth.hour}시' : '시간 미상'}',
        'saju': pp.saju.toSajuAnalysisJson(),
        'birth': {'y': p.birth.date.year, 'm': p.birth.date.month, 'd': p.birth.date.day, 'h': p.birth.hour},
      };
  return {
    'type': 'pair',
    'relation': record.relation.name,
    'people': [person(record.a, c.a), person(record.b, c.b)],
    'rules': {
      'score': c.score,
      'title': c.title,
      'parts': [
        for (final p in c.parts) {'label': p.label, 'badge': p.badge, 'points': p.points, 'max': p.max, 'text': p.text},
      ],
      'tenGods': [for (final g in c.tenGods) {'from': g.from, 'to': g.to, 'name': g.name}],
    },
  };
}

/// 가족 케미: 결제할 결과 자리 만들기 (AI 없음. 무료 점수·해설은 규칙으로 이미 계산)
Map<String, dynamic> familyRequest(FamilyChemiRecord record) {
  final c = record.chemi;
  return {
    'type': 'family',
    'people': [
      for (final (i, m) in record.members.indexed)
        {
          'role': m.role.name,
          'roleLabel': m.role.label,
          'name': m.name,
          'birthInfo': '${m.birth.date.year}-${m.birth.date.month.toString().padLeft(2, '0')}-'
              '${m.birth.date.day.toString().padLeft(2, '0')} ${m.birth.hourKnown ? '${m.birth.hour}시' : '시간 미상'}',
          'saju': c.members[i].person.saju.toSajuAnalysisJson(),
          'birth': {'y': m.birth.date.year, 'm': m.birth.date.month, 'd': m.birth.date.day, 'h': m.birth.hour},
        },
    ],
    'rules': {
      'score': c.score,
      'title': c.title,
      'oheng': c.oheng,
      'missing': c.missing,
      'pairs': [
        for (final p in c.pairs) {'a': c.members[p.i].name, 'b': c.members[p.j].name, 'score': p.chemi.score, 'title': p.chemi.title},
      ],
    },
  };
}

extension RemoteResultToSaved on RemoteResult {
  /// 새로 받은 결과를 기기 저장용으로 (입력 원본은 기기에만 있으므로 같이 넘긴다)
  SavedResult toSaved({
    FamilyNamingInput? familyInput,
    SajuInput? simpleInput,
    DiagnosisInput? diagnosisInput,
  }) =>
      SavedResult.fromRemote(
        id: id,
        type: kind!,
        createdAt: createdAt,
        unlocked: unlocked,
        paidProducts: paidProducts,
        isFreeTrial: isFreeTrial,
        lockedCount: lockedCount,
        input: input,
        content: content,
        familyInput: familyInput,
        simpleInput: simpleInput,
        diagnosisInput: diagnosisInput,
      );

  /// 기기에 있던 결과를 이 서버 상태로 갱신
  SavedResult applyTo(SavedResult local) => local.withRemote(
        unlocked: unlocked,
        paidProducts: paidProducts,
        lockedCount: lockedCount,
        content: content,
      );
}
