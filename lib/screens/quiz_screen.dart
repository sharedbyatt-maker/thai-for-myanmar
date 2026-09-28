import 'package:flutter/material.dart';

import '../data/phrase_repository.dart';
import '../models/phrase.dart';
import '../quiz/quiz_logic.dart';
import '../services/app_state.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({
    required this.repository,
    required this.appState,
    super.key,
  });

  final PhraseRepository repository;
  final AppState appState;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<QuizQuestion> _questions;
  int _index = 0;
  int _score = 0;
  Phrase? _selected;
  bool _myanmarToThai = false;
  bool _complete = false;

  @override
  void initState() {
    super.initState();
    _questions = QuizLogic.createQuestions(widget.repository.phrases);
  }

  void _start() {
    setState(() {
      _questions = QuizLogic.createQuestions(widget.repository.phrases);
      _index = 0;
      _score = 0;
      _selected = null;
      _complete = false;
    });
  }

  void _answer(Phrase option) {
    if (_selected != null) return;
    setState(() {
      _selected = option;
      if (QuizLogic.isCorrect(_questions[_index].phrase, option)) _score++;
    });
  }

  void _next() {
    if (_index + 1 == _questions.length) {
      setState(() => _complete = true);
      widget.appState.recordQuizCompletion();
      return;
    }
    setState(() {
      _index++;
      _selected = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return const Center(child: Text('Quiz အတွက် စကားစု မလုံလောက်သေးပါ။'));
    }
    if (_complete) return _buildComplete(context);
    final question = _questions[_index];
    final prompt = _myanmarToThai
        ? question.phrase.myanmar
        : question.phrase.thaiFor(widget.appState.politeStyle);
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('ထိုင်း → မြန်မာ'),
              selected: !_myanmarToThai,
              onSelected: (_) => setState(() => _myanmarToThai = false),
            ),
            ChoiceChip(
              label: const Text('မြန်မာ → ထိုင်း'),
              selected: _myanmarToThai,
              onSelected: (_) => setState(() => _myanmarToThai = true),
            ),
          ],
        ),
        const SizedBox(height: 14),
        LinearProgressIndicator(value: (_index + 1) / _questions.length),
        const SizedBox(height: 9),
        Text('မေးခွန်း ${_index + 1} / ${_questions.length} • မှန် $_score ခု'),
        const SizedBox(height: 22),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  _myanmarToThai
                      ? 'ထိုင်းလို ဘယ်လိုပြောမလဲ?'
                      : 'မြန်မာလို ဘာအဓိပ္ပာယ်လဲ?',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 14),
                Text(
                  prompt,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(fontSize: 28),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...question.options.map((option) {
          final isSelected = _selected?.id == option.id;
          final isAnswer = question.phrase.id == option.id;
          final answered = _selected != null;
          final background = !answered
              ? null
              : isAnswer
              ? Theme.of(context).colorScheme.primaryContainer
              : isSelected
              ? Theme.of(context).colorScheme.errorContainer
              : null;
          return Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Card(
              color: background,
              child: ListTile(
                title: Text(
                  _myanmarToThai
                      ? option.thaiFor(widget.appState.politeStyle)
                      : option.myanmar,
                ),
                trailing: answered && isAnswer
                    ? const Icon(Icons.check_circle_rounded)
                    : null,
                onTap: () => _answer(option),
              ),
            ),
          );
        }),
        if (_selected != null) ...[
          const SizedBox(height: 4),
          Text(
            QuizLogic.isCorrect(question.phrase, _selected!)
                ? 'မှန်ပါတယ်။'
                : 'အဖြေမှန်က ${_myanmarToThai ? question.phrase.thaiFor(widget.appState.politeStyle) : question.phrase.myanmar} ပါ။',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: _next,
            child: Text(
              _index + 1 == _questions.length ? 'ရလဒ်ကြည့်ရန်' : 'နောက်တစ်ခု',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildComplete(BuildContext context) {
    final percent = (_score * 100 / _questions.length).round();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              'လေ့ကျင့်ခန်း ပြီးပါပြီ',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('မှန်ကန်မှု $percent%  •  $_score / ${_questions.length} ခု'),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _start,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('ထပ်လေ့ကျင့်မယ်'),
            ),
          ],
        ),
      ),
    );
  }
}
