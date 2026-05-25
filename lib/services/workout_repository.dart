import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

enum SensorType { timer, step, jump }

SensorType _parseSensor(String s) {
  switch (s) {
    case 'step':
      return SensorType.step;
    case 'jump':
      return SensorType.jump;
    default:
      return SensorType.timer;
  }
}

class Exercise {
  final String id;
  final String name;
  final String category; // 'low' | 'high'
  final SensorType sensor;
  final int targetSec;
  final int? targetSteps;
  final int? targetReps;
  final double met;
  final int kcalMin;
  final int kcalMax;
  final String detail;
  final bool sensorReady;

  const Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.sensor,
    required this.targetSec,
    required this.targetSteps,
    required this.targetReps,
    required this.met,
    required this.kcalMin,
    required this.kcalMax,
    required this.detail,
    required this.sensorReady,
  });

  factory Exercise.fromJson(Map<String, dynamic> j) => Exercise(
        id: j['id'] as String,
        name: j['name'] as String,
        category: j['category'] as String,
        sensor: _parseSensor(j['sensor'] as String),
        targetSec: (j['targetSec'] as num).toInt(),
        targetSteps: (j['targetSteps'] as num?)?.toInt(),
        targetReps: (j['targetReps'] as num?)?.toInt(),
        met: (j['met'] as num).toDouble(),
        kcalMin: (j['kcalMin'] as num).toInt(),
        kcalMax: (j['kcalMax'] as num).toInt(),
        detail: j['detail'] as String,
        sensorReady: j['sensorReady'] as bool? ?? false,
      );

  int kcalForWeight(int weightKg) {
    final minutes = targetSec / 60.0;
    return (met * weightKg * 3.5 / 200 * minutes).round();
  }
}

class WeekPlan {
  final int week;
  final String level;
  final String focus;
  final List<String> exerciseIds;
  final int dailyTargetMin;

  const WeekPlan({
    required this.week,
    required this.level,
    required this.focus,
    required this.exerciseIds,
    required this.dailyTargetMin,
  });

  factory WeekPlan.fromJson(Map<String, dynamic> j) => WeekPlan(
        week: (j['week'] as num).toInt(),
        level: j['level'] as String,
        focus: j['focus'] as String,
        exerciseIds: (j['exerciseIds'] as List).cast<String>(),
        dailyTargetMin: (j['dailyTargetMin'] as num).toInt(),
      );
}

class WorkoutRepository {
  static List<Exercise>? _exercisesCache;
  static List<WeekPlan>? _planCache;

  static Future<List<Exercise>> loadExercises() async {
    if (_exercisesCache != null) return _exercisesCache!;
    final raw = await rootBundle.loadString('assets/exercises.json');
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    _exercisesCache = list.map(Exercise.fromJson).toList();
    return _exercisesCache!;
  }

  static Future<List<WeekPlan>> loadPlan() async {
    if (_planCache != null) return _planCache!;
    final raw = await rootBundle.loadString('assets/weekly_plan.json');
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    _planCache = list.map(WeekPlan.fromJson).toList();
    return _planCache!;
  }

  static int currentWeek(DateTime ftueDate) {
    final ftueMidnight =
        DateTime(ftueDate.year, ftueDate.month, ftueDate.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = today.difference(ftueMidnight).inDays;
    return (days ~/ 7) + 1;
  }

  static WeekPlan planForWeek(List<WeekPlan> plans, int week) {
    if (week <= 0) return plans.first;
    if (week >= plans.last.week) return plans.last;
    return plans.firstWhere((p) => p.week == week, orElse: () => plans.last);
  }

  static List<Exercise> exercisesByIds(
    List<Exercise> all,
    List<String> ids,
  ) {
    final byId = {for (final e in all) e.id: e};
    return ids
        .map((id) => byId[id])
        .where((e) => e != null)
        .cast<Exercise>()
        .toList();
  }
}
