import 'dart:ui';

import 'package:flutter/material.dart';

/// A glass-themed app bar built on [BackdropFilter].
///
/// Implements [PreferredSizeWidget] so it can be used directly as
/// `Scaffold.appBar`. The blur and tint match [GlassContainer] defaults
/// for visual consistency across the Liquid Glass design system.
///
/// ### Usage
/// ```dart
/// Scaffold(
///   extendBodyBehindAppBar: true,   // let content blur through
///   appBar: GlassAppBar(
///     title: Text('My Trips'),
///     actions: [IconButton(...)],
///   ),
///   body: ...,
/// )
/// ```
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.blurSigma = 20.0,
    this.tintColor,
    this.borderColor,
    this.elevation = 0,
    this.toolbarHeight = kToolbarHeight,
  });

  /// Widget displayed as the primary title (usually [Text]).
  final Widget? title;

  /// Widget placed before the [title] (e.g. a back button).
  final Widget? leading;

  /// Trailing action widgets (e.g. icons, avatars).
  final List<Widget>? actions;

  /// Blur intensity. Matches [GlassContainer.blurSigma] default.
  final double blurSigma;

  /// Background tint over the blur.
  final Color? tintColor;

  /// Bottom border colour.
  final Color? borderColor;

  /// Material elevation. Defaults to `0` so the glass effect dominates.
  final double elevation;

  /// Height of the toolbar area.
  final double toolbarHeight;

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);

  @override
  Widget build(BuildContext context) {
    final effectiveTint = tintColor ?? Colors.white.withOpacity(0.06);
    final effectiveBorder = borderColor ?? Colors.white.withOpacity(0.08);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: effectiveTint,
            border: Border(
              bottom: BorderSide(color: effectiveBorder, width: 0.5),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: toolbarHeight,
              child: NavigationToolbar(
                leading: leading ??
                    (Navigator.of(context).canPop()
                        ? IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                size: 20),
                            onPressed: () => Navigator.of(context).pop(),
                          )
                        : null),
                middle: title != null
                    ? DefaultTextStyle(
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.3,
                            ),
                        child: title!,
                      )
                    : null,
                trailing: actions != null
                    ? Row(mainAxisSize: MainAxisSize.min, children: actions!)
                    : null,
                centerMiddle: true,
                middleSpacing: NavigationToolbar.kMiddleSpacing,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
