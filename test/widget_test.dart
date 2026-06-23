import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:body_battery/main.dart';

void main() {
  testWidgets('Radar Kiệt Sức app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RadarKietSucApp());

    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Radar Kiệt Sức'), findsWidgets);
  });
}
