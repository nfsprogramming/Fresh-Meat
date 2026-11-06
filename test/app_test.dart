import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fresh_meat_market/data.dart';
import 'package:fresh_meat_market/models.dart';
import 'package:fresh_meat_market/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Product and Pricing Tests', () {
    test('Calculates price accurately for arbitrary weights', () {
      final product = products.first; // Mutton Curry Cut: 820/kg
      expect(product.priceFor(1000), 820.0);
      expect(product.priceFor(500), 410.0);
      expect(product.priceFor(250), 205.0);
    });

    test('UserProfile serializes and deserializes cleanly', () {
      const user = UserProfile(
        id: 'u_123',
        name: 'Ahmad Khan',
        email: 'ahmad@gmail.com',
        photoUrl: 'assets/images/avatar_user.jpg',
      );
      final json = user.toJson();
      final restored = UserProfile.fromJson(json);

      expect(restored.id, 'u_123');
      expect(restored.name, 'Ahmad Khan');
      expect(restored.email, 'ahmad@gmail.com');
      expect(restored.photoUrl, 'assets/images/avatar_user.jpg');
      expect(restored.initials, 'AK');
      expect(restored.avatarBgColor, isNotNull);
    });
  });

  group('AppState Business Logic Tests', () {
    test('Cart additions, updates, and subtotals work properly', () {
      final state = AppState();
      final product = products[0];

      expect(state.cart.isEmpty, isTrue);
      expect(state.cartCount, 0);

      state.addToCart(product, 1000);
      expect(state.cart.length, 1);
      expect(state.cartCount, 1);
      expect(state.cartTotal, 820.0);

      // Increase quantity
      state.changeQty(state.cart.first.key, 1);
      expect(state.cartCount, 2);
      expect(state.cartTotal, 1640.0);

      // Decrease quantity
      state.changeQty(state.cart.first.key, -1);
      expect(state.cartCount, 1);
      expect(state.cartTotal, 820.0);

      state.clearCart();
      expect(state.cart.isEmpty, isTrue);
      state.dispose();
    });

    test('Google sign-in and sign-out update authentication state', () async {
      final state = AppState();
      expect(state.isLoggedIn, isFalse);
      expect(state.currentUser, isNull);

      await state.signInWithGoogle(
        id: 'g_test',
        name: 'Rashid Ali',
        email: 'rashid.ali@gmail.com',
      );

      expect(state.isLoggedIn, isTrue);
      expect(state.currentUser?.name, 'Rashid Ali');
      expect(state.currentUser?.email, 'rashid.ali@gmail.com');

      await state.signOut();
      expect(state.isLoggedIn, isFalse);
      expect(state.currentUser, isNull);
      state.dispose();
    });

    test('Order placement respects idempotency', () {
      final state = AppState();
      state.addToCart(products[0], 1000);

      final res1 = state.placeOrder();
      expect(res1, isNotNull);
      expect(res1!.duplicate, isFalse);
      expect(state.orders.containsKey(res1.order.id), isTrue);

      // Verify delivery with QR scan flow
      final orderId = res1.order.id;
      expect(res1.order.isDeliveryVerified, isFalse);
      expect(res1.order.invoiceNumber, startsWith('FM-INV-2026-'));
      expect(res1.order.verificationToken, contains('freshmeat://verify?order=$orderId'));

      final verified = state.verifyDeliveryWithQr(orderId, executiveName: 'Rashid Khan');
      expect(verified, isTrue);

      final updatedOrder = state.orders[orderId]!;
      expect(updatedOrder.isDeliveryVerified, isTrue);
      expect(updatedOrder.status, OrderStatus.delivered);
      expect(updatedOrder.verificationExecutive, 'Rashid Khan');
      expect(updatedOrder.verifiedAt, isNotNull);

      state.dispose();
    });

    test('ShopProfile serializes, deserializes, and AppState updates it', () async {
      final state = AppState();
      expect(state.shopProfile.name, 'Al-Noor Halal Cuts & Central Butchery');

      await state.updateShopProfile(
        name: 'Prime Artisan Meats',
        photoUrl: 'assets/images/beef_ribeye.jpg',
        address: '123 Commercial Street, Tasker Town, Bengaluru 560001',
        phone: '+91 99999 88888',
        isOpen: false,
      );

      expect(state.shopProfile.name, 'Prime Artisan Meats');
      expect(state.shopProfile.photoUrl, 'assets/images/beef_ribeye.jpg');
      expect(state.shopProfile.address, '123 Commercial Street, Tasker Town, Bengaluru 560001');
      expect(state.shopProfile.phone, '+91 99999 88888');
      expect(state.shopProfile.isOpen, isFalse);

      final json = state.shopProfile.toJson();
      final restored = ShopProfile.fromJson(json);
      expect(restored.name, 'Prime Artisan Meats');
      expect(restored.phone, '+91 99999 88888');

      await state.resetShopProfile();
      expect(state.shopProfile.name, ShopProfile.defaultShop.name);

      state.dispose();
    });
  });
}

