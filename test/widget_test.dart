import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:orders/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows admin sign in on Windows', (WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;

    await tester.pumpWidget(const OrderApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Admin Sign In'), findsOneWidget);
    expect(
      find.textContaining('Windows build is the admin app'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.login_outlined), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('shows user sign in on Android and iOS builds', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    await tester.pumpWidget(const OrderApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('User Sign In'), findsOneWidget);
    expect(
      find.textContaining('Android and iOS build is for user accounts'),
      findsOneWidget,
    );
    debugDefaultTargetPlatformOverride = null;
  });
}
