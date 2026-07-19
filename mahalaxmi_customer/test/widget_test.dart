import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahalaxmi_customer/app/app.dart';

void main() {
  testWidgets('Customer app renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MahalaxmiCustomerApp()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
