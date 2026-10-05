/// Supabase credentials the app boots on.
///
/// The defaults point at the local stack, so a fresh clone runs with
/// `npx supabase@latest start` then `flutter run -d chrome` and no flag at all —
/// someone reviewing the project should not have to create a Supabase account,
/// nor copy a file that git deliberately ignores.
///
/// Hard-coding them is not a leak: these are the demo values Supabase itself
/// publishes, identical on every machine that starts the stack with the default
/// config, and that stack only ever listens on loopback. The `service_role` and
/// secret keys bypass row level security and must never appear here.
///
/// Point the app elsewhere with
/// `--dart-define-from-file=dart_define.json` (see `dart_define.example.json`),
/// which overrides both values — that is how the Android emulator reaches the
/// host (`10.0.2.2` instead of `127.0.0.1`) and how a hosted project is targeted.
abstract final class Env {
  static const _localStackUrl = 'http://127.0.0.1:54321';
  static const _localStackPublishableKey =
      'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH';

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: _localStackUrl,
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: _localStackPublishableKey,
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
