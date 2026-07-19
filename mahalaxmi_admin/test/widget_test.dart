import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahalaxmi_admin/app/app.dart';

void main() {
  testWidgets('Admin app renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MahalaxmiAdminApp()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
