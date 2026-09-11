/// The level shown on the member card.
///
/// No levelling scheme existed, so this one is defined here rather than
/// discovered: a level every [pointsPerLevel] points, named in bands. It is a
/// product decision as much as a technical one, and the only place to change it
/// is this file — nothing else hard-codes a threshold or a title.
///
/// Points equal minutes of sport, so 500 points is a little over eight hours:
/// roughly a month of the WHO's weekly recommendation, which makes a level feel
/// earned rather than handed out.
class MemberLevel {
  const MemberLevel({
    required this.number,
    required this.title,
    required this.pointsIntoLevel,
    required this.pointsToNextLevel,
  });

  static const pointsPerLevel = 500;

  static const _titles = <String>[
    'Débutant',
    'Initié',
    'Régulier',
    'Confirmé',
    'Expert',
    'Athlète',
  ];

  factory MemberLevel.fromPoints(int totalPoints) {
    final points = totalPoints < 0 ? 0 : totalPoints;
    final completedLevels = points ~/ pointsPerLevel;
    final intoLevel = points % pointsPerLevel;

    return MemberLevel(
      number: completedLevels + 1,
      // The last title stays for every level beyond it rather than cycling,
      // which would demote someone for having trained more.
      title: _titles[completedLevels.clamp(0, _titles.length - 1)],
      pointsIntoLevel: intoLevel,
      pointsToNextLevel: pointsPerLevel - intoLevel,
    );
  }

  final int number;
  final String title;
  final int pointsIntoLevel;
  final int pointsToNextLevel;

  double get progress => pointsIntoLevel / pointsPerLevel;
}
