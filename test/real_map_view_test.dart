import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fresh_meat_market/models.dart';
import 'package:fresh_meat_market/widgets/real_map_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildMapTestApp({Order? order, bool isCancelled = false}) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 500,
          child: RealMapView(
            order: order,
            anim: const AlwaysStoppedAnimation<double>(0.45),
            isCancelled: isCancelled,
          ),
        ),
      ),
    );
  }

  testWidgets('RealMapView renders route, pins, courier and map controls cleanly',
      (tester) async {
    final now = DateTime.now();
    final dummyOrder = Order(
      id: 'ORD-9999',
      items: const [
        CartItem(
          product: Product(
            id: 'c1',
            name: 'Chicken Curry Cut',
            type: MeatType.chicken,
            description: 'Fresh curry cut',
            pricePerKg: 280,
            butcher: 'Al-Noor Halal Cuts',
          ),
          grams: 1000,
          qty: 1,
        ),
      ],
      total: 280,
      status: OrderStatus.onTheWay,
      idempotencyKey: 'test_key_123',
      createdAt: now,
      updatedAt: now,
      deliveryAddress: '123 Richmond Circle, Bengaluru',
      slot: '09:00 AM - 11:00 AM',
      driverName: 'Rashid Khan',
      driverPhone: '+91 98450 11223',
    );

    await tester.pumpWidget(buildMapTestApp(order: dummyOrder));
    await tester.pump();

    // 1. Verify Markers
    expect(find.text('Al-Noor Halal Cuts'), findsOneWidget);
    expect(find.text('Delivery Location'), findsOneWidget);
    expect(find.byIcon(Icons.two_wheeler_rounded), findsOneWidget);

    // 2. Verify Map Controls
    expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);

    // 3. Test pan gesture
    await tester.drag(find.byType(GestureDetector).first, const Offset(-50, -30));
    await tester.pump();

    // 4. Test double-tap zoom
    await tester.tap(find.byType(GestureDetector).first);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byType(GestureDetector).first);
    await tester.pump(const Duration(milliseconds: 300));

    // 5. Test re-center action
    await tester.tap(find.byIcon(Icons.my_location_rounded));
    await tester.pumpAndSettle();
  });

  testWidgets('RealMapView renders fallback state cleanly when cancelled',
      (tester) async {
    await tester.pumpWidget(buildMapTestApp(order: null, isCancelled: true));
    await tester.pump();

    expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);
    expect(find.text('Master Butcher'), findsOneWidget);
    expect(find.text('Delivery Location'), findsOneWidget);
  });
}
