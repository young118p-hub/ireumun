// 케미연구소 - 사주·MBTI 케미 + 작명 앱
// 진입점 & Provider 설정 + Hive·Supabase 초기화 + 탭 네비게이션 (실험실 / 내 결과)

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/app_env.dart';
import 'core/theme/chemi_theme.dart';
import 'data/mbti/mbti_history.dart';
import 'data/name_chemi/name_chemi_history.dart';
import 'data/services/api_service.dart';
import 'data/services/device_id_service.dart';
import 'data/services/purchase_service.dart';
import 'data/services/result_storage_service.dart';
import 'presentation/providers/chemi_provider.dart';
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

  final prefs = await SharedPreferences.getInstance();
  final chemi = ChemiProvider(MbtiHistory(prefs), NameChemiHistory(prefs));

  runApp(ChemiLabApp(provider: provider, chemi: chemi));

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

class ChemiLabApp extends StatelessWidget {
  final NamingProvider provider;
  final ChemiProvider chemi;

  const ChemiLabApp({super.key, required this.provider, required this.chemi});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: provider),
        ChangeNotifierProvider.value(value: chemi),
      ],
      child: MaterialApp(
        scaffoldMessengerKey: scaffoldMessengerKey,
        title: '케미연구소',
        debugShowCheckedModeBanner: false,
        theme: chemiTheme(),
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

/// 하단 탭 (실험실 / 내 결과). 시안처럼 떠 있는 검은 알약 모양.
class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _currentIndex = 0;

  void _go(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(onOpenAllResults: () => _go(1)),
          MyResultsScreen(onGoHome: () => _go(0)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(22, 0, 22, 18),
        child: Container(
          height: 60,
          decoration: BoxDecoration(color: ChemiColors.ink, borderRadius: BorderRadius.circular(999)),
          child: Row(
            children: [
              _TabButton(label: '실험실', icon: Icons.science_outlined, selected: _currentIndex == 0, onTap: () => _go(0)),
              _TabButton(label: '내 결과', icon: Icons.receipt_long_outlined, selected: _currentIndex == 1, onTap: () => _go(1)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: selected ? ChemiColors.pink : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20, color: selected ? ChemiColors.ink : Colors.white),
                  const SizedBox(width: 6),
                  Text(label, style: ChemiText.label(13, color: selected ? ChemiColors.ink : Colors.white)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
