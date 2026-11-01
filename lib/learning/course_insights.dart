import 'course_catalog.dart';
import 'course_progress.dart';

/// Presentation derived from saved evidence; never awards XP or invents mastery.
class CourseInsights {
  CourseInsights(this.course, this.progress, this.now);
  final CourseCatalog course;
  final CourseProgress progress;
  final DateTime now;

  List<CourseUnit> get practicedUnits => course.units
      .where(
        (u) => u.lessons.every((l) => progress.completed.containsKey(l.id)),
      )
      .toList();
  int get delayedUnits =>
      practicedUnits.where((u) => (progress.probeStages[u.id] ?? 0) > 0).length;
  int get dueCards => progress.memory.entries
      .where((e) => course.lines.containsKey(e.key) && e.value.isDue(now))
      .length;
  bool get probeDue => course.dueUnitProbe(progress, now) != null;
  int get dueItems => dueCards + (probeDue ? 1 : 0);
  int completedIn(CourseUnit unit) =>
      unit.lessons.where((l) => progress.completed.containsKey(l.id)).length;

  String unitStatus(CourseUnit unit) {
    final stage = progress.probeStages[unit.id] ?? 0;
    if (stage >= 2) return 'အချိန်ခြား ပြန်စမ်းမှု ၂ ကြိမ် ပြီး';
    if (stage == 1) return 'အချိန်ခြား ပြန်စမ်းမှု ၁ ကြိမ် ပြီး';
    return 'လေ့ကျင့်ပြီး · အချိန်ခြား ပြန်စမ်းရန် ကျန်';
  }
}
