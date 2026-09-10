import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'screens/auth/auth_gate.dart';

class XefiSportApp extends StatelessWidget {
  const XefiSportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XEFI Sport',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}
