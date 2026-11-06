import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/fly_to_bag.dart';
import '../widgets/steak.dart';
import '../widgets/liquid_motion.dart';
import 'bag_screen.dart';

class ProductScreen extends StatefulWidget {
  final Product product;
  const ProductScreen({super.key, required this.product});
  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  int _grams = 1000;
  final _steakKey = GlobalKey();
  final _bagKey = GlobalKey();
  bool _isAdding = false;

  void _add() {
    if (_isAdding) return;
    setState(() => _isAdding = true);
    final state = context.read<AppState>();
    final p = state.getLiveProduct(widget.product);
    final g = _grams;
    FlyToBag.run(
      context,
      from: _steakKey,
      to: _bagKey,
      child: MeatImage(product: p, width: 64),
      grams: g,
      onLanded: () {
        state.addToCart(p, g);
        if (mounted) setState(() => _isAdding = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = state.getLiveProduct(widget.product);
    final count = state.cartCount;
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: const Alignment(-.2, -1), end: const Alignment(.2, 1), colors: p.type.heroColors, stops: const [0, .42, 1]),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalH = constraints.maxHeight;
            final totalW = constraints.maxWidth;
            final sheetH = (totalH * 0.44).clamp(300.0, 355.0);
            final titleBottom = sheetH + 12.0;
            const titleH = 48.0;
            final headerBottom = top + 54.0;
            final availablePlatterH = (totalH - titleBottom - titleH - headerBottom).clamp(160.0, 360.0);
            final platterMaxDim = totalW - 48.0;
            final platterSize = (availablePlatterH < platterMaxDim ? availablePlatterH : platterMaxDim).clamp(170.0, 340.0);
            final steakSize = (platterSize * (290.0 / 340.0)).clamp(140.0, 290.0);
            final platterTop = headerBottom + ((totalH - titleBottom - titleH - headerBottom - platterSize) / 2).clamp(0.0, 24.0);

            return Stack(children: [
              Positioned(
                top: top + 8,
                left: 20,
                child: Semantics(
                  button: true,
                  label: 'Back',
                  child: GlassIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.of(context).pop()),
                ),
              ),
              Positioned(
                top: top + 22,
                left: 0,
                right: 0,
                child: Center(child: Text(p.type.label.toUpperCase(), style: body(12, w: FontWeight.w700).copyWith(letterSpacing: 5, color: op(Colors.white, .85)))),
              ),
              Positioned(
                top: top + 6,
                right: 20,
                child: BagButton(key: _bagKey, count: count, onTap: () => Navigator.of(context).push(fadeRoute(const BagScreen()))),
              ),
              Positioned(
                top: platterTop,
                left: 20,
                right: 20,
                child: Center(
                  child: SizedBox(
                    width: platterSize,
                    height: platterSize,
                    child: Stack(alignment: Alignment.center, children: [
                      Spin(seconds: 30, child: CustomPaint(size: Size(platterSize, platterSize), painter: DashedRingPainter(op(C.cream, .4)))),
                      Floating(child: KeyedSubtree(key: _steakKey, child: MeatImage(product: p, width: steakSize))),
                    ]),
                  ),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: titleBottom,
                child: Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(child: Text(p.name, style: display(24, h: 1.15))),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(rupees(p.pricePerKg), style: display(20)),
                    const SizedBox(height: 3),
                    Text('/ kg · ${p.rating} ★', style: body(12).copyWith(color: op(Colors.white, .8))),
                  ]),
                ]),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: sheetH,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16050A),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                    border: Border(
                      top: BorderSide(color: op(Colors.white, 0.14), width: 1.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(180),
                        blurRadius: 36,
                        offset: const Offset(0, -12),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      LiquidSegmentedControl(
                        height: 60,
                        selectedIndex: const [500, 1000, 2000].indexOf(_grams).clamp(0, 2),
                        onSelected: (idx) {
                          setState(() => _grams = const [500, 1000, 2000][idx]);
                        },
                        backgroundColor: const Color(0xFF220811),
                        borderColor: op(Colors.white, 0.12),
                        children: [
                          for (final g in const [500, 1000, 2000])
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  gramsLabel(g),
                                  style: display(
                                    15,
                                    color: g == _grams ? Colors.white : op(Colors.white, 0.85),
                                    w: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  rupees(p.priceFor(g)),
                                  style: body(
                                    11,
                                    color: g == _grams ? op(Colors.white, .95) : C.gold,
                                    w: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (p.pieces != null || p.serves != null) ...[
                        Row(
                          children: [
                            if (p.pieces != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: op(C.ember, 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: op(C.ember, 0.35)),
                                ),
                                child: Text(p.pieces!, style: body(10.5, color: C.ember, w: FontWeight.w700)),
                              ),
                            if (p.serves != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: op(Colors.white, 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: op(Colors.white, 0.14)),
                                ),
                                child: Text(p.serves!, style: body(10.5, color: op(Colors.white, 0.85), w: FontWeight.w600)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                      Row(children: const [
                        _Trust(icon: Icons.verified_user_outlined, label: 'Halal\ncertified'),
                        _Trust(icon: Icons.water_drop_outlined, label: 'Hygiene\nchecked'),
                        _Trust(icon: Icons.ac_unit_rounded, label: 'Cold\nchain'),
                      ]),
                      const SizedBox(height: 12),
                      Text(
                        p.description ?? 'Sold by ${p.butcher} · cut ${p.cutAgo}. Net weight after cleaning.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: body(11.5, color: op(Colors.white, 0.70), h: 1.45),
                      ),
                      const Spacer(),
                      Semantics(
                        button: true,
                        label: 'Add to bag, ${p.name}, ${gramsLabel(_grams)}, ${rupees(p.priceFor(_grams))}',
                        child: ShineButton(
                          onTap: _isAdding ? null : _add,
                          width: double.infinity,
                          height: 62,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 26),
                            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Text('Add to bag', style: body(16, w: FontWeight.w800)),
                              Text(rupees(p.priceFor(_grams)), style: display(15)),
                            ]),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ]),
                  ),
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

class _Trust extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Trust({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: op(C.gold, 0.15),
              border: Border.all(color: op(C.gold, 0.35), width: 1),
            ),
            child: Icon(icon, size: 16, color: C.gold),
          ),
          const SizedBox(width: 8),
          Text(label, style: body(11, color: op(Colors.white, 0.90), w: FontWeight.w700, h: 1.2)),
        ]),
      );
}
