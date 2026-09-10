/// Points at the shared hosted Supabase project by default, so anyone who
/// clones the repo can `flutter run` with zero setup — no Docker, no CLI.
/// The anon key is public by design (RLS enforces access, not secrecy) so
/// hardcoding it here is safe. Override both via --dart-define-from-file
/// only if you need to point at a different Supabase project (e.g. a local
/// `supabase start` stack for offline schema work).
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://rafgjfdfqktddshnlots.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJhZmdqZmRmcWt0ZGRzaG5sb3RzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODkwNDI4NDEsImV4cCI6MjEwNDYxODg0MX0.e_HKfG0ZiQWw1UsC239Wz9_6lh3JhTb9PQnWnAulWak',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
