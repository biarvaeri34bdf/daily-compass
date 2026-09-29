
import 'package:flutter/material.dart';

import '../theme.dart';

/// One stat pill. Same widget on Menu and on the result screen — no raster
/// icons, the accent dot and the colour carry the meaning.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.valueColor,
    this.onDark = false,
  });

  final String value;
  final String label;
  final Color valueColor;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.white.withValues(alpha: 0.10)
            : Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: valueColor.withValues(alpha: onDark ? 0.38 : 0.33),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: valueColor, shape: BoxShape.circle),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: valueColor,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: onDark
                  ? Colors.white.withValues(alpha: 0.72)
                  : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
