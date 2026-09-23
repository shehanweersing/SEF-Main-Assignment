import 'dart:ui';

import 'package:flutter/material.dart';

/// A reusable **Liquid Glass** container built entirely with native
/// [BackdropFilter] + [ImageFilter.blur] — no third-party glass package.
///
/// Renders a frosted-glass panel with:
/// - Gaussian blur behind the widget ([blurSigma])
/// - Translucent tint overlay ([tintColor])
/// - Rounded corners ([borderRadius])
/// - Subtle luminous border ([borderColor] / [borderWidth])
///
/// ### Usage
/// ```dart
/// GlassContainer(
///   blurSigma: 24,
///   tintColor: Colors.white.withOpacity(0.06),
///   borderRadius: 24,
///   padding: EdgeInsets.all(20),
///   child: Text('Hello, glass!'),
/// )
/// ```
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.blurSigma = 20.0,
    this.tintColor,
    this.borderRadius = 20.0,
    this.borderWidth = 0.5,
    this.borderColor,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
    this.width,
    this.height,
  });

  /// The widget rendered inside the glass panel.
  final Widget child;

  /// Blur intensity. Higher = frostier. Defaults to `20`.
  final double blurSigma;

  /// Tint colour painted over the blurred background.
  /// Defaults to white at 6 % opacity for a subtle frost.
  final Color? tintColor;

  /// Corner radius for the clipping shape. Defaults to `20`.
  final double borderRadius;

  /// Width of the luminous border stroke. Defaults to `0.5`.
  final double borderWidth;

  /// Colour of the border stroke.
  /// Defaults to white at 12 % opacity.
  final Color? borderColor;

  /// Inner padding. Defaults to [EdgeInsets.zero].
  final EdgeInsets padding;

  /// Outer margin. Defaults to [EdgeInsets.zero].
  final EdgeInsets margin;

  /// Optional fixed width.
  final double? width;

  /// Optional fixed height.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final effectiveTint = tintColor ?? Colors.white.withOpacity(0.06);
    final effectiveBorder = borderColor ?? Colors.white.withOpacity(0.12);

    return Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurSigma,
            sigmaY: blurSigma,
          ),
          child: Container(
            width: width,
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              color: effectiveTint,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: effectiveBorder,
                width: borderWidth,
              ),
              // Subtle inner glow for depth
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
