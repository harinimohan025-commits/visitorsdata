
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visitorsdata/splash_screen.dart';

import 'providers/theme_provider.dart';
import 'providers/visitor_provider.dart';
import 'screens/home_page.dart';
import 'services/visitor_api.dart';
import 'theme/app_theme.dart';

void main() => runApp(const VisitorApp());

class VisitorApp extends StatelessWidget {
  const VisitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..load()),
        // GET all visitors from MockAPI as soon as the app opens
        ChangeNotifierProvider(create: (_) => VisitorProvider(VisitorApi())..load()),
      ],
      child: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: ' Visitor Management',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: theme.mode,
      home: const SplashScreen(),
    );
  }
}