import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lista_smart/core/persistence/shared_preferences_provider.dart';
import 'package:lista_smart/features/auth/presentation/login_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LoginScreen', () {
    Future<void> pumpLoginScreen(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
    }

    testWidgets('renders title, subtitle, fields and button (AUTH-01)', (tester) async {
      await pumpLoginScreen(tester);

      expect(find.text('Lista Smart'), findsOneWidget);
      expect(find.text('Faça compras mais inteligentes'), findsOneWidget);
      expect(find.text('Avançar'), findsOneWidget);
      expect(find.byIcon(LucideIcons.mail), findsOneWidget);
      expect(find.byIcon(LucideIcons.lock), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      // Password field starts obscured — eye icon shows (reveal)
      expect(find.byIcon(LucideIcons.eye), findsOneWidget);
    });

    testWidgets('tapping password toggle switches icon', (tester) async {
      await pumpLoginScreen(tester);

      // Initially obscured: eye visible, eyeOff hidden
      expect(find.byIcon(LucideIcons.eye), findsOneWidget);
      expect(find.byIcon(LucideIcons.eyeOff), findsNothing);

      // Tap the toggle
      await tester.tap(find.byIcon(LucideIcons.eye));
      await tester.pump();

      // Now revealed: eyeOff visible, eye hidden
      expect(find.byIcon(LucideIcons.eyeOff), findsOneWidget);
      expect(find.byIcon(LucideIcons.eye), findsNothing);
    });
  });
}
