import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Flies an origami craft paper bag from [from] widget to [to] widget:
/// 1. The open kraft paper bag appears and unfolds on screen.
/// 2. The selected cut of meat slides directly down into the open bag.
/// 3. The paper bag creases and folds shut with a gold wax seal.
/// 4. The sealed kraft parcel glides along a 3D parabolic arc into the cart.
class FlyToBag {
  static void run(
    BuildContext context, {
    required GlobalKey from,
    required GlobalKey to,
    required Widget child,
    int grams = 1000,
    required VoidCallback onLanded,
  }) {
    final fb = from.currentContext?.findRenderObject() as RenderBox?;
    final tb = to.currentContext?.findRenderObject() as RenderBox?;
    if (fb == null || tb == null || !fb.attached || !tb.attached) {
      onLanded();
      return;
    }

    final start = fb.localToGlobal(fb.size.center(Offset.zero));
    final end = tb.localToGlobal(tb.size.center(Offset.zero));
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _OrigamiFlyOverlay(
        start: start,
        end: end,
        grams: grams,
        onDone: () {
          entry.remove();
          onLanded();
        },
        child: child,
      ),
    );

    overlay.insert(entry);
  }
}

class _OrigamiFlyOverlay extends StatefulWidget {
  final Offset start;
  final Offset end;
  final Widget child;
  final int grams;
  final VoidCallback onDone;

  const _OrigamiFlyOverlay({
    required this.start,
    required this.end,
    required this.child,
    this.grams = 1000,
    required this.onDone,
  });

  @override
  State<_OrigamiFlyOverlay> createState() => _OrigamiFlyOverlayState();
}

class _OrigamiFlyOverlayState extends State<_OrigamiFlyOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _dropHapticFired = false;
  bool _foldHapticFired = false;
  bool _landHapticFired = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    );

    _controller.addListener(() {
      final t = _controller.value;
      // 1. Meat lands inside open bag
      if (t >= 0.34 && !_dropHapticFired) {
        _dropHapticFired = true;
        HapticFeedback.selectionClick();
      }
      // 2. Paper flap creases and wax seal stamps shut
      if (t >= 0.54 && !_foldHapticFired) {
        _foldHapticFired = true;
        HapticFeedback.lightImpact();
      }
      // 3. Arrives at cart target
      if (t >= 0.92 && !_landHapticFired) {
        _landHapticFired = true;
        HapticFeedback.mediumImpact();
      }
    });

    _controller.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Offset _bezier(double t) {
    final p0 = widget.start;
    final p2 = widget.end;
    final midX = (p0.dx + p2.dx) / 2;
    // Graceful arch, staying clear of status bar / header
    final highestY = math.min(p0.dy, p2.dy);
    final archY = math.max(48.0, highestY - 145);
    final p1 = Offset(midX, archY);

    final a = (1 - t) * (1 - t);
    final b = 2 * (1 - t) * t;
    final c = t * t;
    return Offset(
      a * p0.dx + b * p1.dx + c * p2.dx,
      a * p0.dy + b * p1.dy + c * p2.dy,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;

            // --- Stage 1: Bag Appears & Opens (0.00 - 0.20) ---
            final bagOpenRaw = (t / 0.20).clamp(0.0, 1.0);
            final bagOpenProgress = Curves.easeOutBack.transform(bagOpenRaw);

            // --- Stage 2: Meat Slides Down into Bag (0.18 - 0.42) ---
            final meatDropRaw = ((t - 0.18) / 0.24).clamp(0.0, 1.0);
            final meatDropProgress = Curves.easeInOutCubic.transform(meatDropRaw);

            // --- Stage 3: Origami Flap Creases & Seals (0.42 - 0.60) ---
            final foldRaw = ((t - 0.42) / 0.18).clamp(0.0, 1.0);
            final foldProgress = Curves.easeInOutCubic.transform(foldRaw);

            // --- Stage 4: 3D Flight to Cart (0.60 - 0.94) ---
            final flightRaw = ((t - 0.60) / 0.34).clamp(0.0, 1.0);
            final flightT = Curves.easeInOutCubic.transform(flightRaw);

            // --- Stage 5: Cart Settle & Impact (0.90 - 1.00) ---
            final impactRaw = ((t - 0.90) / 0.10).clamp(0.0, 1.0);
            final opacity = (1.0 - impactRaw).clamp(0.0, 1.0);

            // Position along parabolic arc (stays at start until flight starts)
            final pos = t < 0.60 ? widget.start : _bezier(flightT);

            // Dynamic sizing factor: bigger bag for bigger quantity
            // 500g: 0.94 (compact pouch), 1kg: 1.08 (standard sack), 2kg: 1.25 (generous butcher sack)
            final double qtyScale = widget.grams <= 500
                ? 0.94
                : (widget.grams >= 2000 ? 1.25 : 1.08);

            final double weightFactor = widget.grams <= 500
                ? 0.82
                : (widget.grams >= 2000 ? 1.35 : 1.0);

            // Tactile squash on meat drop impact (satisfying heavy thud for 2kg)
            double squashX = 1.0;
            double squashY = 1.0;
            if (t >= 0.32 && t <= 0.44) {
              final impactPhase = (t - 0.32) / 0.12;
              final wave = math.sin(impactPhase * math.pi);
              squashY = 1.0 - (0.08 * weightFactor) * wave;
              squashX = 1.0 + (0.06 * weightFactor) * wave;
            }

            // Overall scale: pops open with quantity size, absorbs meat drop, then scales down towards cart button
            double scale;
            if (t < 0.60) {
              scale = bagOpenProgress * qtyScale;
            } else {
              // Smooth scale down to match cart button scale
              scale = math.max(0.28, qtyScale * (1.0 - 0.72 * flightT));
            }

            // 3D paper rotation and aerodynamic flight wobble
            final wobble = math.sin(flightT * math.pi * 3.5) * 0.16;
            final flightRotation = -0.26 + flightT * 0.52 + wobble;

            return Stack(
              children: [
                Positioned(
                  left: pos.dx - 55,
                  top: pos.dy - 65,
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.002) // 3D paper perspective
                          ..rotateZ(t < 0.60 ? 0.0 : flightRotation)
                          ..rotateY(wobble * 0.7)
                          ..rotateX(flightT * 0.18),
                        child: Transform.scale(
                          scaleX: squashX,
                          scaleY: squashY,
                          alignment: Alignment.bottomCenter,
                          child: SizedBox(
                            width: 110,
                            height: 130,
                            child: OrigamiFoldPackage(
                              bagOpenProgress: bagOpenProgress,
                              meatDropProgress: meatDropProgress,
                              foldProgress: foldProgress,
                              flightProgress: flightT,
                              grams: widget.grams,
                              child: widget.child,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Tiny origami golden spark burst when tucked into the cart
                if (t >= 0.88)
                  Positioned(
                    left: widget.end.dx - 32,
                    top: widget.end.dy - 32,
                    child: OrigamiSparkBurst(progress: impactRaw),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Renders a multi-layer realistic Origami Kraft Paper Butcher Bag:
/// Layer 1: Soft ground shadow
/// Layer 2: Back wall, rope handles, and dark inner cavity
/// Layer 3: Meat cut sliding down into the open bag
/// Layer 4: Front wall with serrated rim, side gussets, bottom tucks, and folding flap + gold seal
/// Layer 5: Artisanal butcher parcel weight ink stamp
class OrigamiFoldPackage extends StatelessWidget {
  final double bagOpenProgress;
  final double meatDropProgress;
  final double foldProgress;
  final double flightProgress;
  final int grams;
  final Widget child;

  const OrigamiFoldPackage({
    super.key,
    required this.bagOpenProgress,
    required this.meatDropProgress,
    required this.foldProgress,
    this.flightProgress = 0.0,
    this.grams = 1000,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Meat slides from floating above the bag mouth down into the pouch
    // Starts at y = -14 (above rim) and drops to y = 24 (deep in the bag)
    final meatY = -14.0 + 38.0 * meatDropProgress;
    final meatScale = 1.0 - 0.22 * meatDropProgress;
    final meatOpacity = (1.0 - foldProgress * 1.6).clamp(0.0, 1.0);

    return Stack(
      alignment: Alignment.center,
      children: [
        // 1. Soft Dimensional Drop Shadow (fades when flying high)
        Positioned(
          bottom: 6,
          child: Container(
            width: grams >= 2000 ? 86 : (grams <= 500 ? 68 : 74),
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(
                    (85 * bagOpenProgress * (1.0 - flightProgress * 0.8)).toInt(),
                  ),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: Offset(0, 4 * (1.0 - flightProgress)),
                ),
              ],
            ),
          ),
        ),

        // 2. Paper Bag Back Layer (Back twisted handles, back wall & inner dark cavity)
        CustomPaint(
          size: const Size(110, 130),
          painter: _OrigamiBagBackPainter(
            openProgress: bagOpenProgress,
          ),
        ),

        // 3. Meat Cut (sandwiched between back cavity and front panel)
        Positioned(
          top: meatY,
          child: Opacity(
            opacity: meatOpacity,
            child: Transform.scale(
              scale: meatScale,
              child: SizedBox(
                width: grams <= 500 ? 56.0 : (grams >= 2000 ? 70.0 : 62.0),
                height: grams <= 500 ? 56.0 : (grams >= 2000 ? 70.0 : 62.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    child,
                    // Submerged depth shadow as meat slides deeper into the bag cavity
                    if (meatDropProgress > 0.15)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withAlpha(
                                  (140 * meatDropProgress).toInt(),
                                ),
                              ],
                              stops: const [0.35, 1.0],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 4. Paper Bag Front Layer (Serrated rim, front panel, accordion gussets,
        //    bottom folds, front handles, folding flap & gold wax seal)
        CustomPaint(
          size: const Size(110, 130),
          painter: _OrigamiBagFrontPainter(
            openProgress: bagOpenProgress,
            foldProgress: foldProgress,
          ),
        ),

        // 5. Artisanal Butcher Parcel Weight Ink Stamp (appears when bag is folded)
        if (foldProgress > 0.25)
          Positioned(
            bottom: 22,
            right: 18,
            child: Opacity(
              opacity: ((foldProgress - 0.25) / 0.75).clamp(0.0, 0.88),
              child: Transform.rotate(
                angle: -0.10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE59247).withAlpha(85),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFF451704).withAlpha(150),
                      width: 1.1,
                    ),
                  ),
                  child: Text(
                    grams >= 1000
                        ? '${(grams / 1000).toStringAsFixed(grams % 1000 == 0 ? 0 : 1)} KG'
                        : '${grams}G',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF381203),
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Paints the rear half of the paper bag:
/// - Twisted kraft paper cord back handle
/// - Kraft paper glue reinforcement tabs
/// - Back wall with subtle kraft gradient
/// - Dark inner cavity shadow providing realistic depth
class _OrigamiBagBackPainter extends CustomPainter {
  final double openProgress;

  _OrigamiBagBackPainter({required this.openProgress});

  @override
  void paint(Canvas canvas, Size size) {
    if (openProgress <= 0.02) return;

    const bagLeft = 20.0;
    const bagRight = 90.0;
    const bagWidth = bagRight - bagLeft;
    const bagBottom = 118.0;
    const backRimY = 40.0;

    final paint = Paint()..isAntiAlias = true;

    // 1. Back Twisted Kraft Rope Handle
    final handlePaint = Paint()
      ..color = const Color(0xFF7C3510)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    final handleHighlight = Paint()
      ..color = const Color(0xFFBA6F33)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final handlePath = Path()
      ..moveTo(bagLeft + 16, backRimY + 4)
      ..cubicTo(
        bagLeft + 16,
        14.0,
        bagRight - 16,
        14.0,
        bagRight - 16,
        backRimY + 4,
      );

    canvas.drawPath(handlePath, handlePaint);
    canvas.drawPath(handlePath, handleHighlight);

    // 2. Glue reinforcement tabs on back handle
    final tabPaint = Paint()
      ..color = const Color(0xFF8F4113)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bagLeft + 12, backRimY + 2, 9, 8),
        const Radius.circular(2),
      ),
      tabPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bagRight - 21, backRimY + 2, 9, 8),
        const Radius.circular(2),
      ),
      tabPaint,
    );

    // 3. Back Wall & Inner Cavity
    // Serrated back rim
    const teethCount = 10;
    const toothW = bagWidth / teethCount;
    final backWall = Path()..moveTo(bagLeft, backRimY);
    for (int i = 0; i < teethCount; i++) {
      final x0 = bagLeft + i * toothW;
      final xMid = x0 + toothW / 2;
      final x1 = x0 + toothW;
      backWall.lineTo(xMid, backRimY - 2.5);
      backWall.lineTo(x1, backRimY);
    }
    backWall.lineTo(bagRight, bagBottom);
    backWall.lineTo(bagLeft, bagBottom);
    backWall.close();

    // Deep interior kraft gradient
    final cavityGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Color(0xFF6B2909), // Dark upper inner rim
        Color(0xFF451704), // Deep bag cavity
        Color(0xFF240A01), // Pitch shadow at bottom of bag
      ],
      stops: const [0.0, 0.45, 1.0],
    );

    paint.shader = cavityGradient.createShader(
      Rect.fromLTRB(bagLeft, backRimY, bagRight, bagBottom),
    );
    canvas.drawPath(backWall, paint);
  }

  @override
  bool shouldRepaint(covariant _OrigamiBagBackPainter oldDelegate) =>
      oldDelegate.openProgress != openProgress;
}

/// Paints the front half of the paper bag:
/// - Front wall with natural kraft paper shading & micro-creases
/// - Serrated die-cut top rim (classic kraft grocery bag teeth)
/// - Accordion side gussets with dimensional V-folds
/// - Bottom envelope origami fold creases
/// - Front twisted paper cord handle
/// - Origami top flap that folds shut over the meat
/// - Gold wax seal with Halal/star stamp
class _OrigamiBagFrontPainter extends CustomPainter {
  final double openProgress;
  final double foldProgress;

  _OrigamiBagFrontPainter({
    required this.openProgress,
    required this.foldProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (openProgress <= 0.02) return;

    final w = size.width;
    const bagLeft = 20.0;
    const bagRight = 90.0;
    const bagWidth = bagRight - bagLeft;
    const bagBottom = 118.0;
    const frontRimY = 50.0;
    const bagHeight = bagBottom - frontRimY;

    final paint = Paint()..isAntiAlias = true;

    // 1. Front Wall with Serrated Die-Cut Teeth Rim
    const teethCount = 12;
    const toothW = bagWidth / teethCount;
    final frontBody = Path()..moveTo(bagLeft, frontRimY);
    for (int i = 0; i < teethCount; i++) {
      final x0 = bagLeft + i * toothW;
      final xMid = x0 + toothW / 2;
      final x1 = x0 + toothW;
      frontBody.lineTo(xMid, frontRimY - 2.5);
      frontBody.lineTo(x1, frontRimY);
    }
    frontBody.lineTo(bagRight, bagBottom - 4);
    frontBody.cubicTo(bagRight, bagBottom, bagRight - 4, bagBottom, bagRight - 6, bagBottom);
    frontBody.lineTo(bagLeft + 6, bagBottom);
    frontBody.cubicTo(bagLeft + 4, bagBottom, bagLeft, bagBottom, bagLeft, bagBottom - 4);
    frontBody.close();

    // Warm artisanal Kraft Paper Gradient
    final bodyGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: const [
        Color(0xFFE59247), // Warm kraft sunlight highlight
        Color(0xFFD27B31), // Natural unbleached craft paper
        Color(0xFFA8551B), // Butcher craft amber
        Color(0xFF78340C), // Shaded paper fold edge
      ],
      stops: const [0.0, 0.35, 0.78, 1.0],
    );

    paint.shader = bodyGradient.createShader(
      Rect.fromLTRB(bagLeft, frontRimY, bagRight, bagBottom),
    );
    canvas.drawPath(frontBody, paint);

    // 2. Accordion Side Gusset Folds (V-pleats on left and right)
    final leftGusset = Path()
      ..moveTo(bagLeft, frontRimY)
      ..lineTo(bagLeft + 9.0, frontRimY + bagHeight * 0.48)
      ..lineTo(bagLeft, bagBottom)
      ..close();

    final rightGusset = Path()
      ..moveTo(bagRight, frontRimY)
      ..lineTo(bagRight - 9.0, frontRimY + bagHeight * 0.48)
      ..lineTo(bagRight, bagBottom)
      ..close();

    final gussetPaint = Paint()
      ..color = Colors.black.withAlpha(48)
      ..style = PaintingStyle.fill;
    canvas.drawPath(leftGusset, gussetPaint);
    canvas.drawPath(rightGusset, gussetPaint);

    // Gusset crease ridge lines
    final creaseRidgePaint = Paint()
      ..color = const Color(0xFFFFE2B8).withAlpha(100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(bagLeft, frontRimY),
      Offset(bagLeft + 9.0, frontRimY + bagHeight * 0.48),
      creaseRidgePaint,
    );
    canvas.drawLine(
      Offset(bagLeft + 9.0, frontRimY + bagHeight * 0.48),
      Offset(bagLeft, bagBottom),
      creaseRidgePaint,
    );
    canvas.drawLine(
      Offset(bagRight, frontRimY),
      Offset(bagRight - 9.0, frontRimY + bagHeight * 0.48),
      creaseRidgePaint,
    );
    canvas.drawLine(
      Offset(bagRight - 9.0, frontRimY + bagHeight * 0.48),
      Offset(bagRight, bagBottom),
      creaseRidgePaint,
    );

    // 3. Subtle Kraft Paper Grain & Diagonal Creases
    final fiberPaint = Paint()
      ..color = const Color(0xFFFFDFC0).withAlpha(45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    canvas.drawLine(
      Offset(bagLeft + 8, bagBottom - 10),
      Offset(bagRight - 8, frontRimY + 8),
      fiberPaint,
    );
    canvas.drawLine(
      Offset(bagRight - 8, bagBottom - 10),
      Offset(bagLeft + 8, frontRimY + 8),
      fiberPaint,
    );

    // Center vertical fold guide
    canvas.drawLine(
      Offset(w * 0.5, frontRimY + 4),
      Offset(w * 0.5, bagBottom - 6),
      Paint()
        ..color = Colors.black.withAlpha(35)
        ..strokeWidth = 1.1,
    );

    // 4. Bottom Envelope Origami Fold (Classic paper bag bottom)
    final bottomTuck = Path()
      ..moveTo(bagLeft + 4, bagBottom - 12)
      ..lineTo(bagLeft + 16, bagBottom)
      ..lineTo(bagRight - 16, bagBottom)
      ..lineTo(bagRight - 4, bagBottom - 12)
      ..close();

    canvas.drawPath(
      bottomTuck,
      Paint()
        ..color = Colors.black.withAlpha(28)
        ..style = PaintingStyle.fill,
    );

    final bottomFoldLine = Paint()
      ..color = const Color(0xFFFFDEB5).withAlpha(90)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(bagLeft + 4, bagBottom - 12),
      Offset(bagRight - 4, bagBottom - 12),
      bottomFoldLine,
    );
    canvas.drawLine(
      Offset(bagLeft + 4, bagBottom - 12),
      Offset(bagLeft + 16, bagBottom),
      bottomFoldLine,
    );
    canvas.drawLine(
      Offset(bagRight - 4, bagBottom - 12),
      Offset(bagRight - 16, bagBottom),
      bottomFoldLine,
    );

    // 5. Front Twisted Kraft Rope Handle
    final frontHandlePaint = Paint()
      ..color = const Color(0xFF8F3E12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final frontHandleHighlight = Paint()
      ..color = const Color(0xFFE2924E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    final frontHandlePath = Path()
      ..moveTo(bagLeft + 16, frontRimY + 6)
      ..cubicTo(
        bagLeft + 16,
        22.0,
        bagRight - 16,
        22.0,
        bagRight - 16,
        frontRimY + 6,
      );

    canvas.drawPath(frontHandlePath, frontHandlePaint);
    canvas.drawPath(frontHandlePath, frontHandleHighlight);

    // Handle glue reinforcement patches
    final patchPaint = Paint()
      ..color = const Color(0xFFA5511D)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bagLeft + 12, frontRimY + 4, 9, 8),
        const Radius.circular(2),
      ),
      patchPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bagRight - 21, frontRimY + 4, 9, 8),
        const Radius.circular(2),
      ),
      patchPaint,
    );

    // 6. Outer paper contour border
    canvas.drawPath(
      frontBody,
      Paint()
        ..color = const Color(0xFFFFD49E).withAlpha(95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );

    // 7. Stage 3 Origami Top Folding Flap (folds down over the opening)
    if (foldProgress > 0.01) {
      final flapHeight = 28.0 * foldProgress;
      final flapBottom = frontRimY + flapHeight;

      final flapPath = Path()
        ..moveTo(bagLeft + 1, frontRimY)
        ..lineTo(bagRight - 1, frontRimY)
        ..lineTo(bagRight - 3, flapBottom - 3)
        ..lineTo(w * 0.5, flapBottom + 3 * foldProgress)
        ..lineTo(bagLeft + 3, flapBottom - 3)
        ..close();

      final flapGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0xFFEBA052), // Golden folded crease top
          Color(0xFFC76F26), // Kraft body
          Color(0xFF8F4110), // Flap bottom shade
        ],
      );

      final flapPaint = Paint()
        ..shader = flapGradient.createShader(
          Rect.fromLTWH(bagLeft, frontRimY, bagWidth, flapHeight + 4),
        )
        ..style = PaintingStyle.fill;

      // Drop shadow from flap onto the bag
      canvas.drawShadow(flapPath, Colors.black, 4.0 * foldProgress, true);
      canvas.drawPath(flapPath, flapPaint);

      // Flap crease highlight along top fold
      canvas.drawLine(
        Offset(bagLeft + 1, frontRimY),
        Offset(bagRight - 1, frontRimY),
        Paint()
          ..color = const Color(0xFFFFF2D4).withAlpha(190)
          ..strokeWidth = 1.5,
      );

      // Flap edge contour
      canvas.drawPath(
        flapPath,
        Paint()
          ..color = const Color(0xFFFFE8BC).withAlpha(140)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1,
      );

      // 8. Gold Wax Seal / Halal Star Stamp (presses onto the folded flap)
      if (foldProgress >= 0.55) {
        final sealProgress = ((foldProgress - 0.55) / 0.45).clamp(0.0, 1.0);
        final sealScale = Curves.elasticOut.transform(sealProgress);

        final sealCenter = Offset(w * 0.5, flapBottom);
        final sealRadius = 13.0 * sealScale;

        // Seal drop shadow
        canvas.drawCircle(
          sealCenter + const Offset(0, 1.5),
          sealRadius,
          Paint()..color = Colors.black.withAlpha(70),
        );

        // Radial gold wax gradient
        final sealGradient = RadialGradient(
          colors: const [
            Color(0xFFFFF19E), // Golden wax highlight
            Color(0xFFD69C22), // Warm burnished gold
            Color(0xFF7E4B07), // Deep wax edge
          ],
        );

        canvas.drawCircle(
          sealCenter,
          sealRadius,
          Paint()
            ..shader = sealGradient.createShader(
              Rect.fromCircle(center: sealCenter, radius: sealRadius),
            ),
        );

        // Gold seal border
        canvas.drawCircle(
          sealCenter,
          sealRadius,
          Paint()
            ..color = const Color(0xFFFFFAD6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.1,
        );

        // Inner seal star / crest
        if (sealScale > 0.4) {
          final starPaint = Paint()
            ..color = const Color(0xFF381603)
            ..style = PaintingStyle.fill;

          final starPath = Path();
          const points = 5;
          final outerR = 6.0 * sealScale;
          final innerR = 2.8 * sealScale;

          for (int i = 0; i < points * 2; i++) {
            final r = i.isEven ? outerR : innerR;
            final angle = (i * math.pi / points) - math.pi / 2;
            final x = sealCenter.dx + math.cos(angle) * r;
            final y = sealCenter.dy + math.sin(angle) * r;
            if (i == 0) {
              starPath.moveTo(x, y);
            } else {
              starPath.lineTo(x, y);
            }
          }
          starPath.close();
          canvas.drawPath(starPath, starPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OrigamiBagFrontPainter oldDelegate) =>
      oldDelegate.openProgress != openProgress ||
      oldDelegate.foldProgress != foldProgress;
}

/// Little confetti/spark triangles burst when the origami bag lands in the cart.
class OrigamiSparkBurst extends StatelessWidget {
  final double progress;

  const OrigamiSparkBurst({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(64, 64),
      painter: _SparkPainter(progress: progress),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final double progress;

  _SparkPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const count = 8;
    final p = Curves.easeOutQuad.transform(progress);
    final alpha = (1.0 - progress).clamp(0.0, 1.0);

    for (int i = 0; i < count; i++) {
      final angle = (i * 2 * math.pi / count) + 0.25;
      final dist = 8 + 26 * p;
      final sparkCenter = Offset(
        center.dx + math.cos(angle) * dist,
        center.dy + math.sin(angle) * dist,
      );

      final sparkColors = [
        const Color(0xFFFFD700), // Gold
        const Color(0xFFE53935), // Red
        const Color(0xFFFFA726), // Amber
        const Color(0xFFFFE082), // Light Gold
      ];

      final sparkPaint = Paint()
        ..color = sparkColors[i % sparkColors.length]
            .withAlpha((255 * alpha).toInt())
        ..style = PaintingStyle.fill;

      // Small paper origami diamond/triangle
      final triSize = 4.2 * (1.0 - 0.35 * p);
      final triPath = Path()
        ..moveTo(sparkCenter.dx, sparkCenter.dy - triSize)
        ..lineTo(sparkCenter.dx + triSize * 0.8, sparkCenter.dy)
        ..lineTo(sparkCenter.dx, sparkCenter.dy + triSize)
        ..lineTo(sparkCenter.dx - triSize * 0.8, sparkCenter.dy)
        ..close();

      canvas.save();
      canvas.translate(sparkCenter.dx, sparkCenter.dy);
      canvas.rotate(angle + p * 2.8);
      canvas.translate(-sparkCenter.dx, -sparkCenter.dy);
      canvas.drawPath(triPath, sparkPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

