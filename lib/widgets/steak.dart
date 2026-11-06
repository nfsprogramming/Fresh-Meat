import 'package:flutter/material.dart';

import '../models.dart';

/// Illustrated cut. When you have real photos, use [MeatImage] instead.
class SteakWidget extends StatelessWidget {
  final MeatType type;
  final double width;
  const SteakWidget({super.key, this.type = MeatType.mutton, required this.width});

  @override
  Widget build(BuildContext context) => Semantics(
        label: '${type.name} cut illustration',
        image: true,
        child: RepaintBoundary(
          child: SizedBox(
            width: width,
            height: width * 160 / 210,
            child: CustomPaint(painter: SteakPainter(type)),
          ),
        ),
      );
}

/// Shows the product's real photo if it has one, otherwise the illustration.
class MeatImage extends StatelessWidget {
  final Product product;
  final double width;
  const MeatImage({super.key, required this.product, required this.width});

  @override
  Widget build(BuildContext context) {
    final p = product.photo;
    if (p == null) return SteakWidget(type: product.type, width: width);
    final isNetwork = p.startsWith('http');
    final cacheW = (width * 2.5).round();
    final img = isNetwork
        ? Image.network(
            p,
            fit: BoxFit.cover,
            cacheWidth: cacheW,
            errorBuilder: (_, __, ___) => SteakWidget(type: product.type, width: width),
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return Container(
                color: const Color(0x33000000),
                child: const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF5A3C)),
                  ),
                ),
              );
            },
          )
        : Image.asset(
            p,
            fit: BoxFit.cover,
            cacheWidth: cacheW,
            errorBuilder: (_, __, ___) => SteakWidget(type: product.type, width: width),
          );

    return Semantics(
      label: '${product.name} photo',
      image: true,
      child: RepaintBoundary(
        child: SizedBox(
          width: width,
          height: width * 160 / 210,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(width * .16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                img,
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(width * .16),
                    border: Border.all(color: Colors.white.withAlpha(40), width: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SteakPainter extends CustomPainter {
  final MeatType type;
  SteakPainter(this.type);

  static Path _body() => Path()
    ..moveTo(20, 82)
    ..cubicTo(8, 40, 58, 8, 112, 12)
    ..cubicTo(164, 16, 198, 42, 192, 80)
    ..cubicTo(186, 120, 130, 144, 80, 136)
    ..cubicTo(42, 130, 28, 112, 20, 82)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 210, size.height / 160);
    const rect = Rect.fromLTWH(0, 0, 210, 160);
    final body = _body();

    canvas.drawPath(
      body.shift(const Offset(0, 22)),
      Paint()
        ..color = const Color(0x66000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawPath(
      body,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.24, -.4),
          radius: .9,
          colors: type.steakColors,
          stops: const [0, .45, 1],
        ).createShader(rect),
    );

    final rim = Path()
      ..moveTo(20, 82)
      ..cubicTo(8, 40, 58, 8, 112, 12)
      ..cubicTo(164, 16, 198, 42, 192, 80);
    canvas.drawPath(
      rim,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF6EA), Color(0xFFE9C4A2)],
        ).createShader(rect),
    );

    final m = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x80FFD9CC);
    canvas.drawPath(Path()..moveTo(48, 62)..cubicTo(78, 40, 110, 50, 140, 68), m);
    canvas.drawPath(Path()..moveTo(58, 98)..cubicTo(90, 84, 120, 90, 156, 102), m);
    canvas.drawPath(Path()..moveTo(78, 38)..cubicTo(100, 50, 120, 46, 150, 30), m);
    canvas.drawPath(Path()..moveTo(96, 78)..cubicTo(110, 72, 126, 74, 140, 82), m);

    canvas.drawOval(Rect.fromCenter(center: const Offset(105, 118), width: 140, height: 28), Paint()..color = const Color(0x402A0305));
    canvas.drawOval(Rect.fromCenter(center: const Offset(80, 38), width: 84, height: 26), Paint()..color = const Color(0x38FFFFFF));
    canvas.drawCircle(const Offset(146, 94), 10, Paint()..color = const Color(0xFFFFF0E0));
    canvas.drawCircle(const Offset(146, 94), 5, Paint()..color = const Color(0xFFE6BF9A));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SteakPainter old) => old.type != type;
}
