import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'bag_screen.dart';

/// Fresh Fish & Coastal Seafood Coming Soon screen
/// Unified with the Fresh Meat artisanal butcher visual identity.
class FishComingSoonScreen extends StatefulWidget {
  const FishComingSoonScreen({super.key});

  @override
  State<FishComingSoonScreen> createState() => _FishComingSoonScreenState();
}

class _FishComingSoonScreenState extends State<FishComingSoonScreen> {
  bool _isNotified = false;

  final List<({
    String name,
    String tamilName,
    String tag,
    String desc,
    String cutType,
    IconData icon,
  })> _upcomingCatches = const [
    (
      name: 'King Seer Fish',
      tamilName: 'Vanjaram',
      tag: 'MOST POPULAR',
      desc: 'Thick-cut round steaks from wild ocean Seer fish. Firm, rich flesh ideal for pan frying or traditional meen kuzhambu.',
      cutType: 'Round Steaks · Boneless Cubes',
      icon: Icons.set_meal_rounded,
    ),
    (
      name: 'Jumbo Tiger Prawns',
      tamilName: 'Periya Iral',
      tag: 'DEEP SEA HARVEST',
      desc: 'Succulent, naturally sweet coastal prawns. Thoroughly deveined, deshelled, and packed in sub-zero chill boxes.',
      cutType: 'Peeled & Deveined · Whole Tail-on',
      icon: Icons.water_rounded,
    ),
    (
      name: 'Black Pomfret',
      tamilName: 'Karuppu Vaval',
      tag: 'PRIME WHITE MEAT',
      desc: 'Tender buttery flakes with pristine sweetness. Expertly descaled and gutted by artisan coastal fishmongers.',
      cutType: 'Whole Gutted · Diamond Slices',
      icon: Icons.waves_rounded,
    ),
    (
      name: 'Indian Salmon',
      tamilName: 'Rawas',
      tag: 'OMEGA-3 RICH',
      desc: 'Silky, delicate pink fillets packed with natural healthy fats. Superb for tawa grilling and oven bakes.',
      cutType: 'Center-Cut Steaks · Skin-on Fillets',
      icon: Icons.scatter_plot_rounded,
    ),
    (
      name: 'Blue Sea Crab',
      tamilName: 'Kadal Nandu',
      tag: 'COASTAL CATCH',
      desc: 'Live-harvested blue swimmer sea crabs with sweet, tender body meat and meaty claws.',
      cutType: 'Whole Cleaned · Cracked Claws',
      icon: Icons.bubble_chart_rounded,
    ),
  ];

  void _handleNotify() {
    HapticFeedback.mediumImpact();
    setState(() => _isNotified = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1F0810),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: op(C.gold, 0.4), width: 1.2),
        ),
        content: Row(
          children: [
            const Icon(Icons.notifications_active_rounded, color: C.gold, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Priority list confirmed! You will be alerted the morning our first coastal boats dock.',
                style: body(12, color: Colors.white, w: FontWeight.w600),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0306),
      body: Container(
        decoration: const BoxDecoration(gradient: darkBg),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Top Bar (Exact Fresh Meat standard top navigation)
              Padding(
                padding: EdgeInsets.fromLTRB(20, top > 0 ? 8 : 16, 20, 12),
                child: Row(
                  children: [
                    GlassIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Fresh Fish & Seafood',
                                  style: display(16, color: Colors.white, w: FontWeight.w800),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: op(C.gold, 0.18),
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(color: op(C.gold, 0.45), width: 1),
                                ),
                                child: Text(
                                  'SOON',
                                  style: body(9, color: C.gold, w: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Daily coastal catch · Harbour direct',
                            style: body(11, color: op(Colors.white, 0.7)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    BagButton(
                      count: state.cartCount,
                      onTap: () => Navigator.of(context).push(fadeRoute(const BagScreen())),
                    ),
                  ],
                ),
              ),

              // Main Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 36 + bottom),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero Feature Card (Consistent with Fresh Meat brand hero cards)
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: op(C.gold, 0.25), width: 1.2),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF6E0F1C), // Deep Fresh Meat Crimson
                              Color(0xFF380712), // Rich Wine
                              Color(0xFF1E060C), // Dark Plum
                            ],
                            stops: [0.0, 0.52, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(140),
                              blurRadius: 26,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(22, 28, 22, 26),
                        child: Column(
                          children: [
                            // Rotating Decorative Ring with Warm Gold Fish Emblem
                            SizedBox(
                              width: 124,
                              height: 124,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Spin(
                                    seconds: 24,
                                    child: CustomPaint(
                                      size: const Size(124, 124),
                                      painter: DashedRingPainter(op(C.gold, 0.45)),
                                    ),
                                  ),
                                  Container(
                                    width: 92,
                                    height: 92,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const RadialGradient(
                                        colors: [
                                          Color(0xFFD32F2F),
                                          Color(0xFF8B1224),
                                          Color(0xFF40060E),
                                        ],
                                        stops: [0.0, 0.65, 1.0],
                                      ),
                                      border: Border.all(color: op(C.gold, 0.6), width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: op(C.crimson, 0.45),
                                          blurRadius: 22,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.set_meal_rounded,
                                        size: 46,
                                        color: C.cream,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Coming Soon Status Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: op(C.gold, 0.16),
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(color: op(C.gold, 0.45), width: 1.1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: C.gold,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'COMING SOON · COASTAL FLEET',
                                    style: body(10, color: C.gold, w: FontWeight.w800).copyWith(letterSpacing: 1.1),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Headline
                            Text(
                              'Harbour-Direct Fresh Catch',
                              textAlign: TextAlign.center,
                              style: display(22, color: Colors.white, w: FontWeight.w800, h: 1.15),
                            ),
                            const SizedBox(height: 10),

                            // Description
                            Text(
                              'We are partnering directly with artisan coastal fishing cooperatives in Kasimedu and Royapuram harbours. 100% wild-caught, strictly formalin-free, delivered on sub-2°C crushed ice.',
                              textAlign: TextAlign.center,
                              style: body(12.5, color: op(Colors.white, 0.85), h: 1.5),
                            ),
                            const SizedBox(height: 24),

                            // Notify Me Button (Uses Fresh Meat signature CTA gradient)
                            BouncyPress(
                              onTap: _isNotified ? null : _handleNotify,
                              child: Container(
                                width: double.infinity,
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: _isNotified
                                      ? const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)])
                                      : emberGradient,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_isNotified ? const Color(0xFF2E7D32) : C.ember).withAlpha(85),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _isNotified
                                            ? Icons.check_circle_rounded
                                            : Icons.notifications_active_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        _isNotified
                                            ? 'Priority Notification Active'
                                            : 'Notify Me on First Catch Launch',
                                        style: body(
                                          13,
                                          color: Colors.white,
                                          w: FontWeight.w800,
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
                      const SizedBox(height: 28),

                      // Section Header: Upcoming Catch Menu
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Upcoming Catch Menu',
                              style: display(16, color: Colors.white, w: FontWeight.w800),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: op(C.gold, 0.15),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(color: op(C.gold, 0.35)),
                            ),
                            child: Text(
                              '5 Varieties',
                              style: body(10, color: C.gold, w: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Inspected, descaled, and sliced to your preference on arrival',
                        style: body(11.5, color: op(Colors.white, 0.70)),
                      ),
                      const SizedBox(height: 16),

                      // Catch Variety Cards (Styled matching Fresh Meat cuts cards)
                      ..._upcomingCatches.map((fish) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B070E),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: op(Colors.white, 0.12)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(90),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: op(C.gold, 0.14),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: op(C.gold, 0.35)),
                                  ),
                                  child: Icon(fish.icon, color: C.gold, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text.rich(
                                              TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: fish.name,
                                                    style: display(14, color: Colors.white, w: FontWeight.w800),
                                                  ),
                                                  const TextSpan(text: '  '),
                                                  TextSpan(
                                                    text: '(${fish.tamilName})',
                                                    style: body(11, color: C.gold, w: FontWeight.w700),
                                                  ),
                                                ],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                            decoration: BoxDecoration(
                                              color: op(C.ember, 0.16),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: op(C.ember, 0.35), width: 0.8),
                                            ),
                                            child: Text(
                                              fish.tag,
                                              style: body(8.5, color: C.ember, w: FontWeight.w800),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        fish.desc,
                                        style: body(11.5, color: op(Colors.white, 0.75), h: 1.4),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          const Icon(Icons.content_cut_rounded, size: 12, color: C.gold),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              fish.cutType,
                                              style: body(10.5, color: C.gold, w: FontWeight.w700),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
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
                      }),
                      const SizedBox(height: 16),

                      // Quality Pledge Section
                      Text(
                        'The Fresh Meat Coastal Standard',
                        style: display(16, color: Colors.white, w: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'How we bring genuine harbour freshness without chemical shortcuts',
                        style: body(11.5, color: op(Colors.white, 0.70)),
                      ),
                      const SizedBox(height: 14),

                      _buildPledgeTile(
                        icon: Icons.sanitizer_rounded,
                        color: const Color(0xFF00E676),
                        title: '0% Formalin & Ammonia Free',
                        desc: 'Never artificially preserved. Tested against formaldehyde adulteration at dock arrival before being accepted.',
                      ),
                      const SizedBox(height: 10),
                      _buildPledgeTile(
                        icon: Icons.ac_unit_rounded,
                        color: C.gold,
                        title: 'Sub-2°C Crushed Ice Slurry',
                        desc: 'Fish rest on hygienic flaked ice from harbour landing to your kitchen. Never thawed and refrozen.',
                      ),
                      const SizedBox(height: 10),
                      _buildPledgeTile(
                        icon: Icons.clean_hands_rounded,
                        color: C.ember,
                        title: 'RO Water Descaling & Gutting',
                        desc: 'Cleaned, descaled, and gut-evacuated using 100% RO filtered water in sanitized temperature-controlled bays.',
                      ),
                      const SizedBox(height: 28),

                      // Return to Cuts CTA
                      BouncyPress(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            color: op(Colors.white, 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: op(Colors.white, 0.16)),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.arrow_back_rounded, size: 16, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  'Explore Today’s Fresh Meat Cuts',
                                  style: body(13, color: Colors.white, w: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPledgeTile({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B070E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: op(color, 0.3)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: op(color, 0.16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: op(color, 0.45)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: display(13, color: Colors.white, w: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: body(11, color: op(Colors.white, 0.75), h: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

