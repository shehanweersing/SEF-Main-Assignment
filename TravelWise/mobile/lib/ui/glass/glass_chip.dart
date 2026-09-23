import 'dart:ui';
import 'package:flutter/material.dart';

/// A sleek floating **Liquid Glass Chip** badge used for metrics,
/// ratings, weather tags, category filters, and status chips.
class GlassChip extends StatelessWidget {
  const GlassChip({
    super.key,
    required this.label,
    this.icon,
    this.isSelected = false,
    this.onTap,
    this.accentColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    this.borderRadius = 20.0,
  });

  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? accentColor;
  final EdgeInsets padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = accentColor ?? const Color(0xFF00D9C0);
    final bgTint = isSelected
        ? effectiveAccent.withValues(alpha: 0.25)
        : Colors.white.withValues(alpha: 0.08);

    final borderColor = isSelected
        ? effectiveAccent.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.18);

    Widget content = Padding(
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: isSelected ? effectiveAccent : Colors.white.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? effectiveAccent : Colors.white.withValues(alpha: 0.9),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Container(
              decoration: BoxDecoration(
                color: bgTint,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(color: borderColor, width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
