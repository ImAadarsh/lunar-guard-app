import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunar_security_guard/app.dart';
import 'package:lunar_security_guard/auth/auth_controller.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('App loads', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthController(),
        child: const LunarSecurityApp(),
      ),
    );

    // Splash uses a 2.2s timer; advance fake time so tests dispose cleanly.
    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
