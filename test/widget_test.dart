import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// الاستدعاء القياسي الصحيح بدون مسارات نسبية 🟢
import 'package:lamma_new/main.dart'; 

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const LammaApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}