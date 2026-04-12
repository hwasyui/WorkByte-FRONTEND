import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../widgets/login_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/social_button.dart';
import '../../screens/auth/signup.dart';
import '../../screens/dashboard/dashboard.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  bool _validate() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      // Email
      if (email.isEmpty) {
        _emailError = 'Email is required';
      } else if (!_isValidEmail(email)) {
        _emailError = 'Enter a valid email address';
      } else {
        _emailError = null;
      }

      // Password
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

  Future<void> _handleLogin() async {
    if (!_validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await context.read<AuthProvider>().login(
      _emailController.text.trim(),
      _passwordController.text,
      profileProvider: context.read<ProfileProvider>(),
    );

    if (success) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.error ?? 'Login failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 160),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back',
                      style: AppText.h1.copyWith(
                        color: const Color(0xFF333333),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Fill your details or continue with social media',
                      style: AppText.caption.copyWith(
                        color: const Color(0xFF7D7D7D),
                      ),
                    ),

                    const SizedBox(height: 50),

                    /// Email
                    LoginTextField(
                      hintText: 'Email address',
                      controller: _emailController,
                      errorText: _emailError,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(
                        Icons.mail_outline,
                        size: 24,
                        color: Color(0xFF7D7D7D),
                      ),
                    ),

                    const SizedBox(height: 22),

                    /// Password
                    LoginTextField(
                      hintText: 'Password',
                      controller: _passwordController,
                      isPassword: true,
                      errorText: _passwordError,
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        size: 24,
                        color: Color(0xFF7D7D7D),
                      ),
                    ),

                    const SizedBox(height: 14),

                    /// Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {},
                        child: Text(
                          'Forgot password?',
                          style: AppText.caption.copyWith(
                            color: const Color(0xFF7D7D7D),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    /// Login button
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return PrimaryButton(
                          label: authProvider.isLoading
                              ? 'Logging in...'
                              : 'Login',
                          onPressed: authProvider.isLoading
                              ? null
                              : _handleLogin,
                        );
                      },
                    ),

                    const SizedBox(height: 48),

                    Center(
                      child: Text(
                        'Or continue with',
                        style: AppText.caption.copyWith(
                          color: const Color(0xFF7D7D7D),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SocialButton(
                            assetPath: 'assets/google.png',
                            iconSize: 34,
                            onPressed: () {},
                          ),
                          const SizedBox(width: 8),
                          SocialButton(
                            assetPath: 'assets/linkedin.png',
                            iconSize: 36,
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),

              /// Bottom wave
              Builder(
                builder: (context) {
                  final bottomInset = MediaQuery.of(context).padding.bottom;
                  return ClipPath(
                    clipper: _WaveClipper(),
                    child: Container(
                      height: 140 + bottomInset,
                      padding: EdgeInsets.only(bottom: bottomInset),
                      color: AppColors.primary,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'New user? ',
                            style: AppText.caption.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignUpScreen(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Create account',
                              style: AppText.captionSemiBold.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
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
      ),
    );
  }
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
