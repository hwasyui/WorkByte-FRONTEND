import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../widgets/login_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/social_button.dart';
import '../../screens/auth/login.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
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
                    /// Title
                    Text(
                      'Sign Up',
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

                    /// Full name
                    LoginTextField(
                      hintText: 'Full name',
                      controller: _nameController,
                      prefixIcon: const Icon(
                        Icons.person_outline,
                        size: 24,
                        color: Color(0xFF7D7D7D),
                      ),
                    ),

                    const SizedBox(height: 14),

                    /// Username
                    LoginTextField(
                      hintText: 'Username',
                      controller: _usernameController,
                      prefixIcon: const Icon(
                        Icons.person_outline,
                        size: 24,
                        color: Color(0xFF7D7D7D),
                      ),
                    ),

                    const SizedBox(height: 14),

                    /// Email
                    LoginTextField(
                      hintText: 'Email address',
                      controller: _emailController,
                      prefixIcon: const Icon(
                        Icons.mail_outline,
                        size: 24,
                        color: Color(0xFF7D7D7D),
                      ),
                    ),

                    const SizedBox(height: 14),

                    /// Password
                    LoginTextField(
                      hintText: 'Password',
                      controller: _passwordController,
                      isPassword: true,
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        size: 24,
                        color: Color(0xFF7D7D7D),
                      ),
                    ),

                    const SizedBox(height: 26),

                    /// Sign Up button
                    PrimaryButton(label: 'Sign Up', onPressed: () {}),

                    const SizedBox(height: 48),

                    /// Or continue with
                    Center(
                      child: Text(
                        'Or continue with',
                        style: AppText.caption.copyWith(
                          color: const Color(0xFF7D7D7D),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// Social buttons
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
                            'Have an account? ',
                            style: AppText.caption.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Login',
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
