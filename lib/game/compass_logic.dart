import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'game_config.dart';
import 'models.dart';

/// Pure functions behind the compass. No I/O, no widgets.
class CompassLogic {
  const CompassLogic._();

  /// Completion ratio per direction for the given steps.
  static Map<StepCategory, double> fillByCategory(List<RoutineStep> steps) {
    final result = <StepCategory, double>{
      for (final c in StepCategory.values) c: 0.0,
    };
    for (final c in StepCategory.values) {
      final inCat = steps.where((s) => s.category == c).toList(growable: false);
      if (inCat.isEmpty) continue;
      final done = inCat.where((s) => s.done).length;
      result[c] = done / inCat.length;
    }
    return result;
  }

  /// Sum of the per-direction unit vectors weighted by completion.
  static Offset imbalanceVector(Map<StepCategory, double> fill) {
    var dx = 0.0;
    var dy = 0.0;
    for (final entry in fill.entries) {
      dx += entry.key.unit.dx * entry.value;
      dy += entry.key.unit.dy * entry.value;
    }
    return Offset(dx, dy);
  }

  /// Needle bearing in radians. 0 points east, grows clockwise on screen.
  static double needleAngle(Offset vector) {
    if (vector.distance < 0.0001) return -math.pi / 2; // rest at north
    return math.atan2(vector.dy, vector.dx);
  }

  /// Needle length 0..1 — how far the day leans off centre.
  static double needleLean(Offset vector) =>
      math.min(1.0, vector.distance).clamp(0.0, 1.0);

  /// 100 only when the day is both complete and evenly spread.
  static int balanceScore(List<RoutineStep> steps) {
    if (steps.isEmpty) return 0;
    final fill = fillByCategory(steps);
    final lean = needleLean(imbalanceVector(fill));
    final donePct = steps.where((s) => s.done).length / steps.length;
    return (100 * (1 - lean) * (0.35 + 0.65 * donePct)).round().clamp(0, 100);
  }

  /// Direction the day leans towards, or null when it is even.
  static StepCategory? leaning(Map<StepCategory, double> fill) {
    final vector = imbalanceVector(fill);
    if (vector.distance < 0.35) return null;
    StepCategory? best;
    var bestDot = 0.0;
    for (final c in StepCategory.values) {
      final dot = c.unit.dx * vector.dx + c.unit.dy * vector.dy;
      if (dot > bestDot) {
        bestDot = dot;
        best = c;
      }
    }
    return best;
  }

  static DayRecord recordFor(DateTime day, List<RoutineStep> steps) {
    final fill = fillByCategory(steps);
    return DayRecord(
      isoDate: isoDay(day),
      done: steps.where((s) => s.done).length,
      total: steps.length,
      perCategory: fill,
      balance: balanceScore(steps),
    );
  }

  /// Consecutive calendar days ending today that logged at least one step.
  static int streakFrom(List<DayRecord> history, DateTime today) {
    final byDate = <String, DayRecord>{
      for (final r in history) r.isoDate: r,
    };
    var streak = 0;
    var cursor = DateTime(today.year, today.month, today.day);
    for (var i = 0; i < AppConfig.historyDays + 1; i++) {
      final record = byDate[isoDay(cursor)];
      if (record == null || record.done == 0) break;
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Seven completion ratios, Monday first, for the week containing [today].
  static List<double> weekRatios(List<DayRecord> history, DateTime today) {
    final byDate = <String, DayRecord>{
      for (final r in history) r.isoDate: r,
    };
    final monday = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: today.weekday - 1));
    return List<double>.generate(7, (i) {
      final record = byDate[isoDay(monday.add(Duration(days: i)))];
      return record == null ? 0.0 : record.donePct.clamp(0.0, 1.0);
    }, growable: false);
  }

  static RoutineKind activeKindAt(DateTime now) =>
      now.hour < AppConfig.eveningStartHour
          ? RoutineKind.morning
          : RoutineKind.evening;

  static String isoDay(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static const List<String> _weekdays = <String>[
    'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN',
  ];
  static const List<String> _months = <String>[
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];

  /// e.g. `TUE · 29 SEP`
  static String headerDate(DateTime d) =>
      '${_weekdays[d.weekday - 1]} · ${d.day} ${_months[d.month - 1]}';

  static String weekdayLetter(int index) => _weekdays[index % 7].substring(0, 1);
}
