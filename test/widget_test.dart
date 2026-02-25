import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giffapp_1/main.dart';
void main() {
  testWidgets('App builds and shows search field', (WidgetTester tester) async {
    await tester.pumpWidget(const GifSearchApp());
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
  });
}
