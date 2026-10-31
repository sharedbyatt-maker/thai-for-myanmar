import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/phrase.dart';
import 'course_progress.dart';

class CourseLine {
  CourseLine(this.data);
  final Map<String, dynamic> data;
  String get id => data['id'] as String;
  String get my => data['my'] as String;
  String myFor(String style) =>
      data[style == 'male' ? 'myMale' : 'myFemale'] as String? ?? my;
  String get scene =>
      data['scene'] as String? ?? 'ဒီစကားလုံးကို အသံ၊ အဓိပ္ပာယ်နဲ့ တွဲလေ့လာပါ။';
  String thai(String style) => data[style] as String;
  List<String> parts(String style) =>
      List<String>.from((data['parts'] as Map)[style] as List? ?? []);
  String source(String style) =>
      (data['sources'] as Map)[style] as String? ?? '';
  Phrase phrase(String style) => Phrase(
    id: source(style).isEmpty ? id : source(style),
    categoryId: 'course',
    thai: thai(style),
    myanmar: my,
    pronunciation: '',
    english: '',
    keywords: const [],
    tags: const [],
  );
}

class CourseLesson {
  CourseLesson(this.data);
  final Map<String, dynamic> data;
  String get id => 'course-v2.1:${data['id']}';
  String get title => data['title'] as String;
  List<Map<String, dynamic>> get steps => (data['steps'] as List)
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
}

class CourseUnit {
  CourseUnit(this.data);
  final Map<String, dynamic> data;
  String get id => data['id'] as String;
  String get title => data['title'] as String;
  String get goal => data['goal'] as String;
  String get tips => data['tips'] as String;
  int get section => data['section'] as int;
  List<String> get prerequisites =>
      List<String>.from(data['prerequisites'] as List);
  List<String> get models => List<String>.from(data['models'] as List);
  List<CourseLesson> get lessons => (data['lessons'] as List)
      .map((e) => CourseLesson(Map<String, dynamic>.from(e as Map)))
      .toList();
}

class CourseCatalog {
  CourseCatalog.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != 2) {
      throw const FormatException('Invalid course version');
    }
    lines = (json['lines'] as Map).map(
      (k, v) => MapEntry(
        k as String,
        CourseLine(Map<String, dynamic>.from(v as Map)),
      ),
    );
    units = (json['units'] as List)
        .map((u) => CourseUnit(Map<String, dynamic>.from(u as Map)))
        .toList();
    sections = List<String>.from(json['sections'] as List);
    final known = <String>{};
    final lessonIds = <String>{};
    for (final unit in units) {
      if (!known.add(unit.id) ||
          unit.prerequisites.any(
            (id) => id == unit.id || !known.contains(id),
          )) {
        throw const FormatException('Invalid course prerequisites');
      }
      for (final lesson in unit.lessons) {
        if (!lessonIds.add(lesson.id) || lesson.steps.isEmpty) {
          throw const FormatException('Invalid course lesson');
        }
        for (final step in lesson.steps) {
          final ids = [
            if (step['line'] is String) step['line'] as String,
            ...List<String>.from(step['lines'] as List? ?? []),
          ];
          if (ids.any((id) => !lines.containsKey(id))) {
            throw const FormatException('Unknown course utterance');
          }
        }
      }
    }
  }
  late final Map<String, CourseLine> lines;
  late final List<CourseUnit> units;
  late final List<String> sections;
  static Future<CourseCatalog> load(AssetBundle bundle) async =>
      CourseCatalog.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(await bundle.loadString('assets/data/course_v2.json'))
              as Map,
        ),
      );

  Map<String, dynamic>? dueUnitProbe(CourseProgress progress, DateTime now) {
    for (final unit in units) {
      final completed = progress.completed[unit.lessons.last.id];
      final stage = progress.probeStages[unit.id] ?? 0;
      if (completed == null || stage >= 2) continue;
      if (now.toUtc().isBefore(
        completed.add(Duration(days: stage == 0 ? 1 : 7)),
      )) {
        continue;
      }
      return {
        'kind': 'choice',
        'line': unit.models.last,
        'review': true,
        'probeUnit': unit.id,
        'probeStage': stage + 1,
      };
    }
    return null;
  }

  List<CourseLine> choices(CourseUnit unit, CourseLine target) {
    final seen = <String>{target.my};
    return [
      target,
      ...unit.models
          .map((id) => lines[id]!)
          .where((line) => seen.add(line.my))
          .take(3),
    ];
  }
}
