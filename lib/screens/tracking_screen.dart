import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/steak.dart';
import '../widgets/paper_invoice.dart';
import '../widgets/real_map_view.dart';
import 'bag_screen.dart';

class TrackingScreen extends StatefulWidget {
  final String? initialOrderId;
  final bool isEmbedded;
  final VoidCallback? onBrowseCuts;
  final bool isActive;

  const TrackingScreen({
    super.key,
    this.initialOrderId,
    this.isEmbedded = false,
    this.onBrowseCuts,
    this.isActive = true,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 8));
  String? _selected;
  ModalRoute? _route;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selected = widget.initialOrderId;
    if (widget.isActive) {
      _c.repeat();
    }
  }

  @override
  void didUpdateWidget(TrackingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _resumeAnimation();
      } else {
        _pauseAnimation();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != _route) {
      _route?.secondaryAnimation?.removeListener(_onSecondaryAnimation);
      _route = route;
      _route?.secondaryAnimation?.addListener(_onSecondaryAnimation);
    }
  }

  void _onSecondaryAnimation() {
    final secAnim = _route?.secondaryAnimation;
    if (secAnim != null && secAnim.value > 0.95) {
      _pauseAnimation();
    } else if (secAnim != null && secAnim.value == 0.0) {
      _resumeAnimation();
    }
  }

  void _pauseAnimation() {
    if (_c.isAnimating) {
      _c.stop();
    }
  }

  void _resumeAnimation() {
    if (!widget.isActive) return;
    final isResumed = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    final isTop = _route?.isCurrent ?? true;
    if (isResumed && isTop && !_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resumeAnimation();
    } else {
      _pauseAnimation();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _route?.secondaryAnimation?.removeListener(_onSecondaryAnimation);
    _c.dispose();
    super.dispose();
  }

  Future<void> _callDriver(BuildContext context, [Order? order]) async {
    final phoneNumber = order?.driverPhone ?? '+91 98450 12345';
    final driverName = order?.driverName ?? 'Rashid Khan';
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    } catch (_) {
      // Fall through to clipboard fallback
    }

    // Fallback for tablets, emulators, or devices without dialer
    await Clipboard.setData(ClipboardData(text: cleanPhone));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF1E0A10),
      content: Text('Phone number copied to clipboard: $phoneNumber ($driverName)', style: body(13)),
    ));
  }

  void _confirmCancel(BuildContext context, Order order) async {
    if (!order.canCancel) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E0A10),
        content: Text('Orders can only be cancelled within 5 minutes of placing.', style: body(13)),
      ));
      return;
    }
    final state = context.read<AppState>();
    _pauseAnimation();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E0A10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: op(Colors.white, .15))),
        title: Text('Cancel Order?', style: display(18)),
        content: Text('Are you sure you want to cancel order #${order.id}? The butcher will be notified.', style: body(13, color: op(Colors.white, .8))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Keep Order', style: body(13, color: op(Colors.white, .7))),
          ),
          BouncyPress(
            onTap: () {
              Navigator.of(ctx).pop();
              final ok = state.cancelOrder(order.id);
              if (ok) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: const Color(0xFF1E0A10),
                  content: Text('Order #${order.id} was cancelled.', style: body(13)),
                ));
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: C.crimson, borderRadius: BorderRadius.circular(99)),
              child: Text('Cancel Order', style: body(13, w: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
    if (mounted) {
      _resumeAnimation();
    }
  }

  void _confirmClearHistory(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E0A10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: op(Colors.white, .15)),
        ),
        title: Text('Clear Order History?', style: display(18)),
        content: Text(
          'This will remove all past delivered and cancelled order records from this device.',
          style: body(13, color: op(Colors.white, .8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Keep History', style: body(13, color: op(Colors.white, .7))),
          ),
          BouncyPress(
            onTap: () {
              Navigator.of(ctx).pop();
              state.clearAllOrders();
              setState(() => _selected = null);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: const Color(0xFF1E0A10),
                  content: Text('Order history cleared.', style: body(13)),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: C.crimson, borderRadius: BorderRadius.circular(99)),
              child: Text('Clear', style: body(13, w: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoCurrentOrdersView(BuildContext context, AppState state, double top) {
    final pastOrders = state.allOrders;
    return Container(
      color: const Color(0xFF14090C),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: [
                  if (!widget.isEmbedded) ...[
                    GlassIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 14),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: op(Colors.white, .08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: C.gold, size: 20),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      'Orders & Tracking',
                      style: display(18, color: Colors.white, w: FontWeight.w800),
                    ),
                  ),
                  if (pastOrders.isNotEmpty)
                    BouncyPress(
                      onTap: () => _confirmClearHistory(context, state),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: op(Colors.white, .06),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: op(Colors.white, .1)),
                        ),
                        child: Text(
                          'Clear History',
                          style: body(11, color: op(Colors.white, .65), w: FontWeight.w600),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(20, 12, 20, widget.isEmbedded ? 120 : 32),
                children: [
                  // No Current Orders Hero Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B070E),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: op(C.gold, .25), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(120),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [op(C.gold, .25), op(C.ember, .08)],
                            ),
                            border: Border.all(color: op(C.gold, .4), width: 1.5),
                          ),
                          child: const Icon(Icons.delivery_dining_rounded, size: 42, color: C.gold),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No Current Orders',
                          style: display(20, color: Colors.white, w: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You don\'t have any orders out for delivery right now.\nWhen you place an order, live butcher cutting and rider GPS tracking will appear here.',
                          textAlign: TextAlign.center,
                          style: body(13, color: op(Colors.white, .75), h: 1.45),
                        ),
                        const SizedBox(height: 24),
                        ShineButton(
                          onTap: widget.onBrowseCuts ?? () => Navigator.of(context).pop(),
                          width: 230,
                          height: 48,
                          radius: 24,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.storefront_rounded, size: 18, color: Colors.white),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Browse Fresh Cuts',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: display(13, color: Colors.white, w: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Past Orders Section (if any completed/cancelled orders exist)
                  if (pastOrders.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: op(C.gold, .15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.history_rounded, size: 16, color: C.gold),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Past Orders (${pastOrders.length})',
                          style: display(15, color: Colors.white, w: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final o in pastOrders)
                      _buildPastOrderCard(context, state, o),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPastOrderCard(BuildContext context, AppState state, Order o) {
    final isDelivered = o.status == OrderStatus.delivered;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E0A12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: op(Colors.white, .1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDelivered ? const Color(0xFF1E3822) : const Color(0xFF2A1C20),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDelivered ? const Color(0xFF4CAF50).withAlpha(120) : op(Colors.white, .15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isDelivered ? Icons.check_circle_rounded : Icons.cancel_outlined,
                          size: 13,
                          color: isDelivered ? const Color(0xFF81C784) : Colors.grey,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          o.status.label,
                          style: body(
                            11,
                            w: FontWeight.w800,
                            color: isDelivered ? const Color(0xFF81C784) : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('#${o.id}', style: body(13, color: Colors.white, w: FontWeight.w800)),
                ],
              ),
              Text(
                rupees(o.total),
                style: body(14, color: C.ember, w: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            o.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: body(12, color: op(Colors.white, .8)),
          ),
          const SizedBox(height: 4),
          Text(
            '${o.items.length} cut${o.items.length > 1 ? 's' : ''} · ${o.paymentMethod}',
            style: body(11, color: op(Colors.white, .5)),
          ),
          const SizedBox(height: 12),
          Divider(color: op(Colors.white, .08), height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: BouncyPress(
                  onTap: () => setState(() => _selected = o.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: op(Colors.white, .07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: op(Colors.white, .1)),
                    ),
                    child: Center(
                      child: Text('View Details & Invoice', style: body(12, color: Colors.white, w: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              BouncyPress(
                onTap: () {
                  state.reorder(o);
                  Navigator.of(context).pushReplacement(fadeRoute(const BagScreen()));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: emberGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.replay_rounded, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text('Reorder', style: body(12, color: Colors.white, w: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final activeOrders = state.activeOrders;

    // Only show an order details view if the user explicitly picked one (e.g. from history),
    // or if there is an active ongoing delivery right now.
    // If no active orders exist and none was explicitly selected, order is null -> shows "No Current Orders"!
    final hasExplicit = _selected != null && state.orders.containsKey(_selected);
    final order = hasExplicit
        ? state.orders[_selected]
        : (activeOrders.isNotEmpty ? activeOrders.first : null);

    final h = MediaQuery.of(context).size.height;
    final top = MediaQuery.of(context).padding.top;

    if (order == null) {
      return _buildNoCurrentOrdersView(context, state, top);
    }

    final isViewingPastOrder = order.status == OrderStatus.delivered || order.status == OrderStatus.cancelled;

    final content = Stack(children: [
        // Real Interactive Delivery Map
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: h * .54,
          child: RealMapView(
            order: order,
            anim: _c,
            isCancelled: order.status == OrderStatus.cancelled,
          ),
        ),

        // Back button (shown in full-screen push mode, or when inspecting a past order in embedded mode)
        if (!widget.isEmbedded)
          Positioned(
            top: top + 8,
            left: 20,
            child: GlassIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.of(context).pop()),
          )
        else if (isViewingPastOrder || hasExplicit)
          Positioned(
            top: top + 10,
            left: 20,
            child: BouncyPress(
              onTap: () => setState(() => _selected = null),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B070E),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: op(C.gold, .4), width: 1.2),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(120), blurRadius: 10, offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back_rounded, size: 15, color: C.gold),
                    const SizedBox(width: 6),
                    Text('Back to Current Orders', style: body(12, color: C.gold, w: FontWeight.w800)),
                  ],
                ),
              ),
            ),
          ),

        // Multi-order Tabs (show active deliveries or selected past order)
        if (activeOrders.length > 1)
          Positioned(
            top: top + 12,
            right: 20,
            left: widget.isEmbedded ? 20 : 80,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: false,
              child: Row(children: [
                for (final o in activeOrders)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: BouncyPress(
                      onTap: () => setState(() => _selected = o.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: const Cubic(0.16, 1.0, 0.3, 1.0),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          gradient: o.id == order.id ? emberGradient : null,
                          color: o.id == order.id ? null : op(Colors.white, .08),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: o.id == order.id ? op(Colors.white, .3) : op(Colors.white, .12),
                            width: 1.2,
                          ),
                          boxShadow: o.id == order.id
                              ? [
                                  BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 4, offset: const Offset(0, 2)),
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '#${o.id}',
                              style: body(
                                12,
                                w: o.id == order.id ? FontWeight.w800 : FontWeight.w700,
                                color: o.id == order.id ? Colors.white : op(Colors.white, .8),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: switch (o.status) {
                                  OrderStatus.delivered => C.gold,
                                  OrderStatus.cancelled => Colors.grey,
                                  _ => C.ember,
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ]),
            ),
          ),

        // Bottom Sheet Order Card - Harmonized Dark Luxury Theme
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: h * .58,
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
            decoration: BoxDecoration(
              color: const Color(0xFF1B070E),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border(
                top: BorderSide(color: op(C.gold, .35), width: 1.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(160),
                  blurRadius: 36,
                  offset: const Offset(0, -12),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: widget.isEmbedded ? 120 : 28),
              child: _Sheet(
                order: order,
                anim: _c,
                onCallDriver: () => _callDriver(context, order),
                onCancel: () => _confirmCancel(context, order),
                onAdvanceStatus: () => state.advanceOrderStatus(order.id),
                onReorder: () {
                  state.reorder(order);
                  Navigator.of(context).pushReplacement(fadeRoute(const BagScreen()));
                },
              ),
            ),
          ),
        ),
      ]);

    if (widget.isEmbedded) {
      return Container(
        color: const Color(0xFF14090C),
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF14090C),
      body: content,
    );
  }
}

class _Sheet extends StatelessWidget {
  final Order order;
  final Animation<double> anim;
  final VoidCallback onCallDriver;
  final VoidCallback onCancel;
  final VoidCallback? onAdvanceStatus;
  final VoidCallback onReorder;

  const _Sheet({
    required this.order,
    required this.anim,
    required this.onCallDriver,
    required this.onCancel,
    this.onAdvanceStatus,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    final eta = order.status.etaMinutes;
    const progressSteps = [
      OrderStatus.placed,
      OrderStatus.accepted,
      OrderStatus.cutting,
      OrderStatus.onTheWay,
      OrderStatus.delivered,
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Top status & ETA
      Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            order.status == OrderStatus.cancelled
                ? 'ORDER CANCELLED'
                : (eta == 0 ? 'DELIVERED' : 'ARRIVING IN'),
            style: body(12, color: order.status == OrderStatus.cancelled ? Colors.grey : C.ember, w: FontWeight.w800).copyWith(letterSpacing: 2),
          ),
          if (eta > 0 && order.status != OrderStatus.cancelled)
            Text.rich(TextSpan(children: [
              TextSpan(text: '$eta ', style: display(36, color: Colors.white)),
              TextSpan(text: 'min', style: display(16, color: C.gold)),
            ])),
        ]),
        if (order.items.isNotEmpty)
          SizedBox(width: 84, child: Floating(child: MeatImage(product: order.items.first.product, width: 80))),
      ]),
      Text('Order #${order.id} · ${order.subtitle}', style: body(12, color: op(Colors.white, 0.7))),
      const SizedBox(height: 14),

      // Segmented Progress Bar (for non-cancelled orders)
      if (order.status != OrderStatus.cancelled) ...[
        Row(children: [
          for (final s in progressSteps)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _Segment(status: s, current: order.status, anim: anim),
              ),
            ),
        ]),
        const SizedBox(height: 14),
      ],

      // Driver info card (with fleet assignment support)
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF280B14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: op(Colors.white, 0.12)),
        ),
        child: Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF3D131F)),
            child: ClipOval(child: Image.asset('assets/images/avatar_rider.jpg', fit: BoxFit.cover, cacheWidth: 138)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _showRiderPicker(context, order),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(
                    child: Text(order.driverName, style: body(14, color: Colors.white, w: FontWeight.w800)),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: op(C.gold, 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: op(C.gold, 0.3), width: 0.8),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.swap_horiz_rounded, size: 11, color: C.gold),
                      const SizedBox(width: 2),
                      Text('Fleet', style: body(9, color: C.gold, w: FontWeight.w700)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 2),
                Text('Delivery Partner · 4.9 ★ · ${order.driverVehicle}', style: body(11, color: op(Colors.white, 0.65))),
              ]),
            ),
          ),
          BouncyPress(
            onTap: onCallDriver,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: emberGradient),
              child: const Icon(Icons.call_rounded, color: Colors.white, size: 20),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 12),

      // Delivery Address & Payment summary
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: op(Colors.white, 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: op(Colors.white, 0.08)),
        ),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Deliver to:', style: body(12, color: C.gold, w: FontWeight.w700)),
            Flexible(child: Text(order.deliveryAddress, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(12, color: Colors.white, w: FontWeight.w800))),
          ]),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Payment:', style: body(12, color: op(Colors.white, 0.7), w: FontWeight.w700)),
            Text('${order.paymentMethod} · ${rupees(order.total)}', style: body(12, color: C.ember, w: FontWeight.w800)),
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      // Itemized Cuts List & Bill Breakdown
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF280B14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: op(Colors.white, 0.12)),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(60), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('ORDER ITEMS (${order.items.length})', style: body(11, color: C.gold, w: FontWeight.w800).copyWith(letterSpacing: 1)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: op(C.ember, .2), borderRadius: BorderRadius.circular(99)),
              child: Text('Fresh Cut', style: body(10, color: C.ember, w: FontWeight.w800)),
            ),
          ]),
          Divider(color: op(Colors.white, 0.1), height: 18),
          for (final item in order.items) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: MeatImage(product: item.product, width: 38),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item.product.name, style: body(13, color: Colors.white, w: FontWeight.w800)),
                    Text('${gramsLabel(item.grams)} × ${item.qty} · ${item.product.butcher}',
                        style: body(11, color: op(Colors.white, 0.65))),
                  ]),
                ),
                Text(rupees(item.lineTotal), style: body(13, color: Colors.white, w: FontWeight.w800)),
              ]),
            ),
            if (item != order.items.last) const SizedBox(height: 6),
          ],
          Divider(color: op(Colors.white, 0.1), height: 18),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Item Total', style: body(12, color: op(Colors.white, 0.7))),
            Text(rupees(order.total), style: body(12, color: Colors.white, w: FontWeight.w700)),
          ]),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Cold-chain delivery', style: body(12, color: op(Colors.white, 0.7))),
            Row(children: [
              Text('₹50 ', style: body(11, color: Colors.grey).copyWith(decoration: TextDecoration.lineThrough)),
              Text('FREE', style: body(12, color: const Color(0xFF81C784), w: FontWeight.w800)),
            ]),
          ]),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Packaging & Insulated box', style: body(12, color: op(Colors.white, 0.7))),
            Row(children: [
              Text('₹25 ', style: body(11, color: Colors.grey).copyWith(decoration: TextDecoration.lineThrough)),
              Text('FREE', style: body(12, color: const Color(0xFF81C784), w: FontWeight.w800)),
            ]),
          ]),
        ]),
      ),
      const SizedBox(height: 14),

      // Action Buttons
      Row(children: [
        if (order.status != OrderStatus.delivered && order.status != OrderStatus.cancelled) ...[
          Expanded(
            child: BouncyPress(
              onTap: onCallDriver,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(gradient: emberGradient, borderRadius: BorderRadius.circular(99)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.call_rounded, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Call Delivery Partner',
                      style: body(12, w: FontWeight.w800, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          BouncyPress(
            onTap: onCancel,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: order.canCancel ? op(Colors.white, 0.12) : op(Colors.white, 0.05),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: op(Colors.white, 0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!order.canCancel) ...[
                    Icon(Icons.lock_clock_rounded, size: 14, color: op(Colors.white, 0.5)),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    'Cancel',
                    style: body(
                      12,
                      w: FontWeight.w700,
                      color: order.canCancel ? Colors.white : op(Colors.white, 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          Expanded(
            child: BouncyPress(
              onTap: onReorder,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(gradient: emberGradient, borderRadius: BorderRadius.circular(99)),
                child: Center(
                  child: Text('Order Again ↺', style: body(13, w: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ]),
      const SizedBox(height: 12),

      // Paper invoice & QR button
      BouncyPress(
        onTap: () => PaperInvoiceWidget.show(context, order),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF280B14),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: op(C.gold, 0.4), width: 1.2),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('🧾', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text('Paper Invoice & Delivery QR', style: body(12, color: C.gold, w: FontWeight.w800)),
          ]),
        ),
      ),

      const SizedBox(height: 16),
    ]);
  }
}

class _Segment extends StatelessWidget {
  final OrderStatus status, current;
  final Animation<double> anim;
  const _Segment({required this.status, required this.current, required this.anim});

  @override
  Widget build(BuildContext context) {
    final done = status.index < current.index;
    final isNow = status == current && current != OrderStatus.delivered;
    final reached = status.index <= current.index;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        height: 5,
        decoration: BoxDecoration(color: op(Colors.white, 0.12), borderRadius: BorderRadius.circular(3)),
        alignment: Alignment.centerLeft,
        child: done || (status == current && current == OrderStatus.delivered)
            ? Container(decoration: BoxDecoration(gradient: emberGradient, borderRadius: BorderRadius.circular(3)))
            : isNow
                ? RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: anim,
                      builder: (_, __) => FractionallySizedBox(
                        widthFactor: (anim.value * 2 % 1).clamp(.05, 1.0),
                        child: Container(decoration: BoxDecoration(gradient: emberGradient, borderRadius: BorderRadius.circular(3))),
                      ),
                    ),
                  )
                : null,
      ),
      const SizedBox(height: 6),
      Text(
        status.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: body(
          10,
          color: isNow ? C.ember : (reached ? Colors.white : op(Colors.white, 0.45)),
          w: FontWeight.w800,
        ),
      ),
    ]);
  }
}

void _showRiderPicker(BuildContext context, Order order) {
  final state = context.read<AppState>();
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1E0A12),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      side: BorderSide(color: Color(0x33C5A059), width: 1.2),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Shop Delivery Fleet', style: display(18, color: Colors.white, w: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF4CAF50).withAlpha(100)),
                  ),
                  child: Text('${state.deliveryFleet.length} Active Riders', style: body(10, color: const Color(0xFF81C784), w: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Select a delivery partner from this shop to assign to Order #${order.id}.',
              style: body(12, color: Colors.white60),
            ),
            const SizedBox(height: 16),
            for (final rider in state.deliveryFleet) ...[
              BouncyPress(
                onTap: () {
                  state.assignDeliveryPartner(order.id, rider);
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: const Color(0xFF1E0A10),
                    content: Text('Order #${order.id} assigned to ${rider.name} (${rider.vehicle})', style: body(13)),
                  ));
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: rider.name == order.driverName ? op(C.ember, 0.15) : op(Colors.white, 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: rider.name == order.driverName ? C.ember : op(Colors.white, 0.1),
                      width: rider.name == order.driverName ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF3D131F)),
                        child: ClipOval(child: Image.asset('assets/images/avatar_rider.jpg', fit: BoxFit.cover)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(rider.name, style: body(14, color: Colors.white, w: FontWeight.bold)),
                          Text('${rider.vehicle} · ${rider.phone}', style: body(11, color: Colors.white60)),
                        ]),
                      ),
                      if (rider.name == order.driverName)
                        const Icon(Icons.check_circle_rounded, color: C.ember, size: 20)
                      else
                        Text('Assign', style: body(12, color: C.gold, w: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
