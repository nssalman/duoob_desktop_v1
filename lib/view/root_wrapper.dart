import 'package:duoob_desktop_app_v1/services/user_repository.dart';
import 'package:duoob_desktop_app_v1/view/login_screen.dart';
import 'package:duoob_desktop_app_v1/view/main_screen.dart';
import 'package:flutter/material.dart';

class RootWrapper extends StatelessWidget {
   RootWrapper({super.key});
    final UserRepository userRepository = UserRepository();

  Future<bool> _checkAuth() async {
    bool isLogged  = await userRepository.isUserLoggedIn();
    await Future.delayed(const Duration(milliseconds: 500)); 
    return isLogged;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkAuth(),
      builder: (context, snapshot) {
        // While waiting for SharedPreferences
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        // Once we have the data
        if (snapshot.data == true) {
          return const MainScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}