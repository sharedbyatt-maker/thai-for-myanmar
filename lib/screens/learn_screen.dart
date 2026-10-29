import 'package:flutter/material.dart';

import '../data/phrase_repository.dart';
import '../learning/learning_progress.dart';
import '../learning/study_catalog.dart';
import '../services/app_state.dart';
import '../services/thai_playback_service.dart';
import '../widgets/playful_components.dart';
import 'phrase_browser_screen.dart';
import 'study_session_screen.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({
    required this.repository,
    required this.appState,
    required this.playbackService,
    this.onSearch,
    super.key,
  });
  final PhraseRepository repository;
  final AppState appState;
  final ThaiPlaybackService playbackService;
  final VoidCallback? onSearch;
  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  String? _categoryId;
  void _open(StudyLesson lesson) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => StudySessionScreen(
        repository: widget.repository,
        appState: widget.appState,
        playbackService: widget.playbackService,
        phrases: lesson.phrases,
        mode: LearningMode.flashcard,
        lessonId: lesson.id,
        title: '${lesson.category.my} • ${lesson.number}',
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.appState,
    builder: (context, _) {
      final lessons = StudyCatalog.lessons(widget.repository);
      final progress = widget.appState.learning;
      final pending = lessons.where(
        (l) => !progress.completedLessons.contains(l.id),
      );
      final next = pending.isEmpty ? lessons.first : pending.first;
      final category = widget.repository.categoryFor(
        _categoryId ?? next.category.id,
      )!;
      final unit = lessons.where((l) => l.category.id == category.id).toList();
      final done = unit
          .where((l) => progress.completedLessons.contains(l.id))
          .length;
      final colors = Theme.of(context).colorScheme;
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              MetricPill(
                icon: Icons.local_fire_department_rounded,
                label: '${progress.streak(DateTime.now())} ရက်ဆက်',
              ),
              MetricPill(
                icon: Icons.check_circle_rounded,
                label: '${progress.completedLessons.length} သင်ပြီး',
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'နည်းနည်းစီ၊ နေ့တိုင်း',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    const Text('နားထောင် · မှတ်မိ · ပြန်စမ်း'),
                  ],
                ),
              ),
              const ElephantBuddy(size: 96),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            color: colors.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'ဆက်သင်ရန် · ${next.category.my}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${next.phrases.length} စကားစု · သင်ခန်းစာ ${next.number}',
                  ),
                  const SizedBox(height: 14),
                  LiftButton(
                    label: 'အခု စလေ့ကျင့်မယ်',
                    onPressed: () => _open(next),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          DropdownButtonFormField<String>(
            key: ValueKey(category.id),
            initialValue: category.id,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'သင်ယူမှု လမ်းကြောင်း',
            ),
            items: widget.repository.categories
                .map(
                  (c) => DropdownMenuItem(
                    value: c.id,
                    child: Text('${c.icon} ${c.my}'),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _categoryId = v),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(category.icon, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.my,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text('$done / ${unit.length}'),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: unit.isEmpty ? 0 : done / unit.length,
            minHeight: 8,
          ),
          const SizedBox(height: 24),
          ...List.generate(unit.length, (i) {
            final lesson = unit[i];
            final complete = progress.completedLessons.contains(lesson.id);
            final current = lesson.id == next.id;
            return Column(
              children: [
                Align(
                  alignment: Alignment(i.isEven ? -.35 : .35, 0),
                  child: SizedBox(
                    width: 200,
                    child: Column(
                      children: [
                        if (current)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              'ဒီကနေ စမယ်',
                              style: TextStyle(
                                color: colors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        Semantics(
                          label:
                              '${category.my} သင်ခန်းစာ ${lesson.number}${complete ? " သင်ပြီး" : ""}',
                          button: true,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (complete
                                              ? const Color(0xFF267A65)
                                              : colors.primary)
                                          .withValues(alpha: .28),
                                  offset: const Offset(0, 7),
                                ),
                              ],
                            ),
                            child: SizedBox.square(
                              dimension: 82,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  shape: const CircleBorder(),
                                  padding: EdgeInsets.zero,
                                  backgroundColor: complete
                                      ? const Color(0xFF27866E)
                                      : current
                                      ? colors.primary
                                      : colors.secondaryContainer,
                                  foregroundColor: current || complete
                                      ? Colors.white
                                      : colors.onSecondaryContainer,
                                ),
                                onPressed: () => _open(lesson),
                                child: Icon(
                                  complete
                                      ? Icons.check_rounded
                                      : current
                                      ? Icons.play_arrow_rounded
                                      : Icons.star_rounded,
                                  size: 36,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'သင်ခန်းစာ ${lesson.number}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          '${lesson.phrases.length} စကားစု',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                if (i + 1 < unit.length)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: List.generate(
                        3,
                        (_) => Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: colors.outlineVariant,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
          const SizedBox(height: 24),
          Center(
            child: Icon(
              Icons.emoji_events_rounded,
              size: 44,
              color: colors.tertiary,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => PhraseBrowserScreen(
                  repository: widget.repository,
                  appState: widget.appState,
                  playbackService: widget.playbackService,
                  title: category.my,
                  categoryId: category.id,
                ),
              ),
            ),
            icon: const Icon(Icons.menu_book_rounded),
            label: const Text('ဒီအကြောင်းအရာရဲ့ စကားစုအားလုံး ကြည့်မယ်'),
          ),
          if (widget.onSearch != null)
            TextButton.icon(
              key: const ValueKey('home-search'),
              onPressed: widget.onSearch,
              icon: const Icon(Icons.search),
              label: const Text('စကားစုရှာရန်'),
            ),
        ],
      );
    },
  );
}
