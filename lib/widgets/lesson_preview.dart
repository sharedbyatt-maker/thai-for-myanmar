import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../learning/study_catalog.dart';

/// A dismissible, node-anchored introduction. Opening it never earns progress.
Future<bool?> showLessonPreview({
  required BuildContext context,
  required StudyLesson lesson,
  required bool completed,
  required Rect anchor,
}) => showDialog<bool>(
  context: context,
  useSafeArea: false,
  barrierColor: Colors.black.withValues(alpha: .12),
  builder: (context) => CustomSingleChildLayout(
    delegate: _PreviewPosition(
      anchor: anchor,
      padding: MediaQuery.paddingOf(context),
      viewInsets: MediaQuery.viewInsetsOf(context),
    ),
    child: Semantics(
      namesRoute: true,
      label: 'သင်ခန်းစာ အကြိုကြည့်',
      child: _LessonPreviewCard(lesson: lesson, completed: completed),
    ),
  ),
);

class _LessonPreviewCard extends StatelessWidget {
  const _LessonPreviewCard({required this.lesson, required this.completed});
  final StudyLesson lesson;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    // Keep white copy legible in dark mode as well as the light theme.
    final background = completed
        ? const Color(0xFF24745F)
        : const Color(0xFF5B4FDB);
    return Material(
      key: const ValueKey('lesson-preview'),
      color: background,
      elevation: 12,
      shadowColor: background.withValues(alpha: .28),
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ExcludeSemantics(
                  child: Text(
                    lesson.category.icon,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'သင်ခန်းစာ ${lesson.number}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'ပိတ်မယ်',
                  color: Colors.white,
                  onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              lesson.category.my,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _Detail(
                  icon: Icons.style_rounded,
                  text: 'စကားစု ${lesson.phrases.length} ခု',
                ),
                _Detail(
                  icon: completed
                      ? Icons.check_circle_rounded
                      : Icons.bolt_rounded,
                  text: completed ? 'သင်ပြီး' : '+20 XP',
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              completed
                  ? 'မှတ်မိနေအောင် ပြန်လေ့ကျင့်ပါ။'
                  : 'ပထမဆုံး သင်ခန်းစာပြီးရင် +20 XP',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              key: const ValueKey('lesson-preview-start'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: background,
                minimumSize: const Size.fromHeight(54),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              icon: Icon(
                completed ? Icons.replay_rounded : Icons.play_arrow_rounded,
              ),
              label: Text(
                completed ? 'ပြန်လေ့ကျင့်မယ်' : 'စလေ့ကျင့်မယ်',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 19, color: Colors.white),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PreviewPosition extends SingleChildLayoutDelegate {
  const _PreviewPosition({
    required this.anchor,
    required this.padding,
    required this.viewInsets,
  });
  final Rect anchor;
  final EdgeInsets padding;
  final EdgeInsets viewInsets;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final width = math.min(
      360.0,
      math.max(0.0, constraints.maxWidth - padding.horizontal - 32),
    );
    return BoxConstraints(
      minWidth: width,
      maxWidth: width,
      maxHeight: math.max(
        0.0,
        constraints.maxHeight - padding.vertical - viewInsets.bottom - 32,
      ),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final left = padding.left + 16;
    final top = padding.top + 16;
    final right = math.max(
      left,
      size.width - padding.right - childSize.width - 16,
    );
    final bottom = math.max(
      top,
      size.height - padding.bottom - viewInsets.bottom - childSize.height - 16,
    );
    final below = anchor.bottom + 14;
    final above = anchor.top - childSize.height - 14;
    return Offset(
      (anchor.center.dx - childSize.width / 2).clamp(left, right),
      (below <= bottom
              ? below
              : above >= top
              ? above
              : below)
          .clamp(top, bottom),
    );
  }

  @override
  bool shouldRelayout(_PreviewPosition oldDelegate) =>
      anchor != oldDelegate.anchor ||
      padding != oldDelegate.padding ||
      viewInsets != oldDelegate.viewInsets;
}
