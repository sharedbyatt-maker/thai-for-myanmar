import 'dart:async';

import 'package:flutter/material.dart';

import '../data/phrase_repository.dart';
import '../learning/learning_progress.dart';
import '../learning/sentence_chunks.dart';
import '../learning/study_catalog.dart';
import '../services/app_state.dart';
import '../services/thai_playback_service.dart';
import 'study_session_screen.dart';

String modeLabel(LearningMode mode) => switch (mode) {
  LearningMode.flashcard => 'စာကတ်',
  LearningMode.meaning => 'အဓိပ္ပာယ်ရွေး',
  LearningMode.reverseMeaning => 'မြန်မာ → ထိုင်း',
  LearningMode.listening => 'နားထောင်ပြီးရွေး',
  LearningMode.matching => 'အတွဲချိတ်',
  LearningMode.sentence => 'စာကြောင်းစီ',
};

String filterLabel(ReviewFilter filter) => switch (filter) {
  ReviewFilter.due => 'ဒီနေ့ပြန်လေ့ကျင့်ရန်',
  ReviewFilter.fresh => 'အသစ်သင်ရန်',
  ReviewFilter.difficult => 'ခက်တဲ့စကားစု',
  ReviewFilter.favorites => 'သိမ်းထားတာ',
  ReviewFilter.all => 'အားလုံး',
};

class QuizScreen extends StatefulWidget {
  const QuizScreen({
    required this.repository,
    required this.appState,
    required this.playbackService,
    super.key,
  });
  final PhraseRepository repository;
  final AppState appState;
  final ThaiPlaybackService playbackService;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  LearningMode _mode = LearningMode.flashcard;
  ReviewFilter _filter = ReviewFilter.due;
  String _category = '';

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.appState,
    builder: (context, _) {
      final source = widget.repository.phrases
          .where(
            (p) =>
                (_category.isEmpty || p.categoryId == _category) &&
                (_mode != LearningMode.sentence ||
                    sentenceChunks(p, widget.appState.politeStyle) != null),
          )
          .toList();
      final selected = StudyCatalog.select(
        source,
        widget.appState.learning,
        _mode,
        _filter,
        widget.appState.favorites,
        DateTime.now(),
        limit: _mode == LearningMode.matching ? 4 : 10,
      );
      return ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            'ကိုယ့်အတွက် လေ့ကျင့်ခန်း',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'ပုံစံနဲ့ စကားစုကို အရင်ရွေးပြီး လေ့ကျင့်ပါ။ ရလဒ်အလိုက် နောက်တစ်ခါ ပြန်မေးပေးမယ်။',
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: LearningMode.values
                .map(
                  (mode) => ChoiceChip(
                    label: Text(modeLabel(mode)),
                    selected: _mode == mode,
                    onSelected: (_) => setState(() => _mode = mode),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: _category,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'အကြောင်းအရာ'),
            items: [
              const DropdownMenuItem(
                value: '',
                child: Text('အကြောင်းအရာအားလုံး'),
              ),
              ...widget.repository.categories.map(
                (c) => DropdownMenuItem(
                  value: c.id,
                  child: Text('${c.icon} ${c.my}'),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _category = value ?? ''),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ReviewFilter.values
                .map(
                  (filter) => ChoiceChip(
                    label: Text(filterLabel(filter)),
                    selected: _filter == filter,
                    onSelected: (_) => setState(() => _filter = filter),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 22),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${selected.length} စကားစုနဲ့ လေ့ကျင့်မယ်',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (_mode == LearningMode.flashcard)
                    const Text(
                      'အဓိပ္ပာယ်ကို ဖော်ကြည့်ပြီး ကိုယ်မှတ်မိမှုကို အမှန်အတိုင်း ရွေးပါ။',
                    ),
                  if (_mode == LearningMode.listening)
                    const Text(
                      'ထိုင်းအသံရတဲ့စက်မှာ နားထောင်ပြီး မြန်မာအဖြေရွေးပါ။ အသံမရရင် အမှတ်မပေးဘဲ စာကတ်ပုံစံကို ပြောင်းနိုင်ပါတယ်။',
                    ),
                  if (_mode == LearningMode.sentence)
                    const Text(
                      'စစ်ထားတဲ့ စာကြောင်းအပိုင်းတွေကို စီပါ။ ဒီပုံစံက ထိုင်းစာ စဖတ်နေသူအတွက်ပါ။',
                    ),
                  if (selected.isEmpty)
                    const Text(
                      'ဒီရွေးချယ်မှုအတွက် စကားစုမရှိသေးပါ။ အခြားအကြောင်းအရာ သို့မဟုတ် အားလုံးကို ရွေးပါ။',
                    ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: selected.isEmpty
                        ? null
                        : () {
                            unawaited(widget.playbackService.stop());
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => StudySessionScreen(
                                  repository: widget.repository,
                                  appState: widget.appState,
                                  playbackService: widget.playbackService,
                                  phrases: selected,
                                  mode: _mode,
                                  title: modeLabel(_mode),
                                ),
                              ),
                            );
                          },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('စလေ့ကျင့်မယ်'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}
