import 'dart:async';

import 'package:flutter/material.dart';

import '../data/phrase_repository.dart';
import '../learning/learning_progress.dart';
import '../learning/sentence_chunks.dart';
import '../learning/study_catalog.dart';
import '../services/app_state.dart';
import '../services/thai_playback_service.dart';
import 'study_session_screen.dart';
import '../widgets/playful_components.dart';

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
    this.active = true,
    this.clock,
    super.key,
  });
  final PhraseRepository repository;
  final AppState appState;
  final ThaiPlaybackService playbackService;
  final bool active;
  final DateTime Function()? clock;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  Timer? _refresh;
  @override
  void initState() {
    super.initState();
    _startRefresh();
  }

  void _startRefresh() {
    _refresh?.cancel();
    if (widget.active) {
      _refresh = Timer.periodic(const Duration(minutes: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void didUpdateWidget(covariant QuizScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) _startRefresh();
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  LearningMode _mode = LearningMode.listening;
  ReviewFilter _filter = ReviewFilter.due;
  String _category = '';

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.appState,
    builder: (context, _) {
      final now = widget.clock?.call() ?? DateTime.now();
      final reviewed =
          widget.repository.phrases
              .where(
                (p) =>
                    widget.appState.learning.cardFor(
                      p.id,
                      LearningMode.flashcard,
                    ) !=
                    null,
              )
              .toList()
            ..sort(
              (a, b) => widget.appState.learning
                  .cardFor(a.id, LearningMode.flashcard)!
                  .due
                  .compareTo(
                    widget.appState.learning
                        .cardFor(b.id, LearningMode.flashcard)!
                        .due,
                  ),
            );
      final due = reviewed
          .where(
            (p) => widget.appState.learning
                .cardFor(p.id, LearningMode.flashcard)!
                .isDue(now),
          )
          .toList();
      final next = reviewed.isEmpty
          ? null
          : widget.appState.learning
                .cardFor(reviewed.first.id, LearningMode.flashcard)!
                .due
                .toLocal();
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
        now,
        limit: _mode == LearningMode.matching ? 4 : 10,
      );
      return ListView(
        padding: const EdgeInsets.all(18),
        children: [
          if (reviewed.isNotEmpty)
            Card(
              key: const ValueKey('scheduled-review'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'ကိုယ့်အတွက် ပြန်လေ့ကျင့်ရန်',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      due.isEmpty
                          ? 'အခု ပြန်လေ့ကျင့်ချိန် မရောက်သေးပါ။'
                          : '${due.length} စကားစု ပြန်လေ့ကျင့်ချိန် ရောက်ပါပြီ။',
                    ),
                    if (due.isEmpty && next != null)
                      Text(
                        'နောက်တစ်ကြိမ် · ${next.day}/${next.month} ${next.hour.toString().padLeft(2, "0")}:${next.minute.toString().padLeft(2, "0")}',
                      ),
                    if (due.isNotEmpty)
                      FilledButton.icon(
                        key: const ValueKey('start-scheduled-review'),
                        icon: const Icon(Icons.headphones_rounded),
                        label: const Text('နားထောင်ပြီး ပြန်ဖြေမယ်'),
                        onPressed: () {
                          unawaited(widget.playbackService.stop());
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => StudySessionScreen(
                                repository: widget.repository,
                                appState: widget.appState,
                                playbackService: widget.playbackService,
                                phrases: due.take(5).toList(),
                                mode: LearningMode.flashcard,
                                guided: true,
                                title: 'ကိုယ့်အတွက် ပြန်လေ့ကျင့်ရန်',
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          const Center(child: ElephantBuddy(size: 48)),
          Text(
            'ဘာလေ့ကျင့်မလဲ?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: 12,
              runSpacing: 12,
              children: LearningMode.values.map((mode) {
                final icon = switch (mode) {
                  LearningMode.flashcard => Icons.style_rounded,
                  LearningMode.listening => Icons.headphones_rounded,
                  LearningMode.meaning => Icons.touch_app_rounded,
                  LearningMode.reverseMeaning => Icons.swap_horiz_rounded,
                  LearningMode.matching => Icons.extension_rounded,
                  LearningMode.sentence => Icons.view_stream_rounded,
                };
                final active = _mode == mode;
                const accents = [
                  Color(0xFF6554CE),
                  Color(0xFF197B69),
                  Color(0xFF246BA6),
                  Color(0xFF9B6028),
                  Color(0xFFA34274),
                  Color(0xFF7044A8),
                ];
                final accent = accents[mode.index];
                return SizedBox(
                  width: (constraints.maxWidth - 12) / 2,
                  child: Card(
                    key: ValueKey('mode-${mode.name}'),
                    color: active
                        ? accent
                        : Theme.of(context).colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: active
                            ? accent
                            : Theme.of(context).colorScheme.outlineVariant,
                        width: active ? 2 : 1,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => setState(() => _mode = mode),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(
                              icon,
                              size: 30,
                              color: active
                                  ? Colors.white
                                  : Theme.of(context).brightness ==
                                        Brightness.dark
                                  ? Color.lerp(accent, Colors.white, .45)
                                  : accent,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              modeLabel(mode),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: active ? Colors.white : null,
                                  ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Icon(
                                active
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                size: 18,
                                color: active
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          ExpansionTile(
            title: const Text('စကားစု ရွေးချယ်ရန်'),
            children: [
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
            ],
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
