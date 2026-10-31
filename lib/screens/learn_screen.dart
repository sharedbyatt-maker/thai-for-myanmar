import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/phrase_repository.dart';
import '../learning/course_catalog.dart';
import '../services/app_state.dart';
import '../services/thai_playback_service.dart';
import 'course_lesson_screen.dart';
import 'legacy_learn_screen.dart';

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
  late Future<CourseCatalog> _catalog;
  @override
  void initState() {
    super.initState();
    _catalog = widget.repository.course != null
        ? Future.value(widget.repository.course)
        : CourseCatalog.load(rootBundle);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<CourseCatalog>(
    future: _catalog,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(
          child: FilledButton(
            onPressed: () =>
                setState(() => _catalog = CourseCatalog.load(rootBundle)),
            child: const Text('သင်ရိုး ပြန်ဖွင့်မယ်'),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final course = snapshot.data!;
      return AnimatedBuilder(
        animation: widget.appState,
        builder: (context, _) {
          final progress = widget.appState.learning.course;
          bool done(CourseUnit u) =>
              u.lessons.every((l) => progress.completed.containsKey(l.id));
          final next = course.units.firstWhere(
            (u) => !done(u),
            orElse: () => course.units.last,
          );
          final count = course.units.where(done).length;
          return ListView.builder(
            key: const ValueKey('course-main-path'),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
            itemCount: course.units.length + 2,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'လက်တွေ့သုံး ထိုင်းစကား',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            const Icon(Icons.school_rounded),
                          ],
                        ),
                        Text(
                          '$count / ${course.units.length} unit လေ့ကျင့်ပြီး',
                        ),
                        const SizedBox(height: 12),
                        Text(next.goal),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          key: const ValueKey('course-continue'),
                          onPressed: () => _openUnit(course, next),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: Text(
                            count == course.units.length
                                ? 'ပြန်လေ့ကျင့်မယ်'
                                : 'ဒီကနေ ဆက်သင်မယ်',
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'စာသားလေ့ကျင့်နိုင်ပါပြီ · အသံအချို့ ထည့်ရန်ကျန်',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (i == course.units.length + 1) {
                return TextButton.icon(
                  key: const ValueKey('legacy-learning-history'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('အရင်သင်ခန်းစာများ')),
                        body: LegacyLearnScreen(
                          repository: widget.repository,
                          appState: widget.appState,
                          playbackService: widget.playbackService,
                          onSearch: widget.onSearch,
                        ),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.history),
                  label: const Text('အရင်သင်ခန်းစာနဲ့ မှတ်တမ်းများ'),
                );
              }
              final u = course.units[i - 1];
              final previous = i > 1 ? course.units[i - 2] : null;
              final complete = u.lessons
                  .where((l) => progress.completed.containsKey(l.id))
                  .length;
              final available = u.prerequisites.every(
                (id) => done(course.units.firstWhere((v) => v.id == id)),
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (previous?.section != u.section)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 28, 6, 12),
                      child: Text(
                        'အပိုင်း ${u.section} · ${course.sections[u.section - 1]}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  Card(
                    child: ListTile(
                      key: ValueKey('course-unit-${u.id}'),
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        radius: 25,
                        child: Icon(
                          done(u)
                              ? Icons.check_rounded
                              : available
                              ? Icons.star_rounded
                              : Icons.lock_outline,
                        ),
                      ),
                      title: Text(
                        '${i.toString().padLeft(2, '0')}  ${u.title}',
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('$complete / ${u.lessons.length} lesson'),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openUnit(course, u),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    },
  );
  void _openUnit(CourseCatalog course, CourseUnit unit) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => CourseUnitScreen(
        course: course,
        unit: unit,
        appState: widget.appState,
        playbackService: widget.playbackService,
      ),
    ),
  );
}

class CourseUnitScreen extends StatelessWidget {
  const CourseUnitScreen({
    required this.course,
    required this.unit,
    required this.appState,
    required this.playbackService,
    super.key,
  });
  final CourseCatalog course;
  final CourseUnit unit;
  final AppState appState;
  final ThaiPlaybackService playbackService;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(unit.title)),
    body: AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final p = appState.learning.course;
        final missing = unit.prerequisites
            .where(
              (id) => !course.units
                  .firstWhere((u) => u.id == id)
                  .lessons
                  .every((l) => p.completed.containsKey(l.id)),
            )
            .toList();
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(unit.goal, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                ExpansionTile(
                  title: const Text('ဒီ unit အတွက် လမ်းညွှန်'),
                  tilePadding: EdgeInsets.zero,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(unit.tips),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (missing.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('လိုအပ်တဲ့ အခြေခံကို အရင်လေ့ကျင့်ကြမယ်။'),
                          const SizedBox(height: 8),
                          Text(
                            course.units
                                .firstWhere((u) => u.id == missing.first)
                                .title,
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => CourseUnitScreen(
                                  course: course,
                                  unit: course.units.firstWhere(
                                    (u) => u.id == missing.first,
                                  ),
                                  appState: appState,
                                  playbackService: playbackService,
                                ),
                              ),
                            ),
                            child: const Text('အခြေခံမှ စမယ်'),
                          ),
                        ],
                      ),
                    ),
                  ),
                for (var i = 0; i < unit.lessons.length; i++)
                  Builder(
                    builder: (context) {
                      final lesson = unit.lessons[i];
                      final complete = p.completed.containsKey(lesson.id);
                      final unlocked =
                          missing.isEmpty &&
                          (i == 0 ||
                              p.completed.containsKey(unit.lessons[i - 1].id));
                      return Card(
                        child: ListTile(
                          key: ValueKey('course-lesson-${unit.id}-${i + 1}'),
                          contentPadding: const EdgeInsets.all(14),
                          leading: CircleAvatar(
                            child: Icon(
                              complete
                                  ? Icons.check
                                  : unlocked
                                  ? Icons.play_arrow
                                  : Icons.lock_outline,
                            ),
                          ),
                          title: Text(lesson.title),
                          subtitle: Text(
                            complete
                                ? 'စာသားလေ့ကျင့်ပြီး · ပြန်လေ့ကျင့်နိုင်'
                                : unlocked
                                ? 'စတင်ရန်'
                                : 'အရင် lesson ကို ဆက်သင်ပါ',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: unlocked
                              ? () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => CourseLessonScreen(
                                      course: course,
                                      unit: unit,
                                      lesson: lesson,
                                      appState: appState,
                                      playbackService: playbackService,
                                    ),
                                  ),
                                )
                              : () =>
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'အခြေခံ lesson ကို အရင်လေ့ကျင့်ပါ။',
                                        ),
                                      ),
                                    ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
