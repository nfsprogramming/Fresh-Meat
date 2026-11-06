import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fresh_meat_market/data.dart';
import 'package:fresh_meat_market/services/price_sync_service.dart';
import 'package:fresh_meat_market/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Telegram / Google Sheets Daily Pricing Automation Tests', () {
    test('Product.copyWith modifies price without mutating original', () {
      final original = products.first; // Mutton Curry Cut (820)
      final modified = original.copyWith(pricePerKg: 890);

      expect(original.pricePerKg, 820.0);
      expect(modified.pricePerKg, 890.0);
      expect(modified.id, original.id);
      expect(modified.name, original.name);
    });

    test('PriceSyncService parses and caches live rates properly', () async {

      await PriceSyncService.instance.saveCachedPrices({
        'mutton': 860.0,
        'm1': 899.0,
      });

      final cached = await PriceSyncService.instance.getCachedPrices();
      expect(cached['mutton'], 860.0);
      expect(cached['m1'], 899.0);
    });

    test('AppState applies specific cut overrides and category overrides', () async {
      final state = AppState();
      addTearDown(state.dispose);

      final p = products.first; // id: 'm1', type: MeatType.mutton, base: 820

      // Initially base price
      expect(state.getPriceForProduct(p), 820.0);

      // Category override
      state.priceOverrides = {'mutton': 850.0};
      expect(state.getPriceForProduct(p), 850.0);

      // Specific cut override takes higher priority
      state.priceOverrides = {'mutton': 850.0, 'm1': 899.0};
      expect(state.getPriceForProduct(p), 899.0);

      final liveProduct = state.getLiveProduct(p);
      expect(liveProduct.pricePerKg, 899.0);
    });

    test('Cart additions use live rates', () {
      final state = AppState();
      addTearDown(state.dispose);

      final p = products.first;
      state.priceOverrides = {'m1': 900.0};

      state.addToCart(p, 1000);
      expect(state.cart.length, 1);
      expect(state.cart.first.product.pricePerKg, 900.0);
      expect(state.cartTotal, 900.0);
    });
  });
}
