// 작명 API 서비스
// 백엔드 서버를 통한 Claude API 호출 (API 키 서버에만 보관)

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/saju_input.dart';
import '../models/naming_result.dart';

class ClaudeService {
  // 백엔드 서버 URL (Supabase Edge Function)
  static const String _backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://YOUR_PROJECT.supabase.co/functions/v1/naming',
  );
  static const String _apiSecret = String.fromEnvironment(
    'API_SECRET',
    defaultValue: 'ireumun-secret-2024',
  );
  static const int _maxRetries = 3;
  static const int _timeoutSeconds = 60;

  /// 이름 생성 요청 (재시도 로직 포함)
  static Future<NamingResult> generateNames(SajuInput input) async {
    int attempt = 0;

    while (attempt < _maxRetries) {
      attempt++;
      try {
        final response = await _callBackend(input).timeout(
          const Duration(seconds: _timeoutSeconds),
          onTimeout: () => throw TimeoutException('AI 응답 시간 초과'),
        );

        // 유효성 검사
        if (!_validateResponse(response)) {
          if (attempt < _maxRetries) continue;
          throw const FormatException('유효하지 않은 응답 형식');
        }

        return NamingResult.fromJson(response);
      } on TimeoutException {
        if (attempt >= _maxRetries) rethrow;
      } on FormatException {
        if (attempt >= _maxRetries) rethrow;
      } catch (e) {
        if (attempt >= _maxRetries) rethrow;
      }

      // 재시도 전 대기 (exponential backoff)
      await Future.delayed(Duration(milliseconds: 500 * attempt));
    }

    throw Exception('이름 추천에 실패했습니다. 다시 시도해주세요.');
  }

  /// 백엔드 서버 호출
  static Future<Map<String, dynamic>> _callBackend(SajuInput input) async {
    final body = jsonEncode({
      'surname': input.surname,
      'year': input.year,
      'month': input.month,
      'day': input.day,
      'hour': input.hasHour ? input.hour : -1,
      'gender': input.genderString,
    });

    final response = await http.post(
      Uri.parse(_backendUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiSecret',
      },
      body: body,
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      final errorMsg = data['error'] ?? '알 수 없는 오류';
      throw Exception('서버 오류 (${response.statusCode}): $errorMsg');
    }

    return data;
  }

  /// 응답 유효성 검사
  static bool _validateResponse(Map<String, dynamic> json) {
    try {
      if (!json.containsKey('saju') || !json.containsKey('names')) return false;

      final saju = json['saju'] as Map<String, dynamic>;
      if (saju['yearPillar'] == null || saju['dayMaster'] == null) return false;

      final names = json['names'] as List;
      if (names.isEmpty || names.length < 5) return false;

      for (final name in names) {
        final nameStr = name['name'] as String? ?? '';
        if (nameStr.length != 2) return false;

        final hanja = name['hanja'] as String? ?? '';
        if (hanja.isEmpty) return false;

        // 한자 범위 체크 (CJK Unified Ideographs: 4E00-9FFF)
        for (final char in hanja.runes) {
          if (char < 0x4E00 || char > 0x9FFF) return false;
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
