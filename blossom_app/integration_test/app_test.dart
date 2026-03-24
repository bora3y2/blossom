import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'package:blossom_app/main.dart' as app;

const _email = 'admin@blossom.com';
const _password = 'password123';

void main() {
  patrolTest(
    'login flow',
    ($) async {
      app.main();
      await $.pumpAndSettle();

      // Should start on login screen
      expect(find.text('Welcome Back'), findsOneWidget);

      // Enter email (first TextField) and password (second TextField)
      await $(TextField).at(0).enterText(_email);
      await $(TextField).at(1).enterText(_password);
      await $('Log In').tap();

      // Wait for auth + navigation
      await $.pump(const Duration(seconds: 8));
      await $.pumpAndSettle();

      // Should now be past the login screen
      expect(find.text('Welcome Back'), findsNothing);
    },
  );

  patrolTest(
    'home/community feed loads',
    ($) async {
      app.main();
      await $.pumpAndSettle();

      await $(TextField).at(0).enterText(_email);
      await $(TextField).at(1).enterText(_password);
      await $('Log In').tap();
      await $.pump(const Duration(seconds: 8));
      await $.pumpAndSettle();

      // Navigate to HOME tab (community feed)
      if (find.text('HOME').evaluate().isNotEmpty) {
        await $('HOME').tap();
        await $.pump(const Duration(seconds: 3));
        await $.pumpAndSettle();
      }

      // Community feed should show posts or empty state — no error text
      expect(find.text('Database connection unavailable'), findsNothing);
      expect(find.text('Invalid access token'), findsNothing);
    },
  );

  patrolTest(
    'garden tab loads',
    ($) async {
      app.main();
      await $.pumpAndSettle();

      await $(TextField).at(0).enterText(_email);
      await $(TextField).at(1).enterText(_password);
      await $('Log In').tap();
      await $.pump(const Duration(seconds: 8));
      await $.pumpAndSettle();

      // Navigate to GARDEN tab
      await $('GARDEN').tap();
      await $.pump(const Duration(seconds: 3));
      await $.pumpAndSettle();

      expect(find.text('Database connection unavailable'), findsNothing);
      expect(find.text('Invalid access token'), findsNothing);
    },
  );

  patrolTest(
    'profile tab loads',
    ($) async {
      app.main();
      await $.pumpAndSettle();

      await $(TextField).at(0).enterText(_email);
      await $(TextField).at(1).enterText(_password);
      await $('Log In').tap();
      await $.pump(const Duration(seconds: 8));
      await $.pumpAndSettle();

      // Navigate to PROFILE tab
      await $('PROFILE').tap();
      await $.pump(const Duration(seconds: 3));
      await $.pumpAndSettle();

      expect(find.text('Database connection unavailable'), findsNothing);
      expect(find.text('Invalid access token'), findsNothing);
    },
  );

  patrolTest(
    'add plant flow: step 1 answers navigate to step 2 with suggestions',
    ($) async {
      app.main();
      await $.pumpAndSettle();

      await $(TextField).at(0).enterText(_email);
      await $(TextField).at(1).enterText(_password);
      await $('Log In').tap();
      await $.pump(const Duration(seconds: 8));
      await $.pumpAndSettle();

      // Go to GARDEN tab
      await $('GARDEN').tap();
      await $.pump(const Duration(seconds: 3));
      await $.pumpAndSettle();

      // Tap the add-plant icon in the header
      await $(Icons.add).tap();
      await $.pump(const Duration(seconds: 2));
      await $.pumpAndSettle();

      // Step 1 questions should be visible
      expect(find.text('Where will your plant live?'), findsOneWidget);

      // Answer all 4 questions
      await $('Indoor').tap();
      await $('Indirect').tap();
      await $("I'm a bit forgetful").tap();
      await $('No pets here').tap();
      await $.pumpAndSettle();

      // Tap Next
      await $('Next').tap();
      await $.pump(const Duration(seconds: 6));
      await $.pumpAndSettle();

      // Step 2 should show suggestions header
      expect(find.text('Suggestions for your space'), findsOneWidget);
      expect(find.text('Unable to load plant suggestions.'), findsNothing);
    },
  );

  patrolTest(
    'add plant flow: pet safety filter loads without error',
    ($) async {
      app.main();
      await $.pumpAndSettle();

      await $(TextField).at(0).enterText(_email);
      await $(TextField).at(1).enterText(_password);
      await $('Log In').tap();
      await $.pump(const Duration(seconds: 8));
      await $.pumpAndSettle();

      await $('GARDEN').tap();
      await $.pump(const Duration(seconds: 3));
      await $.pumpAndSettle();

      await $(Icons.add).tap();
      await $.pump(const Duration(seconds: 2));
      await $.pumpAndSettle();

      // Select "Yes, keep it safe" to trigger pet_safe_only filter
      await $('Indoor').tap();
      await $('Low Light').tap();
      await $("I'm a bit forgetful").tap();
      await $('Yes, keep it safe').tap();
      await $.pumpAndSettle();

      await $('Next').tap();
      await $.pump(const Duration(seconds: 6));
      await $.pumpAndSettle();

      expect(find.text('Suggestions for your space'), findsOneWidget);
      expect(find.text('Unable to load plant suggestions.'), findsNothing);
    },
  );

  patrolTest(
    'add plant flow: step 2 plant selection opens step 3',
    ($) async {
      app.main();
      await $.pumpAndSettle();

      await $(TextField).at(0).enterText(_email);
      await $(TextField).at(1).enterText(_password);
      await $('Log In').tap();
      await $.pump(const Duration(seconds: 8));
      await $.pumpAndSettle();

      await $('GARDEN').tap();
      await $.pump(const Duration(seconds: 3));
      await $.pumpAndSettle();

      await $(Icons.add).tap();
      await $.pump(const Duration(seconds: 2));
      await $.pumpAndSettle();

      await $('Indoor').tap();
      await $('Indirect').tap();
      await $("I'm a bit forgetful").tap();
      await $('No pets here').tap();
      await $.pumpAndSettle();

      await $('Next').tap();
      await $.pump(const Duration(seconds: 6));
      await $.pumpAndSettle();

      // Tap the first plant card's Select Plant button
      await $('Select Plant').at(0).tap();
      await $.pump(const Duration(seconds: 3));
      await $.pumpAndSettle();

      // Step 3 detail screen should be visible
      expect(find.text('Add to my garden'), findsOneWidget);
    },
  );
}
