import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'screens/auth/auth_gate.dart';

const _frenchLocale = Locale('fr', 'FR');

class XefiSportApp extends StatelessWidget {
  const XefiSportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XEFI Sport',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: _frenchLocale,
      supportedLocales: const [_frenchLocale],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthGate(),
    );
  }
}
