import 'package:flutter/material.dart';

import '../theme/lunar_theme_extension.dart';

/// Theme-aware card/tile surface for list items and sections.
class LunarSurface extends StatelessWidget {
  const LunarSurface({
    super.key,
    required this.child,
    this.padding,
    this.radius = 14,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final lunar = context.lunar;
    final content =
        padding != null ? Padding(padding: padding!, child: child) : child;

    return Material(
      color: lunar.tileBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: lunar.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, child: content),
    );
  }
}
