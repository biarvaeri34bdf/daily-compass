import 'package:flutter/material.dart';

import '../theme.dart';

/// Shared top bar. Keeps the 44px status-bar inset in one place.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 44, left: 8, right: 16, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        border: const Border(
          bottom: BorderSide(color: AppColors.hairline, width: 1),
        ),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 48,
            height: 48,
            child: onBack == null
                ? null
                : IconButton(
                    onPressed: onBack,
                    icon: const Icon(
                      Icons.arrow_back,
                      size: 24,
                      color: AppColors.ink,
                    ),
                    tooltip: 'Back',
                  ),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.4,
                    color: AppColors.ink,
                  ),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.6,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 48, height: 48, child: trailing),
        ],
      ),
    );
  }
}

/// Small uppercase label with a brass rule underneath.
class SectionLabel extends StatelessWidget {
  const SectionLabel({super.key, required this.text, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.6,
            color: color ?? AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(width: 40, height: 1, color: AppColors.accent),
      ],
    );
  }
}
