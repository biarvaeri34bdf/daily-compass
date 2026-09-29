import 'package:flutter/material.dart';

import '../theme.dart';

enum StepCategory { mind, body, home, focus }

enum RoutineKind { morning, evening }

enum RoundEndReason { completed, timeUp, exited }

extension StepCategoryX on StepCategory {
  String get label => switch (this) {
        StepCategory.mind => 'MIND',
        StepCategory.body => 'BODY',
        StepCategory.home => 'HOME',
        StepCategory.focus => 'FOCUS',
      };

  /// Compass bearing letter for this direction.
  String get bearing => switch (this) {
        StepCategory.mind => 'N',
        StepCategory.body => 'E',
        StepCategory.home => 'S',
        StepCategory.focus => 'W',
      };

  Color get color => switch (this) {
        StepCategory.mind => AppColors.mind,
        StepCategory.body => AppColors.body,
        StepCategory.home => AppColors.home,
        StepCategory.focus => AppColors.focus,
      };

  /// Unit vector, screen coordinates (y grows downwards).
  Offset get unit => switch (this) {
        StepCategory.mind => const Offset(0, -1),
        StepCategory.body => const Offset(1, 0),
        StepCategory.home => const Offset(0, 1),
        StepCategory.focus => const Offset(-1, 0),
      };

  static StepCategory fromName(String? raw) => StepCategory.values.firstWhere(
        (c) => c.name == raw,
        orElse: () => StepCategory.mind,
      );
}

extension RoutineKindX on RoutineKind {
  String get label =>
      this == RoutineKind.morning ? 'MORNING ROUTINE' : 'EVENING ROUTINE';

  String get shortLabel => this == RoutineKind.morning ? 'MORNING' : 'EVENING';

  RoutineKind get other =>
      this == RoutineKind.morning ? RoutineKind.evening : RoutineKind.morning;

  static RoutineKind fromName(String? raw) => RoutineKind.values.firstWhere(
        (k) => k.name == raw,
        orElse: () => RoutineKind.morning,
      );
}

@immutable
class RoutineStep {
  const RoutineStep({
    required this.id,
    required this.title,
    required this.category,
    this.done = false,
  });

  final String id;
  final String title;
  final StepCategory category;
  final bool done;

  RoutineStep copyWith({String? title, StepCategory? category, bool? done}) {
    return RoutineStep(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      done: done ?? this.done,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'category': category.name,
        'done': done,
      };

  factory RoutineStep.fromJson(Map<String, dynamic> json) {
    return RoutineStep(
      id: (json['id'] as String?) ?? UniqueKey().toString(),
      title: (json['title'] as String?) ?? 'Untitled step',
      category: StepCategoryX.fromName(json['category'] as String?),
      done: (json['done'] as bool?) ?? false,
    );
  }
}

@immutable
class Routine {
  Routine({required this.kind, required List<RoutineStep> steps})
      // Always copy: a const literal seed would throw on the first mutation.
      : steps = List<RoutineStep>.of(steps);

  final RoutineKind kind;
  final List<RoutineStep> steps;

  int get total => steps.length;
  int get doneCount => steps.where((s) => s.done).length;
  double get donePct => total == 0 ? 0 : doneCount / total;

  Routine copyWith({List<RoutineStep>? steps}) =>
      Routine(kind: kind, steps: List<RoutineStep>.of(steps ?? this.steps));

  Map<String, dynamic> toJson() => <String, dynamic>{
        'kind': kind.name,
        'steps': steps.map((s) => s.toJson()).toList(growable: false),
      };

  factory Routine.fromJson(Map<String, dynamic> json) {
    final raw = (json['steps'] as List<dynamic>?) ?? const <dynamic>[];
    return Routine(
      kind: RoutineKindX.fromName(json['kind'] as String?),
      steps: raw
          .whereType<Map<String, dynamic>>()
          .map(RoutineStep.fromJson)
          .toList(),
    );
  }
}

@immutable
class DayRecord {
  DayRecord({
    required this.isoDate,
    required this.done,
    required this.total,
    required Map<StepCategory, double> perCategory,
    required this.balance,
  }) : perCategory = Map<StepCategory, double>.unmodifiable(perCategory);

  final String isoDate;
  final int done;
  final int total;

  /// Completion ratio 0..1 per compass direction.
  final Map<StepCategory, double> perCategory;
  final int balance;

  double get donePct => total == 0 ? 0 : done / total;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'isoDate': isoDate,
        'done': done,
        'total': total,
        'balance': balance,
        'perCategory': <String, double>{
          for (final entry in perCategory.entries) entry.key.name: entry.value,
        },
      };

  factory DayRecord.fromJson(Map<String, dynamic> json) {
    final raw =
        (json['perCategory'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    return DayRecord(
      isoDate: (json['isoDate'] as String?) ?? '',
      done: (json['done'] as int?) ?? 0,
      total: (json['total'] as int?) ?? 0,
      balance: (json['balance'] as int?) ?? 0,
      perCategory: <StepCategory, double>{
        for (final c in StepCategory.values)
          c: ((raw[c.name] as num?) ?? 0).toDouble(),
      },
    );
  }
}

@immutable
class RoundResult {
  const RoundResult({
    required this.kind,
    required this.reason,
    required this.record,
    required this.streak,
  });

  final RoutineKind kind;
  final RoundEndReason reason;
  final DayRecord record;
  final int streak;

  bool get isFullDay => record.total > 0 && record.done == record.total;
  bool get isMissed => record.done == 0;
}
