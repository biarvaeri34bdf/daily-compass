import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../assets.dart';
import '../game/compass_logic.dart';
import '../game/models.dart';
import '../game/storage.dart';
import '../theme.dart';
import '../widgets/app_background.dart';
import '../widgets/compass_dial.dart';
import '../widgets/primary_button.dart';
import '../widgets/stat_card.dart';
import 'sheets/routine_editor_sheet.dart';
import 'sheets/settings_sheet.dart';

/// Archetype M4 — asymmetric editorial. Hero wordmark left, dial pushed
/// right, CTA anchored above the bottom edge.
class MenuScreen extends StatefulWidget {
  const MenuScreen({
    super.key,
    required this.kind,
    required this.onStart,
    required this.onKindChanged,
  });

  final RoutineKind kind;
  final VoidCallback onStart;
  final ValueChanged<RoutineKind> onKindChanged;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  final CompassStorage _storage = CompassStorage.instance;

  late final AnimationController _entry;
  Routine _routine = Routine(kind: RoutineKind.morning, steps: <RoutineStep>[]);
  List<DayRecord> _history = <DayRecord>[];

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
    _read();
  }

  @override
  void didUpdateWidget(covariant MenuScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind) _reload();
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  void _read() {
    _routine = _storage.loadRoutine(widget.kind);
    _history = _storage.loadHistory();
  }

  void _reload() {
    if (!mounted) return;
    setState(_read);
  }

  Animation<double> _stagger(double begin, double end) => CurvedAnimation(
        parent: _entry,
        curve: Interval(begin, end, curve: Curves.easeOutCubic),
      );

  Future<void> _openEditor() async {
    final edited = await showModalBottomSheet<List<RoutineStep>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RoutineEditorSheet(
        routine: _routine,
        loadFailed: _storage.lastReadFailed,
        onRestoreDefaults: () {
          _storage.restoreDefaults(widget.kind);
          return _storage.loadRoutine(widget.kind).steps;
        },
      ),
    );
    if (edited == null) return;
    _storage.saveRoutine(Routine(kind: widget.kind, steps: edited));
    _reload();
  }

  Future<void> _openSettings() async {
    final action = await showModalBottomSheet<SettingsAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SettingsSheet(
        settings: _storage.loadSettings(),
        onChanged: _storage.saveSettings,
      ),
    );
    if (action == null) return;
    if (action == SettingsAction.resetToday) {
      _storage.resetToday();
    } else {
      _storage.resetAll();
    }
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final now = DateTime.now();
    final fill = CompassLogic.fillByCategory(_routine.steps);
    final vector = CompassLogic.imbalanceVector(fill);
    final streak = CompassLogic.streakFrom(_history, now);
    final balance = CompassLogic.balanceScore(_routine.steps);
    final dial = math.min(size.width - 64, 232.0);

    return Scaffold(
      body: AppBackground(
        asset: AppAssets.bgMenu,
        overlay: const <Color>[Color(0xF2F7F5F0), Color(0xE6F2EDE3)],
        baseColor: AppColors.background,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
              top: 44,
              left: 24,
              right: 20,
              bottom: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _microHeader(now),
                const SizedBox(height: 18),
                _fadeSlide(
                  _stagger(0.0, 0.5),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text(
                        'DAILY',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 3.0,
                          height: 0.98,
                          color: AppColors.ink,
                        ),
                      ),
                      const Text(
                        'COMPASS',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 3.0,
                          height: 0.98,
                          color: AppColors.primary,
                        ),
                      ),
                      const Hairline(width: 72, color: AppColors.accent),
                      const Text(
                        'MORNING AND EVENING RITUALS · OFFLINE',
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.6,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Never let the dial outgrow the slack the column left
                      // it — that is the only overflow risk on this screen.
                      final side = math.min(
                        dial,
                        math.min(constraints.maxWidth, constraints.maxHeight),
                      );
                      return Align(
                    alignment: Alignment.centerRight,
                    child: _fadeSlide(
                      _stagger(0.2, 0.7),
                      CompassDial(
                        fill: fill,
                        needleAngle: CompassLogic.needleAngle(vector),
                        needleLean: CompassLogic.needleLean(vector),
                        size: side,
                        roseSize: side * 0.57,
                        center: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              '${_routine.doneCount}/${_routine.total}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            const Text(
                              'STEPS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.0,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                      );
                    },
                  ),
                ),
                _routineBadge(),
                const SizedBox(height: 14),
                if (streak > 0 && balance > 0)
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: StatCard(
                          value: '$streak',
                          label: 'day streak',
                          valueColor: AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          value: '$balance%',
                          label: 'balance',
                          valueColor: AppColors.primary,
                        ),
                      ),
                    ],
                  )
                else
                  const SizedBox.shrink(),
                const SizedBox(height: 16),
                // Hint sits above the CTA, never under it.
                const Text(
                  'TWO RITUALS · FOUR DIRECTIONS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.4,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 10),
                _fadeSlide(
                  _stagger(0.4, 1.0),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      PrimaryButton(
                        label: 'START ROUTINE',
                        icon: Icons.explore,
                        onTap: widget.onStart,
                      ),
                      const SizedBox(height: 10),
                      SecondaryButton(
                        label: widget.kind == RoutineKind.morning
                            ? 'SWITCH TO EVENING'
                            : 'SWITCH TO MORNING',
                        color: AppColors.primary,
                        onTap: () => widget.onKindChanged(widget.kind.other),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _microHeader(DateTime now) {
    return SizedBox(
      height: 44,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              CompassLogic.headerDate(now),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.0,
                color: AppColors.textMuted,
              ),
            ),
          ),
          _roundIcon(Icons.tune, _openEditor, 'Routine editor'),
          const SizedBox(width: 4),
          _roundIcon(Icons.settings_outlined, _openSettings, 'Settings'),
        ],
      ),
    );
  }

  Widget _roundIcon(IconData icon, VoidCallback onTap, String tooltip) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        onPressed: onTap,
        tooltip: tooltip,
        icon: Icon(icon, size: 22, color: AppColors.ink),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.7),
          shape: const CircleBorder(
            side: BorderSide(color: AppColors.hairline),
          ),
        ),
      ),
    );
  }

  Widget _routineBadge() {
    final isMorning = widget.kind == RoutineKind.morning;
    return Row(
      children: <Widget>[
        Image.asset(
          isMorning ? AppAssets.spriteSun : AppAssets.spriteMoon,
          width: 28,
          height: 28,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 10),
        Text(
          isMorning ? 'MORNING ROUTINE' : 'EVENING ROUTINE',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }

  Widget _fadeSlide(Animation<double> animation, Widget child) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, inner) => Opacity(
        opacity: animation.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - animation.value)),
          child: inner,
        ),
      ),
      child: child,
    );
  }
}
