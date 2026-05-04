import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../widgets/login_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/social_button.dart';
import '../../screens/auth/login.dart';
import '../../screens/auth/verify_email.dart';
import '../../providers/auth_provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  String? _nameError;
  String? _emailError;
  String? _passwordError;

  String _selectedRole = 'Freelancer';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  bool _validate() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final fullName = _nameController.text.trim();

    setState(() {
      // Full name
      if (fullName.isEmpty) {
        _nameError = 'Full name is required';
      } else if (fullName.length < 2) {
        _nameError = 'Name must be at least 2 characters';
      } else {
        _nameError = null;
      }

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

    return _nameError == null && _emailError == null && _passwordError == null;
  }

  Future<void> _handleSignUp() async {
    if (!_validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final fullName = _nameController.text.trim();
    final userType = _selectedRole.toLowerCase();

    final success = await authProvider.register(
      email: email,
      password: password,
      userType: userType,
      fullName: userType == 'freelancer' ? fullName : null,
      companyName: userType == 'client' ? fullName : null,
    );

    if (success) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyEmailScreen(email: email),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.error ?? 'Registration failed')),
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
            // Logo section with header image
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
                              /// Title
                              Text(
                                'Sign Up',
                                textAlign: TextAlign.center,
                                style: AppText.h1.copyWith(
                                  fontSize: 32,
                                  color: const Color(0xFF333333),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                'Fill your details or continue with social media',
                                textAlign: TextAlign.center,
                                style: AppText.caption.copyWith(
                                  color: const Color(0xFF7D7D7D),
                                ),
                              ),

                              const SizedBox(height: 24),

                              /// Full name
                              SizedBox(
                                width: double.infinity,
                                child: LoginTextField(
                                  hintText: 'Full name',
                                  controller: _nameController,
                                  errorText: _nameError,
                                  prefixIcon: const Icon(
                                    Icons.person_outline,
                                    size: 24,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 14),

                              /// Email
                              SizedBox(
                                width: double.infinity,
                                child: LoginTextField(
                                  hintText: 'Email address',
                                  controller: _emailController,
                                  errorText: _emailError,
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

                              const SizedBox(height: 26),

                              /// Role Toggle (Freelancer / Client)
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
                              Consumer<AuthProvider>(
                                builder: (context, authProvider, child) {
                                  return PrimaryButton(
                                    label: authProvider.isLoading
                                        ? 'Signing Up...'
                                        : 'Sign Up',
                                    onPressed: authProvider.isLoading
                                        ? null
                                        : _handleSignUp,
                                  );
                                },
                              ),

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
                                  'Have an account? ',
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
