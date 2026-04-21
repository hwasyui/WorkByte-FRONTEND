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
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Image.asset(
              'assets/login-header.png',
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              RichText(
                                textAlign: TextAlign.left,
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

                              /// Email
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

                              /// Password
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

                              /// Forgot password
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: () {},
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

                              /// Login button
                              Consumer<AuthProvider>(
                                builder: (context, authProvider, child) {
                                  return GestureDetector(
                                    onTap: authProvider.isLoading ? null : _handleLogin,
                                    child: Container(
                                      width: double.infinity,
                                      height: 55,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(30),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withOpacity(0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          authProvider.isLoading
                                              ? 'Logging in...'
                                              : 'Login',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
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
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
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
                                      onPressed: () {},
                                    ),
                                    const SizedBox(width: 20),
                                    SocialButton(
                                      assetPath: 'assets/linkedin.png',
                                      iconSize: 36,
                                      onPressed: () {},
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    /// Bottom wave (scrolls with content)
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
            ),
          ],
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
