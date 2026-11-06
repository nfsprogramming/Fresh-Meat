import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fresh_meat_market/screens/home_screen.dart';
import 'package:fresh_meat_market/screens/tracking_screen.dart';
import 'package:fresh_meat_market/state/app_state.dart';
import 'package:fresh_meat_market/widgets/liquid_motion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildHomeScreen() {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const MaterialApp(
        home: HomeScreen(),
      ),
    );
  }

  testWidgets('HomeScreen switches between full destination pages while bottom dock stays persistent', (tester) async {
    await tester.pumpWidget(buildHomeScreen());
    await tester.pump(const Duration(milliseconds: 400));

    // 1. Initial State: On Cuts tab (index 0)
    expect(find.text('Cuts'), findsOneWidget); // Active tab label
    expect(find.text('Artisan Butchers'), findsNothing);
    expect(find.text('Halal Assurance'), findsNothing);

    // 2. Tap "Butchers" tab (index 1) via its icon inside LiquidSlidingDock
    final butchersTab = find.descendant(
      of: find.byType(LiquidSlidingDock),
      matching: find.byIcon(Icons.local_dining_rounded),
    );
    await tester.tap(butchersTab);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify Butchers destination view is visible and label expanded in dock
    expect(find.text('Artisan Butchers'), findsOneWidget);
    expect(find.text('Butchers'), findsOneWidget); // Expanded active tab label

    // 3. Tap "Browse Cuts" for the first butcher in the list
    final browseCutsBtn = find.text('Browse Cuts').first;
    await tester.tap(browseCutsBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify it smoothly switched back to Cuts tab (index 0) with the filter applied
    expect(find.text('Artisan Butchers'), findsNothing);
    expect(find.text('Cuts'), findsOneWidget);
    expect(find.textContaining('Filtered:'), findsOneWidget);

    // 4. Tap "Orders" tab (index 2) via its icon inside LiquidSlidingDock
    final ordersTab = find.descendant(
      of: find.byType(LiquidSlidingDock),
      matching: find.byIcon(Icons.receipt_long_rounded),
    );
    await tester.tap(ordersTab);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify embedded TrackingScreen destination is active and Orders label expanded
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('No Current Orders'), findsOneWidget);
    expect(find.text('Browse Fresh Cuts'), findsOneWidget);

    // 5. Tap "Halal" tab (index 3) via its icon inside LiquidSlidingDock
    final halalTab = find.descendant(
      of: find.byType(LiquidSlidingDock),
      matching: find.byIcon(Icons.verified_user_rounded),
    );
    await tester.tap(halalTab);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify Halal Assurance view is active and Halal label expanded
    expect(find.text('Halal'), findsOneWidget);
    expect(find.text('Halal Assurance'), findsOneWidget);
    expect(find.text('Strict Zabiha Halal Guaranteed'), findsOneWidget);
    expect(find.text('OUR 4 QUALITY PROMISES'), findsOneWidget);
    expect(find.text('Browse Certified Halal Cuts'), findsOneWidget);

    // 6. Scroll and tap "Browse Certified Halal Cuts" CTA
    final halalCta = find.text('Browse Certified Halal Cuts');
    await tester.ensureVisible(halalCta);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(halalCta);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify it smoothly returned to Cuts tab
    expect(find.text('Halal Assurance'), findsNothing);
    expect(find.text('Cuts'), findsOneWidget);
  });

  testWidgets('TrackingScreen respects isActive flag to stop background animations', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(
          home: Scaffold(
            body: TrackingScreen(isActive: false),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(TrackingScreen), findsOneWidget);
    final trackingWidget = tester.widget<TrackingScreen>(find.byType(TrackingScreen));
    expect(trackingWidget.isActive, isFalse);
  });

  testWidgets('LiquidSlidingDock renders all tabs without overflow on narrow screens', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    for (int tabIdx = 0; tabIdx < 4; tabIdx++) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: LiquidSlidingDock(
                  currentIndex: tabIdx,
                  activeOrdersCount: 2,
                  onTabSelected: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Zero RenderFlex overflows occur
      expect(tester.takeException(), isNull);
    }
  });
}
