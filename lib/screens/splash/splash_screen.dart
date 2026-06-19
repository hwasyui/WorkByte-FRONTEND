import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workbyte_app/screens/freelancer_profile/freelancer_profile_setup.dart';
import 'package:workbyte_app/services/deep_link_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../auth/login.dart';
import '../auth/oauth_role_select.dart';
import '../dashboard/dashboard.dart';
import '../server_unavailable_screen.dart';

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

    if (authProvider.backendUnavailable) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ServerUnavailableScreen()),
      );
      return;
    }

    final user = authProvider.currentUser;
    Widget nextScreen;
    if (authProvider.isAuthenticated && user?.hasRole != true) {
      nextScreen = const OAuthRoleSelectScreen();
    } else if (authProvider.isAuthenticated) {
      nextScreen = const HomeScreen();
    } else {
      nextScreen = const LoginScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextScreen),
    );

    // Process any deep link that launched or was received before auth resolved.
    if (authProvider.isAuthenticated && authProvider.token != null) {
      final pendingLink = DeepLinkService.consumePendingLink();
      if (pendingLink != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          DeepLinkService.handleLink(
            uri: pendingLink,
            token: authProvider.token!,
            isClient: profileProvider.isClient,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final logoSize = MediaQuery.of(context).size.width * 0.4;

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
