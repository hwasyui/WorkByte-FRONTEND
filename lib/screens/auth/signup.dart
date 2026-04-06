import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../widgets/login_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/social_button.dart';
import '../../screens/auth/login.dart';
// import '../../providers/auth_provider.dart';

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

  String _selectedRole = 'Freelancer'; // ✅ NEW

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  // Future<void> _handleSignUp() async {
  //   final authProvider = Provider.of<AuthProvider>(context, listen: false);

  //   final email = _emailController.text.trim();
  //   final password = _passwordController.text.trim();
  //   final fullName = _nameController.text.trim();
  //   final userType = _selectedRole.toLowerCase();

  //   if (email.isEmpty || password.isEmpty || fullName.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Please fill all required fields')),
  //     );
  //     return;
  //   }

  //   final success = await authProvider.register(
  //     email: email,
  //     password: password,
  //     userType: userType,
  //     fullName: userType == 'freelancer' ? fullName : null,
  //     companyName: userType == 'client' ? fullName : null,
  //   );

  //   if (success) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Registration successful! Please login.')),
  //     );
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (_) => const LoginScreen()),
  //     );
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text(authProvider.error ?? 'Registration failed')),
  //     );
  //   }
  // }

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

                    /// 🔥 Role Toggle (Freelancer / Client)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F1F1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _selectedRole = 'Freelancer');
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _selectedRole == 'Freelancer'
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Freelancer',
                                  style: TextStyle(
                                    color: _selectedRole == 'Freelancer'
                                        ? Colors.white
                                        : const Color(0xFF7D7D7D),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _selectedRole = 'Client');
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _selectedRole == 'Client'
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Client',
                                  style: TextStyle(
                                    color: _selectedRole == 'Client'
                                        ? Colors.white
                                        : const Color(0xFF7D7D7D),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    /// Sign Up button
                    // Consumer<AuthProvider>(
                    //   builder: (context, authProvider, child) {
                    //     return PrimaryButton(
                    //       label: authProvider.isLoading ? 'Signing Up...' : 'Sign Up',
                    //       onPressed: authProvider.isLoading ? null : _handleSignUp,
                    //     );
                    //   },
                    // ),
                    PrimaryButton(label: 'Sign Up', onPressed: () {
                      // Navigate to login or show message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sign up functionality disabled')),
                      );
                    }),

                    const SizedBox(height: 16),

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
