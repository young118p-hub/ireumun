// 빌드 때 주입하는 설정: flutter run --dart-define-from-file=env/dev.json
// 비밀값은 넣지 않는다. publishable(anon) key는 공개돼도 되는 값이고, 권한은 서버가 막는다.
// (예전 API_SECRET처럼 앱에 넣은 값은 APK에서 누구나 꺼낼 수 있다)

class AppEnv {
  AppEnv._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
