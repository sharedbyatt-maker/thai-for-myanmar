import 'package:flutter/material.dart';

import '../data/phrase_repository.dart';
import '../learning/learning_progress.dart';
import '../learning/study_catalog.dart';
import '../services/app_state.dart';
import '../services/thai_playback_service.dart';
import 'phrase_browser_screen.dart';
import 'study_session_screen.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({
    required this.repository,
    required this.appState,
    required this.playbackService,
    super.key,
  });
  final PhraseRepository repository;
  final AppState appState;
  final ThaiPlaybackService playbackService;

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  String? _categoryId;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.appState,
    builder: (context, _) {
      final lessons = StudyCatalog.lessons(widget.repository);
      final completed = widget.appState.learning.completedLessons;
      final pending = lessons.where((lesson) => !completed.contains(lesson.id));
      final next = pending.isEmpty ? null : pending.first;
      final selectedCategory =
          _categoryId ?? widget.repository.categories.first.id;
      final selectedLessons = lessons.where(
        (l) => l.category.id == selectedCategory,
      );
      void open(StudyLesson lesson) => Navigator.push(
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
      return ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            'တစ်ခါ ၅ စကားစုနဲ့ စလေ့လာပါ',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'နားထောင်၊ အဓိပ္ပာယ်နားလည်၊ မှတ်မိသလား ပြန်စမ်းပါ။ ထိုင်းစာမဖတ်တတ်သေးလည်း မြန်မာအသံထွက်စာကို တွဲကြည့်နိုင်ပါတယ်။',
          ),
          const SizedBox(height: 18),
          if (next != null)
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'ဆက်သင်ရန် — ${next.category.my}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'သင်ခန်းစာ ${next.number} • ${next.phrases.length} စကားစု',
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => open(next),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('စသင်မယ်'),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: selectedCategory,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'သင်ချင်တဲ့အကြောင်းအရာ',
            ),
            items: widget.repository.categories
                .map(
                  (c) => DropdownMenuItem(
                    value: c.id,
                    child: Text('${c.icon} ${c.my}'),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _categoryId = value),
          ),
          const SizedBox(height: 16),
          ...selectedLessons.map(
            (lesson) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  leading: Icon(
                    completed.contains(lesson.id)
                        ? Icons.check_circle
                        : Icons.school_outlined,
                  ),
                  title: Text('သင်ခန်းစာ ${lesson.number}'),
                  subtitle: Text(
                    '${lesson.phrases.length} စကားစု • ${completed.contains(lesson.id) ? "သင်ပြီး" : "စသင်ရန်"}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => open(lesson),
                ),
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => PhraseBrowserScreen(
                  repository: widget.repository,
                  appState: widget.appState,
                  playbackService: widget.playbackService,
                  title: widget.repository.categoryFor(selectedCategory)!.my,
                  categoryId: selectedCategory,
                ),
              ),
            ),
            icon: const Icon(Icons.menu_book),
            label: const Text('ဒီအကြောင်းအရာရဲ့ စကားစုအားလုံး ကြည့်မယ်'),
          ),
        ],
      );
    },
  );
}
