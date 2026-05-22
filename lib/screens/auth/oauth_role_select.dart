import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workbyte_app/screens/freelancer_profile/freelancer_profile_setup.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../widgets/login_text_field.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../dashboard/dashboard.dart';

class OAuthRoleSelectScreen extends StatefulWidget {
  const OAuthRoleSelectScreen({super.key});

  @override
  State<OAuthRoleSelectScreen> createState() => _OAuthRoleSelectScreenState();
}

class _OAuthRoleSelectScreenState extends State<OAuthRoleSelectScreen> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedRole = 'Freelancer';
  String? _nameError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool _validate() {
    final name = _nameController.text.trim();
    setState(() {
      if (name.isEmpty) {
        _nameError = 'Full name is required';
      } else if (name.length < 2) {
        _nameError = 'Name must be at least 2 characters';
      } else {
        _nameError = null;
      }
    });
    return _nameError == null;
  }

  Future<void> _handleContinue() async {
    if (!_validate()) return;

    final authProvider = context.read<AuthProvider>();
    final profileProvider = context.read<ProfileProvider>();

    final success = await authProvider.addRole(
      role: _selectedRole.toLowerCase(),
      fullName: _nameController.text.trim(),
      profileProvider: profileProvider,
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Failed to set up profile'),
        ),
      );
      return;
    }

    if (authProvider.shouldShowProfileSetup(profileProvider)) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const FreelancerProfileSetupScreen()),
        (route) => false,
      );
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 64,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Complete your profile',
                    style: AppText.h1.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tell us your name and how you\'ll use WorkByte',
                    textAlign: TextAlign.center,
                    style: AppText.caption.copyWith(
                      color: const Color(0xFF6B7280),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: LoginTextField(
                      hintText: 'Full name',
                      controller: _nameController,
                      errorText: _nameError,
                      prefixIcon: const Icon(Icons.person_outline, size: 24),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'I am a...',
                      style: AppText.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: const Color(0xFF374151),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
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
                            onTap: () =>
                                setState(() => _selectedRole = 'Freelancer'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
                            onTap: () =>
                                setState(() => _selectedRole = 'Client'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
                  const SizedBox(height: 36),
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      return GestureDetector(
                        onTap: authProvider.isLoading ? null : _handleContinue,
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
                                  ? 'Setting up...'
                                  : 'Continue',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
