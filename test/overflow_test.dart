import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bookshelf/models/book.dart';
import 'package:bookshelf/providers/book_provider.dart';
import 'package:bookshelf/screens/public_home_screen.dart';
import 'package:bookshelf/screens/login_screen.dart';
import 'package:bookshelf/screens/register_screen.dart';
import 'package:bookshelf/screens/book_detail_screen.dart';
import 'package:bookshelf/services/auth_service.dart';

void main() {
  group('Screen 360x640 Overflow Tests', () {
    testWidgets('PublicHomeScreen renders on 360x640 without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: PublicHomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('LoginScreen renders on 360x640 without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AuthService>(create: (_) => AuthService()),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('RegisterScreen renders on 360x640 without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AuthService>(create: (_) => AuthService()),
          ],
          child: const MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('BookDetailScreen renders on 360x640 without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final book = Book(
        id: '1',
        userId: 'u',
        title: 'Very Long Book Title That Might Wrap Over Multiple Lines In Narrow Devices',
        author: 'Very Long Author Name That Might Also Wrap',
        genre: 'Non-Fiction',
        status: 'Reading',
        rating: 5,
        favorite: true,
        notes: 'A great book about architecture and clean code principles with multiple paragraphs of thoughts.',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<BookProvider>(
          create: (_) => BookProvider(),
          child: MaterialApp(
            home: BookDetailScreen(book: book),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
