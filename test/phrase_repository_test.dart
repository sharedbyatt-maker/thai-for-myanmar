import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thai_for_myanmar/data/phrase_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PhraseRepository repository;

  setUpAll(() async {
    repository = await PhraseRepository.load(rootBundle);
  });

  test('bundled content parses and all categories are used', () {
    expect(repository.phrases.length, greaterThanOrEqualTo(60));
    expect(repository.categories.length, greaterThanOrEqualTo(30));
    for (final category in repository.categories) {
      expect(
        repository.inCategory(category.id),
        isNotEmpty,
        reason: '${category.id} should have phrases',
      );
    }
  });

  test('offline search finds Myanmar, Thai, and English terms', () {
    expect(
      repository.search('ဗိုက်နာ').map((phrase) => phrase.id),
      contains('health_stomach'),
    );
    expect(
      repository.search('ปวดท้อง').map((phrase) => phrase.id),
      contains('health_stomach'),
    );
    expect(
      repository.search('stomachache').map((phrase) => phrase.id),
      contains('health_stomach'),
    );
  });

  test('search can be scoped to a situation', () {
    final results = repository.search('ကားခ', categoryId: 'taxi');
    expect(results.map((phrase) => phrase.id), contains('taxi_meter'));
    expect(results.map((phrase) => phrase.id), isNot(contains('money_price')));
  });

  test('male and female polite Thai variants are selected', () {
    final phrase = repository.phrases.firstWhere(
      (item) => item.id == 'greet_hello',
    );
    expect(phrase.thaiFor('male'), 'สวัสดีครับ');
    expect(phrase.thaiFor('female'), 'สวัสดีค่ะ');
  });
}
