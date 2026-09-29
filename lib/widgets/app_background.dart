import 'package:flutter/material.dart';

/// Every screen sits on: asset image -> gradient overlay -> surfaces.
class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.asset,
    required this.overlay,
    required this.child,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.imageOpacity = 1.0,
    this.baseColor,
  });

  final String asset;
  final List<Color> overlay;
  final Widget child;
  final Alignment begin;
  final Alignment end;
  final double imageOpacity;
  final Color? baseColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: baseColor,
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(asset),
            fit: BoxFit.cover,
            opacity: imageOpacity,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: overlay,
              begin: begin,
              end: end,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Hairline rule used throughout the editorial layout.
class Hairline extends StatelessWidget {
  const Hairline({
    super.key,
    required this.width,
    required this.color,
    this.verticalMargin = 14,
  });

  final double width;
  final Color color;
  final double verticalMargin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 1,
      margin: EdgeInsets.symmetric(vertical: verticalMargin),
      color: color,
    );
  }
}
