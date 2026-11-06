import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fresh_meat_market/state/app_state.dart';
import 'package:fresh_meat_market/widgets/delivery_address_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestApp(AppState state) {
    return ChangeNotifierProvider.value(
      value: state,
      child: const MaterialApp(
        home: DeliveryAddressScreen(),
      ),
    );
  }

  testWidgets('DeliveryAddressScreen renders map, pin, sheet, form fields and validates',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final state = AppState();

    await tester.pumpWidget(buildTestApp(state));
    await tester.pump(const Duration(milliseconds: 300));

    // 1. Verify Top Map & Overlays
    expect(find.text('Move the map to adjust the pin'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);

    // 2. Verify Sheet Header & Serviceability
    expect(find.text('Royapuram'), findsOneWidget);
    expect(find.textContaining('We deliver here · about 25–35 min, cold-chain'), findsOneWidget);

    // 3. Verify Form Field Labels
    expect(find.text('FLAT / HOUSE NO. / FLOOR'), findsOneWidget);
    expect(find.text('LANDMARK (OPTIONAL)'), findsOneWidget);
    expect(find.text('SAVE AS'), findsOneWidget);
    expect(find.text('NOTE FOR RIDER'), findsOneWidget);

    // 4. Verify Chips
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
    expect(find.text('Call on arrival'), findsOneWidget);
    expect(find.text('Leave at door'), findsOneWidget);
    expect(find.text("Don't ring bell"), findsOneWidget);

    // 5. Test validation: tap confirm without house number
    final confirmBtn = find.text('Confirm address');
    expect(confirmBtn, findsOneWidget);
    await tester.tap(confirmBtn);
    await tester.pump(const Duration(milliseconds: 350));

    // Error banner should appear
    expect(
      find.text('Add your flat or house number so the rider can find you.'),
      findsOneWidget,
    );

    // 6. Enter valid flat and landmark
    final houseField = find.widgetWithText(TextField, 'e.g. Flat 302, 3rd floor');
    expect(houseField, findsOneWidget);
    await tester.enterText(houseField, 'Flat 401, Sapphire Block');
    await tester.pump();

    // Error banner disappears when typing
    expect(
      find.text('Add your flat or house number so the rider can find you.'),
      findsNothing,
    );

    final landmarkField = find.widgetWithText(TextField, 'e.g. Near the bus stop');
    expect(landmarkField, findsOneWidget);
    await tester.enterText(landmarkField, 'Opposite Metro Station');
    await tester.pump();

    // Select "Work" tag
    final workChip = find.text('Work');
    await tester.ensureVisible(workChip);
    await tester.tap(workChip);
    await tester.pump();

    // Toggle rider note "Leave at door"
    final noteChip = find.text('Leave at door');
    await tester.ensureVisible(noteChip);
    await tester.tap(noteChip);
    await tester.pump();

    // 7. Confirm address and verify AppState update
    await tester.tap(confirmBtn);
    await tester.pump(const Duration(milliseconds: 350));

    expect(state.selectedAddress, contains('Flat 401, Sapphire Block'));
    expect(state.selectedAddress, contains('Opposite Metro Station'));
    expect(state.selectedAddress, contains('Royapuram'));

    state.dispose();
  });
}
