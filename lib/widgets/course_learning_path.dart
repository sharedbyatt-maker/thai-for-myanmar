import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../learning/course_catalog.dart';
import '../services/app_state.dart';
import '../services/thai_playback_service.dart';
import '../screens/course_lesson_screen.dart';
import 'lesson_preview.dart';
import 'playful_components.dart';

const coursePathColors = [
  Color(0xFF5B4FDB),
  Color(0xFF197B69),
  Color(0xFFA34274),
  Color(0xFF246BA6),
  Color(0xFF9B6028),
  Color(0xFF7044A8),
];
Color courseUnitColor(CourseUnit unit) =>
    coursePathColors[(unit.section - 1) % coursePathColors.length];

Color _pathInk(BuildContext context, Color color) =>
    Theme.of(context).brightness == Brightness.dark
    ? Color.lerp(color, Colors.white, .45)!
    : color;

Future<void> previewCourseLesson({
  required BuildContext context,
  required CourseCatalog course,
  required CourseUnit unit,
  required CourseLesson lesson,
  required AppState appState,
  required ThaiPlaybackService playbackService,
}) async {
  final box = context.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) return;
  final start = await showCourseLessonPreview(
    context: context,
    lesson: lesson,
    unit: unit,
    completed: appState.learning.course.completed.containsKey(lesson.id),
    anchor: box.localToGlobal(Offset.zero) & box.size,
    color: courseUnitColor(unit),
  );
  if (start != true || !context.mounted) return;
  await Navigator.push(
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
  );
}

class CourseLearningPath extends StatefulWidget {
  const CourseLearningPath({
    required this.course,
    required this.appState,
    required this.playbackService,
    required this.openUnit,
    required this.openHistory,
    super.key,
  });
  final CourseCatalog course;
  final AppState appState;
  final ThaiPlaybackService playbackService;
  final void Function(CourseUnit) openUnit;
  final VoidCallback openHistory;
  @override
  State<CourseLearningPath> createState() => _CourseLearningPathState();
}

class _CourseLearningPathState extends State<CourseLearningPath> {
  final _scroll = ScrollController();
  final _rows = <({CourseUnit unit, int? lesson})>[];
  final _offsets = <double>[];
  String? _visibleUnit;
  bool _positioned = false, _previewOpen = false;
  double _statsHeight = 68, _nodeHeight = 144, _dividerHeight = 80;
  String? _currentId;

  @override
  void initState() {
    super.initState();
    for (final unit in widget.course.units) {
      _rows.add((unit: unit, lesson: null));
      for (var i = 0; i < unit.lessons.length; i++) {
        _rows.add((unit: unit, lesson: i));
      }
    }
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  bool _done(CourseUnit u) => u.lessons.every(
    (l) => widget.appState.learning.course.completed.containsKey(l.id),
  );
  bool _available(CourseUnit u) => u.prerequisites.every(
    (id) => _done(widget.course.units.firstWhere((v) => v.id == id)),
  );
  double _extent(int index) =>
      _rows[index].lesson == null ? _dividerHeight : _nodeHeight;
  void _onScroll() {
    if (!_scroll.hasClients || _offsets.isEmpty) return;
    var unit = _rows.first.unit;
    for (var i = 0; i < _rows.length; i++) {
      if (_offsets[i] > _scroll.offset + 30) break;
      unit = _rows[i].unit;
    }
    if (_visibleUnit != unit.id) setState(() => _visibleUnit = unit.id);
  }

  void _jump(int index, {bool immediate = false}) {
    if (!_scroll.hasClients) return;
    final offset = _offsets[index].clamp(0.0, _scroll.position.maxScrollExtent);
    if (immediate || MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(offset);
    } else {
      _scroll.animateTo(
        offset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _goCurrent() {
    final index = _rows.indexWhere(
      (r) => r.lesson != null && r.unit.lessons[r.lesson!].id == _currentId,
    );
    if (index >= 0) _jump(index);
  }

  Future<void> _preview(
    BuildContext anchor,
    CourseUnit unit,
    CourseLesson lesson,
  ) async {
    if (_previewOpen) return;
    _previewOpen = true;
    try {
      await previewCourseLesson(
        context: anchor,
        course: widget.course,
        unit: unit,
        lesson: lesson,
        appState: widget.appState,
        playbackService: widget.playbackService,
      );
    } finally {
      _previewOpen = false;
    }
  }

  Future<void> _chooseUnit() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .7,
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'သင်ယူလမ်းကြောင်း',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              for (var i = 0; i < widget.course.units.length; i++)
                ListTile(
                  key: ValueKey('course-jump-${widget.course.units[i].id}'),
                  leading: Icon(
                    _done(widget.course.units[i])
                        ? Icons.check_circle_rounded
                        : _available(widget.course.units[i])
                        ? Icons.star_rounded
                        : Icons.lock_outline_rounded,
                  ),
                  title: Text('${i + 1} · ${widget.course.units[i].title}'),
                  onTap: () =>
                      Navigator.pop(context, widget.course.units[i].id),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected == null || !mounted) return;
    _jump(_rows.indexWhere((r) => r.unit.id == selected));
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.appState,
    builder: (context, _) {
      final progress = widget.appState.learning.course;
      final lessons = widget.course.units.expand((u) => u.lessons).toList();
      _currentId = lessons
          .firstWhere(
            (l) => !progress.completed.containsKey(l.id),
            orElse: () => lessons.last,
          )
          .id;
      final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
      _statsHeight = 64 * scale.clamp(1.0, 1.6);
      _nodeHeight = 144 * scale.clamp(1.0, 1.5);
      _dividerHeight = 80 * scale.clamp(1.0, 1.8);
      _offsets.clear();
      var offset = _statsHeight;
      for (var i = 0; i < _rows.length; i++) {
        _offsets.add(offset);
        offset += _extent(i);
      }
      if (!_positioned) {
        _positioned = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final index = _rows.indexWhere(
            (r) =>
                r.lesson != null && r.unit.lessons[r.lesson!].id == _currentId,
          );
          if (index > 1) _jump(index, immediate: true);
        });
      }
      final active = widget.course.units.firstWhere(
        (u) =>
            u.id ==
            (_visibleUnit ??
                _rows
                    .firstWhere(
                      (r) =>
                          r.lesson != null &&
                          r.unit.lessons[r.lesson!].id == _currentId,
                    )
                    .unit
                    .id),
      );
      final color = courseUnitColor(active);
      return Stack(
        children: [
          CustomScrollView(
            controller: _scroll,
            key: const ValueKey('course-main-path'),
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: _statsHeight,
                  child: Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16,
                      runSpacing: 4,
                      children: [
                        _Stat(
                          icon: Icons.local_fire_department_rounded,
                          color: const Color(0xFFD16D21),
                          value:
                              '${widget.appState.learning.streak(DateTime.now())}',
                        ),
                        _Stat(
                          icon: Icons.task_alt_rounded,
                          color: const Color(0xFF197B69),
                          value:
                              '${lessons.where((l) => progress.completed.containsKey(l.id)).length}/${lessons.length}',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _UnitHeader(
                  height: 132 * math.max(1.0, scale),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Color.lerp(color, Colors.black, .25)!,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 12, 8, 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'အပိုင်း ${active.section} · ယူနစ် ${widget.course.units.indexOf(active) + 1}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        active.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'ယူနစ် ရွေးမယ်',
                                      color: Colors.white,
                                      onPressed: _chooseUnit,
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'ယူနစ် လမ်းညွှန်',
                                      color: Colors.white,
                                      onPressed: () => widget.openUnit(active),
                                      icon: const Icon(Icons.menu_book_rounded),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverVariedExtentList(
                itemExtentBuilder: (index, _) =>
                    index < _rows.length ? _extent(index) : null,
                delegate: SliverChildBuilderDelegate((context, index) {
                  final row = _rows[index];
                  final u = row.unit;
                  final i = row.lesson;
                  if (i == null) {
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: TextButton(
                          key: ValueKey('course-unit-${u.id}'),
                          onPressed: () => widget.openUnit(u),
                          child: Row(
                            children: [
                              const Expanded(child: Divider()),
                              const SizedBox(width: 12),
                              Flexible(
                                flex: 3,
                                child: Text(
                                  u.title,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(child: Divider()),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  final lesson = u.lessons[i];
                  final complete = progress.completed.containsKey(lesson.id);
                  final unlocked =
                      _available(u) &&
                      (i == 0 ||
                          progress.completed.containsKey(u.lessons[i - 1].id));
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Builder(
                        builder: (anchor) => CoursePathNode(
                          nodeKey: ValueKey('course-lesson-${u.id}-${i + 1}'),
                          index: i,
                          height: _nodeHeight,
                          title: lesson.title,
                          color: courseUnitColor(u),
                          completed: complete,
                          current: !complete && lesson.id == _currentId,
                          locked: !unlocked,
                          last: i == u.lessons.length - 1,
                          icon: _lessonIcon(lesson),
                          onPressed: unlocked
                              ? (node) => _preview(node, u, lesson)
                              : (_) =>
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'အခြေခံ lesson ကို အရင်လေ့ကျင့်ပါ။',
                                        ),
                                      ),
                                    ),
                        ),
                      ),
                    ),
                  );
                }, childCount: _rows.length),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  child: Center(
                    child: TextButton.icon(
                      key: const ValueKey('legacy-learning-history'),
                      onPressed: widget.openHistory,
                      icon: const Icon(Icons.history),
                      label: const Text('အရင်သင်ခန်းစာနဲ့ မှတ်တမ်းများ'),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.small(
              key: const ValueKey('course-continue'),
              heroTag: 'course-current',
              tooltip: 'လက်ရှိသင်ခန်းစာကို ပြန်သွားမယ်',
              onPressed: _goCurrent,
              child: const Icon(Icons.my_location_rounded),
            ),
          ),
        ],
      );
    },
  );
}

IconData _lessonIcon(CourseLesson lesson) =>
    lesson.steps.any((s) => s['kind'] == 'reflect')
    ? Icons.emoji_events_rounded
    : lesson.steps.any((s) => s['kind'] == 'dialogue')
    ? Icons.forum_rounded
    : lesson.steps.any((s) => s['kind'] == 'build')
    ? Icons.extension_rounded
    : lesson.steps.any((s) => s['kind'] == 'choice')
    ? Icons.headphones_rounded
    : Icons.star_rounded;

class CoursePathNode extends StatelessWidget {
  const CoursePathNode({
    required this.index,
    required this.height,
    required this.title,
    required this.color,
    required this.completed,
    required this.current,
    required this.locked,
    required this.last,
    required this.icon,
    required this.onPressed,
    this.nodeKey,
    super.key,
  });
  final Key? nodeKey;
  final int index;
  final double height;
  final String title;
  final Color color;
  final bool completed, current, locked, last;
  final IconData icon;
  final void Function(BuildContext) onPressed;
  static const positions = [0.0, -.45, -.7, -.2, .4, .65, .2, -.4, 0.0];
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final travel = math.max(0.0, (width - 140) / 2);
      final dx = positions[index % positions.length] * travel;
      final fill = locked
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : completed
          ? const Color(0xFF197B69)
          : color;
      final foreground = locked
          ? Theme.of(context).colorScheme.onSurfaceVariant
          : Colors.white;
      return SizedBox(
        height: height,
        child: Stack(
          children: [
            if (!last)
              Positioned.fill(
                child: ExcludeSemantics(
                  child: CustomPaint(
                    painter: _Connector(
                      from: width / 2 + dx,
                      to:
                          width / 2 +
                          positions[(index + 1) % positions.length] * travel,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
              ),
            if (index % 4 == 2 && width >= 280)
              Positioned(
                top: 26,
                right: dx < 0 ? 24 : null,
                left: dx < 0 ? null : 24,
                child: const ElephantBuddy(size: 68),
              ),
            Align(
              alignment: Alignment.topCenter,
              child: Transform.translate(
                offset: Offset(
                  dx,
                  30 *
                      (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(
                        1.0,
                        1.5,
                      ),
                ),
                child: Builder(
                  builder: (anchor) => Semantics(
                    key: nodeKey,
                    button: true,
                    label:
                        '$title · ${completed
                            ? 'လေ့ကျင့်ပြီး'
                            : locked
                            ? 'သော့ခတ်ထား'
                            : 'စတင်ရန်'}',
                    onTap: () => onPressed(anchor),
                    child: ExcludeSemantics(
                      child: Tooltip(
                        message: title,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: current
                                ? Border.all(
                                    color: color.withValues(alpha: .55),
                                    width: 5,
                                  )
                                : null,
                          ),
                          child: Container(
                            width: 78,
                            height: 72,
                            decoration: BoxDecoration(
                              color: fill,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color.lerp(fill, Colors.black, .2)!,
                                  offset: const Offset(0, 7),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              shape: const CircleBorder(),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => onPressed(anchor),
                                child: Icon(
                                  completed
                                      ? Icons.check_rounded
                                      : locked
                                      ? Icons.lock_rounded
                                      : icon,
                                  size: 34,
                                  color: foreground,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (current)
              Align(
                alignment: Alignment.topCenter,
                child: Transform.translate(
                  offset: Offset(dx, 0),
                  child: Text(
                    'စတင်မယ်',
                    style: TextStyle(
                      color: _pathInk(context, color),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _Connector extends CustomPainter {
  const _Connector({required this.from, required this.to, required this.color});
  final double from, to;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(from, 76)
      ..cubicTo(
        from,
        size.height * .8,
        to,
        size.height * .7,
        to,
        size.height + 76,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: .45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_Connector old) =>
      old.from != from || old.to != to || old.color != color;
}

class _UnitHeader extends SliverPersistentHeaderDelegate {
  _UnitHeader({required this.height, required this.child});
  final double height;
  final Widget child;
  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => ColoredBox(
    color: Theme.of(context).scaffoldBackgroundColor,
    child: child,
  );
  @override
  bool shouldRebuild(_UnitHeader oldDelegate) =>
      oldDelegate.height != height || oldDelegate.child != child;
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.color, required this.value});
  final IconData icon;
  final Color color;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _pathInk(context, color), size: 24),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            color: _pathInk(context, color),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}
