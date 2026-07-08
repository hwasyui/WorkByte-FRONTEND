import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workbyte_app/screens/freelancer_profile/freelancer_profile_setup.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../widgets/login_text_field.dart';
import '../../widgets/social_button.dart';
import '../../screens/auth/signup.dart';
import '../../screens/auth/forgot_password.dart';
import '../../screens/auth/oauth_role_select.dart';
import '../../screens/admin/admin_shell.dart';
import '../../screens/dashboard/dashboard.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/admin_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _AlertType { success, error, info }

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;

  String? _alertMessage;
  _AlertType? _alertType;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\.\+\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$').hasMatch(email);
  }

  bool _validate() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      if (email.isEmpty) {
        _emailError = 'Email is required';
      } else if (!_isValidEmail(email)) {
        _emailError = 'Enter a valid email address';
      } else {
        _emailError = null;
      }

      if (password.isEmpty) {
        _passwordError = 'Password is required';
      } else if (password.length < 8) {
        _passwordError = 'Password must be at least 8 characters';
      } else {
        _passwordError = null;
      }
    });

    return _emailError == null && _passwordError == null;
  }

  void _showAlert(String message, {required _AlertType type}) {
    setState(() {
      _alertMessage = message;
      _alertType = type;
    });
  }

  void _clearAlert() {
    if (!mounted) return;
    setState(() {
      _alertMessage = null;
      _alertType = null;
    });
  }

  Future<void> _showTemporaryAlert(
    String message, {
    required _AlertType type,
    Duration duration = const Duration(seconds: 2),
  }) async {
    _showAlert(message, type: type);
    await Future.delayed(duration);
    if (!mounted) return;
    _clearAlert();
  }

  void _routeAfterAuth() {
    final authProvider = context.read<AuthProvider>();
    final profileProvider = context.read<ProfileProvider>();

    if (authProvider.currentUser?.isAdmin == true) {
      context.read<AdminProvider>().initWithToken(authProvider.token!);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminShell()),
      );
      return;
    }

    if (authProvider.shouldShowProfileSetup(profileProvider)) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FreelancerProfileSetupScreen()),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _handleGoogleLogin() async {
    _clearAlert();

    final authProvider = context.read<AuthProvider>();
    final profileProvider = context.read<ProfileProvider>();

    final result = await authProvider.loginWithGoogle(
      profileProvider: profileProvider,
    );

    if (!mounted) return;

    if (result == null) {
      final err = authProvider.error ?? 'Google login failed';
      if (err != 'Google login cancelled') {
        _showAlert(err, type: _AlertType.error);
      }
      return;
    }

    final isNewUser = result['is_new_user'] as bool;
    final user = authProvider.currentUser;

    if (isNewUser || user?.hasRole != true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OAuthRoleSelectScreen()),
      );
      return;
    }

    await _showTemporaryAlert(
      'Google login successful',
      type: _AlertType.success,
      duration: const Duration(milliseconds: 600),
    );

    if (!mounted) return;

    if (user?.isAdmin == true) {
      context.read<AdminProvider>().initWithToken(authProvider.token!);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminShell()),
      );
    } else if (authProvider.shouldShowProfileSetup(profileProvider)) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FreelancerProfileSetupScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  Future<void> _handleLogin() async {
    _clearAlert();

    if (!_validate()) {
      _showAlert(
        'Please fix the highlighted fields and try again.',
        type: _AlertType.error,
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final profileProvider = context.read<ProfileProvider>();

    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
      profileProvider: profileProvider,
    );

    if (!mounted) return;

    if (!success) {
      _showAlert(authProvider.error ?? 'Login failed', type: _AlertType.error);
      return;
    }

    final user = authProvider.currentUser;
    if (user?.hasRole != true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OAuthRoleSelectScreen()),
      );
      return;
    } else if (user?.isAdmin == true) {
      await _showTemporaryAlert(
        'Welcome back, admin.',
        type: _AlertType.success,
        duration: const Duration(milliseconds: 600),
      );

      if (!mounted) return;
      context.read<AdminProvider>().initWithToken(authProvider.token!);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminShell()),
      );
      return;
    }

    await _showTemporaryAlert(
      'Login successful. Welcome back!',
      type: _AlertType.success,
      duration: const Duration(milliseconds: 600),
    );

    if (!mounted) return;
    _routeAfterAuth();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 30,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Image.asset(
                                  'assets/workbyte-purple.png',
                                  height: 90,
                                ),
                                const SizedBox(height: 24),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 280),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  transitionBuilder: (child, animation) {
                                    final offsetAnimation = Tween<Offset>(
                                      begin: const Offset(0, -0.12),
                                      end: Offset.zero,
                                    ).animate(animation);

                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: offsetAnimation,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: _alertMessage == null
                                      ? const SizedBox.shrink(
                                          key: ValueKey('empty_alert'),
                                        )
                                      : Padding(
                                          key: ValueKey(_alertMessage!),
                                          padding: const EdgeInsets.only(
                                            bottom: 18,
                                          ),
                                          child: _LoginAlertCard(
                                            message: _alertMessage!,
                                            type: _alertType ?? _AlertType.info,
                                            onClose: _clearAlert,
                                          ),
                                        ),
                                ),
                                RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Welcome ',
                                        style: AppText.h1.copyWith(
                                          fontSize: 32,
                                          color: const Color(0xFF111827),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'back',
                                        style: AppText.h1.copyWith(
                                          fontSize: 32,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Fill your details or continue with social media',
                                  textAlign: TextAlign.center,
                                  style: AppText.caption.copyWith(
                                    color: const Color(0xFF6B7280),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: LoginTextField(
                                    hintText: 'Email address',
                                    controller: _emailController,
                                    errorText: _emailError,
                                    keyboardType: TextInputType.emailAddress,
                                    prefixIcon: const Icon(
                                      Icons.mail_outline,
                                      size: 24,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: LoginTextField(
                                    hintText: 'Password',
                                    controller: _passwordController,
                                    isPassword: true,
                                    errorText: _passwordError,
                                    prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      size: 24,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const ForgotPasswordScreen(),
                                      ),
                                    ),
                                    child: Text(
                                      'Forgot password?',
                                      style: AppText.caption.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Consumer<AuthProvider>(
                                  builder: (context, authProvider, child) {
                                    return GestureDetector(
                                      onTap: authProvider.isLoading
                                          ? null
                                          : _handleLogin,
                                      child: AnimatedOpacity(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        opacity: authProvider.isLoading
                                            ? 0.8
                                            : 1,
                                        child: Container(
                                          width: double.infinity,
                                          height: 55,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.primary
                                                    .withOpacity(0.3),
                                                blurRadius: 12,
                                                offset: const Offset(0, 5),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: authProvider.isLoading
                                                ? Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: const [
                                                      SizedBox(
                                                        width: 18,
                                                        height: 18,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2.2,
                                                          valueColor:
                                                              AlwaysStoppedAnimation<
                                                                Color
                                                              >(Colors.white),
                                                        ),
                                                      ),
                                                      SizedBox(width: 12),
                                                      Text(
                                                        'Logging in...',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                : const Text(
                                                    'Login',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Divider(color: Color(0xFFE5E7EB)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        'Or continue with',
                                        style: AppText.caption.copyWith(
                                          color: const Color(0xFF9CA3AF),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const Expanded(
                                      child: Divider(color: Color(0xFFE5E7EB)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SocialButton(
                                        assetPath: 'assets/google.png',
                                        iconSize: 34,
                                        onPressed:
                                            context
                                                .read<AuthProvider>()
                                                .isLoading
                                            ? null
                                            : _handleGoogleLogin,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Builder(
              builder: (context) {
                final bottomInset = MediaQuery.of(context).padding.bottom;
                return ClipPath(
                  clipper: _WaveClipper(),
                  child: Container(
                    width: double.infinity,
                    height: 80 + bottomInset,
                    padding: EdgeInsets.only(bottom: bottomInset),
                    color: const Color(0xFFE0E7FF),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'New user? ',
                          style: AppText.caption.copyWith(
                            color: AppColors.textDark,
                            fontSize: 15,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignUpScreen(),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Create account',
                            style: AppText.captionSemiBold.copyWith(
                              color: const Color(0xFF4F46E5),
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginAlertCard extends StatelessWidget {
  final String message;
  final _AlertType type;
  final VoidCallback onClose;

  const _LoginAlertCard({
    required this.message,
    required this.type,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final _AlertStyle style = _styleFor(type);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: style.borderColor),
        boxShadow: [
          BoxShadow(
            color: style.shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: style.iconBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(style.icon, color: style.iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      style.title,
                      style: AppText.captionSemiBold.copyWith(
                        color: const Color(0xFF111827),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: AppText.caption.copyWith(
                        color: const Color(0xFF4B5563),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: style.iconBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: style.iconColor,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _AlertStyle _styleFor(_AlertType type) {
    switch (type) {
      case _AlertType.success:
        return const _AlertStyle(
          title: 'Success',
          icon: Icons.check_circle_rounded,
          backgroundColor: Color(0xFFF0FDF4),
          borderColor: Color(0xFFBBF7D0),
          iconBackgroundColor: Color(0xFFDCFCE7),
          iconColor: Color(0xFF15803D),
          shadowColor: Color(0x1A16A34A),
        );
      case _AlertType.error:
        return const _AlertStyle(
          title: 'Login failed',
          icon: Icons.error_rounded,
          backgroundColor: Color(0xFFFEF2F2),
          borderColor: Color(0xFFFECACA),
          iconBackgroundColor: Color(0xFFFEE2E2),
          iconColor: Color(0xFFDC2626),
          shadowColor: Color(0x1ADC2626),
        );
      case _AlertType.info:
        return const _AlertStyle(
          title: 'Notice',
          icon: Icons.info_rounded,
          backgroundColor: Color(0xFFEFF6FF),
          borderColor: Color(0xFFBFDBFE),
          iconBackgroundColor: Color(0xFFDBEAFE),
          iconColor: Color(0xFF2563EB),
          shadowColor: Color(0x1A2563EB),
        );
    }
  }
}

class _AlertStyle {
  final String title;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconBackgroundColor;
  final Color iconColor;
  final Color shadowColor;

  const _AlertStyle({
    required this.title,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.shadowColor,
  });
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height * 0.35);
    path.quadraticBezierTo(
      size.width * 0.5,
      -size.height * 0.25,
      size.width + 10,
      size.height * 0.2,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_WaveClipper oldClipper) => false;
}
