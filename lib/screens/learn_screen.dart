import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/phrase_repository.dart';
import '../learning/course_catalog.dart';
import '../services/app_state.dart';
import '../services/thai_playback_service.dart';
import '../widgets/course_learning_path.dart';
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
      return CourseLearningPath(
        course: course,
        appState: widget.appState,
        playbackService: widget.playbackService,
        openUnit: (unit) => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => CourseUnitScreen(
              course: course,
              unit: unit,
              appState: widget.appState,
              playbackService: widget.playbackService,
            ),
          ),
        ),
        openHistory: () => Navigator.push(
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
      );
    },
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
            constraints: const BoxConstraints(maxWidth: 480),
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
                      return CoursePathNode(
                        nodeKey: ValueKey('course-lesson-${unit.id}-${i + 1}'),
                        index: i,
                        height:
                            144 *
                            (MediaQuery.textScalerOf(context).scale(14) / 14)
                                .clamp(1.0, 1.5),
                        title: lesson.title,
                        color: courseUnitColor(unit),
                        completed: complete,
                        current: unlocked && !complete,
                        locked: !unlocked,
                        last: i == unit.lessons.length - 1,
                        icon: i == unit.lessons.length - 1
                            ? Icons.emoji_events_rounded
                            : Icons.star_rounded,
                        onPressed: (anchor) => unlocked
                            ? previewCourseLesson(
                                context: anchor,
                                course: course,
                                unit: unit,
                                lesson: lesson,
                                appState: appState,
                                playbackService: playbackService,
                              )
                            : ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'အခြေခံ lesson ကို အရင်လေ့ကျင့်ပါ။',
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
