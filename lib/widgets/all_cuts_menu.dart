import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'common.dart';
import 'steak.dart';
import '../screens/fish_screen.dart';

/// Full interactive "All Cuts Menu" displaying the entire fresh meat catalog,
/// with search filtering, meat-type tabs, butcher verification, and instant
/// Origami Bag add-to-cart triggering.
class AllCutsMenu extends StatefulWidget {
  final ValueChanged<Product> onProductTap;
  final ValueChanged<Product> onAddToCart;
  final GlobalKey Function(String id) keyForProduct;
  final String? activeButcherFilter;
  final MeatType? meatType;

  const AllCutsMenu({
    super.key,
    required this.onProductTap,
    required this.onAddToCart,
    required this.keyForProduct,
    this.activeButcherFilter,
    this.meatType,
  });

  @override
  State<AllCutsMenu> createState() => _AllCutsMenuState();
}

class _AllCutsMenuState extends State<AllCutsMenu> {
  String _selectedSubcategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void didUpdateWidget(covariant AllCutsMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.meatType != widget.meatType) {
      _selectedSubcategory = 'All';
      _searchQuery = '';
      _searchCtrl.clear();
    }
  }

  List<({String label, IconData icon})> _getSubcategoriesForType(MeatType? type) {
    switch (type) {
      case MeatType.mutton:
        return const [
          (label: 'All', icon: Icons.lunch_dining_rounded),
          (label: 'Curry Cut', icon: Icons.soup_kitchen_rounded),
          (label: 'Biryani Special', icon: Icons.rice_bowl_rounded),
          (label: 'Boneless', icon: Icons.restaurant_rounded),
          (label: 'Rib Chops', icon: Icons.outdoor_grill_rounded),
          (label: 'Keema', icon: Icons.grain_rounded),
          (label: 'Nalli Shanks', icon: Icons.dinner_dining_rounded),
        ];
      case MeatType.chicken:
        return const [
          (label: 'All', icon: Icons.restaurant_rounded),
          (label: 'Curry Cut', icon: Icons.soup_kitchen_rounded),
          (label: 'Breast Fillet', icon: Icons.lunch_dining_rounded),
          (label: 'Drumsticks', icon: Icons.outdoor_grill_rounded),
          (label: 'Lollipops', icon: Icons.fastfood_rounded),
          (label: 'Whole Bird', icon: Icons.shopping_bag_rounded),
        ];
      case MeatType.beef:
        return const [
          (label: 'All', icon: Icons.outdoor_grill_rounded),
          (label: 'Steak', icon: Icons.dinner_dining_rounded),
          (label: 'Ribs', icon: Icons.outdoor_grill_rounded),
          (label: 'Fine Keema', icon: Icons.grain_rounded),
          (label: 'Stir Fry', icon: Icons.ramen_dining_rounded),
          (label: 'Stew Cuts', icon: Icons.soup_kitchen_rounded),
        ];
      case null:
        return const [
          (label: 'All', icon: Icons.restaurant_menu_rounded),
          (label: 'Mutton', icon: Icons.lunch_dining_rounded),
          (label: 'Chicken', icon: Icons.restaurant_rounded),
          (label: 'Beef', icon: Icons.outdoor_grill_rounded),
        ];
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    // 1. Filter by Butcher (if butcher active filter)
    var items = widget.activeButcherFilter != null
        ? products.where((p) => p.butcher == widget.activeButcherFilter).toList()
        : products.toList();

    // 2. Strict Filter by Active Meat Type
    if (widget.meatType != null) {
      items = items.where((p) => p.type == widget.meatType).toList();
    }

    // 3. Filter by Subcategory / Cut Style
    if (_selectedSubcategory != 'All') {
      if (widget.meatType == null) {
        items = items.where((p) => p.type.label == _selectedSubcategory).toList();
      } else {
        final query = _selectedSubcategory.toLowerCase();
        final tokens = query.split(RegExp(r'\s*/\s*|\s+'));
        items = items.where((p) {
          final target = '${p.name} ${p.description ?? ''}'.toLowerCase();
          return tokens.any((t) => t.length > 2 && target.contains(t));
        }).toList();
      }
    }

    // 4. Filter by Search Query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      items = items.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.butcher.toLowerCase().contains(q) ||
            (p.description?.toLowerCase().contains(q) ?? false) ||
            (p.source?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    // Map to live prices
    final liveItems = items.map(state.getLiveProduct).toList();
    final subcategories = _getSubcategoriesForType(widget.meatType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.meatType != null ? '${widget.meatType!.label} Cuts' : 'All Cuts Menu',
                        style: display(20, w: FontWeight.w800),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: op(C.ember, 0.22),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: op(C.ember, 0.45)),
                        ),
                        child: Text(
                          '${liveItems.length} Cuts',
                          style: body(11, color: C.gold, w: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.meatType != null
                        ? '100% Zabiha Halal · Hand-trimmed fresh ${widget.meatType!.label.toLowerCase()} cuts'
                        : '100% Zabiha Halal · Hand-trimmed by verified artisan butchers',
                    style: body(12, color: op(C.cream, 0.7)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Quick Category / Style Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              ...subcategories.map((cat) {
                final isSelected = _selectedSubcategory == cat.label;
                int count;
                if (widget.meatType != null) {
                  if (cat.label == 'All') {
                    count = products.where((p) => p.type == widget.meatType).length;
                  } else {
                    final query = cat.label.toLowerCase();
                    final tokens = query.split(RegExp(r'\s*/\s*|\s+'));
                    count = products.where((p) {
                      if (p.type != widget.meatType) return false;
                      final target = '${p.name} ${p.description ?? ''}'.toLowerCase();
                      return tokens.any((t) => t.length > 2 && target.contains(t));
                    }).length;
                  }
                } else {
                  count = cat.label == 'All'
                      ? products.length
                      : products.where((p) => p.type.label == cat.label).length;
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: BouncyPress(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedSubcategory = cat.label);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: isSelected ? emberGradient : null,
                        color: isSelected ? null : op(Colors.white, 0.06),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: isSelected ? C.gold : op(Colors.white, 0.12),
                          width: isSelected ? 1.4 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat.icon, size: 14, color: isSelected ? Colors.white : C.gold),
                          const SizedBox(width: 6),
                          Text(
                            count > 0 ? '${cat.label} ($count)' : cat.label,
                            style: body(
                              12,
                              color: isSelected ? Colors.white : op(C.cream, 0.85),
                              w: isSelected ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: BouncyPress(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).push(fadeRoute(const FishComingSoonScreen()));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: op(C.gold, 0.14),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: op(C.gold, 0.40),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.set_meal_rounded, size: 14, color: C.gold),
                        const SizedBox(width: 6),
                        Text(
                          'Fish (Soon)',
                          style: body(
                            12,
                            color: C.gold,
                            w: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Search Bar for Cuts
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: op(Colors.white, 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: op(Colors.white, 0.1)),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: body(13, color: Colors.white),
              decoration: InputDecoration(
                hintText: widget.meatType != null
                    ? 'Search ${widget.meatType!.label.toLowerCase()} cuts (e.g. curry, biryani, keema)...'
                    : 'Search cuts (e.g. biryani, ribeye, keema, curry)...',
                hintStyle: body(12, color: op(Colors.white, 0.35)),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: C.gold),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: const Icon(Icons.close_rounded, size: 16, color: Colors.white70),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Cuts Cards List / Grid
        if (liveItems.isEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Center(
              child: Column(
                children: [
                  if (_searchQuery.toLowerCase().contains('fish') ||
                      _searchQuery.toLowerCase().contains('sea') ||
                      _searchQuery.toLowerCase().contains('prawn') ||
                      _searchQuery.toLowerCase().contains('crab')) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 18),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B070E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: op(C.gold, 0.35), width: 1.2),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.set_meal_rounded, size: 36, color: C.gold),
                          const SizedBox(height: 8),
                          Text(
                            'Fresh Fish & Seafood Coming Soon!',
                            style: display(14, color: Colors.white, w: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Vanjaram, Tiger Prawns, Pomfret & coastal sea catches are being prepared.',
                            textAlign: TextAlign.center,
                            style: body(11.5, color: op(Colors.white, 0.75)),
                          ),
                          const SizedBox(height: 12),
                          BouncyPress(
                            onTap: () => Navigator.of(context).push(fadeRoute(const FishComingSoonScreen())),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                              decoration: BoxDecoration(
                                gradient: emberGradient,
                                borderRadius: BorderRadius.circular(99),
                                boxShadow: [
                                  BoxShadow(
                                    color: C.ember.withAlpha(70),
                                    blurRadius: 12,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Text(
                                'Preview Fresh Fish Catches',
                                style: body(12, color: C.cream, w: FontWeight.w800),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Icon(Icons.search_off_rounded, size: 40, color: op(Colors.white, 0.3)),
                  const SizedBox(height: 8),
                  Text('No cuts matching "$_searchQuery"', style: body(13, color: op(C.cream, 0.7))),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() {
                        _searchQuery = '';
                        _selectedSubcategory = 'All';
                      });
                    },
                    child: Text('Reset Filters', style: body(12, color: C.gold, w: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: liveItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final product = liveItems[index];
                final cutKey = widget.keyForProduct(product.id);

                return _AllCutsMenuItemCard(
                  key: ValueKey(product.id),
                  product: product,
                  steakKey: cutKey,
                  onTap: () => widget.onProductTap(product),
                  onAddToCart: () => widget.onAddToCart(product),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

/// Rich, horizontal card for an individual cut in the All Cuts Menu.
class _AllCutsMenuItemCard extends StatelessWidget {
  final Product product;
  final GlobalKey steakKey;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const _AllCutsMenuItemCard({
    super.key,
    required this.product,
    required this.steakKey,
    required this.onTap,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return BouncyPress(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: op(Colors.white, 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: op(Colors.white, 0.10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cut Picture with Halal & Freshness Badges
            Stack(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: op(Colors.white, 0.06),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: MeatImage(product: product, width: 90),
                  ),
                ),
                Positioned(
                  top: 5,
                  left: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B070E).withAlpha(220),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: op(C.gold, 0.6), width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_user_rounded, size: 9, color: C.gold),
                        const SizedBox(width: 3),
                        Text(
                          'HALAL',
                          style: body(8, color: C.gold, w: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Cut Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cut Name
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: display(14.5, color: Colors.white, w: FontWeight.w700, h: 1.25),
                  ),
                  const SizedBox(height: 5),

                  // Butcher & Freshness
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF34A853), // Live green
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Cut ${product.cutAgo}',
                        style: body(11, color: const Color(0xFF81C784), w: FontWeight.w600),
                      ),
                      Text(' · ', style: body(11, color: op(Colors.white, 0.4))),
                      Flexible(
                        child: Text(
                          product.butcher,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: body(11, color: op(C.cream, 0.7)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Pieces & Servings
                  Text(
                    '${product.pieces} · ${product.serves}',
                    style: body(10.5, color: op(Colors.white, 0.55)),
                  ),
                  const SizedBox(height: 10),

                  // Price & Origami Add to Cart Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: rupees(product.pricePerKg),
                              style: display(16, color: C.gold, w: FontWeight.w800),
                            ),
                            TextSpan(
                              text: ' / kg',
                              style: body(11, color: op(Colors.white, 0.7)),
                            ),
                          ],
                        ),
                      ),

                      // Add to Cart Button with Origami Flight Trigger
                      BouncyPress(
                        onTap: onAddToCart,
                        child: Container(
                          key: steakKey,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            gradient: emberGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: C.ember.withAlpha(70),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_rounded, size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                'ADD',
                                style: body(11, color: Colors.white, w: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
