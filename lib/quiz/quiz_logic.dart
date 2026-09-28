import 'dart:math';

import '../models/phrase.dart';

class QuizQuestion {
  const QuizQuestion({required this.phrase, required this.options});

  final Phrase phrase;
  final List<Phrase> options;
}

class QuizLogic {
  static List<QuizQuestion> createQuestions(
    List<Phrase> phrases, {
    int count = 5,
    Random? random,
  }) {
    if (phrases.length < 4) return const [];
    final rng = random ?? Random();
    final questions = List<Phrase>.from(phrases)..shuffle(rng);
    final selected = questions.take(min(count, questions.length));
    return selected.map((phrase) {
      final distractors = phrases.where((item) => item.id != phrase.id).toList()
        ..shuffle(rng);
      final options = <Phrase>[phrase, ...distractors.take(3)]..shuffle(rng);
      return QuizQuestion(phrase: phrase, options: options);
    }).toList(growable: false);
  }

  static bool isCorrect(Phrase question, Phrase selected) =>
      question.id == selected.id;
}
