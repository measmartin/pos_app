import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/widgets/buttons/wide_action_button.dart';
import 'package:pos_app/widgets/buttons/quick_action_button.dart';

void main() {
  group('WideActionButton Tests', () {
    testWidgets('renders with label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WideActionButton(
              label: 'CHECKOUT',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('CHECKOUT'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('renders with icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WideActionButton(
              label: 'ADD',
              icon: Icons.add,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('ADD'), findsOneWidget);
    });

    testWidgets('shows loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WideActionButton(
              label: 'SUBMIT',
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('SUBMIT'), findsNothing);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WideActionButton(
              label: 'DISABLED',
              onPressed: null,
            ),
          ),
        ),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, null);
    });

    testWidgets('calls onPressed callback', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WideActionButton(
              label: 'PRESS ME',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FilledButton));
      expect(pressed, true);
    });

    testWidgets('renders as outlined button when isOutlined is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WideActionButton(
              label: 'OUTLINED',
              isOutlined: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    });
  });

  group('QuickActionButton Tests', () {
    testWidgets('renders with label and icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActionButton(
              label: 'New Sale',
              icon: Icons.point_of_sale,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('New Sale'), findsOneWidget);
      expect(find.byIcon(Icons.point_of_sale), findsOneWidget);
    });

    testWidgets('calls onPressed callback', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActionButton(
              label: 'Action',
              icon: Icons.add,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Action'));
      expect(pressed, true);
    });

    testWidgets('shows loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActionButton(
              label: 'Loading',
              icon: Icons.save,
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
