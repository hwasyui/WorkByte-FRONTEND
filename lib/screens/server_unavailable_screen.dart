import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/constants/colors.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import 'auth/login.dart';
import 'auth/oauth_role_select.dart';
import 'dashboard/dashboard.dart';

class ServerUnavailableScreen extends StatefulWidget {
  const ServerUnavailableScreen({super.key});

  @override
  State<ServerUnavailableScreen> createState() =>
      _ServerUnavailableScreenState();
}

class _ServerUnavailableScreenState extends State<ServerUnavailableScreen> {
  bool _isRetrying = false;

  Future<void> _retry() async {
    setState(() => _isRetrying = true);

    final authProvider = context.read<AuthProvider>();
    final profileProvider = context.read<ProfileProvider>();

    authProvider.clearBackendUnavailable();
    await authProvider.restoreSession(profileProvider: profileProvider);

    if (!mounted) return;

    if (authProvider.backendUnavailable) {
      setState(() => _isRetrying = false);
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFB),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.14),
                        AppColors.primary.withOpacity(0.05),
                        Colors.transparent,
                      ],
                      stops: const [0.2, 0.6, 1],
                    ),
                  ),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.10),
                                blurRadius: 30,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 132,
                          height: 132,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE9F8F7),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Icon(
                          Icons.cloud_off_rounded,
                          size: 62,
                          color: AppColors.primary,
                        ),
                        Positioned(
                          top: 42,
                          right: 44,
                          child: _Dot(
                            size: 10,
                            color: AppColors.primary.withOpacity(0.30),
                          ),
                        ),
                        Positioned(
                          bottom: 52,
                          left: 36,
                          child: _Dot(
                            size: 14,
                            color: AppColors.primary.withOpacity(0.18),
                          ),
                        ),
                        Positioned(
                          top: 64,
                          left: 34,
                          child: Icon(
                            Icons.cloud_rounded,
                            size: 18,
                            color: AppColors.primary.withOpacity(0.35),
                          ),
                        ),
                        Positioned(
                          bottom: 44,
                          right: 38,
                          child: Icon(
                            Icons.cloud_rounded,
                            size: 22,
                            color: AppColors.primary.withOpacity(0.25),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Under Maintenance',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF102A43),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'WorkByte is temporarily unavailable.\nWe\'ll be back up shortly.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B7280),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9F8F7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          'Our team is working on it. Please check back later.',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            color: const Color(0xFF4B5563),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _isRetrying
                    ? const CircularProgressIndicator(
                        color: AppColors.primary,
                      )
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _retry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Try Again',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final double size;
  final Color color;

  const _Dot({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
