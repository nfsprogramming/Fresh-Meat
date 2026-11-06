import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_meat_market/widgets/liquid_motion.dart';

void main() {
  testWidgets('LiquidSlidingDock renders and switches tabs smoothly', (tester) async {
    int selectedTab = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LiquidSlidingDock(
            currentIndex: selectedTab,
            activeOrdersCount: 2,
            onTabSelected: (i) => selectedTab = i,
          ),
        ),
      ),
    );

    expect(find.text('Cuts'), findsOneWidget);
    expect(find.byIcon(Icons.storefront_rounded), findsOneWidget);
    expect(find.byIcon(Icons.receipt_long_rounded), findsOneWidget);

    // Tap the 'Orders' tab (index 2)
    await tester.tap(find.byIcon(Icons.receipt_long_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(selectedTab, 2);
  });

  testWidgets('LiquidCategoryBar renders all 4 categories bounded to screen and handles tap and dim', (tester) async {
    int selectedIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: LiquidCategoryBar(
              selectedIndex: selectedIndex,
              items: const [
                (label: 'Mutton', icon: Icons.lunch_dining_rounded, badge: null, dim: false),
                (label: 'Chicken', icon: Icons.restaurant_rounded, badge: null, dim: false),
                (label: 'Beef', icon: Icons.outdoor_grill_rounded, badge: null, dim: false),
                (label: 'Fish', icon: Icons.set_meal_rounded, badge: 'Soon', dim: true),
              ],
              onSelected: (i) => selectedIndex = i,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Mutton'), findsOneWidget);
    expect(find.text('Chicken'), findsOneWidget);
    expect(find.text('Beef'), findsOneWidget);
    expect(find.text('Fish'), findsOneWidget);
    expect(find.text('Soon'), findsOneWidget);

    // Tapping Beef (active)
    await tester.tap(find.text('Beef'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(selectedIndex, 2);

    // Tapping Fish triggers onSelected for index 3 (opens Fish preview)
    await tester.tap(find.text('Fish'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(selectedIndex, 3);
  });

  testWidgets('LiquidSegmentedControl animates sliding pill to selected index', (tester) async {
    int selected = 1;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LiquidSegmentedControl(
            selectedIndex: selected,
            onSelected: (i) => selected = i,
            children: const [
              Text('500g'),
              Text('1000g'),
              Text('2000g'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('500g'), findsOneWidget);
    expect(find.text('1000g'), findsOneWidget);
    expect(find.text('2000g'), findsOneWidget);

    // Tap 2000g (index 2)
    await tester.tap(find.text('2000g'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150)); // Mid-animation stretch
    await tester.pumpAndSettle();

    expect(selected, 2);
  });
}
