import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/stores.dart';
import 'pages/app_shell.dart';
import 'pages/auth/splash_page.dart';
import 'theme/med_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HealthCircleApp());
}

class HealthCircleApp extends StatelessWidget {
  /// When true, skips the splash (used by widget tests).
  final bool skipSplash;
  const HealthCircleApp({super.key, this.skipSplash = false});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeStore()..load()),
        ChangeNotifierProvider(create: (_) => AuthStore()..load()),
        ChangeNotifierProvider(create: (_) => HomeStore()),
        ChangeNotifierProvider(create: (_) => EventsStore()),
        ChangeNotifierProvider(create: (_) => PostsStore()),
        ChangeNotifierProvider(create: (_) => MessagesStore()),
      ],
      child: Consumer<ThemeStore>(
        builder: (_, theme, _) => MedTheme(
          tokens: theme.tokens,
          child: MaterialApp(
            title: '健康圈子 · Health Circle',
            debugShowCheckedModeBanner: false,
            theme: theme.tokens.themeData(),
            home: skipSplash ? const AppShell() : const SplashPage(),
          ),
        ),
      ),
    );
  }
}
