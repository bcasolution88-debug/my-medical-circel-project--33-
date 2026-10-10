import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/events_store.dart';
import 'pages/app_shell.dart';
import 'theme/med_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HealthCircleApp());
}

class HealthCircleApp extends StatelessWidget {
  const HealthCircleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EventsStore()..load()),
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: MaterialApp(
        title: '健康圈子 · Health Circle',
        debugShowCheckedModeBanner: false,
        theme: MedTheme.themeData(),
        home: const AppShell(),
      ),
    );
  }
}
