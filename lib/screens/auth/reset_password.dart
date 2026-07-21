import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../widgets/login_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../screens/auth/login.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_toast.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  String? _passwordError;
  String? _confirmError;

  int _secondsLeft = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _otpControllers) c.dispose();
    for (final f in _otpFocusNodes) f.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  String get _otp => _otpControllers.map((c) => c.text).join();

  void _onDigitChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    }
    if (_otp.length == 6) FocusScope.of(context).unfocus();
    setState(() {});
  }

  void _onKeyEvent(KeyEvent event, int index) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _otpControllers[index].text.isEmpty &&
        index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
  }

  bool _validate() {
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    setState(() {
      if (password.isEmpty) {
        _passwordError = 'New password is required';
      } else if (password.length < 8) {
        _passwordError = 'Password must be at least 8 characters';
      } else {
        _passwordError = null;
      }

      if (confirm.isEmpty) {
        _confirmError = 'Please confirm your password';
      } else if (confirm != password) {
        _confirmError = 'Passwords do not match';
      } else {
        _confirmError = null;
      }
    });

    return _passwordError == null && _confirmError == null;
  }

  Future<void> _handleReset() async {
    if (_otp.length < 6) {
      AppToast.error('Please enter the complete 6-digit code');
      return;
    }
    if (!_validate()) return;

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.resetPassword(
      email: widget.email,
      otp: _otp,
      newPassword: _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      AppToast.success('Password reset! You can now log in.');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      for (final c in _otpControllers) c.clear();
      _otpFocusNodes[0].requestFocus();
      AppToast.error(authProvider.error ?? 'Invalid or expired code. Try again.');
    }
  }

  Future<void> _handleResend() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.forgotPassword(email: widget.email);

    if (!mounted) return;

    if (success) {
      _startTimer();
      for (final c in _otpControllers) c.clear();
      _otpFocusNodes[0].requestFocus();
      AppToast.success('A new reset code has been sent.');
    } else {
      AppToast.error(authProvider.error ?? 'Failed to resend code.');
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 30,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.key_rounded,
                                  size: 36,
                                  color: AppColors.primary,
                                ),
                              ),

                              const SizedBox(height: 20),

                              Text(
                                'Reset Password',
                                textAlign: TextAlign.center,
                                style: AppText.h1.copyWith(
                                  fontSize: 28,
                                  color: const Color(0xFF333333),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),

                              const SizedBox(height: 10),

                              Text(
                                'We sent a 6-digit code to',
                                textAlign: TextAlign.center,
                                style: AppText.caption.copyWith(
                                  color: const Color(0xFF7D7D7D),
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                widget.email,
                                textAlign: TextAlign.center,
                                style: AppText.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const SizedBox(height: 28),

                              // OTP boxes
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(6, (i) {
                                  return Padding(
                                    padding: EdgeInsets.only(right: i < 5 ? 10 : 0),
                                    child: _OtpBox(
                                      controller: _otpControllers[i],
                                      focusNode: _otpFocusNodes[i],
                                      onChanged: (v) => _onDigitChanged(v, i),
                                      onKeyEvent: (e) => _onKeyEvent(e, i),
                                    ),
                                  );
                                }),
                              ),

                              const SizedBox(height: 24),

                              SizedBox(
                                width: double.infinity,
                                child: LoginTextField(
                                  hintText: 'New password',
                                  controller: _passwordController,
                                  isPassword: true,
                                  errorText: _passwordError,
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    size: 24,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 14),

                              SizedBox(
                                width: double.infinity,
                                child: LoginTextField(
                                  hintText: 'Confirm new password',
                                  controller: _confirmController,
                                  isPassword: true,
                                  errorText: _confirmError,
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    size: 24,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 28),

                              Consumer<AuthProvider>(
                                builder: (context, auth, _) {
                                  return PrimaryButton(
                                    label: auth.isLoading ? 'Resetting...' : 'Reset Password',
                                    onPressed: auth.isLoading ? null : _handleReset,
                                  );
                                },
                              ),

                              const SizedBox(height: 20),

                              Consumer<AuthProvider>(
                                builder: (context, auth, _) {
                                  if (_secondsLeft > 0) {
                                    return Text(
                                      'Resend code in $_secondsLeft s',
                                      style: AppText.caption.copyWith(
                                        color: const Color(0xFF7D7D7D),
                                      ),
                                    );
                                  }
                                  return TextButton(
                                    onPressed: auth.isLoading ? null : _handleResend,
                                    child: Text(
                                      'Resend Code',
                                      style: AppText.captionSemiBold.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
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
                                  'Remember it? ',
                                  style: AppText.caption.copyWith(
                                    color: AppColors.textDark,
                                    fontSize: 15,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                                    (route) => false,
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Back to Login',
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

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<KeyEvent> onKeyEvent;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onKeyEvent,
  });

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: onKeyEvent,
      child: SizedBox(
        width: 46,
        height: 56,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          onChanged: onChanged,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF333333),
          ),
          decoration: InputDecoration(
            counterText: '',
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: controller.text.isEmpty
                ? const Color(0xFFF9FAFB)
                : AppColors.secondary,
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
