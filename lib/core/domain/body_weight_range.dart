/// The body weights the app accepts, in kilograms.
///
/// These bounds are not a UI preference: they mirror the window the Calories
/// Burned API supports (50-500 lb), which the `calculate-calories` Edge
/// Function enforces. A profile saved outside this range would pass sign-up and
/// then get an HTTP 400 on every session, so its calories would silently read
/// as unknown forever. Widening either side means widening both.
abstract final class BodyWeightRange {
  static const minimumKg = 23.0;
  static const maximumKg = 226.0;

  static bool contains(double weightKg) =>
      weightKg >= minimumKg && weightKg <= maximumKg;

  static String get invalidMessage =>
      'Le poids doit être compris entre ${minimumKg.round()} '
      'et ${maximumKg.round()} kg';
}
