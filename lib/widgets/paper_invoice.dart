import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../state/app_state.dart';

/// Shows the paper invoice modal for [order].
class PaperInvoiceWidget extends StatefulWidget {
  final Order order;
  const PaperInvoiceWidget({super.key, required this.order});

  static Future<void> show(BuildContext context, Order order) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<AppState>(),
        child: PaperInvoiceWidget(order: order),
      ),
    );
  }

  @override
  State<PaperInvoiceWidget> createState() => _PaperInvoiceWidgetState();
}

class _PaperInvoiceWidgetState extends State<PaperInvoiceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _stampCtrl;
  late Animation<double> _stampScale;
  late Animation<double> _stampOpacity;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _stampCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _stampScale = Tween<double>(begin: 3.0, end: 1.0).animate(
      CurvedAnimation(parent: _stampCtrl, curve: Curves.elasticOut),
    );
    _stampOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _stampCtrl, curve: const Interval(0, 0.3)),
    );
    // If already verified, show stamp immediately
    if (widget.order.isDeliveryVerified) {
      _stampCtrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _stampCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmDeliveryReceipt() async {
    if (_verifying) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E0A10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0x33FFFFFF)),
        ),
        title: const Text(
          'Confirm Delivery Receipt',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: const Text(
          'Have you received your fresh meat order with the cold-chain tamper seal verified?',
          style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Not Yet', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm Received'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _verifying = true);
    context.read<AppState>().verifyDeliveryWithQr(
      widget.order.id,
      executiveName: widget.order.driverName,
    );
    _stampCtrl.forward(from: 0);
    setState(() => _verifying = false);
  }

  @override
  Widget build(BuildContext context) {
    final order = context.select<AppState, Order?>(
          (s) => s.orders[widget.order.id],
        ) ??
        widget.order;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.97,
      minChildSize: 0.55,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFAF6EE),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: const Color(0xFFCCBEAB), borderRadius: BorderRadius.circular(2)),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: sc,
              padding: const EdgeInsets.only(bottom: 32),
              child: _buildPaper(order),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildPaper(Order order) {
    final isVerified = order.isDeliveryVerified;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Paper receipt card
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFDF8F0),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 20, offset: const Offset(0, 8)),
                BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(children: [
              // Sawtooth top tear edge
              CustomPaint(
                size: const Size(double.infinity, 16),
                painter: _SawtoothEdgePainter(top: true),
              ),

              // Receipt body
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  const SizedBox(height: 12),

                  // Header
                  _ReceiptHeader(order: order),
                  _dottedDivider(),
                  _HalalCert(order: order),
                  _dottedDivider(),
                  _CustomerBlock(order: order),
                  _dottedDivider(),
                  _ItemsBlock(order: order),
                  _dottedDivider(),
                  _TotalsBlock(order: order),
                  _dottedDivider(),

                  // QR Code
                  const SizedBox(height: 12),
                  Text(
                    'DELIVERY VERIFICATION QR',
                    style: _mono(10, color: const Color(0xFF8B7355)).copyWith(letterSpacing: 2),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFD4C4A8), width: 1),
                    ),
                    child: CustomPaint(
                      size: const Size(160, 160),
                      painter: _ReceiptQrPainter(data: order.verificationToken),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    order.invoiceNumber,
                    style: _mono(9, color: const Color(0xFF8B7355)).copyWith(letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Doorstep Cold-Chain Authentication',
                    style: _mono(9, color: const Color(0xFFAA9B85)),
                  ),

                  // Doorstep Delivery PIN (OTP)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3ECE0),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFD4C4A8), width: 1),
                    ),
                    child: Column(children: [
                      Text(
                        'DOORSTEP DELIVERY PIN',
                        style: _mono(9, color: const Color(0xFF8B7355), bold: true).copyWith(letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.deliveryPin,
                        style: _mono(20, color: const Color(0xFF2C1810), bold: true).copyWith(letterSpacing: 6),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Share with delivery partner or show QR upon arrival',
                        style: _mono(8, color: const Color(0xFFAA9B85)),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 12),

                  // Confirm delivery button (only if not verified)
                  if (!isVerified)
                    _ConfirmDeliveryButton(verifying: _verifying, onTap: _confirmDeliveryReceipt),

                  if (isVerified)
                    _VerifiedFooter(order: order),

                  const SizedBox(height: 20),
                ]),
              ),

              // Sawtooth bottom tear edge
              CustomPaint(
                size: const Size(double.infinity, 16),
                painter: _SawtoothEdgePainter(top: false),
              ),
            ]),
          ),

          // Rubber stamp overlay
          if (isVerified)
            Positioned(
              top: 120,
              right: 30,
              child: AnimatedBuilder(
                animation: _stampCtrl,
                builder: (_, __) => Opacity(
                  opacity: _stampOpacity.value,
                  child: Transform.scale(
                    scale: _stampScale.value,
                    child: Transform.rotate(
                      angle: -0.21, // ~12 degrees
                      child: CustomPaint(
                        size: const Size(130, 130),
                        painter: _RubberStampPainter(
                          executive: order.verificationExecutive ?? order.driverName,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dottedDivider() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: CustomPaint(
      size: const Size(double.infinity, 1),
      painter: _DottedLinePainter(),
    ),
  );
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ReceiptHeader extends StatelessWidget {
  final Order order;
  const _ReceiptHeader({required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text('🥩 FRESH MEAT', style: _mono(22, color: const Color(0xFF2C1810), bold: true).copyWith(letterSpacing: 3)),
      const SizedBox(height: 2),
      Text('ARTISANAL HALAL BUTCHERY', style: _mono(9, color: const Color(0xFF8B7355)).copyWith(letterSpacing: 2.5)),
      const SizedBox(height: 2),
      Text('Est. 2024 · Premium Cuts Since Dawn', style: _mono(8, color: const Color(0xFFAA9B85))),
      const SizedBox(height: 8),
      Text('ORDER RECEIPT', style: _mono(11, color: const Color(0xFF5C3D2E), bold: true).copyWith(letterSpacing: 3)),
      const SizedBox(height: 4),
      Text(order.invoiceNumber, style: _mono(10, color: const Color(0xFF8B7355)).copyWith(letterSpacing: 1.5)),
      const SizedBox(height: 2),
      Text(
        _formatDate(order.createdAt),
        style: _mono(9, color: const Color(0xFFAA9B85)),
      ),
    ]);
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}  $h:$m $ampm';
  }
}

class _HalalCert extends StatelessWidget {
  final Order order;
  const _HalalCert({required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _kv('HALAL CERT', 'HFAA/2024/00${order.id.padLeft(3, '0')}'),
      ]),
      const SizedBox(height: 4),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _kv('CUT BY', order.items.isNotEmpty ? order.items.first.product.butcher : 'Master Butcher'),
      ]),
    ]);
  }
}

class _CustomerBlock extends StatelessWidget {
  final Order order;
  const _CustomerBlock({required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _row2('CUSTOMER', order.customerName),
      const SizedBox(height: 3),
      _row2('PHONE', order.customerPhone),
      const SizedBox(height: 3),
      _row2('DELIVERY SLOT', order.slot),
      const SizedBox(height: 3),
      _row2('ADDRESS', order.deliveryAddress, maxLines: 2),
    ]);
  }
}

class _ItemsBlock extends StatelessWidget {
  final Order order;
  const _ItemsBlock({required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text('ITEM', style: _mono(9, color: const Color(0xFF8B7355)).copyWith(letterSpacing: 1.5))),
        Text('QTY', style: _mono(9, color: const Color(0xFF8B7355)).copyWith(letterSpacing: 1.5)),
        const SizedBox(width: 12),
        SizedBox(width: 55, child: Text('AMOUNT', textAlign: TextAlign.right, style: _mono(9, color: const Color(0xFF8B7355)).copyWith(letterSpacing: 1.5))),
      ]),
      const SizedBox(height: 6),
      for (final item in order.items) ...[
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.product.name, style: _mono(11, color: const Color(0xFF2C1810), bold: true)),
              Text(gramsLabel(item.grams), style: _mono(9, color: const Color(0xFFAA9B85))),
            ]),
          ),
          Text('×${item.qty}', style: _mono(11, color: const Color(0xFF5C3D2E))),
          const SizedBox(width: 12),
          SizedBox(
            width: 55,
            child: Text(
              rupees(item.lineTotal),
              textAlign: TextAlign.right,
              style: _mono(11, color: const Color(0xFF2C1810), bold: true),
            ),
          ),
        ]),
        const SizedBox(height: 6),
      ],
    ]);
  }
}

class _TotalsBlock extends StatelessWidget {
  final Order order;
  const _TotalsBlock({required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _totalRow('SUBTOTAL', rupees(order.total)),
      const SizedBox(height: 3),
      _totalRow('DELIVERY', 'FREE', valueColor: const Color(0xFF2E7D32)),
      _totalRow('PACKAGING', 'FREE', valueColor: const Color(0xFF2E7D32)),
      const SizedBox(height: 6),
      Container(height: 2, color: const Color(0xFF2C1810)),
      const SizedBox(height: 6),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('TOTAL', style: _mono(14, color: const Color(0xFF2C1810), bold: true).copyWith(letterSpacing: 2)),
        Text(rupees(order.total), style: _mono(14, color: const Color(0xFF2C1810), bold: true)),
      ]),
      const SizedBox(height: 4),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('PAYMENT', style: _mono(9, color: const Color(0xFF8B7355)).copyWith(letterSpacing: 1.5)),
        Text(order.paymentMethod.toUpperCase(), style: _mono(9, color: const Color(0xFF5C3D2E), bold: true)),
      ]),
    ]);
  }
}

class _ConfirmDeliveryButton extends StatelessWidget {
  final bool verifying;
  final VoidCallback onTap;
  const _ConfirmDeliveryButton({required this.verifying, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF2C1810),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (verifying) ...[
            const SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
            const SizedBox(width: 10),
          ] else
            const Icon(Icons.verified_user_rounded, color: Color(0xFFC5A059), size: 18),
          const SizedBox(width: 8),
          Text(
            verifying ? 'VERIFYING...' : 'CONFIRM DELIVERY RECEIVED',
            style: _mono(11, color: Colors.white, bold: true).copyWith(letterSpacing: 1.5),
          ),
        ]),
      ),
    );
  }
}

class _VerifiedFooter extends StatelessWidget {
  final Order order;
  const _VerifiedFooter({required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF2E7D32), width: 1.5),
        ),
        child: Column(children: [
          Text('✓ DELIVERY VERIFIED', style: _mono(12, color: const Color(0xFF1B5E20), bold: true).copyWith(letterSpacing: 2)),
          if (order.verifiedAt != null) ...[
            const SizedBox(height: 2),
            Text(_fmtVerified(order.verifiedAt!), style: _mono(9, color: const Color(0xFF2E7D32))),
          ],
          if (order.verificationExecutive != null) ...[
            const SizedBox(height: 2),
            Text('by ${order.verificationExecutive}', style: _mono(9, color: const Color(0xFF388E3C))),
          ],
        ]),
      ),
      const SizedBox(height: 12),
      Text(
        'Thank you for choosing Fresh Meat!\nEnjoy your premium halal cuts.',
        textAlign: TextAlign.center,
        style: _mono(9, color: const Color(0xFFAA9B85)),
      ),
    ]);
  }

  String _fmtVerified(DateTime dt) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${m[dt.month - 1]} ${dt.year} · $h:$min $ap';
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _kv(String k, String v) => RichText(
  textAlign: TextAlign.center,
  text: TextSpan(children: [
    TextSpan(text: '$k: ', style: _mono(9, color: const Color(0xFF8B7355))),
    TextSpan(text: v, style: _mono(9, color: const Color(0xFF2C1810), bold: true)),
  ]),
);

Widget _row2(String label, String value, {int maxLines = 1}) => Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    SizedBox(
      width: 90,
      child: Text(label, style: _mono(9, color: const Color(0xFF8B7355)).copyWith(letterSpacing: 1)),
    ),
    Expanded(
      child: Text(
        value,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: _mono(9, color: const Color(0xFF2C1810), bold: true),
      ),
    ),
  ],
);

Widget _totalRow(String label, String value, {Color? valueColor}) => Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text(label, style: _mono(10, color: const Color(0xFF8B7355)).copyWith(letterSpacing: 1)),
    Text(value, style: _mono(10, color: valueColor ?? const Color(0xFF2C1810), bold: true)),
  ],
);

TextStyle _mono(double size, {Color color = const Color(0xFF2C1810), bool bold = false}) => TextStyle(
  fontFamily: 'Courier',
  fontSize: size,
  color: color,
  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
  height: 1.4,
);

// ── Painters ─────────────────────────────────────────────────────────────────

class _SawtoothEdgePainter extends CustomPainter {
  final bool top;
  const _SawtoothEdgePainter({required this.top});

  @override
  void paint(Canvas canvas, Size size) {
    const toothW = 12.0;
    const bg = Color(0xFFFDF8F0);
    final paint = Paint()..color = bg;
    final path = Path();

    if (top) {
      path.moveTo(0, size.height);
      var x = 0.0;
      while (x < size.width) {
        path.lineTo(x + toothW / 2, 0);
        path.lineTo(x + toothW, size.height);
        x += toothW;
      }
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      var x = 0.0;
      while (x < size.width) {
        path.lineTo(x + toothW / 2, size.height);
        path.lineTo(x + toothW, 0);
        x += toothW;
      }
      path.lineTo(size.width, 0);
    }
    path.close();

    // Draw shadow of torn edge on the backing
    final shadowPaint = Paint()
      ..color = const Color(0x18000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4C4A8)
      ..strokeWidth = 1;
    const dash = 4.0, gap = 4.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _RubberStampPainter extends CustomPainter {
  final String executive;
  const _RubberStampPainter({required this.executive});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 4;
    final ink = const Color(0xFF2E7D32).withAlpha(200);

    final circlePaint = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(c, r, circlePaint);
    canvas.drawCircle(c, r - 6, circlePaint..strokeWidth = 1.5);

    void drawText(String text, double radius, double startAngle, {double fontSize = 8}) {
      final chars = text.split('');
      final totalAngle = (chars.length - 1) * (fontSize * 1.1) / radius;
      var angle = startAngle - totalAngle / 2;
      for (final ch in chars) {
        canvas.save();
        canvas.translate(c.dx + radius * math.cos(angle), c.dy + radius * math.sin(angle));
        canvas.rotate(angle + math.pi / 2);
        final tp = TextPainter(
          text: TextSpan(text: ch, style: TextStyle(color: ink, fontSize: fontSize, fontWeight: FontWeight.bold, fontFamily: 'Courier')),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
        canvas.restore();
        angle += (fontSize * 1.1) / radius;
      }
    }

    drawText('DELIVERY VERIFIED · OTP CONFIRMED', r - 10, -math.pi / 2, fontSize: 7);

    // Center checkmark and text
    final tp = TextPainter(
      text: TextSpan(
        children: [
          const TextSpan(text: '✓\n', style: TextStyle(color: Color(0xFF2E7D32), fontSize: 26, fontWeight: FontWeight.bold)),
          TextSpan(
            text: executive.split(' ').first.toUpperCase(),
            style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 7, fontWeight: FontWeight.bold, fontFamily: 'Courier', letterSpacing: 1),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 20);
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _RubberStampPainter o) => o.executive != executive;
}

/// Renders a visually scannable QR-style grid using the order token as seed.
/// Uses standard finder patterns (3 corner 7×7 boxes) + deterministic data modules.
class _ReceiptQrPainter extends CustomPainter {
  final String data;
  const _ReceiptQrPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    const modules = 25; // grid size
    final cell = size.width / modules;
    const ink = Color(0xFF1A0F00);
    final paint = Paint()..color = ink;

    // Build module grid deterministically from data hash
    final grid = List.generate(modules, (r) => List.generate(modules, (c) => false));

    // Finder patterns: top-left, top-right, bottom-left
    void drawFinder(int row, int col) {
      for (var r = 0; r < 7; r++) {
        for (var c = 0; c < 7; c++) {
          final isOuter = r == 0 || r == 6 || c == 0 || c == 6;
          final isInner = r >= 2 && r <= 4 && c >= 2 && c <= 4;
          grid[row + r][col + c] = isOuter || isInner;
        }
      }
    }
    drawFinder(0, 0);
    drawFinder(0, modules - 7);
    drawFinder(modules - 7, 0);

    // Timing patterns
    for (var i = 8; i < modules - 8; i++) {
      grid[6][i] = i.isEven;
      grid[i][6] = i.isEven;
    }

    // Data modules from hash
    final seed = data.codeUnits.fold(0, (h, c) => (h * 31 + c) & 0x7FFFFFFF);
    final rng = math.Random(seed);
    final safeZones = <String>{};
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        safeZones.add('$r,$c');
        safeZones.add('$r,${modules - 1 - c}');
        safeZones.add('${modules - 1 - r},$c');
      }
    }
    for (var r = 4; r < 7; r++) {
      for (var c = 4; c < 7; c++) {
        safeZones.add('$r,$c');
      }
    }

    for (var r = 0; r < modules; r++) {
      for (var c = 0; c < modules; c++) {
        if (safeZones.contains('$r,$c')) continue;
        if (rng.nextDouble() > 0.55) grid[r][c] = true;
      }
    }

    // Paint
    for (var r = 0; r < modules; r++) {
      for (var c = 0; c < modules; c++) {
        if (grid[r][c]) {
          canvas.drawRect(
            Rect.fromLTWH(c * cell, r * cell, cell - 0.3, cell - 0.3),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ReceiptQrPainter old) => old.data != data;
}
