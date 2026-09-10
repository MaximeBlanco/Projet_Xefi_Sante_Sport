/// Defaults target the local Supabase stack (`supabase start`) reachable
/// from the Android emulator at 10.0.2.2. The anon key is public by design
/// (RLS enforces access, not secrecy) so hardcoding it for local dev is
/// safe — override both via --dart-define-from-file for a staging/prod
/// Supabase project.
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://10.0.2.2:54321',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
