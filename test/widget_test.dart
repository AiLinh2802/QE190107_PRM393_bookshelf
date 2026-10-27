import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookshelf/screens/public_home_screen.dart';

void main() {
  testWidgets('PublicHomeScreen renders features and buttons correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PublicHomeScreen(),
      ),
    );

    // Verify title and actions
    expect(find.text('BookShelf'), findsWidgets);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);

    // Verify at least 3 feature cards
    expect(find.text('Track your books'), findsOneWidget);
    expect(find.text('Sort by status'), findsOneWidget);
    expect(find.text('Rate your favorites'), findsOneWidget);
  });
}
