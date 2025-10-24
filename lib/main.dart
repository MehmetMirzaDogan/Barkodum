import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'controllers/theme_controller.dart';
import 'market_select_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.I.loadTheme();
  runApp(const BarkodApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void restartApp() {
  navigatorKey.currentState?.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const MarketSelectPage()),
    (route) => false,
  );
}

class BarkodApp extends StatelessWidget {
  const BarkodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.I,
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Market Barkod Rehberi',
          debugShowCheckedModeBanner: false,
          supportedLocales: const [
            Locale('tr', 'TR'),
            Locale('en', 'US'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          locale: const Locale('tr', 'TR'),
          themeMode: ThemeController.I.currentMode,
          theme: ThemeData(
            brightness: Brightness.light,
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF6F6F6),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
          ),
          home: const MarketSelectPage(),
        );
      },
    );
  }
}
