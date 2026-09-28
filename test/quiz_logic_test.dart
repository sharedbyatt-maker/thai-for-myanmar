import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thai_for_myanmar/data/phrase_repository.dart';
import 'package:thai_for_myanmar/quiz/quiz_logic.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('questions have one correct answer and unique distractors', () async {
    final repository = await PhraseRepository.load(rootBundle);
    final questions = QuizLogic.createQuestions(
      repository.phrases,
      count: 5,
      random: Random(7),
    );
    expect(questions, hasLength(5));
    for (final question in questions) {
      expect(question.options, hasLength(4));
      expect(question.options.map((item) => item.id).toSet(), hasLength(4));
      expect(
        question.options.where(
          (item) => QuizLogic.isCorrect(question.phrase, item),
        ),
        hasLength(1),
      );
    }
  });

  test('too few phrases returns no unanswerable quiz', () {
    expect(QuizLogic.createQuestions(const [], count: 5), isEmpty);
  });
}
