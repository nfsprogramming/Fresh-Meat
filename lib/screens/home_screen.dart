import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/fly_to_bag.dart';
import '../widgets/steak.dart';
import 'bag_screen.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'product_screen.dart';
import 'tracking_screen.dart';
import '../services/price_sync_service.dart';
import '../widgets/liquid_motion.dart';
import '../widgets/google_user_avatar.dart';
import '../widgets/delivery_address_sheet.dart';
import '../widgets/all_cuts_menu.dart';
import 'admin_shop_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  MeatType _type = MeatType.mutton;
  bool _isFishSelected = false;
  int _currentNavIndex = 0;
  final _bagKey = GlobalKey();
  final _keys = <String, GlobalKey>{};
  final _page = PageController(viewportFraction: .88);
  final _scrollController = ScrollController();

  GlobalKey _keyFor(String id) => _keys.putIfAbsent(id, () => GlobalKey());

  @override
  void dispose() {
    _page.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  final _addingProductIds = <String>{};

  void _quickAdd(Product p, [GlobalKey? fromKey]) {
    if (_addingProductIds.contains(p.id)) return;
    setState(() => _addingProductIds.add(p.id));
    final state = context.read<AppState>();
    final liveProduct = state.getLiveProduct(p);
    FlyToBag.run(
      context,
      from: fromKey ?? _keyFor(p.id),
      to: _bagKey,
      child: MeatImage(product: liveProduct, width: 56),
      onLanded: () {
        state.addToCart(liveProduct, 1000);
        if (mounted) {
          setState(() => _addingProductIds.remove(p.id));
        }
      },
    );
  }

  void _open(Widget page) => Navigator.of(context).push(fadeRoute(page));

  void _onCategorySelected(MeatType t) {
    if (_type == t && !_isFishSelected) return;
    setState(() {
      _type = t;
      _isFishSelected = false;
    });
    if (_page.hasClients) {
      _page.animateToPage(
        0,
        duration: const Duration(milliseconds: 380),
        curve: const Cubic(0.16, 1.0, 0.3, 1.0),
      );
    }
  }

  void _showProfileSheet(BuildContext context) {
    final state = context.read<AppState>();
    final user = state.currentUser;
    if (user == null) {
      _open(const LoginScreen());
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Material(
        color: const Color(0xFF1B070E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          side: BorderSide(color: op(Colors.white, 0.15)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + MediaQuery.of(ctx).padding.bottom),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: op(Colors.white, 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    GoogleUserAvatar(
                      user: user,
                      size: 54,
                      borderWidth: 2.2,
                      borderColor: C.gold,
                      showGoogleBadge: false,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(user.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: display(15, color: Colors.white, w: FontWeight.w700)),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.verified_rounded, size: 16, color: C.gold),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(user.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: body(12, color: op(C.cream, 0.7))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.sync_rounded, color: C.gold),
                  title: Text('Daily Pricing (Telegram & Sheets)', style: body(13, color: Colors.white, w: FontWeight.w600)),
                  subtitle: Text(
                    state.lastPriceSync != null
                        ? 'Last synced ${state.lastPriceSync!.hour}:${state.lastPriceSync!.minute.toString().padLeft(2, '0')}'
                        : 'Sync with Google Sheets database',
                    style: body(11, color: op(C.cream, 0.6)),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white54),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showPricingConfigDialog(context);
                  },
                ),
                const Divider(color: Color(0x22FFFFFF)),
                if (state.isAdmin) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.admin_panel_settings_rounded, color: C.gold),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Shop Administration',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: body(13, color: Colors.white, w: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: op(C.gold, 0.2),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text('ADMIN', style: body(8, color: C.gold, w: FontWeight.w800)),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      'Update shop name, pic, address & phone',
                      style: body(11, color: op(C.cream, 0.6)),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white54),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _open(const AdminShopScreen());
                    },
                  ),
                  const Divider(color: Color(0x22FFFFFF)),
                ],
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.set_meal_rounded, color: C.gold),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Fish & Seafood Catch',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: body(13, color: Colors.white, w: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: op(C.gold, 0.18),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: op(C.gold, 0.45), width: 0.8),
                        ),
                        child: Text('SOON', style: body(8, color: C.gold, w: FontWeight.w800)),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    'Preview upcoming wild-caught coastal fish',
                    style: body(11, color: op(C.cream, 0.6)),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white54),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    setState(() => _isFishSelected = true);
                  },
                ),
                const Divider(color: Color(0x22FFFFFF)),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.explore_outlined, color: C.gold),
                  title: Text('View Onboarding Tour', style: body(13, color: Colors.white, w: FontWeight.w600)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white54),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _open(const OnboardingScreen());
                  },
                ),
                const Divider(color: Color(0x22FFFFFF)),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout_rounded, color: C.ember),
                  title: Text('Sign Out', style: body(13, color: C.ember, w: FontWeight.w700)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    state.signOut();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPricingConfigDialog(BuildContext context) async {
    final state = context.read<AppState>();
    final currentUrl = await PriceSyncService.instance.getEndpointUrl() ?? '';
    final controller = TextEditingController(text: currentUrl);

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E0A10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: C.ember, width: 1.5)),
        title: Row(
          children: [
            const Icon(Icons.sync_rounded, color: C.gold, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Daily Pricing Automation',
                style: display(15, color: Colors.white, w: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Prices update automatically when you send Telegram bot commands (/price mutton 850). Paste your Google Apps Script Web App URL below to sync directly.',
                style: body(12, color: op(C.cream, 0.75), h: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                style: body(13, color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'https://script.google.com/macros/s/.../exec',
                  hintStyle: body(11, color: op(Colors.white, 0.3)),
                  filled: true,
                  fillColor: op(Colors.white, 0.08),
                  labelText: 'Google Apps Script Web App URL',
                  labelStyle: body(12, color: C.gold),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              if (state.lastPriceSync != null)
                Text(
                  'Last synced: ${state.lastPriceSync!.hour}:${state.lastPriceSync!.minute.toString().padLeft(2, '0')}',
                  style: body(11, color: C.gold, w: FontWeight.w600),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Close', style: body(13, color: op(Colors.white, 0.7))),
          ),
          BouncyPress(
            onTap: () async {
              final newUrl = controller.text.trim();
              await PriceSyncService.instance.setEndpointUrl(newUrl);
              await state.refreshPrices();
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF1E0A10),
                    content: Text('Prices refreshed from Google Sheets!', style: body(13)),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(gradient: emberGradient, borderRadius: BorderRadius.circular(12)),
              child: Text('Save & Sync', style: body(13, color: Colors.white, w: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    if (h < 21) return 'Good evening';
    return 'Good night';
  }

  void _showAddressDialog(BuildContext context) {
    showDeliveryAddressSheet(context);
  }

  Widget _buildCertRow(String label, String value, {bool isGold = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: body(11, color: op(Colors.white, 0.55), w: FontWeight.w600),
            ),
            TextSpan(
              text: value,
              style: body(
                11,
                color: isGold ? const Color(0xFFFFDF9E) : op(Colors.white, 0.9),
                w: isGold ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCertificateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFDF9E),
                Color(0xFFD4AF37),
                Color(0xFF7A5718),
                Color(0xFFD4AF37),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withAlpha(60),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withAlpha(160),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          padding: const EdgeInsets.all(1.5),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26.5),
              gradient: const LinearGradient(
                colors: [Color(0xFF260813), Color(0xFF140309)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26.5),
              child: Stack(
                children: [
                  Positioned(
                    right: -25,
                    top: -25,
                    child: IgnorePointer(
                      child: Icon(
                        Icons.workspace_premium_rounded,
                        size: 220,
                        color: const Color(0xFFD4AF37).withAlpha(14),
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFDF9E), Color(0xFFD4AF37)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFD4AF37).withAlpha(90),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(Icons.workspace_premium_rounded, color: Color(0xFF1B070E), size: 24),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Official Halal Certificate',
                                    style: display(16, color: Colors.white, w: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'CENTRAL ISLAMIC SHARIAH BOARD',
                                    style: body(9.5, color: const Color(0xFFFFDF9E), w: FontWeight.w700)
                                        .copyWith(letterSpacing: 1.2),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(10),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFD4AF37).withAlpha(75)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'ISLAMIC COMPLIANCE BOARD',
                                    style: body(10, color: const Color(0xFFFFDF9E), w: FontWeight.w800)
                                        .copyWith(letterSpacing: 1.2),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                    decoration: BoxDecoration(
                                      color: Colors.greenAccent.withAlpha(35),
                                      borderRadius: BorderRadius.circular(99),
                                      border: Border.all(color: Colors.greenAccent.withAlpha(120), width: 0.8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 5,
                                          height: 5,
                                          decoration: const BoxDecoration(
                                            color: Colors.greenAccent,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text('VERIFIED', style: body(9, color: Colors.greenAccent, w: FontWeight.w800)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.verified_user_rounded, color: Color(0xFFFFDF9E), size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'License: HAL-2026-IND-8841',
                                    style: display(13, color: Colors.white, w: FontWeight.w800),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              _buildCertRow('Registration', 'Direct Artisan Butchery Protocol'),
                              _buildCertRow('Issued to', 'Fresh Meat Supply & Cold-Chain Logistics'),
                              _buildCertRow('Validity', 'Active · Inspected Daily at 05:00 AM', isGold: true),
                              const SizedBox(height: 14),
                              Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      const Color(0xFFD4AF37).withAlpha(120),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Verified Shariah Protocols:',
                                style: display(12, color: const Color(0xFFFFDF9E), w: FontWeight.w800),
                              ),
                              const SizedBox(height: 8),
                              ...[
                                '100% Zabiha manual slaughter by trained Muslim slaughtermen',
                                'Recitation of Bismillahi Allahu Akbar per individual cut',
                                'Zero mechanical rotary or automated mass slaughter blades',
                                'Strict sub-4°C dedicated halal cold chain monitoring',
                                'Surgical steel blades sanitized at 82°C every 2 hours',
                              ].map(
                                (rule) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(top: 2),
                                        child: Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 14),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(rule, style: body(11, color: op(Colors.white, 0.85), h: 1.4)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        BouncyPress(
                          onTap: () => Navigator.of(ctx).pop(),
                          child: Container(
                            width: double.infinity,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFDF9E), Color(0xFFD4AF37)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFD4AF37).withAlpha(70),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'Close Certificate',
                                style: display(13, color: const Color(0xFF1B070E), w: FontWeight.w800),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShopThumb(String path, double w, double h) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: w,
        height: h,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: w,
          height: h,
          color: const Color(0xFF2A0914),
          child: const Icon(Icons.storefront_rounded, color: C.gold, size: 24),
        ),
      );
    }
    return Image.asset(
      path,
      width: w,
      height: h,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: w,
        height: h,
        color: const Color(0xFF2A0914),
        child: const Icon(Icons.storefront_rounded, color: C.gold, size: 24),
      ),
    );
  }

  Widget _buildCutsView(BuildContext context, AppState state, List<Product> list, List<Product> others) {
    return SafeArea(
      child: RefreshIndicator(
        color: C.gold,
        backgroundColor: const Color(0xFF1B070E),
        onRefresh: () => state.refreshPrices(),
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 124),
          child: Column(children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(children: [
                BouncyPress(
                  onTap: () => state.isLoggedIn ? _showProfileSheet(context) : _open(const LoginScreen()),
                  child: GoogleUserAvatar(
                    user: state.currentUser,
                    size: 46,
                    borderWidth: 2,
                    borderColor: state.isLoggedIn ? C.gold : C.ember,
                    showGoogleBadge: !state.isLoggedIn,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      state.isLoggedIn
                          ? '$_greeting, ${state.currentUser!.name.split(' ').first}'
                          : '$_greeting · Sign in',
                      style: body(12).copyWith(color: op(Colors.white, .75)),
                    ),
                    const SizedBox(height: 3),
                    GestureDetector(
                      onTap: () => _showAddressDialog(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_rounded, size: 14, color: C.gold),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              state.shortAddressDisplay,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: display(14, w: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: C.gold),
                        ],
                      ),
                    ),
                  ]),
                ),
                BagButton(key: _bagKey, count: state.cartCount, onTap: () => _open(const BagScreen())),
              ]),
            ),

            // Active Butcher Filter Chip (if selected)
            if (state.filterButcher != null) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: op(C.ember, .2),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: C.ember),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.storefront_rounded, size: 14, color: C.ember),
                      const SizedBox(width: 6),
                      Text('Filtered: ${state.filterButcher}', style: body(11, color: C.ember, w: FontWeight.w800)),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => state.setButcherFilter(null),
                        child: const Icon(Icons.close_rounded, size: 15, color: Colors.white),
                      ),
                    ]),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 14),

            // Liquid Smooth Category Bar with Animated Pill Transitions
            LiquidCategoryBar(
              selectedIndex: _isFishSelected ? 3 : MeatType.values.indexOf(_type),
              items: [
                for (final t in MeatType.values)
                  (
                    label: t.label,
                    icon: switch (t) {
                      MeatType.mutton => Icons.lunch_dining_rounded,
                      MeatType.chicken => Icons.restaurant_rounded,
                      MeatType.beef => Icons.outdoor_grill_rounded,
                    },
                    badge: null,
                    dim: false,
                  ),
                (
                  label: 'Fish',
                  icon: Icons.set_meal_rounded,
                  badge: 'Soon',
                  dim: false,
                ),
              ],
              onSelected: (idx) {
                HapticFeedback.selectionClick();
                if (idx < MeatType.values.length) {
                  _onCategorySelected(MeatType.values[idx]);
                } else {
                  setState(() => _isFishSelected = true);
                }
              },
            ),

            if (_isFishSelected) ...[
              const SizedBox(height: 32),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B070E),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: op(C.gold, 0.25)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(90),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: op(C.gold, 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: op(C.gold, 0.30)),
                      ),
                      child: const Center(
                        child: Icon(Icons.set_meal_rounded, size: 32, color: C.gold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Fish & Seafood',
                      style: display(18, w: FontWeight.w800, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: op(C.ember, 0.16),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: op(C.ember, 0.40)),
                      ),
                      child: Text(
                        'Coming Soon',
                        style: body(12, w: FontWeight.w800, color: C.ember),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Direct daily harbour catch & fresh-water cuts are coming soon.',
                      textAlign: TextAlign.center,
                      style: body(12.5, color: op(Colors.white, 0.65), h: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ] else ...[
              const SizedBox(height: 24),

              // Hero Cards Carousel with 3D Depth & Smooth Parallax Scale
              SizedBox(
                height: 415,
                child: PageView.builder(
                  controller: _page,
                  clipBehavior: Clip.none,
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    return AnimatedBuilder(
                      animation: _page,
                      builder: (context, child) {
                        double value = 0.0;
                        if (_page.position.haveDimensions) {
                          value = (i - (_page.page ?? _page.initialPage.toDouble())).toDouble();
                        } else {
                          value = (i - 0).toDouble();
                        }
                        final scale = (1 - (value.abs() * 0.12)).clamp(0.88, 1.0);
                        return Transform.scale(
                          scale: scale,
                          child: child,
                        );
                      },
                      child: RepaintBoundary(
                        child: _HeroCard(
                          product: list[i],
                          steakKey: _keyFor(list[i].id),
                          onAdd: () => _quickAdd(list[i]),
                          onTap: () => _open(ProductScreen(product: list[i])),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Marquee Quality Ticker
              Marquee(
                text: 'HALAL CERTIFIED · HYGIENE CHECKED · COLD CHAIN · LOCAL BUTCHERS · CASH ON DELIVERY · ',
                style: body(12, color: C.gold, w: FontWeight.w700).copyWith(letterSpacing: 4),
              ),
              const SizedBox(height: 20),

              // All Cuts Catalog Menu
              AllCutsMenu(
                meatType: _type,
                activeButcherFilter: state.filterButcher,
                keyForProduct: (id) => _keyFor('menu_$id'),
                onProductTap: (p) => _open(ProductScreen(product: p)),
                onAddToCart: (p) => _quickAdd(p, _keyFor('menu_${p.id}')),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _buildButchersView(BuildContext context, AppState state) {
    final butcherMap = <String, List<Product>>{};
    for (final p in products) {
      butcherMap.putIfAbsent(p.butcher, () => []).add(state.getLiveProduct(p));
    }

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: C.gold,
        backgroundColor: const Color(0xFF1B070E),
        onRefresh: () => state.refreshPrices(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 124),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Artisan Butchers', style: display(22, w: FontWeight.w800)),
                            const SizedBox(width: 8),
                            const Icon(Icons.verified_rounded, color: C.gold, size: 20),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Local master butchers verified for Zabiha & hygiene',
                          style: body(12, color: op(Colors.white, .7)),
                        ),
                      ],
                    ),
                  ),
                  if (state.isAdmin) ...[
                    BouncyPress(
                      onTap: () => _open(const AdminShopScreen()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: op(C.gold, 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: op(C.gold, 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.admin_panel_settings_rounded, size: 16, color: C.gold),
                            const SizedBox(width: 4),
                            Text('Admin', style: body(11, color: C.gold, w: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  BagButton(count: state.cartCount, onTap: () => _open(const BagScreen())),
                ],
              ),
              const SizedBox(height: 16),

              // Active Filter Banner (if filter active)
              if (state.filterButcher != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: op(C.ember, .2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: C.ember),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_alt_rounded, color: C.ember, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Active Filter: ${state.filterButcher}',
                          style: body(12, color: Colors.white, w: FontWeight.w700),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => state.setButcherFilter(null),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: op(Colors.white, .15),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text('Reset', style: body(11, color: Colors.white, w: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Featured Primary Storefront Card (Editable via Admin)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF2B0E17),
                      Color(0xFF1B070E),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: op(C.gold, 0.4), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(90),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Shop Photo
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: op(Colors.white, 0.2)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: _buildShopThumb(state.shopProfile.photoUrl, 58, 58),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      state.shopProfile.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: display(15, color: Colors.white, w: FontWeight.w800),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: op(C.gold, 0.2),
                                      borderRadius: BorderRadius.circular(99),
                                      border: Border.all(color: op(C.gold, 0.5)),
                                    ),
                                    child: Text('PRIMARY SHOP',
                                        style: body(8, color: C.gold, w: FontWeight.w800)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: state.shopProfile.isOpen ? const Color(0xFF34A853) : Colors.redAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      state.shopProfile.isOpen ? 'Open · ${state.shopProfile.openingHours}' : 'Store Closed',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: body(11, color: state.shopProfile.isOpen ? const Color(0xFF81C784) : Colors.redAccent, w: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'FSSAI: ${state.shopProfile.fssaiLicense} · Halal: ${state.shopProfile.halalCertNumber}',
                                style: body(10, color: op(Colors.white, 0.6)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(color: Color(0x22FFFFFF), height: 1),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_rounded, size: 14, color: C.gold),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            state.shopProfile.address,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: body(11, color: op(Colors.white, 0.85), h: 1.3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.phone_rounded, size: 14, color: Colors.greenAccent),
                            const SizedBox(width: 6),
                            Text(
                              state.shopProfile.phone,
                              style: body(12, color: Colors.greenAccent, w: FontWeight.w700),
                            ),
                          ],
                        ),
                        if (state.isAdmin)
                          BouncyPress(
                            onTap: () => _open(const AdminShopScreen()),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: op(C.gold, 0.15),
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(color: op(C.gold, 0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.edit_rounded, size: 12, color: C.gold),
                                  const SizedBox(width: 4),
                                  Text('Edit Shop Details', style: body(10, color: C.gold, w: FontWeight.w800)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Notice Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: op(Colors.white, .05),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: op(Colors.white, .08)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: op(C.gold, .15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.storefront_rounded, color: C.gold, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tap "Browse Cuts" on any butcher to filter the storefront catalog directly to their cuts.',
                        style: body(12, color: op(Colors.white, .85), h: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Butcher Cards
              for (final entry in butcherMap.entries) ...[
                Builder(
                  builder: (ctx) {
                    final butcher = entry.key;
                    final butcherCuts = entry.value;
                    final firstCut = butcherCuts.first;
                    final isFiltered = state.filterButcher == butcher;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isFiltered ? op(C.ember, .15) : op(Colors.white, .06),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isFiltered ? C.ember : op(Colors.white, .1),
                          width: isFiltered ? 1.5 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(60),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: op(Colors.white, .08),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: MeatImage(product: firstCut, width: 52),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            butcher,
                                            style: body(15, w: FontWeight.w800, color: Colors.white),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: op(C.gold, .15),
                                            borderRadius: BorderRadius.circular(99),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.star_rounded, color: C.gold, size: 14),
                                              const SizedBox(width: 3),
                                              Text('${firstCut.rating}', style: body(12, color: C.gold, w: FontWeight.w800)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${butcherCuts.length} fresh cuts · Freshly cut ${firstCut.cutAgo}',
                                      style: body(11, color: op(Colors.white, .7)),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.verified_user_rounded, color: C.gold, size: 13),
                                        const SizedBox(width: 4),
                                        Text('100% Zabiha Halal Certified', style: body(10, color: C.gold, w: FontWeight.w700)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Horizontal preview chips of cuts
                          SizedBox(
                            height: 34,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: butcherCuts.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemBuilder: (_, idx) {
                                final cut = butcherCuts[idx];
                                return GestureDetector(
                                  onTap: () => _open(ProductScreen(product: cut)),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: op(Colors.white, .08),
                                      borderRadius: BorderRadius.circular(99),
                                      border: Border.all(color: op(Colors.white, .1)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(cut.name, style: body(11, color: Colors.white, w: FontWeight.w600)),
                                        const SizedBox(width: 6),
                                        Text(rupees(cut.pricePerKg), style: body(11, color: C.gold, w: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Action button
                          Wrap(
                            alignment: WrapAlignment.end,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              if (isFiltered)
                                TextButton.icon(
                                  onPressed: () => state.setButcherFilter(null),
                                  icon: const Icon(Icons.close_rounded, size: 14, color: Colors.white70),
                                  label: Text('Clear Filter', style: body(12, color: Colors.white70)),
                                ),
                              BouncyPress(
                                onTap: () {
                                  state.setButcherFilter(butcher);
                                  setState(() => _currentNavIndex = 0);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                                  decoration: BoxDecoration(
                                    gradient: isFiltered ? null : emberGradient,
                                    color: isFiltered ? op(Colors.white, .15) : null,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        isFiltered ? 'Viewing in Cuts' : 'Browse Cuts',
                                        style: body(12, color: Colors.white, w: FontWeight.w800),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricPillar(String metric, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1B070E).withAlpha(200),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(55), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(70),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 15),
            ),
            const SizedBox(height: 6),
            Text(metric, style: display(13, color: Colors.white, w: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: body(9.5, color: op(Colors.white, .65), w: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHalalView(BuildContext context, AppState state) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 124),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Luxury Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3D131F), Color(0xFF1B070E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4AF37).withAlpha(60),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.verified_user_rounded, color: Color(0xFFFFDF9E), size: 24),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Halal Assurance',
                              style: display(22, w: FontWeight.w800, color: Colors.white),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: Colors.greenAccent,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: Colors.greenAccent, blurRadius: 6, spreadRadius: 1),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '100% Zabiha & Shariah Audited Standards',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: body(11.5, color: op(Colors.white, .75), w: FontWeight.w600),
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
                const SizedBox(width: 10),
                BagButton(count: state.cartCount, onTap: () => _open(const BagScreen())),
              ],
            ),
            const SizedBox(height: 20),

            // Hero Accreditation Card with Dual Gold Bevel Frame
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFDF9E),
                    Color(0xFFD4AF37),
                    Color(0xFF7A5718),
                    Color(0xFFD4AF37),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withAlpha(45),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withAlpha(120),
                    blurRadius: 20,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(1.4),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF2C0B16),
                      Color(0xFF1B060E),
                      Color(0xFF120308),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -30,
                        top: -30,
                        child: IgnorePointer(
                          child: Icon(
                            Icons.workspace_premium_rounded,
                            size: 190,
                            color: const Color(0xFFD4AF37).withAlpha(14),
                          ),
                        ),
                      ),
                      Positioned(
                        left: -40,
                        bottom: -40,
                        child: IgnorePointer(
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  C.crimson.withAlpha(25),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFFD4AF37).withAlpha(45),
                                        const Color(0xFFD4AF37).withAlpha(20),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(99),
                                    border: Border.all(color: const Color(0xFFD4AF37).withAlpha(140), width: 1),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.stars_rounded, color: Color(0xFFFFDF9E), size: 13),
                                      const SizedBox(width: 5),
                                      Text(
                                        'OFFICIAL SHARIAH ACCREDITATION',
                                        style: body(9.5, color: const Color(0xFFFFDF9E), w: FontWeight.w800)
                                            .copyWith(letterSpacing: 1.1),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFD4AF37).withAlpha(35),
                                    border: Border.all(color: const Color(0xFFD4AF37).withAlpha(120)),
                                  ),
                                  child: const Icon(Icons.verified_rounded, color: Color(0xFFFFDF9E), size: 18),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'حَلَالٌ طَيِّبٌ  ·  AUTHENTIC SHARIAH COMPLIANCE',
                                style: body(9.5, color: const Color(0xFFD4AF37), w: FontWeight.w700)
                                    .copyWith(letterSpacing: 1.3),
                              ),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              'Strict Zabiha Halal Guaranteed',
                              style: display(20, color: Colors.white, w: FontWeight.w800, h: 1.25),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Every single cut sourced through Fresh Meat is strictly inspected, hand-blessed with Tasmiyah, and certified according to authentic Islamic Shariah requirements.',
                              style: body(12.5, color: op(Colors.white, .82), h: 1.45),
                            ),
                            const SizedBox(height: 18),
                            Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFD4AF37).withAlpha(100),
                                    Colors.white.withAlpha(30),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'REGISTRATION LICENSE',
                                        style: body(9.5, color: op(Colors.white, .5), w: FontWeight.w700)
                                            .copyWith(letterSpacing: 0.8),
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          const Icon(Icons.security_rounded, color: Color(0xFFFFDF9E), size: 14),
                                          const SizedBox(width: 5),
                                          Text(
                                            'HAL-2026-IND-8841',
                                            style: display(12, color: const Color(0xFFFFDF9E), w: FontWeight.w800),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                BouncyPress(
                                  onTap: () => _showCertificateDialog(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFFDF9E),
                                          Color(0xFFD4AF37),
                                          Color(0xFFA57D19),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(99),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFD4AF37).withAlpha(80),
                                          blurRadius: 12,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.description_rounded, size: 14, color: Color(0xFF1B070E)),
                                        const SizedBox(width: 6),
                                        Text(
                                          'View Certificate',
                                          style: body(11.5, color: const Color(0xFF1B070E), w: FontWeight.w800),
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
              ),
            ),
            const SizedBox(height: 20),

            // 4 Trust Pillars Strip
            Row(
              children: [
                _buildMetricPillar('100%', 'Hand Cut', Icons.content_cut_rounded, const Color(0xFFFFDF9E)),
                const SizedBox(width: 8),
                _buildMetricPillar('0%', 'Stunning', Icons.block_rounded, const Color(0xFFFF8570)),
                const SizedBox(width: 8),
                _buildMetricPillar('<4°C', 'Cold Chain', Icons.ac_unit_rounded, const Color(0xFF80D8FF)),
                const SizedBox(width: 8),
                _buildMetricPillar('Daily', 'Vet Verified', Icons.health_and_safety_rounded, const Color(0xFFB9F6CA)),
              ],
            ),
            const SizedBox(height: 24),

            // Section Header with Ornamental Dividers
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, const Color(0xFFD4AF37).withAlpha(90)],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_rounded, color: Color(0xFFD4AF37), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'OUR 4 QUALITY PROMISES',
                        style: display(11, color: const Color(0xFFFFDF9E), w: FontWeight.w800)
                            .copyWith(letterSpacing: 1.6),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFFD4AF37).withAlpha(90), Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const _TrustCard(
              roman: 'I',
              icon: Icons.check_circle_rounded,
              iconColor: Color(0xFFFFDF9E),
              title: 'Zabiha Hand-Slaughtered',
              badge: '100% Shariah Compliant',
              desc: 'Conducted solely by qualified Muslim slaughtermen invoking the Tasmiyah. Strict manual cut of the jugular veins, carotid arteries, and windpipe without electrical or bolt stunning.',
              highlight: 'Tasmiyah blessed · Zero electrical stunning',
            ),
            const SizedBox(height: 14),

            const _TrustCard(
              roman: 'II',
              icon: Icons.ac_unit_rounded,
              iconColor: Color(0xFF80D8FF),
              title: 'Sub-4°C Cold Chain Transit',
              badge: 'IoT Monitored',
              desc: 'Cuts never touch ambient heat. From the butcher block to insulated vacuum chill-packs with real-time sensor temperature logs delivered to your door.',
              highlight: 'Continuous -1.2°C logged in transit',
            ),
            const SizedBox(height: 14),

            const _TrustCard(
              roman: 'III',
              icon: Icons.health_and_safety_rounded,
              iconColor: Color(0xFFB9F6CA),
              title: 'Daily Veterinary Inspections',
              badge: 'Ante & Post-Mortem',
              desc: 'Certified veterinarians examine livestock prior to cutting. Cutting benches and steel blades sanitized at 82°C every 2 hours with zero artificial preservatives.',
              highlight: 'Certified MVSc clinical ante/post inspection',
            ),
            const SizedBox(height: 14),

            const _TrustCard(
              roman: 'IV',
              icon: Icons.qr_code_2_rounded,
              iconColor: C.ember,
              title: 'Full Artisan Traceability',
              badge: 'Farm to Plate',
              desc: 'Know exactly which local partner prepared your cut, the exact cutting time, and batch verification number printed on every package.',
              highlight: 'Individual livestock origin & cut stamp',
            ),
            const SizedBox(height: 24),

            // Luxury CTA to Browse Cuts
            ShineButton(
              onTap: () => setState(() => _currentNavIndex = 0),
              height: 56,
              radius: 20,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stars_rounded, color: Color(0xFFFFDF9E), size: 20),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Browse Certified Halal Cuts',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: display(14, color: Colors.white, w: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final allList = products.where((p) => p.type == _type).map(state.getLiveProduct).toList();
    final list = state.filterButcher != null
        ? (allList.where((p) => p.butcher == state.filterButcher).toList().isNotEmpty
            ? allList.where((p) => p.butcher == state.filterButcher).toList()
            : allList)
        : allList;
    final others = [
      for (final t in MeatType.values)
        if (t != _type)
          state.getLiveProduct(products.firstWhere((p) => p.type == t))
    ];

    return PopScope(
      canPop: _currentNavIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_currentNavIndex != 0) {
          setState(() => _currentNavIndex = 0);
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: darkBg),
          child: Stack(children: [
            IndexedStack(
              index: _currentNavIndex,
              children: [
                TickerMode(
                  enabled: _currentNavIndex == 0,
                  child: _buildCutsView(context, state, list, others),
                ),
                TickerMode(
                  enabled: _currentNavIndex == 1,
                  child: _buildButchersView(context, state),
                ),
                TickerMode(
                  enabled: _currentNavIndex == 2,
                  child: TrackingScreen(
                    isEmbedded: true,
                    isActive: _currentNavIndex == 2,
                    onBrowseCuts: () => setState(() => _currentNavIndex = 0),
                  ),
                ),
                TickerMode(
                  enabled: _currentNavIndex == 3,
                  child: _buildHalalView(context, state),
                ),
              ],
            ),

            // Bottom Scrim Fade to eliminate harsh cutting edges of scrolling content
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 110,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        const Color(0xFF140409).withAlpha(190),
                        const Color(0xFF140409),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Fluid Floating Dock Bottom Navigation Bar - positioned down at the bottom
            Positioned(
              left: 18,
              right: 18,
              bottom: MediaQuery.of(context).padding.bottom > 34
                  ? (MediaQuery.of(context).padding.bottom + 4)
                  : 8.0,
              child: LiquidSlidingDock(
                currentIndex: _currentNavIndex,
                activeOrdersCount: state.activeOrders.length,
                onTabSelected: (index) {
                  setState(() => _currentNavIndex = index);
                  if (index == 0 && _scrollController.hasClients) {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _TrustCard extends StatelessWidget {
  final String roman;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String badge;
  final String desc;
  final String highlight;

  const _TrustCard({
    required this.roman,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.badge,
    required this.desc,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            iconColor.withAlpha(45),
            Colors.white.withAlpha(12),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(90),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(1.2),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(21),
          gradient: const LinearGradient(
            colors: [Color(0xFF220A13), Color(0xFF130409)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: Stack(
            children: [
              Positioned(
                right: 14,
                top: 8,
                child: Text(
                  roman,
                  style: display(36, color: Colors.white.withAlpha(14), w: FontWeight.w900),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          colors: [
                            iconColor.withAlpha(55),
                            iconColor.withAlpha(18),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: iconColor.withAlpha(110), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: iconColor.withAlpha(40),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(icon, color: iconColor, size: 22),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  title,
                                  style: display(13, w: FontWeight.w800, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: iconColor.withAlpha(30),
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(color: iconColor.withAlpha(100), width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 4.5,
                                      height: 4.5,
                                      decoration: BoxDecoration(
                                        color: iconColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      badge,
                                      style: body(8.5, color: iconColor, w: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Text(
                            desc,
                            style: body(11.5, color: op(Colors.white, .78), h: 1.4),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(8),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white.withAlpha(15)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline_rounded, size: 12, color: iconColor),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    highlight,
                                    style: body(10, color: op(Colors.white, .92), w: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final Product product;
  final GlobalKey steakKey;
  final VoidCallback onAdd, onTap;
  const _HeroCard({required this.product, required this.steakKey, required this.onAdd, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cols = product.type.heroColors;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned(
            top: 55,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(38),
                gradient: LinearGradient(
                  begin: const Alignment(-.3, -1),
                  end: const Alignment(.3, 1),
                  colors: cols,
                  stops: const [0, .48, 1],
                ),
                boxShadow: [BoxShadow(color: op(Colors.black, .40), blurRadius: 24, offset: const Offset(0, 12))],
              ),
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: op(Colors.white, .2), borderRadius: BorderRadius.circular(99)),
                  child: Text('HALAL CERTIFIED', style: body(10.5, w: FontWeight.w800).copyWith(letterSpacing: 1.2)),
                ),
                const SizedBox(height: 10),
                Text(product.name, style: display(24, h: 1.18)),
                const SizedBox(height: 6),
                Text('Cut ${product.cutAgo} · ${product.butcher} · ${product.rating} ★', style: body(12.5).copyWith(color: op(Colors.white, .85))),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                  Text.rich(TextSpan(children: [
                    TextSpan(text: rupees(product.pricePerKg), style: display(22)),
                    TextSpan(text: ' / kg', style: body(12).copyWith(color: op(Colors.white, .8))),
                  ])),
                  BouncyPress(
                    onTap: onAdd,
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: C.cream,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 14, offset: const Offset(0, 6)),
                        ],
                      ),
                      child: Center(
                        child: Text('+', style: body(30, color: C.crimson, w: FontWeight.w700)),
                      ),
                    ),
                  ),
                ]),
              ]),
            ),
          ),
          Positioned(
            top: -10,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: Stack(alignment: Alignment.center, children: [
                  Spin(seconds: 30, child: CustomPaint(size: const Size(300, 300), painter: DashedRingPainter(op(C.cream, .35)))),
                  Floating(child: KeyedSubtree(key: steakKey, child: MeatImage(product: product, width: 250))),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
