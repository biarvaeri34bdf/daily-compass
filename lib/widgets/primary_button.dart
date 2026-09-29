import 'package:flutter/material.dart';

import '../theme.dart';

/// Gradient CTA. Icon is always 24px and the label's line height matches it,
/// so the row never drifts off the optical baseline.
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.icon,
    this.gradient = const <Color>[AppColors.primary, AppColors.primaryDeep],
    this.height = 58,
    this.backdrop,
    this.foreground = AppColors.background,
    this.shadowColor,
  });

  final String label;
  final VoidCallback onTap;
  final IconData icon;
  final List<Color> gradient;
  final double height;
  final ImageProvider? backdrop;
  final Color foreground;
  final Color? shadowColor;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final shadow = widget.shadowColor ?? widget.gradient.first;
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 90),
      child: Container(
        width: double.infinity,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: shadow.withValues(alpha: 0.2),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
          image: widget.backdrop == null
              ? null
              : DecorationImage(image: widget.backdrop!, fit: BoxFit.fill),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.backdrop == null
                      ? widget.gradient
                      : <Color>[
                          widget.gradient.first.withValues(alpha: 0.5),
                          widget.gradient.last.withValues(alpha: 0.5),
                        ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: InkWell(
                onTap: widget.onTap,
                onHighlightChanged: (value) {
                  if (mounted) setState(() => _pressed = value);
                },
                splashColor: Colors.white.withValues(alpha: 0.13),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(widget.icon, size: 24, color: widget.foreground),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            height: 24 / 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.6,
                            color: widget.foreground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Outlined companion to [PrimaryButton]. Text only, never an icon.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.color,
    this.height = 48,
    this.borderColor,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;
  final double height;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: color.withValues(alpha: 0.13),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor ?? color.withValues(alpha: 0.75),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.4,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
