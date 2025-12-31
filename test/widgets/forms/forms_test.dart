import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/widgets/forms/custom_text_field.dart';
import 'package:pos_app/widgets/forms/currency_text_field.dart';
import 'package:pos_app/widgets/forms/barcode_field.dart';
import 'package:pos_app/widgets/forms/search_field.dart';

void main() {
  group('CustomTextField Tests', () {
    testWidgets('renders with label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              controller: TextEditingController(),
              labelText: 'Product Name',
            ),
          ),
        ),
      );

      expect(find.text('Product Name'), findsOneWidget);
    });

    testWidgets('validates input correctly', (tester) async {
      final formKey = GlobalKey<FormState>();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: CustomTextField(
                controller: TextEditingController(),
                labelText: 'Name',
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
            ),
          ),
        ),
      );

      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('calls onChanged callback', (tester) async {
      String? changedValue;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              controller: TextEditingController(),
              labelText: 'Test',
              onChanged: (value) => changedValue = value,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'Hello');
      expect(changedValue, 'Hello');
    });
  });

  group('CurrencyTextField Tests', () {
    testWidgets('renders with currency prefix', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyTextField(
              controller: TextEditingController(),
              labelText: 'Price',
            ),
          ),
        ),
      );

      expect(find.text('Price'), findsOneWidget);
      expect(find.byType(CurrencyTextField), findsOneWidget);
    });

    testWidgets('allows decimal input by default', (tester) async {
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyTextField(
              controller: controller,
              labelText: 'Price',
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), '12.99');
      expect(controller.text, '12.99');
    });
  });

  group('BarcodeField Tests', () {
    testWidgets('renders text field and scan button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BarcodeField(
              controller: TextEditingController(),
              onScan: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CustomTextField), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
    });

    testWidgets('calls onScan when button pressed', (tester) async {
      bool scanCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BarcodeField(
              controller: TextEditingController(),
              onScan: () => scanCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      expect(scanCalled, true);
    });
  });

  group('SearchField Tests', () {
    testWidgets('renders with hint text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchField(
              controller: TextEditingController(),
              hintText: 'Search products...',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Search products...'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('calls onChanged callback', (tester) async {
      String? searchValue;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchField(
              controller: TextEditingController(),
              onChanged: (value) => searchValue = value,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'test query');
      expect(searchValue, 'test query');
    });
  });
}
