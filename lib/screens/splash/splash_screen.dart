import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workbyte_app/screens/freelancer_profile/freelancer_profile_setup.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../screens/admin/admin_shell.dart';
import '../../screens/auth/login.dart';
import '../../screens/dashboard/dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    final profileProvider = context.read<ProfileProvider>();

    await authProvider.restoreSession(profileProvider: profileProvider);

    if (!mounted) return;

    Widget nextScreen;

    if (!authProvider.isAuthenticated) {
      nextScreen = const LoginScreen();
    } else if (authProvider.currentUser?.isAdmin == true) {
      nextScreen = const AdminShell();
    } else if (authProvider.shouldShowProfileSetup(profileProvider)) {
      nextScreen = const FreelancerProfileSetupScreen();
    } else {
      nextScreen = const HomeScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logoSize = MediaQuery.of(context).size.width * 0.7;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/workbyte-purple.png',
          width: logoSize,
          height: logoSize,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
