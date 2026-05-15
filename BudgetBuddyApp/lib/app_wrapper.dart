import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/user_auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/setup/initial_setup_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';

class AppWrapper extends StatelessWidget {
  const AppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<UserAuthProvider>(context);

    // ----------------------------
    // 1. LOADING FIREBASE & MODEL
    // ----------------------------
    if (auth.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ----------------------------
    // 2. USER NOT LOGGED IN
    // ----------------------------
    if (auth.firebaseUser == null) {
      return const LoginScreen();
    }

    // ----------------------------
    // 3. USER LOGGED IN, LOAD DATA
    // ----------------------------
    final user = auth.userModel;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ----------------------------
    // 4. ONBOARDING REQUIRED?
    // ----------------------------
    if (user.onboardingComplete == false) {
      return const OnboardingScreen();
    }

    // ----------------------------
    // 5. INITIAL SETUP REQUIRED?
    // ----------------------------
    if (user.setupComplete == false) {
      return const InitialSetupScreen();
    }

    // ----------------------------
    // 6. ALL DONE → DASHBOARD
    // ----------------------------
    return const DashboardScreen();
  }
}
