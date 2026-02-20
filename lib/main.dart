// 이름운 - AI 사주 작명 앱
// 진입점 & Provider 설정

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/services/credit_service.dart';
import 'presentation/providers/naming_provider.dart';
import 'presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 크레딧 서비스 초기화
  final creditService = CreditService();
  await creditService.initialize();

  runApp(IreumunApp(creditService: creditService));
}

class IreumunApp extends StatelessWidget {
  final CreditService creditService;

  const IreumunApp({super.key, required this.creditService});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NamingProvider(creditService: creditService),
      child: MaterialApp(
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
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ko', 'KR'),
        ],
        home: const HomeScreen(),
      ),
    );
  }
}
