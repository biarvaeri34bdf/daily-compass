import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../assets.dart';
import '../game/compass_logic.dart';
import '../game/models.dart';
import '../game/storage.dart';
import '../theme.dart';
import '../widgets/painters.dart';
import '../widgets/primary_button.dart';
import '../widgets/stat_card.dart';

/// WEEKLY BALANCE — dark sage chart, deliberately unlike the cream board.
class GameOverScreen extends StatefulWidget {
  const GameOverScreen({
    super.key,
    required this.result,
    required this.onPlayAgain,
    required this.onMenu,
  });

  final RoundResult result;
  final VoidCallback onPlayAgain;
  final VoidCallback onMenu;

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry;
  late final List<DayRecord> _history;

  @override
  void initState() {
    super.initState();
    _history = CompassStorage.instance.loadHistory();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..forward();
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  String get _title {
    final record = widget.result.record;
    if (record.done == 0) return 'DAY MISSED';
    if (widget.result.isFullDay) return 'DAY LOGGED';
    return 'PARTIAL DAY';
  }

  String get _subtitle {
    final record = widget.result.record;
    if (record.done == 0) return 'NO HEADING';
    final lean = CompassLogic.leaning(record.perCategory);
    return lean == null ? 'BALANCED' : 'LEANING ${lean.label}';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final record = widget.result.record;
    final now = DateTime.now();
    final ratios = CompassLogic.weekRatios(_history, now);
    final ring = math.min(size.width - 64, 260.0);
    final hasHistory = _history.any((r) => r.done > 0);

    return Scaffold(
      backgroundColor: AppColors.primaryDeep,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              AppColors.primaryDeep,
              Color(0xFF2E4A43),
              AppColors.ink,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          image: DecorationImage(
            image: AssetImage(AppAssets.bgResult),
            fit: BoxFit.cover,
            opacity: 0.35,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: <Widget>[
              // Decoration lives in the bottom-left corner, clear of every
              // line of type.
              Positioned(
                left: 16,
                bottom: 18,
                child: Opacity(
                  opacity: 0.55,
                  child: Image.asset(
                    AppAssets.spriteLeaf,
                    width: 56,
                    height: 56,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  top: 44,
                  left: 24,
                  right: 24,
                  bottom: 18,
                ),
                child: Column(
                  children: <Widget>[
                    FadeTransition(
                      opacity: _entry,
                      child: Column(
                        children: <Widget>[
                          Text(
                            _title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 4.0,
                              color: AppColors.background,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _subtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2.0,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: hasHistory
                            ? _weeklyRing(ring, ratios, now)
                            : _emptyHistory(),
                      ),
                    ),
                    _statRow(record),
                    const SizedBox(height: 16),
                    _directionBars(record),
                    const SizedBox(height: 18),
                    PrimaryButton(
                      label: 'START AGAIN',
                      icon: Icons.restart_alt,
                      onTap: widget.onPlayAgain,
                      gradient: const <Color>[
                        AppColors.accent,
                        AppColors.accentDeep,
                      ],
                      backdrop: const AssetImage(AppAssets.buttonCta),
                      foreground: AppColors.ink,
                    ),
                    const SizedBox(height: 10),
                    SecondaryButton(
                      label: 'BACK TO COMPASS',
                      color: AppColors.background,
                      borderColor: AppColors.background.withValues(alpha: 0.4),
                      onTap: widget.onMenu,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _weeklyRing(double ring, List<double> ratios, DateTime now) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => CustomPaint(
        size: Size(ring, ring),
        painter: WeeklyRingPainter(
          ratios: ratios,
          todayIndex: now.weekday - 1,
          progress: value,
        ),
      ),
    );
  }

  Widget _emptyHistory() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(
          Icons.explore_outlined,
          size: 44,
          color: AppColors.secondary,
        ),
        const SizedBox(height: 14),
        const Text(
          'FIRST DAY ON THE MAP',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
            color: AppColors.background,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'EVERY CHECK-IN SETS YOUR HEADING',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
            color: AppColors.secondary.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }

  Widget _statRow(DayRecord record) {
    final cards = <Widget>[];
    if (record.total > 0) {
      cards.add(
        StatCard(
          value: '${record.done}/${record.total}',
          label: 'today',
          valueColor: AppColors.accent,
          onDark: true,
        ),
      );
    }
    if (record.balance > 0) {
      cards.add(
        StatCard(
          value: '${record.balance}%',
          label: 'balance',
          valueColor: AppColors.secondary,
          onDark: true,
        ),
      );
    }
    if (widget.result.streak > 0) {
      cards.add(
        StatCard(
          value: '${widget.result.streak}',
          label: 'streak',
          valueColor: AppColors.background,
          onDark: true,
        ),
      );
    }
    // A lone pill looks orphaned — drop the whole row instead.
    if (cards.length < 2) return const SizedBox.shrink();
    return Row(
      children: <Widget>[
        for (var i = 0; i < cards.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: cards[i]),
        ],
      ],
    );
  }

  Widget _directionBars(DayRecord record) {
    return Row(
      children: <Widget>[
        for (final category in StepCategory.values) ...<Widget>[
          if (category != StepCategory.values.first) const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                LayoutBuilder(
                  builder: (context, constraints) {
                    final value =
                        (record.perCategory[category] ?? 0).clamp(0.0, 1.0);
                    return Stack(
                      children: <Widget>[
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        Container(
                          height: 6,
                          width: constraints.maxWidth * value,
                          decoration: BoxDecoration(
                            color: category.color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 6),
                Text(
                  category.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
