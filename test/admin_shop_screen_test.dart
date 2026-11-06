import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fresh_meat_market/models.dart';
import 'package:fresh_meat_market/screens/admin_shop_screen.dart';
import 'package:fresh_meat_market/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'fresh_meat_admin_role_admin@freshmeat.com': true,
    });
  });

  Widget buildAdminScreen(AppState state) {
    return ChangeNotifierProvider.value(
      value: state,
      child: const MaterialApp(
        home: AdminShopScreen(),
      ),
    );
  }

  testWidgets('AdminShopScreen renders shop details, allows editing and updates AppState',
      (tester) async {
    final state = AppState();
    state.currentUser = const UserProfile(
      id: 'admin_test_uid',
      name: 'Admin Test',
      email: 'admin@freshmeat.com',
      role: 'admin',
    );

    await tester.pumpWidget(buildAdminScreen(state));
    await tester.pumpAndSettle();

    // 1. Verify header and titles
    expect(find.text('Shop Administration'), findsOneWidget);
    expect(find.text('ADMIN'), findsOneWidget);
    expect(find.text('LIVE STOREFRONT PREVIEW'), findsOneWidget);

    // 2. Initial values are loaded
    expect(find.text('Al-Noor Halal Cuts & Central Butchery'), findsWidgets);
    expect(find.text('+91 98450 12345'), findsWidgets);

    // 3. Edit Shop Name
    final nameField = find.widgetWithText(TextField, 'Shop Name');
    expect(nameField, findsOneWidget);

    await tester.enterText(nameField, 'Super Halal Meat House');
    await tester.pump();

    // 4. Edit Phone Number
    final phoneField = find.widgetWithText(TextField, 'Phone Number');
    expect(phoneField, findsOneWidget);

    await tester.enterText(phoneField, '+91 99000 11223');
    await tester.pump();

    // 5. Tap SAVE button in top bar
    final saveBtn = find.text('SAVE').first;
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();

    // 6. Verify state was updated
    expect(state.shopProfile.name, 'Super Halal Meat House');
    expect(state.shopProfile.phone, '+91 99000 11223');

    state.dispose();
  });
}
