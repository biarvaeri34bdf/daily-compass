import 'package:flutter/material.dart';

import '../assets.dart';
import '../game/models.dart';
import 'painters.dart';

/// Sector ring with the AI-rendered compass rose sitting at its centre.
class CompassDial extends StatelessWidget {
  const CompassDial({
    super.key,
    required this.fill,
    required this.needleAngle,
    required this.needleLean,
    required this.size,
    this.roseSize = 132,
    this.showLabels = true,
    this.center,
  });

  final Map<StepCategory, double> fill;
  final double needleAngle;
  final double needleLean;
  final double size;
  final double roseSize;
  final bool showLabels;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Opacity(
            opacity: 0.55,
            child: Image.asset(
              AppAssets.spriteCompassRose,
              width: roseSize,
              height: roseSize,
              fit: BoxFit.contain,
            ),
          ),
          CustomPaint(
            size: Size(size, size),
            painter: CompassDialPainter(
              fill: fill,
              needleAngle: needleAngle,
              needleLean: needleLean,
              showLabels: showLabels,
            ),
          ),
          if (center != null)
            Padding(
              padding: EdgeInsets.only(top: size * 0.30),
              child: center,
            ),
        ],
      ),
    );
  }
}
