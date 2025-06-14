import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_life/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      const DigitalHealthTrackerApp(),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
