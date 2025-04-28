import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ← RiverpodだけでOK
import 'package:frontend/layout/app_scaffold.dart';
import 'theme/theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_page.dart';
import 'screens/register_page.dart';

void main() {
  runApp(
    const ProviderScope( // ← ProviderScopeだけ！
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      initialRoute: '/', // 最初に表示する画面
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const AppScaffold(),
      },
    );
  }
}
