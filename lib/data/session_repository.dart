import 'package:hive_flutter/hive_flutter.dart';

import '../models/sport_session.dart';

/// All data stays on this phone — no server, no account, one user.
class SessionRepository {
  static const _sessionsBoxName = 'sessions';
  static const _settingsBoxName = 'settings';

  late final Box<Map> _sessionsBox;
  late final Box _settingsBox;

  /// Assumes Hive has already been initialized (Hive.initFlutter() in
  /// main(), or Hive.init(path) in tests) — this only opens the boxes.
  Future<void> init() async {
    _sessionsBox = await Hive.openBox<Map>(_sessionsBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }

  List<SportSession> getAllSessions() {
    return _sessionsBox.values
        .map((map) => SportSession.fromMap(map))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> saveSession(SportSession session) {
    return _sessionsBox.put(session.id, session.toMap());
  }

  Future<void> deleteSession(String id) => _sessionsBox.delete(id);

  double? get weightKg => (_settingsBox.get('weightKg') as num?)?.toDouble();

  Future<void> setWeightKg(double weightKg) {
    return _settingsBox.put('weightKg', weightKg);
  }
}
