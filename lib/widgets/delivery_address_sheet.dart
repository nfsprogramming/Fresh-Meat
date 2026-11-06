import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/location_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'common.dart';

/// Opens the high-fidelity Delivery Location screen designed in
/// delivery_address_preview.html, featuring an interactive street map,
/// pulse pin, quick address presets, rider notes, and address validation.
Future<void> showDeliveryAddressSheet(BuildContext context) async {
  HapticFeedback.selectionClick();
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const DeliveryAddressScreen(),
    ),
  );
}

/// Compatibility alias so any existing caller of DeliveryAddressSheet
/// automatically renders the full new screen.
class DeliveryAddressSheet extends StatelessWidget {
  const DeliveryAddressSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return const DeliveryAddressScreen();
  }
}

/// Full interactive Delivery Address screen faithful to delivery_address_preview.html.
class DeliveryAddressScreen extends StatefulWidget {
  const DeliveryAddressScreen({super.key});

  @override
  State<DeliveryAddressScreen> createState() => _DeliveryAddressScreenState();
}

class _DeliveryAddressScreenState extends State<DeliveryAddressScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _searchCtrl;
  late final TextEditingController _houseCtrl;
  late final TextEditingController _landmarkCtrl;
  late final ScrollController _scrollCtrl;

  late final AnimationController _pulseCtrl;

  String _areaName = 'Royapuram';
  String _streetAddress = 'Evening Bazaar Road, Park Town, Chennai, Tamil Nadu';
  double _lat = 13.0827;
  double _lon = 80.2707;
  double _panX = 0.0;
  double _panY = 0.0;
  double _zoom = 15.0;

  bool _isLocating = false;
  bool _houseError = false;

  String _selectedTag = 'Home';
  final Set<String> _selectedRiderNotes = {'Call on arrival'};

  final List<String> _tags = const ['Home', 'Work', 'Other'];
  final List<String> _riderNotes = const [
    'Call on arrival',
    'Leave at door',
    "Don't ring bell",
  ];

  String get displayAreaName {
    if (_areaName.trim().isNotEmpty && _areaName.trim() != 'Current Location') {
      return _areaName.trim();
    }
    if (_streetAddress.isNotEmpty) {
      final parts = _streetAddress
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (parts.length > 1) {
        return parts[1];
      } else if (parts.isNotEmpty) {
        return parts.first;
      }
    }
    return 'Delivery Location';
  }

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _houseCtrl = TextEditingController();
    _landmarkCtrl = TextEditingController();
    _scrollCtrl = ScrollController();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    final state = context.read<AppState>();
    final currentAddr = state.selectedAddress;
    if (currentAddr.isNotEmpty && currentAddr != 'Tap to add delivery address') {
      _streetAddress = currentAddr;
      final parts = currentAddr.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      if (parts.isNotEmpty) {
        _areaName = parts.length > 1 ? parts[1] : parts.first;
      }
    }
    if (state.currentDeliveryLocation != null) {
      _lat = state.currentDeliveryLocation!.latitude;
      _lon = state.currentDeliveryLocation!.longitude;
      if (state.currentDeliveryLocation!.shortTitle.trim().isNotEmpty) {
        _areaName = state.currentDeliveryLocation!.shortTitle.trim();
      }
      if (state.currentDeliveryLocation!.formattedAddress.trim().isNotEmpty) {
        _streetAddress = state.currentDeliveryLocation!.formattedAddress.trim();
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _houseCtrl.dispose();
    _landmarkCtrl.dispose();
    _scrollCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _detectCurrentLocation() async {
    HapticFeedback.selectionClick();
    setState(() => _isLocating = true);

    try {
      final loc = await LocationService.instance.getCurrentLocation();
      if (!mounted) return;

      if (loc != null) {
        setState(() {
          _lat = loc.latitude;
          _lon = loc.longitude;
          _areaName = loc.shortTitle.trim().isNotEmpty ? loc.shortTitle.trim() : 'Delivery Location';
          _streetAddress = loc.formattedAddress;
          _panX = 0.0;
          _panY = 0.0;
          _isLocating = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E0A10),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: C.ember, width: 1.2),
            ),
            content: Row(
              children: [
                const Icon(Icons.my_location_rounded, color: C.ember, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Located: $displayAreaName',
                    style: GoogleFonts.manrope(
                        fontSize: 12.5, color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        setState(() => _isLocating = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _onSearchSubmit(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;

    final parts = clean.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    setState(() {
      _streetAddress = clean;
      _areaName = parts.isNotEmpty ? parts.first : clean;
      _panX = 0.0;
      _panY = 0.0;
    });

    FocusScope.of(context).unfocus();

    try {
      final geo = await LocationService.instance.geocodeAddress(clean);
      if (geo != null && mounted) {
        setState(() {
          _lat = geo.lat;
          _lon = geo.lon;
          _streetAddress = geo.formattedAddress;
          _areaName = geo.shortTitle;
        });
      }
    } catch (_) {}
  }

  void _onMapPanEnd() async {
    final zoomInt = _zoom.round();
    final centerX = _MapTileCanvas.lonToX(_lon, zoomInt.toDouble()) - _panX;
    final centerY = _MapTileCanvas.latToY(_lat, zoomInt.toDouble()) - _panY;

    final newLon = _MapTileCanvas.xToLon(centerX, zoomInt.toDouble());
    final newLat = _MapTileCanvas.yToLat(centerY, zoomInt.toDouble());

    setState(() {
      _lat = newLat;
      _lon = newLon;
      _panX = 0.0;
      _panY = 0.0;
    });

    try {
      final rev = await LocationService.instance.reverseGeocode(newLat, newLon);
      if (rev != null && mounted) {
        setState(() {
          _streetAddress = rev.formattedAddress;
          if (rev.shortTitle.trim().isNotEmpty) {
            _areaName = rev.shortTitle.trim();
          }
        });
      }
    } catch (_) {}
  }

  void _confirmAddress() {
    final house = _houseCtrl.text.trim();
    if (house.isEmpty) {
      setState(() => _houseError = true);
      HapticFeedback.heavyImpact();
      _scrollCtrl.animateTo(
        90.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    }

    final landmark = _landmarkCtrl.text.trim();
    final addressParts = [
      house,
      if (landmark.isNotEmpty) landmark,
      if (!_streetAddress.contains(displayAreaName)) displayAreaName,
      _streetAddress,
    ];
    final fullAddress = addressParts.join(', ');

    final state = context.read<AppState>();
    state.setAddress(
      fullAddress,
      location: DeliveryLocation(
        latitude: _lat,
        longitude: _lon,
        formattedAddress: fullAddress,
        shortTitle: displayAreaName,
        source: 'UserConfirmed',
      ),
    );

    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E0A10),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF00E676), width: 1.2),
        ),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Delivery address saved as $_selectedTag!',
                style: GoogleFonts.manrope(
                    fontSize: 13, color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final topPad = media.padding.top;
    final bottomPad = media.padding.bottom;
    final h = media.size.height;

    // Top map height occupies ~48% of height so the map is spacious and the sheet rests comfortably in the lower half
    final mapHeight = (h * 0.48).clamp(340.0, 440.0);
    final pinY = mapHeight * 0.48;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0306),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ==================== 1. INTERACTIVE MAP SECTION ====================
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: mapHeight + 34, // overlaps under the curved sheet
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _panX += details.delta.dx;
                  _panY += details.delta.dy;
                });
              },
              onPanEnd: (_) => _onMapPanEnd(),
              onDoubleTap: () {
                setState(() {
                  _zoom = (_zoom >= 16.0) ? 14.0 : 16.0;
                });
              },
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // Live OpenStreetMap Tiles & Background
                  Positioned.fill(
                    child: _MapTileCanvas(
                      panX: _panX,
                      panY: _panY,
                      lat: _lat,
                      lon: _lon,
                      zoom: _zoom,
                      pinY: pinY,
                    ),
                  ),

                  // Radar Pulse Wave
                  Positioned(
                    left: 0,
                    right: 0,
                    top: pinY - 29,
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (context, _) {
                          final p = _pulseCtrl.value;
                          final scale = 0.4 + (1.8 * p);
                          final opacity = (1.0 - p).clamp(0.0, 1.0);
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: op(C.ember, opacity * 0.65),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Center Delivery Drop Pin
                  Positioned(
                    left: 0,
                    right: 0,
                    top: pinY - 74,
                    child: Center(
                      child: CustomPaint(
                        size: const Size(54, 72),
                        painter: _DeliveryPinPainter(),
                      ),
                    ),
                  ),

                  // Hint Pill: "Move the map to adjust the pin"
                  Positioned(
                    left: 0,
                    right: 0,
                    top: mapHeight - 38,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xB81E0A0E),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: op(Colors.white, 0.16)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(90),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'Move the map to adjust the pin',
                          style: GoogleFonts.manrope(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: C.cream,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Floating Locate Button (Bottom-Right of Map)
                  Positioned(
                    right: 16,
                    top: mapHeight - 48,
                    child: BouncyPress(
                      onTap: _isLocating ? null : _detectCurrentLocation,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: emberGradient,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(100),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isLocating
                              ? const SizedBox(
                                  width: 17,
                                  height: 17,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(
                                  Icons.my_location_rounded,
                                  color: Colors.white,
                                  size: 19,
                                ),
                        ),
                      ),
                    ),
                  ),

                  // Top Floating Glass Bar: Back button + Search Input
                  Positioned(
                    top: topPad + 6,
                    left: 16,
                    right: 16,
                    child: Row(
                      children: [
                        // Glass Back Button
                        BouncyPress(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xB81E0A0E),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: op(Colors.white, 0.16)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(80),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Glass Search Field
                        Expanded(
                          child: Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xB81E0A0E),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: op(Colors.white, 0.16)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(80),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.search_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _searchCtrl,
                                    textAlignVertical: TextAlignVertical.center,
                                    textInputAction: TextInputAction.search,
                                    onSubmitted: _onSearchSubmit,
                                    style: GoogleFonts.manrope(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: C.cream,
                                    ),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      hintText: 'Search area, street or landmark',
                                      hintStyle: GoogleFonts.manrope(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        color: op(C.cream, 0.70),
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
                ],
              ),
            ),
          ),

          // ==================== 2. CURVED BOTTOM SHEET ====================
          Positioned(
            left: 0,
            right: 0,
            top: mapHeight - 16,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF14050A),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border(
                  top: BorderSide(color: op(C.gold, 0.35), width: 1.2),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x99000000),
                    blurRadius: 36,
                    offset: Offset(0, -16),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Scrollable Form Details
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollCtrl,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Grab Handle
                          Center(
                            child: Container(
                              width: 38,
                              height: 4,
                              decoration: BoxDecoration(
                                color: op(Colors.white, 0.22),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Area & Street Header Row (Aligned vertically in center)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: op(C.ember, 0.16),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: op(C.ember, 0.40)),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.location_on_rounded,
                                    color: C.ember,
                                    size: 22,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      displayAreaName,
                                      style: GoogleFonts.unbounded(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        height: 1.15,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _streetAddress,
                                      style: GoogleFonts.manrope(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: op(Colors.white, 0.65),
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Serviceability Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D2518),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(color: op(const Color(0xFF00E676), 0.35)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_rounded,
                                  size: 15,
                                  color: Color(0xFF00E676),
                                ),
                                const SizedBox(width: 7),
                                Flexible(
                                  child: Text(
                                    'We deliver here · about 25–35 min, cold-chain',
                                    style: GoogleFonts.manrope(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF00E676),
                                      height: 1.15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Form Field: Flat / House No. / Floor
                          Text(
                            'FLAT / HOUSE NO. / FLOOR',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                              color: C.gold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F0910),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: _houseError ? C.crimson : op(C.gold, 0.25),
                                width: _houseError ? 1.5 : 1,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.home_outlined,
                                  size: 19,
                                  color: _houseError ? C.crimson : op(C.gold, 0.70),
                                ),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: TextField(
                                    controller: _houseCtrl,
                                    cursorColor: C.ember,
                                    textAlignVertical: TextAlignVertical.center,
                                    onChanged: (_) {
                                      if (_houseError) setState(() => _houseError = false);
                                    },
                                    style: GoogleFonts.manrope(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                      hintText: 'e.g. Flat 302, 3rd floor',
                                      hintStyle: GoogleFonts.manrope(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                        color: op(Colors.white, 0.35),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_houseError) ...[
                            const SizedBox(height: 5),
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                'Add your flat or house number so the rider can find you.',
                                style: GoogleFonts.manrope(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: C.crimson,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),

                          // Form Field: Landmark (Optional)
                          Text(
                            'LANDMARK (OPTIONAL)',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                              color: C.gold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F0910),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: op(C.gold, 0.25)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.near_me_outlined,
                                  size: 19,
                                  color: op(C.gold, 0.70),
                                ),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: TextField(
                                    controller: _landmarkCtrl,
                                    cursorColor: C.ember,
                                    textAlignVertical: TextAlignVertical.center,
                                    style: GoogleFonts.manrope(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                      hintText: 'e.g. Near the bus stop',
                                      hintStyle: GoogleFonts.manrope(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                        color: op(Colors.white, 0.35),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // SAVE AS (Single Select Chips)
                          Text(
                            'SAVE AS',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                              color: C.gold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: _tags.map((tag) {
                              final isSelected = _selectedTag == tag;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: BouncyPress(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _selectedTag = tag);
                                  },
                                  child: Container(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                                    decoration: BoxDecoration(
                                      gradient: isSelected ? emberGradient : null,
                                      color: isSelected ? null : const Color(0xFF1F0910),
                                      borderRadius: BorderRadius.circular(99),
                                      border: isSelected
                                          ? null
                                          : Border.all(color: op(C.gold, 0.25)),
                                    ),
                                    child: Text(
                                      tag,
                                      style: GoogleFonts.manrope(
                                        fontSize: 13,
                                        fontWeight:
                                            isSelected ? FontWeight.w800 : FontWeight.w600,
                                        color: isSelected ? Colors.white : op(Colors.white, 0.85),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),

                          // NOTE FOR RIDER (Multi-Select Chips)
                          Text(
                            'NOTE FOR RIDER',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                              color: C.gold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _riderNotes.map((note) {
                              final isSelected = _selectedRiderNotes.contains(note);
                              return BouncyPress(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    if (isSelected) {
                                      _selectedRiderNotes.remove(note);
                                    } else {
                                      _selectedRiderNotes.add(note);
                                    }
                                  });
                                },
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                                  decoration: BoxDecoration(
                                    gradient: isSelected ? emberGradient : null,
                                    color: isSelected ? null : const Color(0xFF1F0910),
                                    borderRadius: BorderRadius.circular(99),
                                    border: isSelected
                                        ? null
                                        : Border.all(color: op(C.gold, 0.25)),
                                  ),
                                  child: Text(
                                    note,
                                    style: GoogleFonts.manrope(
                                      fontSize: 13,
                                      fontWeight:
                                          isSelected ? FontWeight.w800 : FontWeight.w600,
                                      color: isSelected ? Colors.white : op(Colors.white, 0.85),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // ==================== 3. FIXED BOTTOM CONFIRM CTA ====================
                  Container(
                    padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottomPad),
                    decoration: BoxDecoration(
                      color: const Color(0xFF14050A),
                      border: Border(top: BorderSide(color: op(C.gold, 0.20), width: 1)),
                    ),
                    child: BouncyPress(
                      onTap: _confirmAddress,
                      child: Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: emberGradient,
                          borderRadius: BorderRadius.circular(27),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x40FF4D2E),
                              blurRadius: 18,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Confirm address',
                              style: GoogleFonts.manrope(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.2,
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
          ),
        ],
      ),
    );
  }
}

/// Canvas rendering live OpenStreetMap tiles (with dark styling) and background cartography.
class _MapTileCanvas extends StatelessWidget {
  final double panX;
  final double panY;
  final double lat;
  final double lon;
  final double zoom;
  final double pinY;

  const _MapTileCanvas({
    required this.panX,
    required this.panY,
    required this.lat,
    required this.lon,
    required this.pinY,
    this.zoom = 15.0,
  });

  static double lonToX(double lon, double zoom) {
    return (lon + 180.0) / 360.0 * math.pow(2.0, zoom) * 256.0;
  }

  static double latToY(double lat, double zoom) {
    final sinLat = math.sin(lat * math.pi / 180.0).clamp(-0.9999, 0.9999);
    return (0.5 - math.log((1.0 + sinLat) / (1.0 - sinLat)) / (4.0 * math.pi)) *
        math.pow(2.0, zoom) *
        256.0;
  }

  static double xToLon(double x, double zoom) {
    return x / (256.0 * math.pow(2.0, zoom)) * 360.0 - 180.0;
  }

  static double yToLat(double y, double zoom) {
    final n = math.pi - (2.0 * math.pi * y) / (256.0 * math.pow(2.0, zoom));
    return 180.0 / math.pi * math.atan(0.5 * (math.exp(n) - math.exp(-n)));
  }

  static String getTileUrl(int z, int x, int y) {
    final maxTiles = 1 << z;
    final wrappedX = (x % maxTiles + maxTiles) % maxTiles;
    if (y < 0 || y >= maxTiles) return '';
    final sub = ['a', 'b', 'c'][(wrappedX + y).abs() % 3];
    return 'https://$sub.tile.openstreetmap.org/$z/$wrappedX/$y.png';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        if (w <= 0 || h <= 0) return const SizedBox.shrink();

        final int zoomInt = zoom.round();
        final centerX = lonToX(lon, zoomInt.toDouble()) - panX;
        final centerY = latToY(lat, zoomInt.toDouble()) - panY;

        // Pin tip is at (w / 2, pinY)
        final screenLeft = centerX - (w / 2.0);
        final screenTop = centerY - pinY;

        final int minTileX = (screenLeft / 256.0).floor();
        final int maxTileX = ((screenLeft + w) / 256.0).floor();
        final int minTileY = (screenTop / 256.0).floor();
        final int maxTileY = ((screenTop + h) / 256.0).floor();

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // 1. Stylized background grid matching dark theme as immediate backdrop
            CustomPaint(
              size: Size(w, h),
              painter: _MapTileGridPainter(panX: panX, panY: panY),
            ),

            // 2. Real Live OpenStreetMap Tiles Grid (with dark styling)
            for (int tx = minTileX; tx <= maxTileX; tx++)
              for (int ty = minTileY; ty <= maxTileY; ty++)
                Positioned(
                  left: tx * 256.0 - screenLeft,
                  top: ty * 256.0 - screenTop,
                  width: 256.0,
                  height: 256.0,
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.matrix([
                      -0.85, 0, 0, 0, 255,
                      0, -0.85, 0, 0, 245,
                      0, 0, -0.80, 0, 240,
                      0, 0, 0, 0.90, 0,
                    ]),
                    child: Image.network(
                      getTileUrl(zoomInt, tx, ty),
                      headers: const {
                        'User-Agent': 'FreshMeatDeliveryApp/1.0 (Halal Meat Delivery)',
                      },
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _MapTileGridPainter extends CustomPainter {
  final double panX;
  final double panY;

  _MapTileGridPainter({required this.panX, required this.panY});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Background dark base
    final bgPaint = Paint()..color = const Color(0xFF1B0B10);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Parks / green zones with opacity
    final parkPaint = Paint()
      ..color = op(const Color(0xFF1C2A1E), 0.70)
      ..style = PaintingStyle.fill;

    final parkRect = Rect.fromLTWH(
      214 + (panX * 0.4),
      120 + (panY * 0.4),
      130,
      80,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(parkRect, const Radius.circular(10)), parkPaint);

    // 3. Road lines matching SVG preview geometry
    final roadPaintLight = Paint()
      ..color = op(Colors.white, 0.07)
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke;

    final roadPaintMain = Paint()
      ..color = op(Colors.white, 0.10)
      ..strokeWidth = 22
      ..style = PaintingStyle.stroke;

    final offsetX = panX * 0.5;
    final offsetY = panY * 0.5;

    // Horizontal roads
    canvas.drawLine(
      Offset(0, 110 + offsetY),
      Offset(size.width, 110 + offsetY),
      roadPaintLight,
    );
    canvas.drawLine(
      Offset(0, 230 + offsetY),
      Offset(size.width, 230 + offsetY),
      roadPaintLight,
    );
    canvas.drawLine(
      Offset(0, 170 + offsetY),
      Offset(size.width, 170 + offsetY),
      roadPaintMain,
    );

    // Vertical roads
    canvas.drawLine(
      Offset(90 + offsetX, 0),
      Offset(90 + offsetX, size.height),
      roadPaintLight,
    );
    canvas.drawLine(
      Offset(215 + offsetX, 0),
      Offset(215 + offsetX, size.height),
      roadPaintLight,
    );
    canvas.drawLine(
      Offset(320 + offsetX, 0),
      Offset(320 + offsetX, size.height),
      roadPaintLight,
    );

    // Diagonal arterial road
    canvas.drawLine(
      Offset(0, 300 + offsetY),
      Offset(size.width, 60 + offsetY),
      roadPaintLight,
    );
  }

  @override
  bool shouldRepaint(_MapTileGridPainter oldDelegate) =>
      oldDelegate.panX != panX || oldDelegate.panY != panY;
}

/// Exact vector painter for the gradient drop-pin from delivery_address_preview.html.
class _DeliveryPinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    canvas.save();
    canvas.translate(cx, cy);

    // Drop shadow under pin
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(128)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(const Offset(0, 24), 14, shadowPaint);

    // Gradient Pin Body: M0 -36C-20 -36 -30 -22 -30 -8C-30 14 0 38 0 38C0 38 30 14 30 -8C30 -22 20 -36 0 -36Z
    final pinPath = Path()
      ..moveTo(0, -36)
      ..cubicTo(-20, -36, -30, -22, -30, -8)
      ..cubicTo(-30, 14, 0, 38, 0, 38)
      ..cubicTo(0, 38, 30, 14, 30, -8)
      ..cubicTo(30, -22, 20, -36, 0, -36)
      ..close();

    final pinPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF8A5C), Color(0xFFFF3D2E)],
      ).createShader(const Rect.fromLTWH(-30, -42, 60, 80));

    canvas.drawPath(pinPath, pinPaint);

    // Inner Cream Circle: circle cx="0" cy="-8" r="11" fill="#fff3e8"
    final innerCirclePaint = Paint()
      ..color = const Color(0xFFFFF3E8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(0, -8), 11, innerCirclePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_DeliveryPinPainter oldDelegate) => false;
}
