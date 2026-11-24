import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/widgets/dropdowns/new_addresses_dropdown.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';

void main() {
  const String firstAddress = 'address-1';
  const String secondAddress = 'address-2';

  setUp(() {
    kAddressLabelMap = <String, String>{
      firstAddress: 'Address 1',
      secondAddress: 'Address 2',
    };
  });

  testWidgets('restores the selected label after focus is lost', (
    WidgetTester tester,
  ) async {
    final ValueNotifier<String> selectedAddress = ValueNotifier<String>(
      firstAddress,
    );
    addTearDown(selectedAddress.dispose);

    await tester.pumpWidget(
      _TestApp(selectedAddress: selectedAddress),
    );
    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'invalid filter');

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    expect(_fieldText(tester), 'Address 1');
    expect(selectedAddress.value, firstAddress);
  });

  testWidgets('restores the label of the latest menu selection', (
    WidgetTester tester,
  ) async {
    final ValueNotifier<String> selectedAddress = ValueNotifier<String>(
      firstAddress,
    );
    addTearDown(selectedAddress.dispose);

    await tester.pumpWidget(
      _TestApp(selectedAddress: selectedAddress),
    );
    await tester.tap(find.byType(DropdownMenu<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Address 2').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'another filter');

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    expect(selectedAddress.value, secondAddress);
    expect(_fieldText(tester), 'Address 2');
  });

  testWidgets('reacts to an external selected-address change', (
    WidgetTester tester,
  ) async {
    final ValueNotifier<String> selectedAddress = ValueNotifier<String>(
      firstAddress,
    );
    addTearDown(selectedAddress.dispose);

    await tester.pumpWidget(
      _TestApp(selectedAddress: selectedAddress),
    );

    selectedAddress.value = secondAddress;
    await tester.pump();
    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'temporary filter');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    expect(_fieldText(tester), 'Address 2');
  });
}

String _fieldText(WidgetTester tester) {
  final EditableText field = tester.widget<EditableText>(
    find.byType(EditableText),
  );
  return field.controller.text;
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.selectedAddress});

  final ValueNotifier<String> selectedAddress;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 300,
            child: NewAddressesDropdown(
              addresses: const <String>['address-1', 'address-2'],
              selectedAddress: selectedAddress,
            ),
          ),
        ),
      ),
    );
  }
}
