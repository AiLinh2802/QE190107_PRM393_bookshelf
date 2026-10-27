import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import 'public_home_screen.dart';
import 'book_list_screen.dart';

/// AuthWrapper acts as the root authentication gatekeeper:
/// - While authStateChanges is loading/checking, ONLY displays CircularProgressIndicator
///   (preventing flash of Home or List, and avoiding wrong navigation).
/// - When authenticated (user != null), routes straight to BookListScreen.
/// - When unauthenticated (user == null), routes to PublicHomeScreen.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Trong lúc app đang kiểm tra trạng thái đăng nhập (authStateChanges chưa trả dữ liệu),
        // CHỈ hiện loading indicator: không flash Home hay List, không điều hướng sai.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = snapshot.data;
        if (user != null) {
          return BookListScreen(user: user);
        }

        return const PublicHomeScreen();
      },
    );
  }
}
