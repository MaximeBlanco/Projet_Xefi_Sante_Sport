import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'core/localization/app_locale.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting(AppLocale.french);

  if (!Env.isConfigured) {
    throw StateError(
      'SUPABASE_URL et SUPABASE_ANON_KEY sont requis. '
      'Lance l\'app avec --dart-define-from-file=dart_define.json '
      '(voir dart_define.example.json).',
    );
  }

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
  );

  runApp(const ProviderScope(child: XefiSportApp()));
}
