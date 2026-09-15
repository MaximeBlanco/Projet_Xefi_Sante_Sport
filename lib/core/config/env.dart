/// Supabase credentials the app boots on.
///
/// The defaults point at the shared project, so a fresh clone runs with
/// `flutter run` and no flag at all — someone reviewing the project should not
/// have to create a Supabase account first.
///
/// Publishing them is deliberate and not a leak: an anon key is public by
/// design, it already ships inside the JavaScript bundle of every Supabase web
/// app. What guards the data is row level security, enabled on every table.
/// The `service_role` key bypasses that and must never appear here.
///
/// Point the app at another project with
/// `--dart-define-from-file=dart_define.json` (see `dart_define.example.json`),
/// which overrides both values.
abstract final class Env {
  static const _sharedProjectUrl = 'https://rafgjfdfqktddshnlots.supabase.co';
  static const _sharedProjectAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
      '.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJhZmdqZmRmcWt0ZGRzaG5sb3RzIiwicm9sZSI6'
      'ImFub24iLCJpYXQiOjE3ODkwNDI4NDEsImV4cCI6MjEwNDYxODg0MX0'
      '.e_HKfG0ZiQWw1UsC239Wz9_6lh3JhTb9PQnWnAulWak';

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: _sharedProjectUrl,
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: _sharedProjectAnonKey,
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
