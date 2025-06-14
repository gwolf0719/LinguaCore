// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lingua_core/main.dart';
import 'package:lingua_core/core/services/service_locator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  setUpAll(() async {
    // Initialize services for testing
    await ServiceLocator.init();
  });

  testWidgets('LinguaCore app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: LinguaCoreApp()));

    // Verify that the app loads without errors
    expect(find.byType(LinguaCoreApp), findsOneWidget);
  });
}
