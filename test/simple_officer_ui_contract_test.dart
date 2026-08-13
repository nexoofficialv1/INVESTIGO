import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investigo/widgets/investigo_ui.dart';

void main() {
  testWidgets('large action card has one clear tap target', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InvestigoActionCard(
            icon: Icons.add,
            title: 'কেস এন্ট্রি',
            subtitle: 'Case Entry',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );
    expect(find.text('কেস এন্ট্রি'), findsOneWidget);
    await tester.tap(find.text('কেস এন্ট্রি'));
    expect(tapped, isTrue);
  });

  testWidgets('progress header exposes current guided step', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: InvestigoProgressHeader(
            title: 'CD-I তৈরি',
            subtitle: 'এক ধাপ করে',
            current: 2,
            total: 10,
          ),
        ),
      ),
    );
    expect(find.text('2/10'), findsOneWidget);
  });

  test('CD builder uses one-current-question simple mode', () {
    final source = File('lib/screens/cd_builder_screen.dart').readAsStringSync();
    expect(source, contains('int _simpleStepIndex = 0;'));
    expect(source, contains('_questionInput(current, plan)'));
    expect(source, contains('পরবর্তী / Next'));
  });

  test('structured forms use guided step index', () {
    final source = File('lib/widgets/structured_bnss_form_panel.dart').readAsStringSync();
    expect(source, contains('int _simpleStepIndex = 0;'));
    expect(source, contains('এক ধাপ করে ফর্ম পূরণ করুন'));
  });
}
