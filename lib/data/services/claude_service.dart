// 작명 API 서비스
// 백엔드 서버를 통한 Claude API 호출
// 가족 사주 기반 작명 + 이름 진단 2가지 엔드포인트

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/saju_input.dart';
import '../models/naming_result.dart';
import '../models/diagnosis_result.dart';
import 'saju_calculator.dart';

class ClaudeService {
  static const String _backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://sgckoxdvsskhiskstgmu.supabase.co/functions/v1',
  );
  static const String _apiSecret = String.fromEnvironment(
    'API_SECRET',
    defaultValue: 'ireumun-secret-2024',
  );
  static const int _maxRetries = 3;
  static const int _timeoutSeconds = 90;

  // ============================================================
  // 신규 작명 (가족 사주 기반)
  // ============================================================

  /// 가족 사주 기반 이름 추천
  /// [nameCount]: 추천 이름 개수 (기본 5, 프리미엄 10)
  static Future<NamingResult> generateFamilyNames({
    required FamilyNamingInput familyInput,
    int nameCount = 5,
  }) async {
    // 1. 코드로 사주 계산 (정확도 보장)
    final babySaju = SajuCalculator.calculate(
      year: familyInput.baby.year,
      month: familyInput.baby.month,
      day: familyInput.baby.day,
      hour: familyInput.baby.hour,
    );
    final fatherSaju = SajuCalculator.calculate(
      year: familyInput.father.year,
      month: familyInput.father.month,
      day: familyInput.father.day,
      hour: familyInput.father.hour,
    );
    final motherSaju = SajuCalculator.calculate(
      year: familyInput.mother.year,
      month: familyInput.mother.month,
      day: familyInput.mother.day,
      hour: familyInput.mother.hour,
    );

    // 2. 사주 결과 + 작명 요청을 백엔드로 전달
    final body = {
      'type': 'naming',
      'surname': familyInput.baby.surname,
      'gender': familyInput.baby.genderString,
      'nameCount': nameCount,
      'babySaju': babySaju.toSajuAnalysisJson(),
      'fatherSaju': fatherSaju.toSajuAnalysisJson(),
      'motherSaju': motherSaju.toSajuAnalysisJson(),
      'babyBirth': familyInput.baby.birthDateString,
      'fatherBirth': familyInput.father.birthDateString,
      'motherBirth': familyInput.mother.birthDateString,
    };

    final response = await _callWithRetry(body);

    // 3. 결과에 코드 계산 사주 결합
    final result = NamingResult.fromJson(response);
    return NamingResult(
      babySaju: SajuAnalysis.fromJson(babySaju.toSajuAnalysisJson()),
      fatherSaju: SajuAnalysis.fromJson(fatherSaju.toSajuAnalysisJson()),
      motherSaju: SajuAnalysis.fromJson(motherSaju.toSajuAnalysisJson()),
      familyAnalysis: result.familyAnalysis,
      names: result.names,
    );
  }

  // ============================================================
  // 이름 진단
  // ============================================================

  /// 현재 이름 사주 궁합 진단
  static Future<DiagnosisResult> diagnoseName({
    required DiagnosisInput input,
  }) async {
    // 1. 코드로 사주 계산
    final saju = SajuCalculator.calculate(
      year: input.person.year,
      month: input.person.month,
      day: input.person.day,
      hour: input.person.hour,
    );

    // 2. 사주 결과 + 진단 요청을 백엔드로 전달
    final body = {
      'type': 'diagnosis',
      'surname': input.person.surname,
      'currentName': input.currentName,
      'currentHanja': input.currentHanja,
      'gender': input.person.genderString,
      'saju': saju.toSajuAnalysisJson(),
      'birthInfo': input.person.birthDateString,
    };

    final response = await _callWithRetry(body);

    // 3. 결과에 코드 계산 사주 결합
    final result = DiagnosisResult.fromJson(response);
    return DiagnosisResult(
      saju: SajuAnalysis.fromJson(saju.toSajuAnalysisJson()),
      diagnosis: result.diagnosis,
      improvementNames: result.improvementNames,
    );
  }

  // ============================================================
  // 진단 후 업그레이드 (추가 개선 이름)
  // ============================================================

  /// 진단 결과 기반 추가 개선 이름 5개
  static Future<List<NameSuggestion>> generateImprovementNames({
    required DiagnosisInput input,
    required DiagnosisResult previousResult,
    int nameCount = 5,
  }) async {
    final saju = SajuCalculator.calculate(
      year: input.person.year,
      month: input.person.month,
      day: input.person.day,
      hour: input.person.hour,
    );

    final body = {
      'type': 'diagnosis_upgrade',
      'surname': input.person.surname,
      'gender': input.person.genderString,
      'nameCount': nameCount,
      'saju': saju.toSajuAnalysisJson(),
      'birthInfo': input.person.birthDateString,
      'previousDiagnosis': previousResult.diagnosis.toJson(),
    };

    final response = await _callWithRetry(body);
    final names = (response['names'] as List)
        .map((e) => NameSuggestion.fromJson(e as Map<String, dynamic>))
        .toList();
    return names;
  }

  // ============================================================
  // 기존 호환: 단일 사주 작명 (무료 체험용)
  // ============================================================

  /// 단일 입력 기반 이름 추천 (무료 체험)
  static Future<NamingResult> generateNames(SajuInput input) async {
    final saju = SajuCalculator.calculate(
      year: input.year,
      month: input.month,
      day: input.day,
      hour: input.hour,
    );

    final body = {
      'type': 'naming_simple',
      'surname': input.surname,
      'gender': input.genderString,
      'nameCount': 5,
      'saju': saju.toSajuAnalysisJson(),
      'birthInfo': input.birthDateString,
    };

    final response = await _callWithRetry(body);
    final result = NamingResult.fromJson(response);
    return NamingResult(
      babySaju: SajuAnalysis.fromJson(saju.toSajuAnalysisJson()),
      names: result.names,
    );
  }

  // ============================================================
  // HTTP 호출 (재시도 포함)
  // ============================================================

  static Future<Map<String, dynamic>> _callWithRetry(
    Map<String, dynamic> body,
  ) async {
    int attempt = 0;

    while (attempt < _maxRetries) {
      attempt++;
      try {
        final response = await _callBackend(body);
        if (_validateResponse(response, body['type'] as String)) {
          return response;
        }
        if (attempt >= _maxRetries) {
          throw const FormatException('유효하지 않은 응답 형식');
        }
      } on TimeoutException {
        if (attempt >= _maxRetries) rethrow;
      } catch (e) {
        if (attempt >= _maxRetries) rethrow;
      }

      await Future.delayed(Duration(milliseconds: 500 * attempt));
    }

    throw Exception('요청에 실패했습니다. 다시 시도해주세요.');
  }

  static Future<Map<String, dynamic>> _callBackend(
    Map<String, dynamic> body,
  ) async {
    final response = await http
        .post(
          Uri.parse('$_backendUrl/naming'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiSecret',
          },
          body: jsonEncode(body),
        )
        .timeout(Duration(seconds: _timeoutSeconds));

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      final errorMsg = data['error'] ?? '알 수 없는 오류';
      throw Exception('서버 오류 (${response.statusCode}): $errorMsg');
    }

    return data;
  }

  static bool _validateResponse(Map<String, dynamic> json, String type) {
    try {
      if (type == 'diagnosis') {
        return json.containsKey('diagnosis') || json.containsKey('saju');
      }
      if (type == 'diagnosis_upgrade') {
        final names = json['names'] as List?;
        return names != null && names.isNotEmpty;
      }
      // naming, naming_simple
      if (!json.containsKey('names')) return false;
      final names = json['names'] as List;
      if (names.isEmpty) return false;

      for (final name in names) {
        final nameStr = name['name'] as String? ?? '';
        if (nameStr.length < 2) return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
