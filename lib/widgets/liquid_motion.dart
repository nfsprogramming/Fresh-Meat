import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../theme.dart';
import 'common.dart';

/// Viscoelastic spring curve for liquid fluid motion.
/// Provides a gentle overshoot and organic fluid settling.
class LiquidSpringCurve extends Curve {
  final double bounce;
  const LiquidSpringCurve({this.bounce = 0.22});

  @override
  double transformInternal(double t) {
    // Tuned damped spring response: 1 - e^(-6t) * cos(8t)
    return 1.0 - math.exp(-6.0 * t) * math.cos((8.0 + bounce * 4.0) * t);
  }
}

/// A liquid smooth sliding pill indicator that glides horizontally across
/// a segmented track with viscoelastic stretch, ambient ember glow, and spring snap.
class LiquidSlidingDock extends StatefulWidget {
  final int currentIndex;
  final int activeOrdersCount;
  final ValueChanged<int> onTabSelected;

  const LiquidSlidingDock({
    super.key,
    required this.currentIndex,
    required this.activeOrdersCount,
    required this.onTabSelected,
  });

  @override
  State<LiquidSlidingDock> createState() => _LiquidSlidingDockState();
}

class _LiquidSlidingDockState extends State<LiquidSlidingDock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _anim;
  double _prevIndex = 0.0;
  double _targetIndex = 0.0;
  bool _isPressed = false;

  final tabs = const [
    (icon: Icons.storefront_rounded, label: 'Cuts'),
    (icon: Icons.local_dining_rounded, label: 'Butchers'),
    (icon: Icons.receipt_long_rounded, label: 'Orders'),
    (icon: Icons.verified_user_rounded, label: 'Halal'),
  ];

  @override
  void initState() {
    super.initState();
    _prevIndex = widget.currentIndex.toDouble();
    _targetIndex = widget.currentIndex.toDouble();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _anim = CurvedAnimation(
      parent: _controller,
      curve: const Cubic(0.22, 1.0, 0.36, 1.0),
    );
  }

  @override
  void didUpdateWidget(covariant LiquidSlidingDock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      if (_controller.isAnimating) {
        final t = _anim.value;
        _prevIndex = _prevIndex + (_targetIndex - _prevIndex) * t;
      } else {
        _prevIndex = oldWidget.currentIndex.toDouble();
      }
      _targetIndex = widget.currentIndex.toDouble();
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xEB1B070E),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: op(Colors.white, .14), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(160),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: SizedBox(
              height: 50,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final count = tabs.length;
                  final tabWidth = constraints.maxWidth / count;
                  const pillHeight = 42.0;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 1. LIQUID SLIDING PILL INDICATOR
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          final t = _anim.value;
                          final currentIndexVal = _prevIndex + (_targetIndex - _prevIndex) * t;

                          // Viscoelastic stretch effect:
                          // During flight (t ~ 0.5), pill widens in direction of motion.
                          final velocity = math.sin(t * math.pi);
                          final stretch = velocity * 8.0 * (_targetIndex - _prevIndex).abs().clamp(0.0, 2.0);

                          final left = currentIndexVal * tabWidth + 2.0 - (stretch * 0.25);
                          final width = (tabWidth - 4.0) + stretch * 0.5;

                          return Positioned(
                            left: left.clamp(1.5, constraints.maxWidth - width - 1.5),
                            top: 4,
                            width: width,
                            height: pillHeight,
                            child: Transform.scale(
                              scale: _isPressed ? 0.94 : 1.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: emberGradient,
                                  borderRadius: BorderRadius.circular(21),
                                  boxShadow: [
                                    BoxShadow(
                                      color: C.ember.withAlpha(80),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // 2. INTERACTIVE TAB ICONS & LABELS
                      Row(
                        children: [
                          for (var i = 0; i < count; i++)
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTapDown: (_) => setState(() => _isPressed = true),
                                onTapUp: (_) {
                                  setState(() => _isPressed = false);
                                  widget.onTabSelected(i);
                                },
                                onTapCancel: () => setState(() => _isPressed = false),
                                child: SizedBox(
                                  height: 50,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      AnimatedBuilder(
                                        animation: _controller,
                                        builder: (context, _) {
                                          final t = _anim.value;
                                          final currentPos = _prevIndex + (_targetIndex - _prevIndex) * t;
                                          final dist = (currentPos - i).abs();
                                          final proximity = (1.0 - dist).clamp(0.0, 1.0);

                                          return Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 2),
                                            child: Center(
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Transform.translate(
                                                      offset: Offset(0, -1.0 * proximity),
                                                      child: Icon(
                                                        tabs[i].icon,
                                                        size: 18 + (1.5 * proximity),
                                                        color: Color.lerp(
                                                          op(Colors.white, .70),
                                                          Colors.white,
                                                          proximity,
                                                        ),
                                                      ),
                                                    ),
                                                    if (proximity > 0.40) ...[
                                                      const SizedBox(width: 4),
                                                      Opacity(
                                                        opacity: ((proximity - 0.40) / 0.60).clamp(0.0, 1.0),
                                                        child: Text(
                                                          tabs[i].label,
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: body(
                                                            11.5,
                                                            w: FontWeight.w800,
                                                            color: Colors.white,
                                                          ).copyWith(letterSpacing: -0.2),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),

                                  // Orders Live Badge
                                  if (i == 2 && widget.activeOrdersCount > 0)
                                    Positioned(
                                      top: 7,
                                      right: 12,
                                      child: Container(
                                        padding: const EdgeInsets.all(3.5),
                                        decoration: BoxDecoration(
                                          color: C.gold,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withAlpha(60),
                                              blurRadius: 3,
                                              offset: const Offset(0, 1),
                                            )
                                          ],
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 8,
                                          minHeight: 8,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  ),
);
  }
}

/// Liquid Sliding Category Bar with continuous animated pill indicator bounded to screen width.
class LiquidCategoryBar extends StatelessWidget {
  final int selectedIndex;
  final List<({String label, IconData icon, String? badge, bool dim})> items;
  final ValueChanged<int> onSelected;
  final EdgeInsetsGeometry margin;

  const LiquidCategoryBar({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onSelected,
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return RepaintBoundary(
      child: Container(
        height: 48,
      margin: margin,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: op(Colors.white, .06),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: op(Colors.white, .10)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final count = items.length;
          final tabWidth = constraints.maxWidth / count;
          final safeIndex = selectedIndex.clamp(0, count - 1);

          return Stack(
            children: [
              // Liquid Sliding Pill Indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 320),
                curve: const Cubic(0.2, 1.0, 0.3, 1.0),
                left: safeIndex * tabWidth,
                top: 0,
                bottom: 0,
                width: tabWidth,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: emberGradient,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(45),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),

              // Categories Row bounded within screen size
              Positioned.fill(
                child: Row(
                  children: [
                    for (var i = 0; i < count; i++)
                      Expanded(
                        child: _LiquidCategoryTab(
                          label: items[i].label,
                          icon: items[i].icon,
                          badge: items[i].badge,
                          dim: items[i].dim,
                          active: selectedIndex == i,
                          onTap: () => onSelected(i),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
}

class _LiquidCategoryTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? badge;
  final bool dim;
  final bool active;
  final VoidCallback onTap;

  const _LiquidCategoryTab({
    required this.label,
    required this.icon,
    this.badge,
    this.dim = false,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BouncyPress(
      onTap: onTap,
      scaleDown: 0.94,
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 15,
                    color: active
                        ? Colors.white
                        : (dim ? op(Colors.white, .35) : op(Colors.white, .75)),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: body(
                      12,
                      w: active ? FontWeight.w800 : FontWeight.w600,
                      color: active
                          ? Colors.white
                          : (dim ? op(Colors.white, .35) : op(Colors.white, .85)),
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: op(C.gold, .2),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        badge!,
                        style: body(8, color: C.gold, w: FontWeight.w800),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Generic Liquid Segmented Control with a single sliding pill indicator.
/// Perfect for weight selectors, filter tabs, and quantity switches.
class LiquidSegmentedControl extends StatelessWidget {
  final int selectedIndex;
  final List<Widget> children;
  final ValueChanged<int> onSelected;
  final double height;
  final Color? backgroundColor;
  final Color? borderColor;

  const LiquidSegmentedControl({
    super.key,
    required this.selectedIndex,
    required this.children,
    required this.onSelected,
    this.height = 64,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RepaintBoundary(
      child: Container(
        height: height,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: backgroundColor ?? (isDark ? const Color(0xFF220811) : Colors.white),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: borderColor ?? (isDark ? Colors.white.withAlpha(25) : const Color(0xFFF0E0D2)),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 50 : 12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final count = children.length;
          final tabWidth = constraints.maxWidth / count;
          final safeIndex = selectedIndex.clamp(0, count > 0 ? count - 1 : 0);

          return Stack(
            children: [
              // Liquid Sliding Pill Indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 340),
                curve: const Cubic(0.22, 1.0, 0.36, 1.0),
                left: safeIndex * tabWidth,
                top: 0,
                bottom: 0,
                width: tabWidth,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: emberGradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: C.ember.withAlpha(75),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                ),
              ),

              // Tab contents
              Positioned.fill(
                child: Row(
                  children: [
                    for (var i = 0; i < count; i++)
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onSelected(i),
                          child: Center(
                            child: children[i],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
}

/// Liquid Smooth Page Route with iOS/macOS grade spring easing and gentle depth scale.
class LiquidPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  LiquidPageRoute({required this.page})
      : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: const Duration(milliseconds: 380),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          transitionsBuilder: (_, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: const Cubic(0.2, 1.0, 0.3, 1.0),
              reverseCurve: Curves.easeInCubic,
            );

            final secondaryCurved = CurvedAnimation(
              parent: secondaryAnimation,
              curve: const Cubic(0.2, 1.0, 0.3, 1.0),
            );

            // Subtle parallax scale and fade
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(curved),
              child: FadeTransition(
                opacity: curved,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: 0.96).animate(secondaryCurved),
                  child: child,
                ),
              ),
            );
          },
        );
}

/// Custom PageTransitionsBuilder for MaterialApp ThemeData
class LiquidPageTransitionsBuilder extends PageTransitionsBuilder {
  const LiquidPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: const Cubic(0.2, 1.0, 0.3, 1.0),
      reverseCurve: Curves.easeInCubic,
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).animate(curved),
      child: FadeTransition(
        opacity: curved,
        child: child,
      ),
    );
  }
}
