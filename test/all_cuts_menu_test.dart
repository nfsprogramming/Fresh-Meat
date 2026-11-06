import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fresh_meat_market/models.dart';
import 'package:fresh_meat_market/state/app_state.dart';
import 'package:fresh_meat_market/widgets/all_cuts_menu.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildMenuWidget({
    required ValueChanged<Product> onAddToCart,
    required ValueChanged<Product> onProductTap,
  }) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AllCutsMenu(
              keyForProduct: (id) => GlobalKey(),
              onProductTap: onProductTap,
              onAddToCart: onAddToCart,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('AllCutsMenu displays title, category chips, and all 18 cuts', (tester) async {
    Product? addedProduct;

    await tester.pumpWidget(buildMenuWidget(
      onAddToCart: (p) => addedProduct = p,
      onProductTap: (_) {},
    ));
    await tester.pumpAndSettle();

    // 1. Header exists
    expect(find.text('All Cuts Menu'), findsOneWidget);
    expect(find.text('18 Cuts'), findsOneWidget);

    // 2. Category chips exist
    expect(find.text('All (18)'), findsOneWidget);
    expect(find.text('Mutton (6)'), findsOneWidget);
    expect(find.text('Chicken (6)'), findsOneWidget);
    expect(find.text('Beef (6)'), findsOneWidget);

    // 3. Search field exists
    expect(find.byType(TextField), findsOneWidget);

    // 4. Tap "Chicken (6)" chip to filter
    await tester.tap(find.text('Chicken (6)'));
    await tester.pumpAndSettle();

    expect(find.text('6 Cuts'), findsOneWidget);
    expect(find.textContaining('Chicken Curry Cut'), findsOneWidget);

    // 5. Test search filter
    await tester.enterText(find.byType(TextField), 'Keema');
    await tester.pumpAndSettle();

    expect(find.textContaining('Keema'), findsWidgets);

    // 6. Test "+ ADD" button
    final addBtn = find.text('ADD').first;
    await tester.tap(addBtn);
    await tester.pump();

    expect(addedProduct, isNotNull);
  });
}
