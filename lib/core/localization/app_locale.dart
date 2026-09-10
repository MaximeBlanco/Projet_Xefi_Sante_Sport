/// The single locale the app renders in. Every [DateFormat] built against it
/// needs `initializeDateFormatting` to have run first, which `main` does before
/// the first frame.
abstract final class AppLocale {
  static const french = 'fr_FR';
}
