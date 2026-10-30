import 'package:flutter/material.dart';
import '../data/phrase_repository.dart';
import '../models/phrase.dart';
import '../learning/learning_progress.dart';
import '../learning/study_catalog.dart';
import '../services/app_state.dart';
import '../services/thai_playback_service.dart';
import '../widgets/playful_components.dart';
import '../widgets/daily_goal_card.dart';
import '../widgets/rank_card.dart';
import '../widgets/topic_picker.dart';
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
  final _scroll = ScrollController();
  final _headerKey = GlobalKey();
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

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
  Future<void> _chooseTopic(
    List<Object> rows,
    double headerExtent,
    double nodeExtent,
    String selected,
  ) async {
    final id = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * .9,
        child: TopicPicker(
          repository: widget.repository,
          appState: widget.appState,
          selected: selected,
        ),
      ),
    );
    if (!mounted || id == null) return;
    setState(() => _categoryId = id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final box = _headerKey.currentContext?.findRenderObject() as RenderBox?;
      var offset = box?.size.height ?? 0;
      for (final row in rows) {
        if (row is PhraseCategory && row.id == id) break;
        offset += row is PhraseCategory ? headerExtent : nodeExtent;
      }
      final target = offset.clamp(0.0, _scroll.position.maxScrollExtent);
      if (MediaQuery.disableAnimationsOf(context)) {
        _scroll.jumpTo(target);
      } else {
        _scroll.animateTo(
          target,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.appState,
    builder: (context, _) {
      final lessons = StudyCatalog.lessons(widget.repository);
      final progress = widget.appState.learning;
      final pending = lessons.where(
        (l) => !progress.completedLessons.contains(l.id),
      );
      final suggested = pending.isEmpty ? lessons.first : pending.first;
      final category = widget.repository.categoryFor(
        _categoryId ?? suggested.category.id,
      )!;
      final unit = lessons.where((l) => l.category.id == category.id).toList();
      final remaining = unit.where(
        (l) => !progress.completedLessons.contains(l.id),
      );
      final next = remaining.isEmpty ? unit.first : remaining.first;
      final rows = <Object>[
        for (final c in widget.repository.categories) ...[
          c,
          ...lessons.where((l) => l.category.id == c.id),
        ],
      ];
      final extra = (MediaQuery.textScalerOf(context).scale(14) - 14)
          .clamp(0, 35)
          .toDouble();
      final headerExtent = 150.0 + extra * 7;
      final nodeExtent = 210.0 + extra * 7;
      final colors = Theme.of(context).colorScheme;
      void choose() =>
          _chooseTopic(rows, headerExtent, nodeExtent, category.id);
      return CustomScrollView(
        key: const ValueKey('learning-path'),
        controller: _scroll,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              key: _headerKey,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RankCard(
                    repository: widget.repository,
                    appState: widget.appState,
                  ),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'နားထောင်၊ ပြောကြည့်',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.repository.categories.length} အကြောင်းအရာ · ${lessons.length} သင်ခန်းစာ',
                            ),
                          ],
                        ),
                      ),
                      const ElephantBuddy(size: 76),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DailyGoalCard(appState: widget.appState),
                  const SizedBox(height: 12),
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
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TopicHeader(
              extent: 92 + extra * 5,
              child: ColoredBox(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.route_rounded),
                      title: Text(
                        category.my,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: const Text('အကြောင်းအရာ ပြောင်းရန်'),
                      trailing: const Icon(Icons.keyboard_arrow_down_rounded),
                      onTap: choose,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverVariedExtentList(
            itemExtentBuilder: (index, _) => index >= rows.length
                ? null
                : rows[index] is PhraseCategory
                ? headerExtent
                : nodeExtent,
            delegate: SliverChildBuilderDelegate((context, index) {
              final row = rows[index];
              if (row is PhraseCategory) {
                final topic = lessons
                    .where((l) => l.category.id == row.id)
                    .toList();
                final done = topic
                    .where((l) => progress.completedLessons.contains(l.id))
                    .length;
                final n = widget.repository.categories.indexOf(row) + 1;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                  child: Card(
                    color: n.isEven
                        ? colors.secondaryContainer
                        : colors.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'အပိုင်း $n · $done / ${topic.length} သင်ပြီး',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                row.icon,
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  row.my,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              IconButton(
                                tooltip: '${row.my} စကားစုများ',
                                icon: const Icon(Icons.menu_book_outlined),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => PhraseBrowserScreen(
                                      repository: widget.repository,
                                      appState: widget.appState,
                                      playbackService: widget.playbackService,
                                      title: row.my,
                                      categoryId: row.id,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              final lesson = row as StudyLesson;
              final complete = progress.completedLessons.contains(lesson.id);
              final current = lesson.id == next.id;
              final left = lesson.number.isOdd;
              return Column(
                children: [
                  Align(
                    alignment: Alignment(left ? -.22 : .22, 0),
                    child: SizedBox(
                      width: 220,
                      child: Column(
                        children: [
                          SizedBox(
                            height: 26 + extra,
                            child: current
                                ? Text(
                                    'ဒီကနေ စမယ်',
                                    style: TextStyle(
                                      color: colors.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  )
                                : null,
                          ),
                          Semantics(
                            label:
                                '${lesson.category.my} သင်ခန်းစာ ${lesson.number}${complete ? " သင်ပြီး" : ""}',
                            button: true,
                            excludeSemantics: true,
                            onTap: () => _open(lesson),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (complete
                                                ? const Color(0xFF27866E)
                                                : colors.primary)
                                            .withValues(alpha: .28),
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: SizedBox.square(
                                dimension: 78,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    shape: const CircleBorder(),
                                    padding: EdgeInsets.zero,
                                    backgroundColor: complete
                                        ? const Color(0xFF27866E)
                                        : current
                                        ? colors.primary
                                        : colors.secondaryContainer,
                                    foregroundColor: complete || current
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
                                    size: 34,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
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
                  const Spacer(),
                  if (index + 1 < rows.length && rows[index + 1] is StudyLesson)
                    SizedBox(
                      height: 32,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _PathLink(
                          left: left,
                          color: colors.outlineVariant,
                        ),
                      ),
                    ),
                ],
              );
            }, childCount: rows.length),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    color: colors.tertiary,
                    size: 56,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ကိုယ့်အရှိန်နဲ့ ကိုယ်သင်ပါ',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'အကြောင်းအရာတိုင်းကို အချိန်မရွေး ဖွင့်လို့ရပါတယ်။',
                    textAlign: TextAlign.center,
                  ),
                  TextButton.icon(
                    onPressed: () => _scroll.animateTo(
                      0,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                    ),
                    icon: const Icon(Icons.vertical_align_top_rounded),
                    label: const Text('အစကို ပြန်သွားမယ်'),
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

class _TopicHeader extends SliverPersistentHeaderDelegate {
  _TopicHeader({required this.extent, required this.child});
  final double extent;
  final Widget child;
  @override
  double get minExtent => extent;
  @override
  double get maxExtent => extent;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => SizedBox.expand(child: child);
  @override
  bool shouldRebuild(covariant _TopicHeader oldDelegate) =>
      oldDelegate.extent != extent || oldDelegate.child != child;
}

class _PathLink extends CustomPainter {
  _PathLink({required this.left, required this.color});
  final bool left;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final start = size.width * (left ? .39 : .61);
    final end = size.width * (left ? .61 : .39);
    final path = Path()
      ..moveTo(start, 0)
      ..cubicTo(start, 20, end, 12, end, size.height);
    final paint = Paint()..color = color;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 11) {
        final t = metric.getTangentForOffset(d);
        if (t != null) canvas.drawCircle(t.position, 2.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PathLink oldDelegate) =>
      oldDelegate.left != left || oldDelegate.color != color;
}
