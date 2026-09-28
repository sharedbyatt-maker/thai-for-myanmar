import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thai_for_myanmar/services/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

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
}
