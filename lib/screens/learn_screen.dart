import 'package:flutter/material.dart';

import '../data/phrase_repository.dart';
import '../models/phrase.dart';
import '../learning/learning_progress.dart';
import '../learning/study_catalog.dart';
import '../services/app_state.dart';
import '../services/thai_playback_service.dart';
import '../learning/learner_rank.dart';
import '../widgets/daily_goal_card.dart';
import '../widgets/rank_card.dart';
import '../widgets/topic_picker.dart';
import '../widgets/lesson_preview.dart';
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
  final _scroll = ScrollController();
  final _headerKey = GlobalKey();
  bool _previewOpen = false;
  bool _positioned = false;
  bool _showJump = false;
  List<Object> _pathRows = [];
  double _unitExtent = 134;
  double _lessonExtent = 206;
  String? _currentLessonId;
  static const _unitColors = [
    Color(0xFF5B4FDB),
    Color(0xFF197B69),
    Color(0xFFA34274),
    Color(0xFF246BA6),
    Color(0xFF9B6028),
    Color(0xFF7044A8),
  ];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_handleScroll);
  }

  double get _statsExtent =>
      (_headerKey.currentContext?.findRenderObject() as RenderBox?)
          ?.size
          .height ??
      0;

  double _currentOffset() {
    var offset = _statsExtent;
    for (var i = 0; i < _pathRows.length; i++) {
      final row = _pathRows[i];
      if (row is StudyLesson && row.id == _currentLessonId) return offset;
      offset += row is PhraseCategory
          ? (i == 0 ? 0 : _unitExtent)
          : _lessonExtent;
    }
    return 0;
  }

  void _handleScroll() {
    if (!mounted || !_scroll.hasClients || _pathRows.isEmpty) return;
    var offset = _statsExtent;
    var active = widget.repository.categories.first.id;
    for (var i = 0; i < _pathRows.length; i++) {
      final row = _pathRows[i];
      if (row is PhraseCategory && _scroll.offset >= offset - 1) {
        active = row.id;
      }
      offset += row is PhraseCategory
          ? (i == 0 ? 0 : _unitExtent)
          : _lessonExtent;
    }
    final away =
        (_scroll.offset - _currentOffset()).abs() >
        _scroll.position.viewportDimension * .75;
    if (_categoryId != active || _showJump != away) {
      setState(() {
        _categoryId = active;
        _showJump = away;
      });
    }
  }

  void _goCurrent({bool initial = false}) {
    if (!mounted || !_scroll.hasClients) return;
    final offset = _currentOffset().clamp(
      0.0,
      _scroll.position.maxScrollExtent,
    );
    if (initial &&
        MediaQuery.sizeOf(context).height >= 600 &&
        offset < _scroll.position.viewportDimension * .6) {
      return;
    }
    if (initial || MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(offset);
    } else {
      _scroll.animateTo(
        offset,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Color _unitColor(PhraseCategory category) =>
      _unitColors[widget.repository.categories.indexOf(category) %
          _unitColors.length];

  Widget _unitBanner(
    BuildContext context,
    PhraseCategory category,
    List<StudyLesson> unit,
    StudyLesson next,
    VoidCallback choose, {
    bool compact = false,
  }) {
    final color = _unitColor(category);
    final done = unit
        .where((l) => widget.appState.learning.completedLessons.contains(l.id))
        .length;
    if (compact) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'အပိုင်း ${widget.repository.categories.indexOf(category) + 1} · $done/${unit.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Text(
                    '${category.icon} ${category.my}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'အကြောင်းအရာ ပြောင်းရန်',
              onPressed: choose,
              color: Colors.white,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
            ),
          ],
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.fromLTRB(18, 6, 10, 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .3),
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'အပိုင်း ${widget.repository.categories.indexOf(category) + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: '${category.my} လမ်းညွှန်',
                color: Colors.white,
                icon: const Icon(Icons.menu_book_rounded),
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
              ),
              IconButton(
                tooltip: 'အကြောင်းအရာ ပြောင်းရန်',
                color: Colors.white,
                onPressed: choose,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
            ],
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${category.icon} ${category.my}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: done / unit.length,
                  minHeight: 5,
                  color: Colors.white,
                  backgroundColor: Colors.white24,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$done/${unit.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Builder(
              builder: (anchorContext) => TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
                onPressed: () => _preview(next, anchorContext),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('သင်ခန်းစာ ကြည့်မယ်'),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
  Future<void> _preview(StudyLesson lesson, BuildContext anchorContext) async {
    if (_previewOpen) return;
    final box = anchorContext.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    _previewOpen = true;
    final start = await showLessonPreview(
      context: context,
      lesson: lesson,
      completed: widget.appState.learning.completedLessons.contains(lesson.id),
      anchor: box.localToGlobal(Offset.zero) & box.size,
    );
    _previewOpen = false;
    if (mounted && start == true) _open(lesson);
  }

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
        offset += row is PhraseCategory
            ? (row.id == widget.repository.categories.first.id
                  ? 0
                  : headerExtent)
            : nodeExtent;
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

  void _details(BuildContext context, bool rank) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: rank
            ? RankCard(
                repository: widget.repository,
                appState: widget.appState,
                showBadges: true,
              )
            : DailyGoalCard(appState: widget.appState),
      ),
    ),
  );

  Widget _stat(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    VoidCallback tap,
  ) => Semantics(
    label: '$label $value',
    button: true,
    excludeSemantics: true,
    onTap: tap,
    child: InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ],
        ),
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
      final compact = MediaQuery.sizeOf(context).height < 600;
      final headerExtent = 134.0 + extra * 7;
      final nodeExtent = 206.0 + extra * 7;
      final colors = Theme.of(context).colorScheme;
      _pathRows = rows;
      _unitExtent = headerExtent;
      _lessonExtent = nodeExtent;
      _currentLessonId = suggested.id;
      if (!_positioned) {
        _positioned = true;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _goCurrent(initial: true),
        );
      }
      void choose() =>
          _chooseTopic(rows, headerExtent, nodeExtent, category.id);
      return Stack(
        children: [
          CustomScrollView(
            key: const ValueKey('learning-path'),
            controller: _scroll,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  key: _headerKey,
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: _stat(
                          context,
                          Icons.local_fire_department_rounded,
                          '${progress.streak(DateTime.now())}',
                          'ရက်ဆက်',
                          () => _details(context, false),
                        ),
                      ),
                      Expanded(
                        child: _stat(
                          context,
                          Icons.bolt_rounded,
                          '${LearnerRank(widget.repository, progress).xp}',
                          'XP',
                          () => _details(context, true),
                        ),
                      ),
                      Expanded(
                        child: _stat(
                          context,
                          Icons.flag_rounded,
                          '${progress.reviewsOn(DateTime.now())}/${progress.dailyGoal}',
                          'ဒီနေ့',
                          () => _details(context, false),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TopicHeader(
                  extent: compact ? 100 + extra * 2 : 196 + extra * 7,
                  child: ColoredBox(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: _unitBanner(
                      context,
                      category,
                      unit,
                      next,
                      choose,
                      compact: compact,
                    ),
                  ),
                ),
              ),
              SliverVariedExtentList(
                itemExtentBuilder: (index, _) => index >= rows.length
                    ? null
                    : rows[index] is PhraseCategory
                    ? (index == 0 ? 0 : headerExtent)
                    : nodeExtent,
                delegate: SliverChildBuilderDelegate((context, index) {
                  final row = rows[index];
                  if (row is PhraseCategory) {
                    if (index == 0) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                      child: Card(
                        color: _unitColor(row).withValues(alpha: .10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
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
                                          playbackService:
                                              widget.playbackService,
                                          title: row.my,
                                          categoryId: row.id,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value:
                                    lessons
                                        .where(
                                          (l) =>
                                              l.category.id == row.id &&
                                              progress.completedLessons
                                                  .contains(l.id),
                                        )
                                        .length /
                                    lessons
                                        .where((l) => l.category.id == row.id)
                                        .length,
                                minHeight: 5,
                                color: _unitColor(row),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  final lesson = row as StudyLesson;
                  final complete = progress.completedLessons.contains(
                    lesson.id,
                  );
                  final current = lesson.id == suggested.id;
                  final accent = _unitColor(lesson.category);
                  final unitEnd =
                      index + 1 == rows.length ||
                      rows[index + 1] is PhraseCategory;
                  final left = lesson.number.isOdd;
                  return Column(
                    children: [
                      Stack(
                        children: [
                          Align(
                            alignment: Alignment(left ? -.22 : .22, 0),
                            child: SizedBox(
                              width: 220,
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 26 + extra * 2,
                                    child: current
                                        ? Text(
                                            complete
                                                ? 'ပြန်လေ့ကျင့်မယ်'
                                                : 'ဒီကနေ စမယ်',
                                            style: TextStyle(
                                              color: accent,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          )
                                        : null,
                                  ),
                                  Builder(
                                    builder: (anchorContext) => Semantics(
                                      label:
                                          '${lesson.category.my} သင်ခန်းစာ ${lesson.number}${complete ? " သင်ပြီး" : ""}',
                                      button: true,
                                      excludeSemantics: true,
                                      onTap: () =>
                                          _preview(lesson, anchorContext),
                                      child: Container(
                                        padding: const EdgeInsets.all(7),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: current
                                                ? accent
                                                : Colors.transparent,
                                            width: 3,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: accent.withValues(
                                                alpha: .28,
                                              ),
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
                                              backgroundColor:
                                                  complete || current
                                                  ? accent
                                                  : accent.withValues(
                                                      alpha: .14,
                                                    ),
                                              foregroundColor:
                                                  complete || current
                                                  ? Colors.white
                                                  : colors.brightness ==
                                                        Brightness.dark
                                                  ? colors.primary
                                                  : accent,
                                            ),
                                            key: ValueKey(
                                              'lesson-node-${lesson.id}',
                                            ),
                                            onPressed: () =>
                                                _preview(lesson, anchorContext),
                                            child: Icon(
                                              complete
                                                  ? (unitEnd
                                                        ? Icons
                                                              .workspace_premium_rounded
                                                        : Icons.check_rounded)
                                                  : current
                                                  ? Icons.play_arrow_rounded
                                                  : unitEnd
                                                  ? Icons.flag_rounded
                                                  : Icons.star_rounded,
                                              size: 34,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (current)
                                    Text(
                                      'သင်ခန်းစာ ${lesson.number}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall,
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (current)
                            Positioned(
                              top: 40,
                              left: left ? null : 14,
                              right: left ? 14 : null,
                              child: const ElephantBuddy(size: 58),
                            ),
                        ],
                      ),
                      const Spacer(),
                      if (index + 1 < rows.length &&
                          rows[index + 1] is StudyLesson)
                        SizedBox(
                          height: 32,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: _PathLink(
                              left: left,
                              color: accent.withValues(alpha: .35),
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
          ),
          if (_showJump)
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton.small(
                key: const ValueKey('jump-current-lesson'),
                tooltip: 'လက်ရှိ သင်ခန်းစာဆီ',
                onPressed: () => _goCurrent(),
                child: Icon(
                  _scroll.hasClients && _scroll.offset > _currentOffset()
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
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
