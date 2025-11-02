import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_twin_fashion/main.dart';

void main() {
  group('App Tests', () {
    testWidgets('App starts without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(const DigitalTwinFashionApp());
      expect(find.text('Digital Twin Fashion App'), findsOneWidget);
    });

    testWidgets('HomeScreen displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: DigitalTwinFashionApp(),
        ),
      );
      
      expect(find.text('Digital Twin Fashion'), findsOneWidget);
      expect(find.text('Digital Twin Fashion App'), findsOneWidget);
    });
  });
}