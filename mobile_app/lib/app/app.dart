import 'package:flutter/material.dart';
import 'package:qds/app/routes.dart';
import 'package:qds/app/theme.dart';

/// Root application widget for QDS.
class QdsApp extends StatelessWidget {
  const QdsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QDS',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Backward-compatible alias for test suites.
typedef MyApp = QdsApp;
