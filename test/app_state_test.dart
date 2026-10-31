import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thai_for_myanmar/learning/learning_progress.dart';
import 'package:thai_for_myanmar/services/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'one corrupt preference does not discard intact learning or other settings',
    () async {
      final progress = LearningProgress()
        ..record(
          'greet_hello',
          LearningMode.flashcard,
          5,
          DateTime(2026, 10, 31),
        );
      SharedPreferences.setMockInitialValues({
        'thai_for_myanmar.favorites.v1': 17,
        'thai_for_myanmar.learned.v1': <String>['greet_hello'],
        'thai_for_myanmar.theme.v1': 'invalid',
        'thai_for_myanmar.polite.v1': 42,
        'thai_for_myanmar.quiz_count.v1': -5,
        'thai_for_myanmar.audio_volume.v1': double.nan,
        'thai_for_myanmar.learning.v1': jsonEncode(progress.toJson()),
      });
      final state = AppState();
      await state.load();
      expect(state.favorites, isEmpty);
      expect(state.learned, contains('greet_hello'));
      expect(state.learning.totalReviews, 1);
      expect(state.themePreference, 'system');
      expect(state.politeStyle, 'female');
      expect(state.quizCount, 0);
      expect(state.audioVolume, 1);
      await state.setPoliteStyle('male');
      final restored = AppState();
      await restored.load();
      expect(restored.politeStyle, 'male');
      expect(restored.learning.totalReviews, 1);
    },
  );

  test('incorrect practice does not mark a new phrase as learned', () async {
    final state = AppState();
    await state.load();
    await state.recordReview('greet_hello', LearningMode.meaning, 2);
    expect(state.learned, isEmpty);
    expect(state.learning.totalReviews, 1);
    await state.recordReview('greet_hello', LearningMode.meaning, 5);
    expect(state.learned, contains('greet_hello'));
  });

  test(
    'learning state persists without replacing existing favorites',
    () async {
      final state = AppState();
      await state.load();
      await state.toggleFavorite('greet_hello');
      await state.recordReview(
        'greet_hello',
        LearningMode.meaning,
        5,
        now: DateTime(2026, 10, 13),
      );
      await state.setDailyGoal(20);
      await state.setAudioVolume(0.4);
      await state.completeOnboarding();
      await state.finishStudySession(lessonId: 'greetings:greet_hello');
      final restored = AppState();
      await restored.load();
      expect(restored.isFavorite('greet_hello'), isTrue);
      expect(restored.learning.totalReviews, 1);
      expect(
        restored.learning.completedLessons,
        contains('greetings:greet_hello'),
      );
      expect(restored.learning.dailyGoal, 20);
      expect(restored.learning.onboardingComplete, isTrue);
      expect(restored.audioVolume, 0.4);
    },
  );

  test(
    'favorites, learned phrases, theme, and quiz count persist locally',
    () async {
      final first = AppState();
      await first.load();
      await first.toggleFavorite('greet_hello');
      await first.markLearned('greet_hello');
      await first.setThemePreference('dark');
      await first.setPoliteStyle('male');
      await first.recordQuizCompletion();

      final restored = AppState();
      await restored.load();
      expect(restored.isFavorite('greet_hello'), isTrue);
      expect(restored.learned, contains('greet_hello'));
      expect(restored.themePreference, 'dark');
      expect(restored.politeStyle, 'male');
      expect(restored.quizCount, 1);
    },
  );

  test(
    'recent phrase history stays bounded and moves newest to the front',
    () async {
      final state = AppState();
      await state.load();
      for (var index = 0; index < 15; index++) {
        await state.remember('phrase_$index');
      }
      await state.remember('phrase_10');
      expect(state.recent, hasLength(12));
      expect(state.recent.first, 'phrase_10');
      expect(state.recent, isNot(contains('phrase_0')));
    },
  );

  test('phrase issues are saved locally and can be removed', () async {
    final state = AppState();
    await state.load();
    expect(
      await state.savePhraseIssue(
        phraseId: 'greet_hello',
        thai: 'สวัสดีค่ะ',
        myanmar: 'မင်္ဂလာပါ။',
        description: '  အသံထွက်ကို စစ်ပေးပါ  ',
      ),
      isTrue,
    );
    final restored = AppState();
    await restored.load();
    expect(restored.phraseIssues, hasLength(1));
    final issue = restored.phraseIssues.single;
    expect(issue.description, 'အသံထွက်ကို စစ်ပေးပါ');
    expect(issue.shareText, contains('Phrase ID: greet_hello'));
    expect(issue.shareText, contains('စစ်ပေးပါ'));
    expect(await restored.removePhraseIssue(issue.id), isTrue);
    final again = AppState();
    await again.load();
    expect(again.phraseIssues, isEmpty);
  });

  test('empty issues cannot be saved or shown as submitted', () async {
    final state = AppState();
    await state.load();
    expect(
      await state.savePhraseIssue(
        phraseId: 'greet_hello',
        thai: 'สวัสดีค่ะ',
        myanmar: 'မင်္ဂလာပါ။',
        description: '   ',
      ),
      isFalse,
    );
    expect(state.phraseIssues, isEmpty);
  });
}
