class SportDefinition {
  const SportDefinition({
    required this.name,
    required this.emoji,
    required this.isGpsTrackable,
    required this.caloriesApiActivity,
  });

  final String name;
  final String emoji;
  final bool isGpsTrackable;

  /// Name sent to the Calories Burned API — kept separate from [name]
  /// because the API expects specific English activity terms.
  final String caloriesApiActivity;
}

const availableSports = [
  SportDefinition(
    name: 'Course à pied',
    emoji: '🏃',
    isGpsTrackable: true,
    caloriesApiActivity: 'running',
  ),
  SportDefinition(
    name: 'Vélo',
    emoji: '🚴',
    isGpsTrackable: true,
    caloriesApiActivity: 'cycling',
  ),
  SportDefinition(
    name: 'Marche',
    emoji: '🚶',
    isGpsTrackable: true,
    caloriesApiActivity: 'walking',
  ),
  SportDefinition(
    name: 'Natation',
    emoji: '🏊',
    isGpsTrackable: false,
    caloriesApiActivity: 'swimming',
  ),
  SportDefinition(
    name: 'Football',
    emoji: '⚽',
    isGpsTrackable: false,
    caloriesApiActivity: 'soccer',
  ),
  SportDefinition(
    name: 'Basketball',
    emoji: '🏀',
    isGpsTrackable: false,
    caloriesApiActivity: 'basketball',
  ),
  SportDefinition(
    name: 'Tennis',
    emoji: '🎾',
    isGpsTrackable: false,
    caloriesApiActivity: 'tennis',
  ),
  SportDefinition(
    name: 'Yoga',
    emoji: '🧘',
    isGpsTrackable: false,
    caloriesApiActivity: 'yoga',
  ),
  SportDefinition(
    name: 'Musculation',
    emoji: '🏋️',
    isGpsTrackable: false,
    caloriesApiActivity: 'weight lifting',
  ),
  SportDefinition(
    name: 'Boxe',
    emoji: '🥊',
    isGpsTrackable: false,
    caloriesApiActivity: 'boxing',
  ),
];
