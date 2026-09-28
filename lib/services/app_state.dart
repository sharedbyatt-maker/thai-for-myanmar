import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  static const _favoritesKey = 'thai_for_myanmar.favorites.v1';
  static const _learnedKey = 'thai_for_myanmar.learned.v1';
  static const _recentKey = 'thai_for_myanmar.recent.v1';
  static const _themeKey = 'thai_for_myanmar.theme.v1';
  static const _politeKey = 'thai_for_myanmar.polite.v1';
  static const _quizKey = 'thai_for_myanmar.quiz_count.v1';

  SharedPreferences? _preferences;
  final Set<String> _favorites = <String>{};
  final Set<String> _learned = <String>{};
  final List<String> _recent = <String>[];
  String _themePreference = 'system';
  String _politeStyle = 'female';
  int _quizCount = 0;

  Set<String> get favorites => Set<String>.unmodifiable(_favorites);
  Set<String> get learned => Set<String>.unmodifiable(_learned);
  List<String> get recent => List<String>.unmodifiable(_recent);
  String get themePreference => _themePreference;
  String get politeStyle => _politeStyle;
  int get quizCount => _quizCount;

  Future<void> load() async {
    try {
      _preferences = await SharedPreferences.getInstance();
      _favorites
        ..clear()
        ..addAll(_preferences!.getStringList(_favoritesKey) ?? const []);
      _learned
        ..clear()
        ..addAll(_preferences!.getStringList(_learnedKey) ?? const []);
      _recent
        ..clear()
        ..addAll(_preferences!.getStringList(_recentKey) ?? const []);
      _themePreference = _preferences!.getString(_themeKey) ?? 'system';
      _politeStyle = _preferences!.getString(_politeKey) ?? 'female';
      _quizCount = _preferences!.getInt(_quizKey) ?? 0;
    } catch (_) {
      // Keep the bundled learning experience usable if local storage is unavailable.
      _preferences = null;
    }
    notifyListeners();
  }

  bool isFavorite(String phraseId) => _favorites.contains(phraseId);

  Future<void> toggleFavorite(String phraseId) async {
    if (!_favorites.add(phraseId)) _favorites.remove(phraseId);
    await _saveStringList(_favoritesKey, _favorites.toList()..sort());
    notifyListeners();
  }

  Future<void> markLearned(String phraseId) async {
    if (_learned.add(phraseId)) {
      await _saveStringList(_learnedKey, _learned.toList()..sort());
      notifyListeners();
    }
  }

  Future<void> remember(String phraseId) async {
    _recent.remove(phraseId);
    _recent.insert(0, phraseId);
    if (_recent.length > 12) _recent.removeRange(12, _recent.length);
    await _saveStringList(_recentKey, _recent);
    notifyListeners();
  }

  Future<void> setThemePreference(String value) async {
    if (!const {'system', 'light', 'dark'}.contains(value)) return;
    _themePreference = value;
    await _preferences?.setString(_themeKey, value);
    notifyListeners();
  }

  Future<void> setPoliteStyle(String value) async {
    if (!const {'male', 'female'}.contains(value)) return;
    _politeStyle = value;
    await _preferences?.setString(_politeKey, value);
    notifyListeners();
  }

  Future<void> recordQuizCompletion() async {
    _quizCount += 1;
    await _preferences?.setInt(_quizKey, _quizCount);
    notifyListeners();
  }

  Future<void> _saveStringList(String key, List<String> value) async {
    try {
      await _preferences?.setStringList(key, value);
    } catch (_) {
      // State remains available in memory for the current app session.
    }
  }
}
