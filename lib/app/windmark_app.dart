import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:windmark/app/app_copy.dart';
import 'package:windmark/app/theme.dart';
import 'package:windmark/features/shell/main_shell.dart';

class WindmarkApp extends StatelessWidget {
  const WindmarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppCopy.name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      themeMode: ThemeMode.light,
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const MainShell(),
    );
  }
}
