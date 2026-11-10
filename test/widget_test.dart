// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:via_mioritica/main.dart' show ViaMioriticaApp;
import 'package:via_mioritica/src/screens/splash_screen.dart';

void main() {
  testWidgets('App smoke test – renders without crashing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: ViaMioriticaApp()));
    expect(find.byType(SplashScreen), findsOneWidget);
    // Unmount so the splash navigation timer is cancelled.
    await tester.pumpWidget(const SizedBox());
  });
}
