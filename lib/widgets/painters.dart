import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../game/models.dart';
import '../theme.dart';

/// Static full-canvas grain for the loader. Painted once — `shouldRepaint`
/// is always false, so it never keeps the window busy.
class StarfieldPainter extends CustomPainter {
  StarfieldPainter({this.points = 130000, this.seed = 20260929});

  final int points;
  final int seed;

  Float32List? _cache;
  Size _cachedSize = Size.zero;

  static const List<Color> _tints = <Color>[
    Color(0x14FFFFFF),
    Color(0x1ACBA135),
    Color(0x12A7C4B5),
    Color(0x0FFFFFFF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    if (_cache == null || _cachedSize != size) {
      _cache = _build(size);
      _cachedSize = size;
    }
    final data = _cache!;
    final perPass = (points / _tints.length).floor();
    for (var pass = 0; pass < _tints.length; pass++) {
      final start = pass * perPass * 2;
      final end = math.min(start + perPass * 2, data.length);
      if (end <= start) break;
      final slice = Float32List.sublistView(data, start, end);
      final paint = Paint()
        ..color = _tints[pass]
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.square;
      canvas.drawRawPoints(ui.PointMode.points, slice, paint);
    }
  }

  Float32List _build(Size size) {
    final data = Float32List(points * 2);
    var state = seed;
    int next() {
      // xorshift32 — deterministic, no allocation.
      state ^= (state << 13) & 0x7FFFFFFF;
      state ^= state >> 17;
      state ^= (state << 5) & 0x7FFFFFFF;
      return state & 0x7FFFFFFF;
    }

    for (var i = 0; i < points; i++) {
      data[i * 2] = (next() % 100000) / 100000 * size.width;
      data[i * 2 + 1] = (next() % 100000) / 100000 * size.height;
    }
    return data;
  }

  @override
  bool shouldRepaint(covariant StarfieldPainter oldDelegate) => false;
}

/// Sector ring + brass ticks + needle.
class CompassDialPainter extends CustomPainter {
  const CompassDialPainter({
    required this.fill,
    required this.needleAngle,
    required this.needleLean,
    this.showLabels = true,
    this.ringWidth = 12,
  });

  final Map<StepCategory, double> fill;
  final double needleAngle;
  final double needleLean;
  final bool showLabels;
  final double ringWidth;

  static const List<StepCategory> _order = <StepCategory>[
    StepCategory.mind, // N
    StepCategory.body, // E
    StepCategory.home, // S
    StepCategory.focus, // W
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    if (radius <= 0) return;
    final rect = Rect.fromCircle(center: centre, radius: radius - ringWidth / 2);

    const sweep = 86 * math.pi / 180;
    const gap = 4 * math.pi / 180;

    for (var i = 0; i < _order.length; i++) {
      final category = _order[i];
      // Sector centres sit on N / E / S / W.
      final start = -math.pi / 2 + i * (math.pi / 2) - sweep / 2 + gap / 2;

      canvas.drawArc(
        rect,
        start,
        sweep - gap,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ringWidth
          ..strokeCap = StrokeCap.butt
          ..color = AppColors.hairline,
      );

      final value = (fill[category] ?? 0).clamp(0.0, 1.0);
      if (value > 0) {
        canvas.drawArc(
          rect,
          start,
          (sweep - gap) * value,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = ringWidth
            ..strokeCap = StrokeCap.round
            ..color = category.color,
        );
      }
    }

    // Brass ticks.
    final tickOuter = radius - ringWidth - 4;
    for (var i = 0; i < 36; i++) {
      final angle = -math.pi / 2 + i * (math.pi * 2 / 36);
      final major = i % 9 == 0;
      final length = major ? 10.0 : 5.0;
      final paint = Paint()
        ..color = AppColors.accent.withValues(alpha: major ? 0.7 : 0.35)
        ..strokeWidth = major ? 2 : 1
        ..strokeCap = StrokeCap.round;
      final unit = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        centre + unit * tickOuter,
        centre + unit * (tickOuter - length),
        paint,
      );
    }

    if (showLabels) {
      const labels = <String>['N', 'E', 'S', 'W'];
      for (var i = 0; i < labels.length; i++) {
        final angle = -math.pi / 2 + i * (math.pi / 2);
        final unit = Offset(math.cos(angle), math.sin(angle));
        final painter = TextPainter(
          text: TextSpan(
            text: labels[i],
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
              color: AppColors.textMuted,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final at = centre + unit * (tickOuter - 26);
        painter.paint(
          canvas,
          at - Offset(painter.width / 2, painter.height / 2),
        );
      }
    }

    _paintNeedle(canvas, centre, radius);
  }

  void _paintNeedle(Canvas canvas, Offset centre, double radius) {
    final length = radius * 0.62 * (0.45 + 0.55 * needleLean.clamp(0.0, 1.0));
    final dir = Offset(math.cos(needleAngle), math.sin(needleAngle));
    final perp = Offset(-dir.dy, dir.dx);
    final tip = centre + dir * length;
    final tail = centre - dir * (length * 0.42);

    final head = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo((centre + perp * 7).dx, (centre + perp * 7).dy)
      ..lineTo((centre - perp * 7).dx, (centre - perp * 7).dy)
      ..close();
    canvas.drawPath(head, Paint()..color = AppColors.accent);

    final back = Path()
      ..moveTo(tail.dx, tail.dy)
      ..lineTo((centre + perp * 5).dx, (centre + perp * 5).dy)
      ..lineTo((centre - perp * 5).dx, (centre - perp * 5).dy)
      ..close();
    canvas.drawPath(back, Paint()..color = AppColors.ink.withValues(alpha: 0.8));

    canvas.drawCircle(centre, 5, Paint()..color = AppColors.ink);
    canvas.drawCircle(
      centre,
      5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = AppColors.accent,
    );
  }

  @override
  bool shouldRepaint(covariant CompassDialPainter old) =>
      old.needleAngle != needleAngle ||
      old.needleLean != needleLean ||
      old.fill != fill ||
      old.ringWidth != ringWidth;
}

/// Seven concentric arcs — one per weekday.
class WeeklyRingPainter extends CustomPainter {
  const WeeklyRingPainter({
    required this.ratios,
    required this.todayIndex,
    required this.progress,
  });

  /// Completion 0..1 for Monday..Sunday.
  final List<double> ratios;
  final int todayIndex;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final outer = math.min(size.width, size.height) / 2 - 4;
    if (outer <= 0) return;
    const step = 15.0;

    for (var i = 0; i < 7; i++) {
      final radius = outer - i * step;
      if (radius <= 8) continue;
      final rect = Rect.fromCircle(center: centre, radius: radius);
      final isToday = i == todayIndex;
      final isPast = i < todayIndex;
      final value = (i < ratios.length ? ratios[i] : 0.0).clamp(0.0, 1.0);

      canvas.drawArc(
        rect,
        0,
        math.pi * 2,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = isToday ? 9 : 6
          ..color = Colors.white.withValues(alpha: 0.12),
      );

      if (!isToday && !isPast) continue;
      if (value <= 0) continue;

      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * value * progress.clamp(0.0, 1.0),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = isToday ? 9 : 6
          ..strokeCap = StrokeCap.round
          ..color = isToday
              ? AppColors.accent
              : AppColors.secondary.withValues(alpha: 0.35 + 0.5 * value),
      );
    }
  }

  @override
  bool shouldRepaint(covariant WeeklyRingPainter old) =>
      old.progress != progress ||
      old.todayIndex != todayIndex ||
      old.ratios != ratios;
}
