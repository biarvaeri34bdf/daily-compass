import 'dart:convert';
import 'dart:math' as math;

import 'compass_logic.dart';
import 'game_config.dart';
import 'models.dart';

/// Settings toggles surfaced in the Settings sheet.
class AppSettings {
  AppSettings({
    this.eveningReminder = true,
    this.haptics = true,
    this.weeklyHints = true,
  });

  bool eveningReminder;
  bool haptics;
  bool weeklyHints;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'eveningReminder': eveningReminder,
        'haptics': haptics,
        'weeklyHints': weeklyHints,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        eveningReminder: (json['eveningReminder'] as bool?) ?? true,
        haptics: (json['haptics'] as bool?) ?? true,
        weeklyHints: (json['weeklyHints'] as bool?) ?? true,
      );
}

/// Offline, in-process store. Everything is JSON-encoded through the same
/// codec a disk-backed implementation would use, so swapping the backing map
/// for a key/value plugin later is a drop-in change — and the app pulls in no
/// extra pub dependency today.
class CompassStorage {
  CompassStorage._();

  static final CompassStorage instance = CompassStorage._();

  static const String keyMorning = 'dc.routine.morning';
  static const String keyEvening = 'dc.routine.evening';
  static const String keyHistory = 'dc.history';
  static const String keySettings = 'dc.settings';

  final Map<String, String> _box = <String, String>{};

  /// True when the last read fell back to defaults because the stored blob
  /// could not be decoded. Drives the Routine Editor error state.
  bool lastReadFailed = false;

  bool _seeded = false;

  void ensureSeeded() {
    if (_seeded) return;
    _seeded = true;
    _box[keyMorning] = jsonEncode(_seedRoutine(RoutineKind.morning).toJson());
    _box[keyEvening] = jsonEncode(_seedRoutine(RoutineKind.evening).toJson());
    _box[keyHistory] = jsonEncode(
      _seedHistory().map((r) => r.toJson()).toList(growable: false),
    );
    _box[keySettings] = jsonEncode(AppSettings().toJson());
  }

  String _keyFor(RoutineKind kind) =>
      kind == RoutineKind.morning ? keyMorning : keyEvening;

  Routine loadRoutine(RoutineKind kind) {
    ensureSeeded();
    try {
      final raw = _box[_keyFor(kind)];
      if (raw == null) throw const FormatException('missing routine');
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final routine = Routine.fromJson(decoded);
      lastReadFailed = false;
      return Routine(kind: kind, steps: routine.steps);
    } catch (_) {
      lastReadFailed = true;
      return _seedRoutine(kind);
    }
  }

  void saveRoutine(Routine routine) {
    try {
      _box[_keyFor(routine.kind)] = jsonEncode(routine.toJson());
      lastReadFailed = false;
    } catch (_) {
      // Persisting is best-effort; the in-memory model stays authoritative.
    }
  }

  List<DayRecord> loadHistory() {
    ensureSeeded();
    try {
      final raw = _box[keyHistory];
      if (raw == null) return <DayRecord>[];
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(DayRecord.fromJson)
          .toList();
    } catch (_) {
      return <DayRecord>[];
    }
  }

  void saveRecord(DayRecord record) {
    try {
      final history = loadHistory()
        ..removeWhere((r) => r.isoDate == record.isoDate);
      history.add(record);
      history.sort((a, b) => a.isoDate.compareTo(b.isoDate));
      final trimmed = history.length > AppConfig.historyDays
          ? history.sublist(history.length - AppConfig.historyDays)
          : history;
      _box[keyHistory] =
          jsonEncode(trimmed.map((r) => r.toJson()).toList(growable: false));
    } catch (_) {
      // Ignore — history is a nicety, never a blocker for the round.
    }
  }

  AppSettings loadSettings() {
    ensureSeeded();
    try {
      final raw = _box[keySettings];
      if (raw == null) return AppSettings();
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return AppSettings();
    }
  }

  void saveSettings(AppSettings settings) {
    try {
      _box[keySettings] = jsonEncode(settings.toJson());
    } catch (_) {
      // Best effort.
    }
  }

  /// Clears the check-ins on both routines and drops today from history.
  void resetToday() {
    for (final kind in RoutineKind.values) {
      final routine = loadRoutine(kind);
      saveRoutine(
        routine.copyWith(
          steps: routine.steps
              .map((s) => s.copyWith(done: false))
              .toList(growable: true),
        ),
      );
    }
    final today = CompassLogic.isoDay(DateTime.now());
    try {
      final history = loadHistory()..removeWhere((r) => r.isoDate == today);
      _box[keyHistory] =
          jsonEncode(history.map((r) => r.toJson()).toList(growable: false));
    } catch (_) {
      // Ignore.
    }
  }

  void resetAll() {
    _box.clear();
    _seeded = false;
    lastReadFailed = false;
    ensureSeeded();
  }

  void restoreDefaults(RoutineKind kind) {
    saveRoutine(_seedRoutine(kind));
    lastReadFailed = false;
  }

  Routine _seedRoutine(RoutineKind kind) {
    final seed = kind == RoutineKind.morning
        ? const <List<String>>[
            <String>['m1', 'Drink a glass of water', 'body'],
            <String>['m2', 'Ten minutes of stretching', 'body'],
            <String>['m3', 'Write three lines', 'mind'],
            <String>['m4', 'Make the bed', 'home'],
            <String>['m5', 'Plan top task', 'focus'],
            <String>['m6', 'Step outside', 'body'],
          ]
        : const <List<String>>[
            <String>['e1', 'Tidy one surface', 'home'],
            <String>['e2', 'Read ten pages', 'mind'],
            <String>['e3', 'Screens off', 'focus'],
            <String>['e4', 'Prep tomorrow bag', 'home'],
            <String>['e5', 'Slow breathing', 'body'],
          ];
    // List.of — never hand a const literal to something that gets mutated.
    return Routine(
      kind: kind,
      steps: List<RoutineStep>.of(
        seed.map(
          (row) => RoutineStep(
            id: row[0],
            title: row[1],
            category: StepCategoryX.fromName(row[2]),
          ),
        ),
      ),
    );
  }

  /// A short plausible history so the streak and the weekly ring are not
  /// empty on a fresh install.
  List<DayRecord> _seedHistory() {
    final today = DateTime.now();
    final rng = math.Random(7);
    return List<DayRecord>.generate(4, (i) {
      final day = today.subtract(Duration(days: i + 1));
      const total = 6;
      final done = 3 + rng.nextInt(3);
      final fill = <StepCategory, double>{
        StepCategory.mind: 0.4 + rng.nextDouble() * 0.6,
        StepCategory.body: 0.4 + rng.nextDouble() * 0.6,
        StepCategory.home: 0.3 + rng.nextDouble() * 0.6,
        StepCategory.focus: 0.3 + rng.nextDouble() * 0.6,
      };
      final lean = CompassLogic.needleLean(CompassLogic.imbalanceVector(fill));
      return DayRecord(
        isoDate: CompassLogic.isoDay(day),
        done: done,
        total: total,
        perCategory: fill,
        balance: (100 * (1 - lean) * (0.35 + 0.65 * done / total)).round(),
      );
    }, growable: true);
  }
}
