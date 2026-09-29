import 'package:flutter/material.dart';

import '../game/models.dart';
import '../theme.dart';

/// One check-in row. Hit box is the full 64px card.
class RoutineStepTile extends StatelessWidget {
  const RoutineStepTile({
    super.key,
    required this.step,
    required this.onToggle,
  });

  final RoutineStep step;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final categoryColor = step.category.color;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: step.done
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.hairline,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(14),
          splashColor: categoryColor.withValues(alpha: 0.13),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: <Widget>[
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    step.done
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    key: ValueKey<bool>(step.done),
                    size: 24,
                    color: step.done
                        ? AppColors.primary
                        : const Color(0xFFC4C0B6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    step.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: step.done ? AppColors.textMuted : AppColors.ink,
                      decoration: step.done
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    step.category.label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: categoryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
