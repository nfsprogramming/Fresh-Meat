import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/steak.dart';
import '../services/location_service.dart';
import '../widgets/delivery_address_sheet.dart';
import 'tracking_screen.dart';

class BagScreen extends StatefulWidget {
  const BagScreen({super.key});

  @override
  State<BagScreen> createState() => _BagScreenState();
}

class _BagScreenState extends State<BagScreen> {
  List<String> get _slots => getDynamicSlots();

  Future<bool> _place(BuildContext context) async {
    final state = context.read<AppState>();
    if (state.selectedAddress == 'Tap to add delivery address' || state.selectedAddress.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: const Color(0xFF1F0A10),
        behavior: SnackBarBehavior.floating,
        content: Text('Please enter a delivery address first.', style: body(13)),
      ));
      _showAddressDialog(context);
      return false;
    }
    final result = state.placeOrder();
    if (result == null) return false;
    if (result.duplicate) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: const Color(0xFF1F0A10),
        behavior: SnackBarBehavior.floating,
        content: Text('Active order already in progress. Showing order #${result.order.id}.', style: body(13)),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: const Color(0xFF1F0A10),
        behavior: SnackBarBehavior.floating,
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: C.gold, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text('Order #${result.order.id} placed! The butcher is preparing your fresh cuts.', style: body(13, w: FontWeight.w700))),
        ]),
      ));
    }
    if (mounted) {
      Navigator.of(context).pushReplacement(fadeRoute(TrackingScreen(initialOrderId: result.order.id)));
    }
    return true;
  }

  void _showAddressDialog(BuildContext context) {
    final state = context.read<AppState>();
    final addressCtrl = TextEditingController(text: state.selectedAddress == 'Tap to add delivery address' ? '' : state.selectedAddress);
    final nameCtrl = TextEditingController(text: state.customerName);
    final phoneCtrl = TextEditingController(text: state.customerPhone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E0A10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: op(Colors.white, .15))),
        title: Text('Delivery Details', style: display(18)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recipient Name', style: body(12, color: op(Colors.white, .7))),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                style: body(14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: op(Colors.white, .08),
                  hintText: 'e.g. Rahul Sharma',
                  hintStyle: body(13, color: op(Colors.white, .4)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              Text('Contact Phone', style: body(12, color: op(Colors.white, .7))),
              const SizedBox(height: 6),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                style: body(14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: op(Colors.white, .08),
                  hintText: 'e.g. +91 98765 43210',
                  hintStyle: body(13, color: op(Colors.white, .4)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Delivery Address', style: body(12, color: op(Colors.white, .7))),
                  GestureDetector(
                    onTap: () async {
                      final loc = await LocationService.instance.getCurrentLocation();
                      if (loc != null) {
                        addressCtrl.text = loc.formattedAddress;
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.my_location_rounded, size: 13, color: C.gold),
                        const SizedBox(width: 4),
                        Text('Detect GPS', style: body(11, color: C.gold, w: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: addressCtrl,
                style: body(14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: op(Colors.white, .08),
                  hintText: 'e.g. Flat 302, Lake View Apts, Main Rd',
                  hintStyle: body(13, color: op(Colors.white, .4)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: body(13, color: op(Colors.white, .7))),
          ),
          BouncyPress(
            onTap: () {
              if (addressCtrl.text.trim().isNotEmpty) {
                state.setAddress(addressCtrl.text.trim());
              }
              state.setCustomerDetails(
                nameCtrl.text.trim().isEmpty ? state.customerName : nameCtrl.text.trim(),
                phoneCtrl.text.trim().isEmpty ? state.customerPhone : phoneCtrl.text.trim(),
              );
              Navigator.of(ctx).pop();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(gradient: emberGradient, borderRadius: BorderRadius.circular(99)),
              child: Text('Save', style: body(13, w: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (state.priceUpdateNotice != null) {
      final notice = state.priceUpdateNotice!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: const Color(0xFF1F0A10),
          behavior: SnackBarBehavior.floating,
          content: Row(children: [
            const Icon(Icons.info_outline_rounded, color: C.gold, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(notice, style: body(12, w: FontWeight.w600))),
          ]),
        ));
        state.clearPriceNotice(notify: false);
      });
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: darkBg),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Header
              Row(children: [
                GlassIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.of(context).pop()),
                const SizedBox(width: 12),
                Text('My bag', style: display(22)),
                const Spacer(),
                if (state.cart.isNotEmpty)
                  GestureDetector(
                    onTap: state.clearCart,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Clear', style: body(12, color: C.crimson, w: FontWeight.w700)),
                    ),
                  ),
              ]),

              // Content
              Expanded(
                child: state.cart.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: op(Colors.white, .06),
                                border: Border.all(color: op(Colors.white, .1)),
                              ),
                              child: const Icon(Icons.shopping_bag_outlined, color: C.gold, size: 38),
                            ),
                            const SizedBox(height: 18),
                            Text('Your bag is empty', style: display(18, w: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text('Add fresh cuts from local butchers to start.', style: body(13, color: op(Colors.white, .65))),
                            const SizedBox(height: 24),
                            BouncyPress(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(gradient: emberGradient, borderRadius: BorderRadius.circular(99)),
                                child: Text('Browse Fresh Cuts', style: body(14, w: FontWeight.w800)),
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.only(top: 6, bottom: 16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          for (var i = 0; i < state.cart.length; i++)
                            Reveal(delayMs: 100 + i * 150, child: _ItemCard(item: state.cart[i])),
                          const SizedBox(height: 18),

                          // Delivery Address Tile
                          Glass(
                            radius: 20,
                            padding: const EdgeInsets.all(14),
                            child: Row(children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(color: op(C.ember, .2), shape: BoxShape.circle),
                                child: const Icon(Icons.location_on_rounded, color: C.ember, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('DELIVERING TO', style: body(10, color: op(Colors.white, .6), w: FontWeight.w700)),
                                  const SizedBox(height: 3),
                                  Text(state.selectedAddress, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(13, w: FontWeight.w800)),
                                ]),
                              ),
                              TextButton(
                                onPressed: () => showDeliveryAddressSheet(context),
                                child: Text('Change', style: body(12, color: C.gold, w: FontWeight.w800)),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 16),

                          // Dynamic Delivery Slots
                          Text('DELIVERY SLOT · TODAY', style: body(12, w: FontWeight.w800).copyWith(color: op(Colors.white, .85))),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(children: [
                              for (final s in _slots)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: BouncyPress(
                                    onTap: () => state.setSlot(s),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 250),
                                      curve: const Cubic(0.16, 1.0, 0.3, 1.0),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        gradient: s == state.slot ? emberGradient : null,
                                        color: s == state.slot ? null : op(Colors.white, .08),
                                        borderRadius: BorderRadius.circular(99),
                                        border: Border.all(
                                          color: s == state.slot ? op(Colors.white, .3) : op(Colors.white, .12),
                                          width: 1.2,
                                        ),
                                        boxShadow: s == state.slot
                                            ? [
                                                BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 4, offset: const Offset(0, 2)),
                                              ]
                                            : [],
                                      ),
                                      child: Text(
                                        s,
                                        style: body(
                                          12,
                                          w: s == state.slot ? FontWeight.w800 : FontWeight.w700,
                                          color: s == state.slot ? Colors.white : op(Colors.white, .8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ]),
                          ),
                          const SizedBox(height: 16),

                          // Payment Method Selector
                          Text('PAYMENT METHOD', style: body(12, w: FontWeight.w800).copyWith(color: op(Colors.white, .85))),
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(
                              child: BouncyPress(
                                onTap: () => state.setPaymentMethod('Cash on delivery'),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: state.paymentMethod == 'Cash on delivery' ? op(C.ember, .18) : op(Colors.white, .06),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: state.paymentMethod == 'Cash on delivery' ? C.ember : op(Colors.white, .12),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    const Icon(Icons.payments_rounded, color: C.ember, size: 22),
                                    const SizedBox(height: 8),
                                    Text('Cash on Delivery', style: body(13, w: FontWeight.w800)),
                                    Text('Pay rider upon arrival', style: body(10, color: op(Colors.white, .65))),
                                  ]),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: BouncyPress(
                                onTap: () => state.setPaymentMethod('UPI (GPay / PhonePe)'),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: state.paymentMethod == 'UPI (GPay / PhonePe)' ? op(C.ember, .18) : op(Colors.white, .06),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: state.paymentMethod == 'UPI (GPay / PhonePe)' ? C.ember : op(Colors.white, .12),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    const Icon(Icons.qr_code_rounded, color: C.gold, size: 22),
                                    const SizedBox(height: 8),
                                    Text('Online UPI', style: body(13, w: FontWeight.w800)),
                                    Text('GPay / PhonePe', style: body(10, color: op(Colors.white, .65))),
                                  ]),
                                ),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 20),

                          // Total
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Total to pay', style: body(13).copyWith(color: op(Colors.white, .8))),
                                Text('Includes all taxes & delivery', style: body(10, color: op(Colors.white, .55))),
                              ]),
                              Text(rupees(state.cartTotal), style: display(26)),
                            ],
                          ),
                        ]),
                      ),
              ),

              // Slide to Order
              if (state.cart.isNotEmpty) ...[
                SlideToConfirm(label: 'Slide to place order', onConfirmed: () => _place(context)),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'Slide to confirm · Idempotent checkout protects against double orders',
                    style: body(11).copyWith(color: op(Colors.white, .55)),
                  ),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final CartItem item;
  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Glass(
        radius: 24,
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          SizedBox(width: 74, child: Floating(child: MeatImage(product: item.product, width: 70))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.product.name, style: body(15, w: FontWeight.w800, h: 1.2)),
              const SizedBox(height: 3),
              Text('${gramsLabel(item.grams)} · ${item.product.butcher}', style: body(12).copyWith(color: op(Colors.white, .7))),
              const SizedBox(height: 6),
              Text(rupees(item.lineTotal), style: display(15)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(gradient: emberGradient, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => state.changeQty(item.key, -1),
                icon: const Icon(Icons.remove, size: 18, color: Colors.white),
              ),
              Text('${item.qty}', style: body(14, w: FontWeight.w800)),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => state.changeQty(item.key, 1),
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Swipe-to-confirm control that triggers order placement.
class SlideToConfirm extends StatefulWidget {
  final String label;
  final FutureOr<bool> Function() onConfirmed;
  const SlideToConfirm({super.key, required this.label, required this.onConfirmed});

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  double _x = 0;
  bool _done = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, cons) {
        final maxX = cons.maxWidth - 68;
        return Container(
          height: 68,
          decoration: BoxDecoration(
            gradient: emberGradient,
            borderRadius: BorderRadius.circular(34),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(60), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Stack(children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 56),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(_done ? 'Placing order...' : widget.label, style: body(15, w: FontWeight.w800)),
                ),
              ),
            ),
            Positioned(
              right: 22,
              top: 0,
              bottom: 0,
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (_, __) => Row(children: [
                    for (var i = 0; i < 3; i++)
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white.withAlpha(
                          ((.2 + .8 * (1 - ((_c.value + i * .2) % 1 - .5).abs() * 2)).clamp(0.2, 1.0) * 255).round(),
                        ),
                        size: 22,
                      ),
                  ]),
                ),
              ),
            ),
            Positioned(
              left: 6 + _x,
              top: 6,
              child: GestureDetector(
                onHorizontalDragUpdate: (d) {
                  if (_done) return;
                  setState(() => _x = (_x + d.delta.dx).clamp(0.0, maxX));
                },
                onHorizontalDragEnd: (_) async {
                  if (_done) return;
                  if (_x >= maxX * .85) {
                    setState(() {
                      _x = maxX;
                      _done = true;
                    });
                    final ok = await widget.onConfirmed();
                    if (!ok && mounted) {
                      setState(() {
                        _x = 0;
                        _done = false;
                      });
                    }
                  } else {
                    setState(() => _x = 0);
                  }
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: C.cream),
                  child: const Icon(Icons.arrow_forward_rounded, color: C.crimson),
                ),
              ),
            ),
          ]),
        );
      });
}
