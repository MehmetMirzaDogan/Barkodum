// Market Barkod Rehberi - Widget Test

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:barkodum/main.dart';

void main() {
  testWidgets('App başlangıç testi', (WidgetTester tester) async {
    // Uygulamayı başlat
    await tester.pumpWidget(const BarkodApp());

    // Market Seç başlığını kontrol et
    expect(find.text('Market Seç'), findsOneWidget);
    
    // 4 market kartının olduğunu kontrol et
    expect(find.byType(Card), findsWidgets);
  });
}
