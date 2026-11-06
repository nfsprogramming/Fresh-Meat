import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models.dart';
import '../services/admin_role_service.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/price_sync_service.dart';

class PlaceResult {
  final Order order;
  final bool duplicate;
  const PlaceResult(this.order, this.duplicate);
}

/// App-wide state: bag + orders with on-device persistence.
class AppState extends ChangeNotifier {
  static const _uuid = Uuid();
  static const _prefCartKey = 'fresh_meat_cart_v1';
  static const _prefOrdersKey = 'fresh_meat_orders_v1';
  static const _prefAddressKey = 'fresh_meat_address_v1';
  static const _prefPaymentKey = 'fresh_meat_payment_v1';
  static const _prefUserKey = 'fresh_meat_user_v1';
  static const _prefCustomerNameKey = 'fresh_meat_customer_name_v1';
  static const _prefCustomerPhoneKey = 'fresh_meat_customer_phone_v1';
  static const _prefShopKey = 'fresh_meat_shop_profile_v1';

  final List<CartItem> cart = [];
  final Map<String, Order> orders = {};
  final Map<String, String> _orderByKey = {};
  final Map<String, ({String orderId, DateTime at})> _recent = {};

  UserProfile? currentUser;
  bool get isLoggedIn => currentUser != null;
  bool get isAdmin => currentUser != null && currentUser!.isAdmin;
  bool isCheckingAdminRole = false;

  ShopProfile shopProfile = ShopProfile.defaultShop;

  String _checkoutKey = _uuid.v4();
  String slot = getDynamicSlots().first;
  String selectedAddress = 'Tap to add delivery address';
  DeliveryLocation? currentDeliveryLocation;
  bool isDetectingLocation = false;

  String get shortAddressDisplay {
    if (selectedAddress.isEmpty || selectedAddress == 'Tap to add delivery address') {
      return 'Tap to add delivery address';
    }
    if (currentDeliveryLocation != null && currentDeliveryLocation!.shortTitle.isNotEmpty) {
      return currentDeliveryLocation!.shortTitle;
    }
    final parts = selectedAddress.split(',');
    if (parts.length > 1) {
      return '${parts[0].trim()}, ${parts[1].trim()}';
    }
    return selectedAddress;
  }

  String customerName = 'Guest Gourmet';
  String customerPhone = '+91 98765 00000';
  String paymentMethod = 'Cash on delivery';
  String? filterButcher;
  String? priceUpdateNotice;
  int _nextNo = 1044;
  Timer? _ticker;
  bool _disposed = false;

  /// Gate demo 25-second fast forward logic in order state machine
  static bool enableDemoFastForward = false;

  // Live Daily Pricing from Telegram / Google Sheets
  Map<String, double> priceOverrides = {};
  bool isSyncingPrices = false;
  DateTime? lastPriceSync;

  void clearPriceNotice({bool notify = true}) {
    priceUpdateNotice = null;
    if (notify) notifyListeners();
  }

  /// Returns effective price per kg for a product
  double getPriceForProduct(Product p) {
    if (priceOverrides.containsKey(p.id.toLowerCase())) {
      return priceOverrides[p.id.toLowerCase()]!;
    }
    if (priceOverrides.containsKey(p.type.name.toLowerCase())) {
      return priceOverrides[p.type.name.toLowerCase()]!;
    }
    return p.pricePerKg;
  }

  /// Returns effective product with today's live rate applied
  Product getLiveProduct(Product p) {
    final livePrice = getPriceForProduct(p);
    if (livePrice == p.pricePerKg) return p;
    return p.copyWith(pricePerKg: livePrice);
  }

  /// Refreshes live prices from Google Sheets
  Future<void> refreshPrices() async {
    isSyncingPrices = true;
    notifyListeners();
    try {
      final fetched = await PriceSyncService.instance.fetchLivePrices();
      if (fetched.isNotEmpty) {
        priceOverrides = fetched;
        lastPriceSync = DateTime.now();

        // Update active cart items with current live rates
        var priceChangedInCart = false;
        for (var i = 0; i < cart.length; i++) {
          final item = cart[i];
          final updatedProduct = getLiveProduct(item.product);
          if (updatedProduct.pricePerKg != item.product.pricePerKg) {
            cart[i] = item.copyWith(product: updatedProduct);
            priceChangedInCart = true;
          }
        }
        if (priceChangedInCart) {
          priceUpdateNotice = 'Prices updated to live market rates.';
        }
        _saveCart();
      }
    } catch (_) {}
    isSyncingPrices = false;
    notifyListeners();
  }

  bool get hasActiveOrders => orders.values.any((o) =>
      o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled);

  void _checkTicker() {
    if (hasActiveOrders) {
      _ticker ??= Timer.periodic(const Duration(seconds: 8), (_) => _advance());
    } else {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  AppState() {
    _initPersistence();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _initPersistence() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Restore user (check Firebase Auth first, then local cache)
      final fbUser = AuthService.instance.currentFirebaseUser;
      if (fbUser != null) {
        currentUser = UserProfile(
          id: fbUser.uid,
          name: fbUser.displayName ?? 'Customer',
          email: fbUser.email ?? '',
          photoUrl: fbUser.photoURL,
        );
      } else {
        final savedUser = prefs.getString(_prefUserKey);
        if (savedUser != null && savedUser.isNotEmpty) {
          currentUser = UserProfile.fromJson(jsonDecode(savedUser) as Map<String, dynamic>);
        }
      }
      if (currentUser != null && currentUser!.email.isNotEmpty) {
        verifyAdminRole();
      }

      // Restore address & payment method
      final savedAddr = prefs.getString(_prefAddressKey);
      if (savedAddr != null && savedAddr.isNotEmpty) {
        selectedAddress = savedAddr;
      }
      final savedLoc = prefs.getString('fresh_meat_location_data_v1');
      if (savedLoc != null && savedLoc.isNotEmpty) {
        try {
          currentDeliveryLocation = DeliveryLocation.fromJson(jsonDecode(savedLoc) as Map<String, dynamic>);
        } catch (_) {}
      }
      final savedPay = prefs.getString(_prefPaymentKey);
      if (savedPay != null && savedPay.isNotEmpty) {
        paymentMethod = savedPay;
      }

      // Restore customer details
      final savedCustName = prefs.getString(_prefCustomerNameKey);
      if (savedCustName != null && savedCustName.isNotEmpty) {
        customerName = savedCustName;
      }
      final savedCustPhone = prefs.getString(_prefCustomerPhoneKey);
      if (savedCustPhone != null && savedCustPhone.isNotEmpty) {
        customerPhone = savedCustPhone;
      }

      // Restore shop profile
      final savedShop = prefs.getString(_prefShopKey);
      if (savedShop != null && savedShop.isNotEmpty) {
        try {
          shopProfile = ShopProfile.fromJson(jsonDecode(savedShop) as Map<String, dynamic>);
        } catch (_) {}
      }

      // Restore cart
      final savedCart = prefs.getString(_prefCartKey);
      if (savedCart != null) {
        final list = (jsonDecode(savedCart) as List<dynamic>)
            .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
            .toList();
        cart.clear();
        cart.addAll(list);
      }

      // Restore orders
      final savedOrders = prefs.getString(_prefOrdersKey);
      if (savedOrders != null) {
        final map = (jsonDecode(savedOrders) as List<dynamic>)
            .map((e) => Order.fromJson(e as Map<String, dynamic>));
        orders.clear();
        int maxId = 1044;
        for (final o in map) {
          orders[o.id] = o;
          final parsed = int.tryParse(o.id);
          if (parsed != null && parsed >= maxId) {
            maxId = parsed + 1;
          }
        }
        _nextNo = maxId;
      }
      if (!_disposed) {
        _advance();
        _checkTicker();
        notifyListeners();
      }

      // Load cached live prices from Telegram/Sheets and trigger background sync
      PriceSyncService.instance.getCachedPrices().then((cached) {
        if (cached.isNotEmpty && !_disposed) {
          priceOverrides = cached;
          notifyListeners();
        }
        refreshPrices();
      });
    } catch (e) {
      debugPrint('Error loading saved state: $e');
    }
  }

  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = jsonEncode(cart.map((e) => e.toJson()).toList());
      await prefs.setString(_prefCartKey, str);
    } catch (_) {}
  }

  Future<void> _saveOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = jsonEncode(orders.values.map((e) => e.toJson()).toList());
      await prefs.setString(_prefOrdersKey, str);
    } catch (_) {}
  }

  // ---- User Authentication ----
  Future<void> signInWithGoogle({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
  }) async {
    if (id != null && name != null && email != null) {
      // Direct explicit profile (e.g. testing or explicit bypass)
      currentUser = UserProfile(
        id: id,
        name: name,
        email: email,
        photoUrl: photoUrl,
      );
    } else {
      // Connect through real Firebase + Google Sign-In
      final profile = await AuthService.instance.signInWithGoogle();
      if (profile == null) return;
      currentUser = profile;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefUserKey, jsonEncode(currentUser!.toJson()));
    } catch (_) {}
    notifyListeners();
    await verifyAdminRole();
  }

  /// Checks Firebase Firestore backend (collection 'admins') to verify if the current user
  /// has been granted the 'admin' role. Only emails approved in Firebase backend can access admin features.
  Future<void> verifyAdminRole() async {
    if (currentUser == null || currentUser!.email.isEmpty) return;
    isCheckingAdminRole = true;
    notifyListeners();
    try {
      final isAdmin = await AdminRoleService.instance.checkAdminRole(
        email: currentUser!.email,
        uid: currentUser!.id,
      );
      final newRole = isAdmin ? 'admin' : 'customer';
      if (currentUser != null && currentUser!.role != newRole) {
        currentUser = currentUser!.copyWith(role: newRole);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefUserKey, jsonEncode(currentUser!.toJson()));
      }
    } catch (e) {
      debugPrint('AppState.verifyAdminRole error: $e');
    } finally {
      isCheckingAdminRole = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await AuthService.instance.signOut();
    currentUser = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefUserKey);
    } catch (_) {}
    notifyListeners();
  }

  // ---- Address & Payment ----
  void setAddress(String newAddress, {DeliveryLocation? location}) {
    selectedAddress = newAddress;
    if (location != null) {
      currentDeliveryLocation = location;
    }
    SharedPreferences.getInstance().then((p) {
      p.setString(_prefAddressKey, newAddress);
      if (currentDeliveryLocation != null) {
        p.setString('fresh_meat_location_data_v1', jsonEncode(currentDeliveryLocation!.toJson()));
      }
    });
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    paymentMethod = method;
    SharedPreferences.getInstance().then((p) => p.setString(_prefPaymentKey, method));
    notifyListeners();
  }

  void setCustomerDetails(String name, String phone) {
    customerName = name.trim();
    customerPhone = phone.trim();
    SharedPreferences.getInstance().then((p) {
      p.setString(_prefCustomerNameKey, customerName);
      p.setString(_prefCustomerPhoneKey, customerPhone);
    });
    notifyListeners();
  }

  void setButcherFilter(String? butcher) {
    filterButcher = butcher;
    notifyListeners();
  }

  // ---- bag ----
  int get cartCount => cart.fold(0, (s, i) => s + i.qty);
  double get cartTotal => cart.fold(0.0, (s, i) => s + i.lineTotal);

  void addToCart(Product p, int grams) {
    final liveProduct = getLiveProduct(p);
    final key = '${liveProduct.id}_$grams';
    final i = cart.indexWhere((e) => e.key == key);
    if (i >= 0) {
      cart[i] = cart[i].copyWith(product: liveProduct, qty: cart[i].qty + 1);
    } else {
      cart.add(CartItem(product: liveProduct, grams: grams, qty: 1));
    }
    _saveCart();
    notifyListeners();
  }

  void changeQty(String key, int delta) {
    final i = cart.indexWhere((e) => e.key == key);
    if (i < 0) return;
    final q = cart[i].qty + delta;
    if (q <= 0) {
      cart.removeAt(i);
    } else {
      cart[i] = cart[i].copyWith(qty: q);
    }
    _saveCart();
    notifyListeners();
  }

  void clearCart() {
    cart.clear();
    _saveCart();
    notifyListeners();
  }

  void setSlot(String s) {
    slot = s;
    notifyListeners();
  }

  // ---- orders ----
  List<Order> get activeOrders {
    final l = orders.values.where((o) => o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled).toList();
    l.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return l;
  }

  List<Order> get allOrders {
    final l = orders.values.toList();
    l.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return l;
  }

  String get _fingerprint =>
      '${(cart.map((e) => '${e.key}x${e.qty}').toList()..sort()).join('|')}@$slot';

  PlaceResult? placeOrder() {
    if (cart.isEmpty) return null;

    final byKey = _orderByKey[_checkoutKey];
    if (byKey != null && orders.containsKey(byKey)) return PlaceResult(orders[byKey]!, true);

    final recent = _recent[_fingerprint];
    if (recent != null && DateTime.now().difference(recent.at) < const Duration(seconds: 3)) {
      final existing = orders[recent.orderId];
      if (existing != null) {
        cart.clear();
        _saveCart();
        notifyListeners();
        return PlaceResult(existing, true);
      }
    }

    final now = DateTime.now();
    final validSlots = getDynamicSlots();
    final effectiveSlot = validSlots.contains(slot) ? slot : validSlots.first;

    final lowerAddr = selectedAddress.toLowerCase();
    double? lat = currentDeliveryLocation?.latitude;
    double? lon = currentDeliveryLocation?.longitude;
    if (lat == null || lat == 0 || lon == null || lon == 0) {
      if (lowerAddr.contains('mountain view') || lowerAddr.contains('amphitheatre') || lowerAddr.contains('california')) {
        lat = 37.4220;
        lon = -122.0841;
      } else if (lowerAddr.contains('chennai') || lowerAddr.contains('tamil nadu')) {
        lat = 13.0827;
        lon = 80.2707;
      } else {
        lat = 13.0078;
        lon = 77.6245;
      }
    }

    String driverName = 'Rashid Khan';
    String driverVehicle = 'KA 01 AB 1234';
    if (lowerAddr.contains('california') || lowerAddr.contains('mountain view') || lowerAddr.contains('ca')) {
      driverName = 'David Miller';
      driverVehicle = 'CA 8TRP210 · Electric Van';
    } else if (lowerAddr.contains('chennai') || lowerAddr.contains('tamil nadu')) {
      driverName = 'Karthik Raja';
      driverVehicle = 'TN 07 AB 4821';
    }

    final order = Order(
      id: '${_nextNo++}',
      items: List.of(cart),
      total: cartTotal,
      status: OrderStatus.placed,
      slot: effectiveSlot,
      idempotencyKey: _checkoutKey,
      paymentMethod: paymentMethod,
      deliveryAddress: selectedAddress,
      customerName: customerName.isNotEmpty ? customerName : 'Guest Gourmet',
      customerPhone: customerPhone.isNotEmpty ? customerPhone : '+91 98765 00000',
      driverName: driverName,
      driverVehicle: driverVehicle,
      deliveryLat: lat,
      deliveryLon: lon,
      createdAt: now,
      updatedAt: now,
    );
    orders[order.id] = order;
    _checkTicker();
    _orderByKey[_checkoutKey] = order.id;
    _recent[_fingerprint] = (orderId: order.id, at: now);
    cart.clear();
    _checkoutKey = _uuid.v4(); // fresh key for the next checkout
    _saveCart();
    _saveOrders();
    notifyListeners();
    return PlaceResult(order, false);
  }

  /// Manually advance order status (for demonstration/testing)
  void advanceOrderStatus(String id) {
    final o = orders[id];
    if (o == null || o.status == OrderStatus.delivered || o.status == OrderStatus.cancelled) return;
    final nextStatus = switch (o.status) {
      OrderStatus.placed => OrderStatus.accepted,
      OrderStatus.accepted => OrderStatus.cutting,
      OrderStatus.cutting => OrderStatus.onTheWay,
      OrderStatus.onTheWay => OrderStatus.delivered,
      _ => o.status,
    };
    orders[id] = o.copyWith(status: nextStatus);
    _saveOrders();
    notifyListeners();
  }

  /// Verify delivery scan via the delivery executive QR flow
  bool verifyDeliveryWithQr(String id, {String? executiveName}) {
    final o = orders[id];
    if (o == null) return false;
    final now = DateTime.now();
    orders[id] = o.copyWith(
      status: OrderStatus.delivered,
      isDeliveryVerified: true,
      verifiedAt: now,
      verificationExecutive: executiveName ?? o.driverName,
      updatedAt: now,
    );
    _saveOrders();
    _checkTicker();
    notifyListeners();
    return true;
  }

  /// Registered fleet of delivery boys / delivery partners for the butcher shop
  final List<DeliveryPartner> deliveryFleet = [
    const DeliveryPartner(
      id: 'rider_1',
      name: 'Rashid Khan',
      phone: '+91 98450 12345',
      vehicle: 'KA 01 AB 1234',
      rating: 4.9,
    ),
    const DeliveryPartner(
      id: 'rider_2',
      name: 'Karthik Raja',
      phone: '+91 98840 55667',
      vehicle: 'TN 07 AB 4821',
      rating: 4.9,
    ),
    const DeliveryPartner(
      id: 'rider_3',
      name: 'Imran Pasha',
      phone: '+91 97410 77889',
      vehicle: 'KA 03 EF 5678',
      rating: 4.8,
    ),
    const DeliveryPartner(
      id: 'rider_4',
      name: 'Syed Farooq',
      phone: '+91 99000 33445',
      vehicle: 'TN 09 XY 9912',
      rating: 5.0,
    ),
  ];

  /// Update or assign a specific delivery partner to an order
  void assignDeliveryPartner(String orderId, DeliveryPartner partner) {
    final o = orders[orderId];
    if (o == null) return;
    orders[orderId] = o.copyWith(
      driverName: partner.name,
      driverPhone: partner.phone,
      driverVehicle: partner.vehicle,
      updatedAt: DateTime.now(),
    );
    _saveOrders();
    notifyListeners();
  }

  /// Cancel order
  bool cancelOrder(String id) {
    final o = orders[id];
    if (o == null || !o.canCancel) return false;
    orders[id] = o.copyWith(status: OrderStatus.cancelled);
    _saveOrders();
    notifyListeners();
    return true;
  }

  /// Reorder all items from a past order
  void reorder(Order o) {
    for (final item in o.items) {
      addToCart(item.product, item.grams);
    }
  }

  /// Merge an order coming from the server (realtime / polling). Never duplicates.
  void upsertOrder(Order incoming) {
    orders[incoming.id] = incoming;
    _saveOrders();
    notifyListeners();
  }

  void _advance() {
    var changed = false;
    final now = DateTime.now();
    for (final o in orders.values.toList()) {
      if (o.status == OrderStatus.delivered || o.status == OrderStatus.cancelled) continue;

      final elapsed = now.difference(o.createdAt);
      OrderStatus targetStatus;
      if (elapsed > const Duration(minutes: 35)) {
        targetStatus = OrderStatus.delivered;
      } else if (elapsed > const Duration(minutes: 18)) {
        targetStatus = OrderStatus.onTheWay;
      } else if (elapsed > const Duration(minutes: 8)) {
        targetStatus = OrderStatus.cutting;
      } else if (elapsed > const Duration(minutes: 2)) {
        targetStatus = OrderStatus.accepted;
      } else {
        if (enableDemoFastForward && now.difference(o.updatedAt) > const Duration(seconds: 25)) {
          targetStatus = switch (o.status) {
            OrderStatus.placed => OrderStatus.accepted,
            OrderStatus.accepted => OrderStatus.cutting,
            OrderStatus.cutting => OrderStatus.onTheWay,
            OrderStatus.onTheWay => OrderStatus.delivered,
            _ => o.status,
          };
        } else {
          targetStatus = o.status;
        }
      }

      if (targetStatus != o.status && targetStatus.index > o.status.index) {
        orders[o.id] = o.copyWith(status: targetStatus, updatedAt: now);
        changed = true;
      }
    }
    if (changed) {
      _saveOrders();
      _checkTicker();
      notifyListeners();
    }
  }

  /// Clear all placed orders from memory and storage
  Future<void> clearAllOrders() async {
    orders.clear();
    _saveOrders();
    notifyListeners();
  }

  /// Update the storefront/butcher shop profile and persist changes
  Future<void> updateShopProfile({
    String? name,
    String? photoUrl,
    String? address,
    String? phone,
    String? email,
    String? openingHours,
    String? fssaiLicense,
    String? halalCertNumber,
    bool? isOpen,
  }) async {
    shopProfile = shopProfile.copyWith(
      name: name,
      photoUrl: photoUrl,
      address: address,
      phone: phone,
      email: email,
      openingHours: openingHours,
      fssaiLicense: fssaiLicense,
      halalCertNumber: halalCertNumber,
      isOpen: isOpen,
    );
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefShopKey, jsonEncode(shopProfile.toJson()));
    } catch (_) {}
  }

  /// Reset shop profile to artisan defaults
  Future<void> resetShopProfile() async {
    shopProfile = ShopProfile.defaultShop;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefShopKey);
    } catch (_) {}
  }
}
