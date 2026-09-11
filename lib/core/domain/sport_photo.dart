/// Maps a sport to its bundled photograph.
///
/// Keyed on `external_activity_name`, the column that already exists and is
/// stable: the French display name could be reworded at any time, and an asset
/// path is not something to rebuild a migration for.
///
/// Photographs come from Wikimedia Commons under Creative Commons licences and
/// were reviewed one by one; see assets/sports/CREDITS.md for the author and
/// licence of each. Sports absent from this map have no photograph yet and fall
/// back to their emoji.
abstract final class SportPhoto {
  static const _byActivityName = <String, String>{
    'running': 'assets/sports/running.jpg',
    'cycling': 'assets/sports/cycling.jpg',
    'walking': 'assets/sports/walking.jpg',
    'swimming': 'assets/sports/swimming.jpg',
    'rowing': 'assets/sports/rowing.jpg',
    'tennis': 'assets/sports/tennis.jpg',
    'football': 'assets/sports/football.jpg',
    'basketball': 'assets/sports/basketball.jpg',
  };

  static String? assetFor(String? externalActivityName) {
    if (externalActivityName == null) return null;
    return _byActivityName[externalActivityName.toLowerCase()];
  }
}
