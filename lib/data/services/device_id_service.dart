// 기기 ID (무료 체험·무료 미리보기 한도용)
// ANDROID_ID는 앱 서명 키 + 기기 + 사용자 조합마다 고정이라 앱을 지웠다 깔아도 같다.
// (예전 코드의 device_info_plus `androidInfo.id`는 빌드 번호(Build.ID)라서
//  같은 펌웨어를 쓰는 모든 기기가 같은 값이었다)

import 'dart:math';
import 'package:android_id/android_id.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceIdService {
  static const _fallbackKey = 'device_id_fallback';
  String? _cached;

  Future<String> get() async {
    if (_cached != null) return _cached!;
    try {
      final id = await const AndroidId().getId();
      if (id != null && id.length >= 8) return _cached = id;
    } catch (_) {}
    // ANDROID_ID를 못 읽는 경우만: 무작위 값을 저장해 둔다 (재설치 시 바뀜)
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_fallbackKey);
    if (id == null) {
      final rnd = Random.secure();
      id = List.generate(16, (_) => rnd.nextInt(16).toRadixString(16)).join();
      await prefs.setString(_fallbackKey, id);
    }
    return _cached = id;
  }
}
