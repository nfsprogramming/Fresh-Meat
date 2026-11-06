import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../services/admin_role_service.dart';
import '../services/location_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Full interactive Admin Screen allowing the store owner/admin
/// to update the Shop Name, Picture/Cover, Physical Address, and Phone Number.
class AdminShopScreen extends StatefulWidget {
  const AdminShopScreen({super.key});

  @override
  State<AdminShopScreen> createState() => _AdminShopScreenState();
}

class _AdminShopScreenState extends State<AdminShopScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _photoCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _hoursCtrl;
  late TextEditingController _fssaiCtrl;
  late TextEditingController _halalCtrl;
  bool _isOpen = true;
  bool _isLocating = false;

  final List<({String label, String path, String desc})> _presetPhotos = const [
    (
      label: 'Artisan Storefront',
      path: 'assets/images/splash_hero.jpg',
      desc: 'Central Butchery',
    ),
    (
      label: 'Official Brand Emblem',
      path: 'assets/images/app_logo.png',
      desc: 'Halal Seal Logo',
    ),
    (
      label: 'Heritage Mutton House',
      path: 'assets/images/mutton_curry.jpg',
      desc: 'Fresh Cuts Display',
    ),
    (
      label: 'Poultry & Farm Fresh',
      path: 'assets/images/chicken_curry.jpg',
      desc: 'Daily Poultry Unit',
    ),
    (
      label: 'Prime Steak Boutique',
      path: 'assets/images/beef_ribeye.jpg',
      desc: 'Prime Cold Chain',
    ),
    (
      label: 'Modern Meat Studio',
      path:
          'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=600&auto=format&fit=crop',
      desc: 'Stainless Steel Cold Chain',
    ),
  ];

  final List<ShopProfile> _quickShopTemplates = const [
    ShopProfile(
      id: 'shop_alnoor',
      name: 'Al-Noor Halal Cuts & Central Butchery',
      photoUrl: 'assets/images/splash_hero.jpg',
      address:
          'Shop #4, Halal Meat Market, Russell Market, Shivaji Nagar, Bengaluru, Karnataka 560051',
      phone: '+91 98450 12345',
      email: 'alnoor.butchery@freshmeatmarket.in',
      openingHours: '06:00 AM – 09:30 PM (Daily)',
      fssaiLicense: 'FSSAI-11223344556677',
      halalCertNumber: 'HAL-2026-IND-8841',
      rating: 4.9,
      isOpen: true,
    ),
    ShopProfile(
      id: 'shop_almadina',
      name: 'Al-Madina Mutton House & Biryani Cuts',
      photoUrl: 'assets/images/mutton_curry.jpg',
      address:
          '#18, Mosque Road Cross, Frazer Town, Pulakeshi Nagar, Bengaluru, Karnataka 560005',
      phone: '+91 98860 54321',
      email: 'almadina@freshmeatmarket.in',
      openingHours: '06:30 AM – 10:00 PM (Daily)',
      fssaiLicense: 'FSSAI-11223344558899',
      halalCertNumber: 'HAL-2026-IND-8842',
      rating: 4.9,
      isOpen: true,
    ),
    ShopProfile(
      id: 'shop_kareem',
      name: 'Kareem Prime Butchery & Steakhouse Supply',
      photoUrl: 'assets/images/beef_ribeye.jpg',
      address:
          'Plot 42, 80 Feet Road, 4th Block, Koramangala, Bengaluru, Karnataka 560034',
      phone: '+91 97400 98765',
      email: 'kareem.butchery@freshmeatmarket.in',
      openingHours: '07:00 AM – 09:00 PM (Daily)',
      fssaiLicense: 'FSSAI-11223344559900',
      halalCertNumber: 'HAL-2026-IND-8843',
      rating: 4.8,
      isOpen: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    final current = context.read<AppState>().shopProfile;
    _nameCtrl = TextEditingController(text: current.name);
    _photoCtrl = TextEditingController(text: current.photoUrl);
    _addressCtrl = TextEditingController(text: current.address);
    _phoneCtrl = TextEditingController(text: current.phone);
    _emailCtrl = TextEditingController(text: current.email);
    _hoursCtrl = TextEditingController(text: current.openingHours);
    _fssaiCtrl = TextEditingController(text: current.fssaiLicense);
    _halalCtrl = TextEditingController(text: current.halalCertNumber);
    _isOpen = current.isOpen;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _photoCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _hoursCtrl.dispose();
    _fssaiCtrl.dispose();
    _halalCtrl.dispose();
    super.dispose();
  }

  void _applyTemplate(ShopProfile t) {
    setState(() {
      _nameCtrl.text = t.name;
      _photoCtrl.text = t.photoUrl;
      _addressCtrl.text = t.address;
      _phoneCtrl.text = t.phone;
      _emailCtrl.text = t.email;
      _hoursCtrl.text = t.openingHours;
      _fssaiCtrl.text = t.fssaiLicense;
      _halalCtrl.text = t.halalCertNumber;
      _isOpen = t.isOpen;
    });
  }

  Future<void> _detectShopGpsAddress() async {
    setState(() => _isLocating = true);
    try {
      final loc = await LocationService.instance.getCurrentLocation();
      if (mounted) {
        setState(() {
          if (loc != null) {
            _addressCtrl.text = loc.formattedAddress;
          }
          _isLocating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E0A10),
            content: Row(
              children: [
                const Icon(Icons.gps_fixed_rounded, color: C.gold, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Live shop coordinates detected & applied!',
                      style: body(13, color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  Future<void> _saveShopProfile() async {
    final name = _nameCtrl.text.trim();
    final photo = _photoCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    if (name.isEmpty) {
      _showError('Shop Name cannot be empty.');
      return;
    }
    if (address.isEmpty) {
      _showError('Shop Address cannot be empty.');
      return;
    }
    if (phone.isEmpty) {
      _showError('Shop Phone Number cannot be empty.');
      return;
    }

    HapticFeedback.heavyImpact();
    final state = context.read<AppState>();
    await state.updateShopProfile(
      name: name,
      photoUrl: photo.isNotEmpty ? photo : 'assets/images/splash_hero.jpg',
      address: address,
      phone: phone,
      email: _emailCtrl.text.trim(),
      openingHours: _hoursCtrl.text.trim(),
      fssaiLicense: _fssaiCtrl.text.trim(),
      halalCertNumber: _halalCtrl.text.trim(),
      isOpen: _isOpen,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1E0A10),
          duration: const Duration(seconds: 3),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Shop profile saved & updated live across the app!',
                    style: body(13, color: Colors.white, w: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: C.ember,
        content: Text(msg, style: body(13, color: Colors.white, w: FontWeight.w600)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    // SECURITY GATE: Only users verified as 'admin' in Firebase backend are allowed.
    if (!state.isAdmin) {
      return _buildAccessDeniedScreen(context, state);
    }

    final previewPhoto = _photoCtrl.text.trim().isNotEmpty
        ? _photoCtrl.text.trim()
        : 'assets/images/splash_hero.jpg';
    final previewName =
        _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : 'Artisan Butchery Store';
    final previewPhone =
        _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : '+91 98450 12345';
    final previewAddress = _addressCtrl.text.trim().isNotEmpty
        ? _addressCtrl.text.trim()
        : 'Storefront location address';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: darkBg),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    BouncyPress(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: op(Colors.white, 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: op(Colors.white, 0.12)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Shop Administration',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: display(16, w: FontWeight.w800),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: op(C.gold, 0.2),
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(color: C.gold, width: 0.8),
                                ),
                                child: Text('ADMIN',
                                    style: body(9, color: C.gold, w: FontWeight.w800)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('Edit storefront picture, name, address & phone',
                              style: body(11, color: op(C.cream, 0.7))),
                        ],
                      ),
                    ),
                    BouncyPress(
                      onTap: _saveShopProfile,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: emberGradient,
                          borderRadius: BorderRadius.circular(99),
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
                            const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text('SAVE',
                                style: body(11, color: Colors.white, w: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: Color(0x22FFFFFF), height: 1),

              // Form & Live Preview Body
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 0. FIREBASE ADMIN ROLE STATUS CARD
                      _buildFirebaseRoleBanner(context, state),
                      const SizedBox(height: 18),

                      // 1. LIVE PREVIEW CARD
                      Text('LIVE STOREFRONT PREVIEW',
                          style: body(11, color: C.gold, w: FontWeight.w800)
                              .copyWith(letterSpacing: 1.2)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E0A10),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: op(C.gold, 0.35), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(90),
                              blurRadius: 16,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Picture Thumbnail
                                Container(
                                  width: 68,
                                  height: 68,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: op(Colors.white, 0.2)),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: _buildImageWidget(previewPhoto, 68, 68),
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
                                              previewName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: display(15,
                                                  color: Colors.white, w: FontWeight.w800),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 7, vertical: 2.5),
                                            decoration: BoxDecoration(
                                              color: op(C.gold, 0.18),
                                              borderRadius: BorderRadius.circular(99),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.star_rounded,
                                                    color: C.gold, size: 13),
                                                const SizedBox(width: 3),
                                                Text('4.9',
                                                    style: body(11,
                                                        color: C.gold, w: FontWeight.w800)),
                                              ],
                                            ),
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
                                              color: _isOpen
                                                  ? const Color(0xFF34A853)
                                                  : Colors.redAccent,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            _isOpen
                                                ? 'Store Open · Accepting Orders'
                                                : 'Store Closed · Pre-orders Only',
                                            style: body(11,
                                                color: _isOpen
                                                    ? const Color(0xFF81C784)
                                                    : Colors.redAccent,
                                                w: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.verified_user_rounded,
                                              color: C.gold, size: 12),
                                          const SizedBox(width: 4),
                                          Text('100% Zabiha Halal Certified',
                                              style: body(10,
                                                  color: C.gold, w: FontWeight.w700)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(color: Color(0x22FFFFFF), height: 1),
                            const SizedBox(height: 10),
                            // Address preview
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on_rounded, size: 14, color: C.gold),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    previewAddress,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: body(11, color: op(Colors.white, 0.85), h: 1.3),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Phone preview
                            Row(
                              children: [
                                const Icon(Icons.phone_rounded,
                                    size: 14, color: Colors.greenAccent),
                                const SizedBox(width: 6),
                                Text(
                                  previewPhone,
                                  style: body(12, color: Colors.greenAccent, w: FontWeight.w700),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 2. QUICK PRESET TEMPLATES
                      Text('QUICK FILL FROM ARTISAN BUTCHERS',
                          style: body(11, color: C.gold, w: FontWeight.w800)
                              .copyWith(letterSpacing: 1.2)),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: _quickShopTemplates.map((t) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: BouncyPress(
                                onTap: () => _applyTemplate(t),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: op(Colors.white, 0.06),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: op(Colors.white, 0.12)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.storefront_rounded,
                                          size: 13, color: C.gold),
                                      const SizedBox(width: 6),
                                      Text(t.name.split(' ').take(2).join(' '),
                                          style: body(11,
                                              color: Colors.white, w: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 3. EDIT SHOP PIC
                      Text('STORE PICTURE / PHOTO',
                          style: body(11, color: C.gold, w: FontWeight.w800)
                              .copyWith(letterSpacing: 1.2)),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _photoCtrl,
                        label: 'Image URL or Asset Path',
                        icon: Icons.image_rounded,
                        hint: 'assets/images/splash_hero.jpg or https://...',
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 10),
                      Text('Select a curated storefront photo:',
                          style: body(11, color: op(C.cream, 0.6))),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 74,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _presetPhotos.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, i) {
                            final preset = _presetPhotos[i];
                            final isSelected = _photoCtrl.text.trim() == preset.path;

                            return BouncyPress(
                              onTap: () {
                                setState(() => _photoCtrl.text = preset.path);
                              },
                              child: Container(
                                width: 90,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected ? C.gold : op(Colors.white, 0.15),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: _buildImageWidget(preset.path, 90, 74),
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withAlpha(200),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 4,
                                      left: 4,
                                      right: 4,
                                      child: Text(
                                        preset.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: body(9,
                                            color: Colors.white, w: FontWeight.w700),
                                      ),
                                    ),
                                    if (isSelected)
                                      const Positioned(
                                        top: 4,
                                        right: 4,
                                        child: Icon(Icons.check_circle_rounded,
                                            color: C.gold, size: 14),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 4. EDIT SHOP NAME
                      Text('STORE NAME',
                          style: body(11, color: C.gold, w: FontWeight.w800)
                              .copyWith(letterSpacing: 1.2)),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _nameCtrl,
                        label: 'Shop Name',
                        icon: Icons.store_rounded,
                        hint: 'e.g. Al-Noor Halal Cuts & Central Butchery',
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 20),

                      // 5. EDIT PHONE NUMBER
                      Text('OFFICIAL PHONE NUMBER (CUSTOMER ORDERS & WHATSAPP)',
                          style: body(11, color: C.gold, w: FontWeight.w800)
                              .copyWith(letterSpacing: 1.2)),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _phoneCtrl,
                        label: 'Phone Number',
                        icon: Icons.phone_rounded,
                        hint: '+91 98450 12345',
                        keyboardType: TextInputType.phone,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 20),

                      // 6. EDIT SHOP ADDRESS WITH GPS BUTTON
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('STORE PHYSICAL ADDRESS',
                              style: body(11, color: C.gold, w: FontWeight.w800)
                                  .copyWith(letterSpacing: 1.2)),
                          BouncyPress(
                            onTap: _isLocating ? null : _detectShopGpsAddress,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: op(C.ember, 0.2),
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(color: op(C.ember, 0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isLocating)
                                    const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: C.gold),
                                    )
                                  else
                                    const Icon(Icons.my_location_rounded,
                                        size: 13, color: C.gold),
                                  const SizedBox(width: 5),
                                  Text(
                                    _isLocating ? 'Locating...' : 'Use GPS Location',
                                    style: body(10, color: C.gold, w: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _addressCtrl,
                        label: 'Storefront Address & Landmark',
                        icon: Icons.location_on_rounded,
                        hint:
                            'Shop #4, Halal Meat Market, Russell Market, Shivaji Nagar, Bengaluru, Karnataka 560051',
                        maxLines: 3,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 20),

                      // 7. OPERATING HOURS & LICENSING
                      Text('HOURS & REGULATORY LICENSES',
                          style: body(11, color: C.gold, w: FontWeight.w800)
                              .copyWith(letterSpacing: 1.2)),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _hoursCtrl,
                        label: 'Operating Hours',
                        icon: Icons.access_time_rounded,
                        hint: '06:00 AM – 09:30 PM (Daily)',
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _fssaiCtrl,
                              label: 'FSSAI License',
                              icon: Icons.assignment_turned_in_rounded,
                              hint: 'FSSAI-11223344556677',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _halalCtrl,
                              label: 'Halal Cert #',
                              icon: Icons.verified_rounded,
                              hint: 'HAL-2026-IND-8841',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 8. STORE OPEN TOGGLE
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: op(Colors.white, 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: op(Colors.white, 0.1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _isOpen
                                      ? Icons.storefront_rounded
                                      : Icons.store_mall_directory_outlined,
                                  color: _isOpen ? Colors.greenAccent : Colors.redAccent,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Storefront Active & Open',
                                        style: body(13,
                                            color: Colors.white, w: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text(
                                        _isOpen
                                            ? 'Accepting live 45-min deliveries'
                                            : 'Accepting pre-orders only',
                                        style: body(11, color: op(C.cream, 0.6))),
                                  ],
                                ),
                              ],
                            ),
                            Switch.adaptive(
                              value: _isOpen,
                              activeTrackColor: C.ember,
                              activeThumbColor: C.gold,
                              onChanged: (val) => setState(() => _isOpen = val),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // SAVE BUTTON
                      BouncyPress(
                        onTap: _saveShopProfile,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: emberGradient,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: C.ember.withAlpha(90),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'SAVE STORE PROFILE',
                                  style: display(14,
                                      color: Colors.white, w: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // RESET BUTTON
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            _applyTemplate(ShopProfile.defaultShop);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF1E0A10),
                                content: Text('Form reset to artisan defaults.',
                                    style: body(12, color: Colors.white)),
                              ),
                            );
                          },
                          icon: const Icon(Icons.restore_rounded,
                              size: 14, color: Colors.white54),
                          label: Text('Reset to Artisan Defaults',
                              style: body(12, color: Colors.white54)),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: op(Colors.white, 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: op(Colors.white, 0.1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: onChanged,
        style: body(13, color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: body(12, color: C.gold, w: FontWeight.w600),
          hintText: hint,
          hintStyle: body(12, color: op(Colors.white, 0.3)),
          prefixIcon: Icon(icon, size: 18, color: C.gold),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _buildImageWidget(String path, double w, double h) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: w,
        height: h,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackImage(w, h),
      );
    }
    return Image.asset(
      path,
      width: w,
      height: h,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _fallbackImage(w, h),
    );
  }

  Widget _fallbackImage(double w, double h) {
    return Container(
      width: w,
      height: h,
      color: const Color(0xFF2A0914),
      alignment: Alignment.center,
      child: const Icon(Icons.storefront_rounded, color: C.gold, size: 24),
    );
  }

  Widget _buildFirebaseRoleBanner(BuildContext context, AppState state) {
    final user = state.currentUser;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E070F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: op(C.gold, 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: op(C.gold, 0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: op(C.gold, 0.45)),
                ),
                child: const Icon(Icons.verified_user_rounded, color: C.gold, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Firebase Admin Verified',
                            style: display(13, color: Colors.white, w: FontWeight.w800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'ROLE: ADMIN',
                            style: body(8.5, color: Colors.white, w: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Account: ${user?.email ?? "master.admin"}',
                      style: body(11, color: op(C.gold, 0.9)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              BouncyPress(
                onTap: () => _showAdminWhitelistDialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: op(Colors.white, 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: op(Colors.white, 0.16)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people_alt_rounded, size: 14, color: C.cream),
                      const SizedBox(width: 4),
                      Text('Roles', style: body(10.5, color: C.cream, w: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Security Rule: Access to this console is strictly controlled by your Firebase Firestore "admins" collection. Only emails assigned role: "admin" can view and edit shop profiles.',
            style: body(11, color: op(Colors.white, 0.7), h: 1.4),
          ),
        ],
      ),
    );
  }

  void _showAdminWhitelistDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E0A10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: C.gold, width: 1.2),
        ),
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings_rounded, color: C.gold, size: 22),
            const SizedBox(width: 8),
            Text('Firebase Admin Roles', style: display(15, color: Colors.white, w: FontWeight.w800)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<List<AdminRecord>>(
            future: AdminRoleService.instance.fetchAllAdmins(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(color: C.ember),
                  ),
                );
              }
              final records = snapshot.data ?? [];
              if (records.isEmpty) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'No admin records returned from Firebase or offline.',
                      style: body(12, color: Colors.white70),
                    ),
                  ],
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Admin Whitelist in Firestore (Project: ${AdminRoleService.projectId}):',
                    style: body(11, color: op(Colors.white, 0.7)),
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: records.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final r = records[i];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: op(Colors.white, 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: op(Colors.white, 0.1)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.email,
                                      style: body(12, color: Colors.white, w: FontWeight.w700),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (r.notes != null)
                                      Text(
                                        r.notes!,
                                        style: body(10, color: C.gold),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: op(C.gold, 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(r.role, style: body(9, color: C.gold, w: FontWeight.w800)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'To grant or revoke access, add or remove documents with the user\'s email in the "admins" collection via your Firebase Console.',
                    style: body(10.5, color: op(C.gold, 0.85), h: 1.35),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Close', style: body(13, color: Colors.white70, w: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessDeniedScreen(BuildContext context, AppState state) {
    final user = state.currentUser;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: darkBg),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: BouncyPress(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: op(Colors.white, 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: op(Colors.white, 0.12)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: op(C.ember, 0.16),
                    shape: BoxShape.circle,
                    border: Border.all(color: op(C.ember, 0.6), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: C.ember.withAlpha(70),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.gpp_bad_rounded, size: 46, color: C.ember),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Access Restricted',
                  style: display(22, w: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Admin privileges are strictly governed by Firebase backend.',
                  textAlign: TextAlign.center,
                  style: body(13, color: op(Colors.white, 0.85), w: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B070E),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: op(Colors.white, 0.10)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            user != null ? Icons.account_circle_rounded : Icons.person_off_rounded,
                            size: 18,
                            color: C.gold,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              user != null ? user.email : 'Not Signed In',
                              style: body(13, color: Colors.white, w: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: op(C.ember, 0.15),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: op(C.ember, 0.4)),
                        ),
                        child: Text(
                          user != null ? 'Role: ${user.role} (Customer Only)' : 'Authentication Required',
                          style: body(10.5, color: C.ember, w: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Only emails registered with role: "admin" in the Firebase Firestore "admins" collection (Project: ${AdminRoleService.projectId}) can access this console.',
                        textAlign: TextAlign.center,
                        style: body(11.5, color: op(Colors.white, 0.65), h: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                BouncyPress(
                  onTap: () async {
                    await state.signInWithGoogle();
                    if (context.mounted && state.isAdmin) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Color(0xFF1E0A10),
                          content: Text('✅ Verified Firebase Admin access!'),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: emberGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: C.ember.withAlpha(80),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.login_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            user != null ? 'Switch to Admin Account' : 'Sign In with Google Admin',
                            style: body(13.5, color: Colors.white, w: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                BouncyPress(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: op(Colors.white, 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: op(Colors.white, 0.15)),
                    ),
                    child: Center(
                      child: Text(
                        'Return to Storefront',
                        style: body(13, color: Colors.white70, w: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
