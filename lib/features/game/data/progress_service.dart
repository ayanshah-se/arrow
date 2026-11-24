import 'package:shared_preferences/shared_preferences.dart';

class ProgressService {
  static const _currentLevelKey = 'current_level';
  static const _levelsClearedKey = 'levels_cleared';

  late SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  int getCurrentLevel() => _prefs.getInt(_currentLevelKey) ?? 1;

  Future<void> saveCurrentLevel(int level) async {
    await _prefs.setInt(_currentLevelKey, level);
  }

  int getLevelsCleared() => _prefs.getInt(_levelsClearedKey) ?? 0;

  Future<void> incrementLevelsCleared() async {
    await _prefs.setInt(_levelsClearedKey, getLevelsCleared() + 1);
  }

  Future<void> reset() async {
    await _prefs.remove(_currentLevelKey);
    await _prefs.remove(_levelsClearedKey);
  }
}

final progressService = ProgressService();
