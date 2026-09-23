// 이름운 - AI 사주 작명 앱
// 진입점 & Provider 설정 + Hive·Supabase 초기화 + 탭 네비게이션

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/app_env.dart';
import 'data/services/api_service.dart';
import 'data/services/device_id_service.dart';
import 'data/services/purchase_service.dart';
import 'data/services/result_storage_service.dart';
import 'presentation/providers/naming_provider.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/my_results_screen.dart';

/// 결제 완료·취소 같은 안내를 어느 화면에서든 띄우기 위한 키
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!AppEnv.isConfigured) {
    runApp(const _MissingConfigApp());
    return;
  }

  // Hive 초기화
  await Hive.initFlutter();

  await Supabase.initialize(
    url: AppEnv.supabaseUrl,
    publishableKey: AppEnv.supabasePublishableKey,
  );

  // 서비스 초기화
  final api = SupabaseApi(Supabase.instance.client, DeviceIdService());
  final purchaseService = PurchaseService(
    billing: InAppPurchaseGateway(),
    api: api,
  );
  await purchaseService.initialize();

  final storageService = ResultStorageService();
  await storageService.initialize();

  final provider = NamingProvider(
    purchaseService: purchaseService,
    storageService: storageService,
    api: api,
  )..onNotice = (message) {
      scaffoldMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    };

  runApp(IreumunApp(provider: provider));

  // 로그인·동기화·덜 끝난 결제 이어받기 (화면은 먼저 띄운다)
  provider.start();
}

/// 빌드 설정(env/*.json)이 빠졌을 때
class _MissingConfigApp extends StatelessWidget {
  const _MissingConfigApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              '서버 설정이 없습니다.\nflutter run --dart-define-from-file=env/dev.json',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class IreumunApp extends StatelessWidget {
  final NamingProvider provider;

  const IreumunApp({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        scaffoldMessengerKey: scaffoldMessengerKey,
        title: '이름운',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1A1A2E),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF8F6F0),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1A1A2E),
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A2E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ko', 'KR'),
        ],
        home: const MainTabScreen(),
      ),
    );
  }
}

/// 하단 탭 네비게이션 (홈 / 내 결과)
class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    MyResultsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1A1A2E),
        unselectedItemColor: const Color(0xFFB0B0B0),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            activeIcon: Icon(Icons.folder),
            label: '내 결과',
          ),
        ],
      ),
    );
  }
}
