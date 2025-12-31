// This is a basic Flutter widget test for the POS app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/main.dart';

void main() {
  testWidgets('App widget can be instantiated', (WidgetTester tester) async {
    // Verify that MyApp widget can be created without errors
    final app = MyApp();
    expect(app, isA<Widget>());
  });
}
