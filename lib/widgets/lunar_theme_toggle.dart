import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/lunar_theme_extension.dart';
import '../theme/theme_controller.dart';

/// Drop into any [AppBar.actions] list.
const List<Widget> lunarAppBarActions = [LunarThemeToggle()];

/// Smooth sun/moon slider for switching light and dark mode.
class LunarThemeToggle extends StatefulWidget {
  const LunarThemeToggle({super.key});

  @override
  State<LunarThemeToggle> createState() => _LunarThemeToggleState();
}

class _LunarThemeToggleState extends State<LunarThemeToggle>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 420);

  late final AnimationController _controller;
  late final Animation<double> _slide;
  ThemeController? _theme;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    _slide = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = context.read<ThemeController>();
    if (_theme != next) {
      _theme?.removeListener(_onThemeChanged);
      _theme = next..addListener(_onThemeChanged);
      _syncToTheme(next.isDark, animate: false);
    }
  }

  @override
  void dispose() {
    _theme?.removeListener(_onThemeChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onThemeChanged() {
    _syncToTheme(_theme!.isDark, animate: true);
  }

  void _syncToTheme(bool isDark, {required bool animate}) {
    final target = isDark ? 1.0 : 0.0;
    if ((_controller.value - target).abs() < 0.001) return;
    if (animate) {
      _controller.animateTo(target, duration: _duration);
    } else {
      _controller.value = target;
    }
  }

  Future<void> _onTap() async {
    await context.read<ThemeController>().toggle();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    final lunar = context.lunar;
    final isDark = _slide.value > 0.5;

    return Semantics(
      label: isDark ? 'Switch to light mode' : 'Switch to dark mode',
      button: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          onTap: _onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedBuilder(
            animation: _slide,
            builder: (context, _) {
              final t = _slide.value;
              final trackStart = Color.lerp(
                const Color(0xFFFFF7E6),
                const Color(0xFF1A3A48),
                t,
              )!;
              final trackEnd = Color.lerp(
                const Color(0xFFFFE082),
                const Color(0xFF0D3240),
                t,
              )!;
              final borderColor = Color.lerp(
                const Color(0xFFFFD54F).withValues(alpha: 0.6),
                lunar.border,
                t,
              )!;

              return Container(
                width: 58,
                height: 30,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [trackStart, trackEnd],
                  ),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: (t > 0.5 ? Colors.black : AppColors.primary)
                          .withValues(alpha: 0.1 + (0.04 * t)),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final thumbTravel =
                        constraints.maxWidth - constraints.maxHeight;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: thumbTravel * t,
                          top: 0,
                          bottom: 0,
                          child: _Thumb(isDark: t > 0.5),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFFE8F4F8) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return RotationTransition(
            turns: Tween<double>(begin: 0.15, end: 0).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: Icon(
          isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
          key: ValueKey(isDark),
          size: 14,
          color: isDark ? AppColors.primary : const Color(0xFFF59E0B),
        ),
      ),
    );
  }
}
