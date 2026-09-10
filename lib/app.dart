import 'package:flutter/material.dart';

import 'data/session_repository.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

class XefiSportApp extends StatelessWidget {
  const XefiSportApp({super.key, required this.repository});

  final SessionRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XEFI Sport',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: HomeScreen(repository: repository),
    );
  }
}
