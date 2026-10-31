import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../learning/learning_progress.dart';
import '../models/phrase_issue.dart';

class AppState extends ChangeNotifier {
  static const _favoritesKey = 'thai_for_myanmar.favorites.v1';
  static const _learnedKey = 'thai_for_myanmar.learned.v1';
  static const _recentKey = 'thai_for_myanmar.recent.v1';
  static const _themeKey = 'thai_for_myanmar.theme.v1';
  static const _politeKey = 'thai_for_myanmar.polite.v1';
  static const _quizKey = 'thai_for_myanmar.quiz_count.v1';
  static const _learningKey = 'thai_for_myanmar.learning.v1';
  static const _volumeKey = 'thai_for_myanmar.audio_volume.v1';
  static const _issuesKey = 'thai_for_myanmar.phrase_issues.v1';

  SharedPreferences? _preferences;
  final Set<String> _favorites = <String>{};
  final Set<String> _learned = <String>{};
  final List<String> _recent = <String>[];
  String _themePreference = 'system';
  String _politeStyle = 'female';
  int _quizCount = 0;
  LearningProgress _learning = LearningProgress();
  double _audioVolume = 1;
  final List<PhraseIssue> _issues = [];
  Future<void> _issueWrites = Future<void>.value();
  Future<void> _learningWrites = Future<void>.value();

  Set<String> get favorites => Set<String>.unmodifiable(_favorites);
  Set<String> get learned => Set<String>.unmodifiable(_learned);
  List<String> get recent => List<String>.unmodifiable(_recent);
  String get themePreference => _themePreference;
  String get politeStyle => _politeStyle;
  int get quizCount => _quizCount;
  LearningProgress get learning => _learning;
  double get audioVolume => _audioVolume;
  List<PhraseIssue> get phraseIssues => List.unmodifiable(_issues);

  Future<void> load() async {
    try {
      _preferences = await SharedPreferences.getInstance();
      Object? read(String key) => _preferences!.get(key);
      List<String> strings(String key) {
        final value = read(key);
        return value is List
            ? value
                  .whereType<String>()
                  .where((s) => s.isNotEmpty)
                  .toSet()
                  .toList()
            : <String>[];
      }

      _favorites
        ..clear()
        ..addAll(strings(_favoritesKey));
      _learned
        ..clear()
        ..addAll(strings(_learnedKey));
      _recent
        ..clear()
        ..addAll(strings(_recentKey).take(12));
      final theme = read(_themeKey);
      _themePreference = const {'system', 'light', 'dark'}.contains(theme)
          ? theme as String
          : 'system';
      final polite = read(_politeKey);
      _politeStyle = const {'male', 'female'}.contains(polite)
          ? polite as String
          : 'female';
      final quizCount = read(_quizKey);
      _quizCount = quizCount is int && quizCount >= 0 ? quizCount : 0;
      final volume = read(_volumeKey);
      _audioVolume = volume is num && volume.isFinite
          ? volume.toDouble().clamp(0.0, 1.0)
          : 1;
      _issues.clear();
      try {
        final savedIssues = read(_issuesKey);
        if (savedIssues is String) {
          final rows = jsonDecode(savedIssues) as List<dynamic>;
          for (final row in rows.take(100)) {
            final issue = PhraseIssue.tryParse(row);
            if (issue != null) _issues.add(issue);
          }
        }
      } catch (_) {
        _issues.clear();
      }
      try {
        _learning = LearningProgress();
        final saved = read(_learningKey);
        if (saved is String) {
          _learning = LearningProgress.fromJson(
            jsonDecode(saved) as Map<String, dynamic>,
          );
        }
      } catch (_) {
        _learning = LearningProgress();
      }
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
    await _saveValue(() async {
      await _preferences?.setString(_themeKey, value);
    });
    notifyListeners();
  }

  Future<void> setPoliteStyle(String value) async {
    if (!const {'male', 'female'}.contains(value)) return;
    _politeStyle = value;
    await _saveValue(() async {
      await _preferences?.setString(_politeKey, value);
    });
    notifyListeners();
  }

  Future<void> recordQuizCompletion() async {
    _quizCount += 1;
    await _saveValue(() async {
      await _preferences?.setInt(_quizKey, _quizCount);
    });
    notifyListeners();
  }

  Future<void> recordReview(
    String phraseId,
    LearningMode mode,
    int quality, {
    DateTime? now,
  }) async {
    _learning.record(phraseId, mode, quality, now ?? DateTime.now());
    if (quality >= 3) _learned.add(phraseId);
    notifyListeners();
    await _persistLearning();
    await _saveStringList(_learnedKey, _learned.toList()..sort());
  }

  Future<void> finishStudySession({String? lessonId}) async {
    _learning.finishSession(lessonId: lessonId);
    notifyListeners();
    await _persistLearning();
  }

  Future<void> setDailyGoal(int goal) async {
    if (!const {5, 10, 20}.contains(goal)) return;
    _learning.dailyGoal = goal;
    notifyListeners();
    await _persistLearning();
  }

  Future<void> completeOnboarding() async {
    _learning.onboardingComplete = true;
    notifyListeners();
    await _persistLearning();
  }

  Future<void> setAudioVolume(double volume) async {
    if (!volume.isFinite) return;
    _audioVolume = volume.clamp(0.0, 1.0);
    notifyListeners();
    await _saveValue(() async {
      await _preferences?.setDouble(_volumeKey, _audioVolume);
    });
  }

  Future<bool> savePhraseIssue({
    required String phraseId,
    required String thai,
    required String myanmar,
    required String description,
  }) {
    final trimmed = description.trim();
    if (trimmed.isEmpty || trimmed.length > 1000 || phraseId.isEmpty) {
      return Future<bool>.value(false);
    }
    final issue = PhraseIssue(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      phraseId: phraseId,
      thai: thai,
      myanmar: myanmar,
      description: trimmed,
      createdAt: DateTime.now(),
    );
    final result = _issueWrites.then((_) async {
      if (_issues.length >= 100 || _preferences == null) return false;
      final next = [issue, ..._issues];
      try {
        final saved = await _preferences!.setString(
          _issuesKey,
          jsonEncode(next.map((row) => row.toJson()).toList()),
        );
        if (!saved) return false;
        _issues
          ..clear()
          ..addAll(next);
        notifyListeners();
        return true;
      } catch (_) {
        return false;
      }
    });
    _issueWrites = result.then<void>((_) {});
    return result;
  }

  Future<bool> removePhraseIssue(String id) {
    final result = _issueWrites.then((_) async {
      final next = _issues.where((row) => row.id != id).toList();
      if (next.length == _issues.length || _preferences == null) return false;
      try {
        final saved = await _preferences!.setString(
          _issuesKey,
          jsonEncode(next.map((row) => row.toJson()).toList()),
        );
        if (!saved) return false;
        _issues
          ..clear()
          ..addAll(next);
        notifyListeners();
        return true;
      } catch (_) {
        return false;
      }
    });
    _issueWrites = result.then<void>((_) {});
    return result;
  }

  Future<void> _persistLearning() {
    final snapshot = jsonEncode(_learning.toJson());
    _learningWrites = _learningWrites.then(
      (_) => _saveValue(() async {
        await _preferences?.setString(_learningKey, snapshot);
      }),
    );
    return _learningWrites;
  }

  Future<void> _saveValue(Future<void> Function() write) async {
    try {
      await write();
    } catch (_) {
      // A failed write never prevents the current session or a UI update.
    }
  }

  Future<void> _saveStringList(String key, List<String> value) async {
    try {
      await _preferences?.setStringList(key, value);
    } catch (_) {
      // State remains available in memory for the current app session.
    }
  }
}
