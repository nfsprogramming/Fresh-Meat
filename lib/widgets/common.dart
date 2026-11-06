import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';

import 'liquid_motion.dart';

Route<T> fadeRoute<T>(Widget page) => LiquidPageRoute<T>(page: page);

/// Tactile spring micro-bounce on press for buttons and pills.
class BouncyPress extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  const BouncyPress({super.key, required this.child, this.onTap, this.scaleDown = 0.92});

  @override
  State<BouncyPress> createState() => _BouncyPressState();
}

class _BouncyPressState extends State<BouncyPress> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
    reverseDuration: const Duration(milliseconds: 220),
  );
  late final Animation<double> _scale = Tween<double>(begin: 1.0, end: widget.scaleDown).animate(
    CurvedAnimation(parent: _c, curve: Curves.easeOutCubic, reverseCurve: Curves.easeOutBack),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _c.forward(),
        onTapUp: (_) {
          _c.reverse();
          widget.onTap?.call();
        },
        onTapCancel: () => _c.reverse(),
        child: AnimatedBuilder(
          animation: _scale,
          builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
          child: widget.child,
        ),
      );
}

/// Gently floats and tilts its child (the hero cuts).
class Floating extends StatefulWidget {
  final Widget child;
  final double angle;
  const Floating({super.key, required this.child, this.angle = -0.105});
  @override
  State<Floating> createState() => _FloatingState();
}

class _FloatingState extends State<Floating> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        child: RepaintBoundary(child: widget.child),
        builder: (_, child) {
          final t = Curves.easeInOut.transform(_c.value);
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.translationValues(0.0, -14.0 * t, 0.0)
              ..rotateZ(widget.angle + 0.05 * t),
            child: child,
          );
        },
      );
}

/// Endless slow rotation.
class Spin extends StatefulWidget {
  final Widget child;
  final int seconds;
  const Spin({super.key, required this.child, this.seconds = 30});
  @override
  State<Spin> createState() => _SpinState();
}

class _SpinState extends State<Spin> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Duration(seconds: widget.seconds))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(turns: _c, child: RepaintBoundary(child: widget.child));
}

class DashedRingPainter extends CustomPainter {
  final Color color;
  DashedRingPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final path = Path()..addOval(Rect.fromCircle(center: size.center(Offset.zero), radius: size.width / 2 - 2));
    for (final m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 3), p);
        d += 13;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedRingPainter old) => old.color != color;
}

/// Text laid out around a circle (splash ring).
class RingTextPainter extends CustomPainter {
  final String text;
  final TextStyle style;
  final List<TextPainter> _painters;

  RingTextPainter(this.text, this.style)
      : _painters = List.generate(
          text.length,
          (i) => TextPainter(
            text: TextSpan(text: text[i], style: style),
            textDirection: TextDirection.ltr,
          )..layout(),
        );

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 22;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.drawCircle(Offset.zero, size.width / 2 - 4, Paint()
      ..style = PaintingStyle.stroke
      ..color = op(C.gold, .25));
    for (var i = 0; i < _painters.length; i++) {
      canvas.save();
      canvas.rotate(i / text.length * 2 * math.pi);
      final tp = _painters[i];
      tp.paint(canvas, Offset(-tp.width / 2, -r - tp.height / 2));
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RingTextPainter old) => old.text != text || old.style != style;
}

/// Frosted glass container.
class Glass extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double opacity;
  const Glass({super.key, required this.child, this.radius = 20, this.padding = EdgeInsets.zero, this.opacity = .1});
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: op(Colors.white, opacity),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: op(Colors.white, .16)),
            ),
            child: child,
          ),
        ),
      );
}

/// Gradient button with a light sweep.
class ShineButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double? width;
  final double height;
  final double radius;
  final Gradient gradient;
  final EdgeInsetsGeometry? padding;
  const ShineButton({
    super.key,
    required this.child,
    required this.onTap,
    this.width,
    this.height = 60,
    this.radius = 30,
    this.gradient = emberGradient,
    this.padding,
  });
  @override
  State<ShineButton> createState() => _ShineButtonState();
}

class _ShineButtonState extends State<ShineButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(widget.radius),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(60), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.radius),
              child: Stack(alignment: Alignment.center, children: [
                Padding(
                  padding: widget.padding ??
                      (widget.width == double.infinity
                          ? EdgeInsets.zero
                          : const EdgeInsets.symmetric(horizontal: 20)),
                  child: widget.child,
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _c,
                      builder: (_, __) {
                        final t = Curves.easeInOut.transform((_c.value / .6).clamp(0.0, 1.0));
                        return Align(
                          alignment: Alignment(-1.6 + 3.2 * t, 0),
                          child: Transform(
                            transform: Matrix4.skewX(-.35),
                            child: Container(width: 60, color: op(Colors.white, .38)),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      );
}

/// Endless horizontal ticker.
class Marquee extends StatefulWidget {
  final String text;
  final TextStyle style;
  const Marquee({super.key, required this.text, required this.style});
  @override
  State<Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<Marquee> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();
  late double _w;
  late Widget _rowChild;

  @override
  void initState() {
    super.initState();
    _computeLayout();
  }

  @override
  void didUpdateWidget(covariant Marquee oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.style != widget.style) {
      _computeLayout();
    }
  }

  void _computeLayout() {
    _w = (TextPainter(text: TextSpan(text: widget.text, style: widget.style), textDirection: TextDirection.ltr)..layout()).width;
    _rowChild = Row(mainAxisSize: MainAxisSize.min, children: [
      Text(widget.text, style: widget.style, softWrap: false, maxLines: 1),
      Text(widget.text, style: widget.style, softWrap: false, maxLines: 1),
    ]);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: SizedBox(
          height: 22,
          child: ClipRect(
            child: AnimatedBuilder(
              animation: _c,
              child: _rowChild,
              builder: (_, child) => OverflowBox(
                alignment: Alignment.centerLeft,
                minWidth: 0,
                maxWidth: double.infinity,
                child: Transform.translate(
                  offset: Offset(-_c.value * _w, 0),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      );
}

/// Fade + rise on first build, with optional delay.
class Reveal extends StatefulWidget {
  final Widget child;
  final int delayMs;
  const Reveal({super.key, required this.child, this.delayMs = 0});
  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _c,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, .3), end: Offset.zero).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic)),
          child: widget.child,
        ),
      );
}

/// Bag icon with a count badge that bumps whenever the count goes up.
class BagButton extends StatefulWidget {
  final int count;
  final VoidCallback? onTap;
  const BagButton({super.key, required this.count, this.onTap});
  @override
  State<BagButton> createState() => _BagButtonState();
}

class _BagButtonState extends State<BagButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 40),
    TweenSequenceItem(tween: Tween(begin: 1.3, end: .95), weight: 30),
    TweenSequenceItem(tween: Tween(begin: .95, end: 1.0), weight: 30),
  ]).animate(_c);

  @override
  void didUpdateWidget(covariant BagButton old) {
    super.didUpdateWidget(old);
    if (widget.count > old.count) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
        scale: _scale,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Stack(clipBehavior: Clip.none, children: [
            const Glass(
              radius: 16,
              child: SizedBox(width: 46, height: 46, child: Icon(Icons.shopping_bag_outlined, color: Colors.white)),
            ),
            if (widget.count > 0)
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(gradient: emberGradient, borderRadius: BorderRadius.circular(99)),
                  child: Text('${widget.count}', style: body(11, w: FontWeight.w800)),
                ),
              ),
          ]),
        ),
      );
}

class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const GlassIconButton({super.key, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Glass(radius: 14, child: SizedBox(width: 44, height: 44, child: Icon(icon, color: Colors.white))),
      );
}
