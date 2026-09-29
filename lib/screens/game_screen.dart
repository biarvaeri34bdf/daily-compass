import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../assets.dart';
import '../game/compass_logic.dart';
import '../game/game_config.dart';
import '../game/models.dart';
import '../game/storage.dart';
import '../theme.dart';
import '../widgets/app_background.dart';
import '../widgets/compass_dial.dart';
import '../widgets/primary_button.dart';
import '../widgets/routine_step_tile.dart';
import '../widgets/screen_header.dart';

/// Archetype G3 — split panel. Dial and step list on top, stats plus the
/// action button on a separate surface underneath.
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.kind,
    required this.onRoundEnd,
    required this.onExit,
  });

  final RoutineKind kind;
  final void Function(RoundResult) onRoundEnd;
  final VoidCallback onExit;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  final CompassStorage _storage = CompassStorage.instance;

  late final AnimationController _needle;
  late Animation<double> _needleAngle;

  Routine _routine = Routine(kind: RoutineKind.morning, steps: <RoutineStep>[]);
  Timer? _backstop;
  Timer? _completion;
  bool _engaged = false;
  bool _finished = false;
  double _currentAngle = -math.pi / 2;

  @override
  void initState() {
    super.initState();
    _routine = _storage.loadRoutine(widget.kind);
    _needle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _needleAngle = AlwaysStoppedAnimation<double>(_currentAngle);
    _armBackstop(AppConfig.idleResolveMs);
  }

  @override
  void dispose() {
    _backstop?.cancel();
    _completion?.cancel();
    _needle.dispose();
    super.dispose();
  }

  /// Passive runs resolve on the long timer; the first check-in swaps in a
  /// short one so a single tap still produces a result. Later taps do NOT
  /// re-arm it, otherwise an active tapper resets it forever.
  void _armBackstop(int ms) {
    _backstop?.cancel();
    _backstop = Timer(Duration(milliseconds: ms), () {
      _finish(RoundEndReason.timeUp);
    });
  }

  void _toggle(int index) {
    if (_finished) return;
    final step = _routine.steps[index];
    final steps = List<RoutineStep>.of(_routine.steps);
    steps[index] = step.copyWith(done: !step.done);
    final next = Routine(kind: widget.kind, steps: steps);

    final fill = CompassLogic.fillByCategory(steps);
    final target = CompassLogic.needleAngle(
      CompassLogic.imbalanceVector(fill),
    );
    _spinNeedleTo(target);

    setState(() => _routine = next);
    _storage.saveRoutine(next);

    try {
      if (_storage.loadSettings().haptics) {
        HapticFeedback.selectionClick();
      }
    } catch (_) {
      // Haptics are optional — never let them break a check-in.
    }

    if (!_engaged) {
      _engaged = true;
      _armBackstop(AppConfig.engagedResolveMs);
    }

    if (next.total > 0 && next.doneCount == next.total) {
      _completion?.cancel();
      _completion = Timer(
        const Duration(milliseconds: AppConfig.completionDelayMs),
        () => _finish(RoundEndReason.completed),
      );
    }
  }

  void _spinNeedleTo(double target) {
    // Take the short way round so the needle never sweeps the long arc.
    var end = target;
    while (end - _currentAngle > math.pi) {
      end -= math.pi * 2;
    }
    while (end - _currentAngle < -math.pi) {
      end += math.pi * 2;
    }
    _needleAngle = Tween<double>(begin: _currentAngle, end: end).animate(
      CurvedAnimation(parent: _needle, curve: Curves.easeOutBack),
    );
    _currentAngle = end;
    _needle
      ..reset()
      ..forward();
  }

  void _finish(RoundEndReason reason) {
    if (_finished || !mounted) return;
    _finished = true;
    _backstop?.cancel();
    _completion?.cancel();

    final record = CompassLogic.recordFor(DateTime.now(), _routine.steps);
    _storage.saveRecord(record);
    final streak = CompassLogic.streakFrom(_storage.loadHistory(), DateTime.now());

    widget.onRoundEnd(
      RoundResult(
        kind: widget.kind,
        reason: reason,
        record: record,
        streak: streak,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dial = math.min(size.width - 48, 320.0);
    final fill = CompassLogic.fillByCategory(_routine.steps);
    final vector = CompassLogic.imbalanceVector(fill);
    final donePct = (_routine.donePct * 100).round();
    final balance = CompassLogic.balanceScore(_routine.steps);
    final streak = CompassLogic.streakFrom(_storage.loadHistory(), DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: <Widget>[
          ScreenHeader(
            title: widget.kind.label,
            subtitle:
                'STEP ${math.min(_routine.doneCount + 1, math.max(_routine.total, 1))} OF ${_routine.total}',
            onBack: () {
              _backstop?.cancel();
              _completion?.cancel();
              widget.onExit();
            },
            trailing: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.9),
                border: Border.all(color: AppColors.hairline),
              ),
              child: Text(
                '$donePct%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          Expanded(
            child: AppBackground(
              asset: AppAssets.bgGame,
              overlay: const <Color>[Color(0xF0F7F5F0), Color(0xE8EDE6DB)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              baseColor: AppColors.background,
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 14),
                  AnimatedBuilder(
                    animation: _needle,
                    builder: (context, _) => CompassDial(
                      fill: fill,
                      needleAngle: _needleAngle.value,
                      needleLean: CompassLogic.needleLean(vector),
                      size: dial * 0.72,
                      roseSize: dial * 0.30,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _routine.steps.isEmpty
                        ? _emptyBoard()
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 8),
                            itemCount: _routine.steps.length,
                            itemBuilder: (context, index) => RoutineStepTile(
                              step: _routine.steps[index],
                              onToggle: () => _toggle(index),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          _splitPanel(donePct: donePct, balance: balance, streak: streak),
        ],
      ),
    );
  }

  Widget _emptyBoard() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Image.asset(
            AppAssets.spriteAnchor,
            width: 64,
            height: 64,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 12),
          const Text(
            'NO STEPS IN THIS ROUTINE',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _splitPanel({
    required int donePct,
    required int balance,
    required int streak,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFDFCFA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Hint above the button, per the layout rules.
                  const Text(
                    'TAP A STEP TO CHECK IT IN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.4,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    label: 'GO TO BALANCE',
                    icon: Icons.navigation,
                    onTap: () => _finish(RoundEndReason.completed),
                  ),
                ],
              ),
            ),
            // Stat strip sits below the action so the button's tap target
            // stays inside the capture band the UI harness sweeps.
            Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.hairline)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  _statPair('DONE', '${_routine.doneCount}/${_routine.total}'),
                  _statPair('BALANCE', '$balance%'),
                  _statPair('STREAK', '$streak'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statPair(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}
