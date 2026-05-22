import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textDark,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: false,
      ),
      body: Consumer2<AuthProvider, ProfileProvider>(
        builder: (context, auth, profile, _) {
          final user = auth.currentUser;
          final hasClientRole = user?.clientId != null;
          final hasFreelancerRole = user?.freelancerId != null;

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _ContactInfoSection(
                userId: user?.userId ?? '-',
                name: profile.displayName,
                email: user?.email ?? '-',
              ),
              const _SectionDivider(),
              _AdditionalAccountsSection(
                isClientActive: profile.isClient,
                hasClientRole: hasClientRole,
                hasFreelancerRole: hasFreelancerRole,
                onCreateAccount: () =>
                    _showAddRoleDialog(context, auth, profile),
              ),
              const _SectionDivider(),
              _SecuritySection(
                passwordLoginEnabled:
                    auth.currentUser?.passwordLoginEnabled ?? true,
                onPasswordAction: () => _showChangePasswordSheet(
                  context,
                  auth,
                  isSetPassword:
                      auth.currentUser?.passwordLoginEnabled != true,
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  void _showChangePasswordSheet(
    BuildContext context,
    AuthProvider auth, {
    required bool isSetPassword,
  }) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        bool showCurrent = false;
        bool showNew = false;
        bool showConfirm = false;
        String? currentError;
        String? newError;
        String? confirmError;

        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isSetPassword ? 'Set Password' : 'Change Password',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isSetPassword
                          ? 'Create a password so you can sign in with email and password later.'
                          : 'Enter your current password and choose a new one.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6B7280),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (!isSetPassword) ...[
                      _PasswordField(
                        label: 'Current Password',
                        hint: 'Enter your current password',
                        controller: currentCtrl,
                        isVisible: showCurrent,
                        errorText: currentError,
                        onToggleVisibility: () =>
                            setState(() => showCurrent = !showCurrent),
                      ),
                      const SizedBox(height: 14),
                    ],
                    _PasswordField(
                      label: 'New Password',
                      hint: 'Min. 8 characters',
                      controller: newCtrl,
                      isVisible: showNew,
                      errorText: newError,
                      onToggleVisibility: () =>
                          setState(() => showNew = !showNew),
                    ),
                    const SizedBox(height: 14),
                    _PasswordField(
                      label: 'Confirm New Password',
                      hint: 'Re-enter your new password',
                      controller: confirmCtrl,
                      isVisible: showConfirm,
                      errorText: confirmError,
                      onToggleVisibility: () =>
                          setState(() => showConfirm = !showConfirm),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary),
                              foregroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Consumer<AuthProvider>(
                            builder: (context, authState, _) {
                              return ElevatedButton(
                                onPressed: authState.isLoading
                                    ? null
                                    : () async {
                                        final current =
                                            currentCtrl.text.trim();
                                        final newPass = newCtrl.text.trim();
                                        final confirm =
                                            confirmCtrl.text.trim();

                                        bool hasError = false;
                                        if (!isSetPassword && current.isEmpty) {
                                          setState(() => currentError =
                                              'Current password is required');
                                          hasError = true;
                                        } else {
                                          setState(() => currentError = null);
                                        }

                                        if (newPass.length < 8) {
                                          setState(() => newError =
                                              'Password must be at least 8 characters');
                                          hasError = true;
                                        } else {
                                          setState(() => newError = null);
                                        }

                                        if (confirm != newPass) {
                                          setState(() => confirmError =
                                              'Passwords do not match');
                                          hasError = true;
                                        } else {
                                          setState(() => confirmError = null);
                                        }

                                        if (hasError) return;

                                        final success = isSetPassword
                                            ? await auth.setPassword(
                                                newPassword: newPass,
                                              )
                                            : await auth.changePassword(
                                                oldPassword: current,
                                                newPassword: newPass,
                                              );

                                        if (success) {
                                          if (sheetContext.mounted) {
                                            Navigator.pop(sheetContext);
                                          }
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  isSetPassword
                                                      ? 'Password login enabled successfully'
                                                      : 'Password changed successfully',
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 13),
                                                ),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                backgroundColor:
                                                    AppColors.primary,
                                              ),
                                            );
                                          }
                                        } else {
                                          setState(() {
                                            final message = auth.error ??
                                                (isSetPassword
                                                    ? 'Could not set password'
                                                    : 'Could not change password');
                                            if (isSetPassword) {
                                              newError = message;
                                            } else {
                                              currentError = message;
                                            }
                                          });
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  disabledBackgroundColor:
                                      AppColors.primary.withValues(alpha: 0.6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  elevation: 0,
                                ),
                                child: authState.isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        isSetPassword
                                            ? 'Set Password'
                                            : 'Save Changes',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddRoleDialog(
    BuildContext context,
    AuthProvider auth,
    ProfileProvider profile,
  ) {
    final isClientActive = profile.isClient;
    final targetRole = isClientActive ? 'freelancer' : 'client';
    final dialogTitle = isClientActive
        ? 'Create a freelancer account'
        : 'Create a client account';
    final dialogSubtitle = isClientActive
        ? 'Setup a freelancer account if you want to apply to jobs and showcase your skills.'
        : 'Setup a client account if you want to post jobs and hire talents.';
    final fieldLabel = isClientActive ? 'Full Name' : 'Company Name';
    final fieldHint =
        isClientActive ? 'Enter your full name' : 'Enter your company name';
    final buttonLabel =
        isClientActive ? 'New Freelancer Account' : 'New Client Account';
    final noteText = isClientActive
        ? 'Your name will NOT appear on job applications unless you complete your freelancer profile.'
        : 'Your company name will NOT appear on job posts unless you have previously worked with the talent or agency on WorkByte.';

    final controller = TextEditingController();
    String? fieldError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      dialogTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      dialogSubtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6B7280),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      fieldLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textDark,
                      ),
                      decoration: InputDecoration(
                        hintText: fieldHint,
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF9CA3AF),
                        ),
                        errorText: fieldError,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFDC2626),
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFDC2626),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      noteText,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6B7280),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppColors.primary,
                              ),
                              foregroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Consumer<AuthProvider>(
                            builder: (context, authState, _) {
                              return ElevatedButton(
                                onPressed: authState.isLoading
                                    ? null
                                    : () async {
                                        final input =
                                            controller.text.trim();
                                        if (input.isEmpty) {
                                          setState(() {
                                            fieldError =
                                                '$fieldLabel is required';
                                          });
                                          return;
                                        }
                                        setState(() => fieldError = null);

                                        final success = await auth.addRole(
                                          role: targetRole,
                                          fullName: input,
                                          profileProvider: profile,
                                        );

                                        if (success) {
                                          if (sheetContext.mounted) {
                                            Navigator.pop(sheetContext);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    targetRole == 'client'
                                                        ? 'Client account created successfully.'
                                                        : 'Freelancer account created successfully.',
                                                    style:
                                                        GoogleFonts.poppins(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  behavior:
                                                      SnackBarBehavior
                                                          .floating,
                                                  shape:
                                                      RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  backgroundColor:
                                                      AppColors.primary,
                                                ),
                                              );
                                            }
                                          }
                                        } else {
                                          if (context.mounted) {
                                            setState(() {
                                              fieldError =
                                                  auth.error ??
                                                  'Could not create account';
                                            });
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  disabledBackgroundColor:
                                      AppColors.primary.withValues(alpha: 0.6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  elevation: 0,
                                ),
                                child: authState.isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        buttonLabel,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ContactInfoSection extends StatelessWidget {
  final String userId;
  final String name;
  final String email;

  const _ContactInfoSection({
    required this.userId,
    required this.name,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Info',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          _InfoRow(label: 'User ID', value: userId),
          const _RowDivider(),
          _InfoRow(label: 'Name', value: name),
          const _RowDivider(),
          _InfoRow(label: 'Email', value: email),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      color: Color(0xFFF3F4F6),
      height: 1,
      thickness: 1,
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      color: const Color(0xFFF3F4F6),
    );
  }
}

class _SecuritySection extends StatelessWidget {
  final bool passwordLoginEnabled;
  final VoidCallback onPasswordAction;

  const _SecuritySection({
    required this.passwordLoginEnabled,
    required this.onPasswordAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Login Methods',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage how you sign in to your account.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          const _MethodStatusRow(
            icon: Icons.g_mobiledata_rounded,
            label: 'Google',
            status: 'Connected',
          ),
          _MethodStatusRow(
            icon: Icons.password_rounded,
            label: 'Password login',
            status: passwordLoginEnabled ? 'Enabled' : 'Not set',
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.lock_outline_rounded,
            label: passwordLoginEnabled ? 'Change Password' : 'Set Password',
            subtitle: passwordLoginEnabled
                ? 'Update your account password'
                : 'Enable email and password login',
            onTap: onPasswordAction,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _MethodStatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String status;

  const _MethodStatusRow({
    required this.icon,
    required this.label,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
          Text(
            status,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: status == 'Enabled' || status == 'Connected'
                  ? AppColors.primary
                  : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isVisible;
  final String? errorText;
  final VoidCallback onToggleVisibility;

  const _PasswordField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.isVisible,
    required this.onToggleVisibility,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: !isVisible,
          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF9CA3AF),
            ),
            errorText: errorText,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            suffixIcon: IconButton(
              icon: Icon(
                isVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF9CA3AF),
                size: 20,
              ),
              onPressed: onToggleVisibility,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFDC2626)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFDC2626), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _AdditionalAccountsSection extends StatelessWidget {
  final bool isClientActive;
  final bool hasClientRole;
  final bool hasFreelancerRole;
  final VoidCallback onCreateAccount;

  const _AdditionalAccountsSection({
    required this.isClientActive,
    required this.hasClientRole,
    required this.hasFreelancerRole,
    required this.onCreateAccount,
  });

  @override
  Widget build(BuildContext context) {
    final hasBothRoles = hasClientRole && hasFreelancerRole;
    final canCreateClient = !hasClientRole;
    final canCreateFreelancer = !hasFreelancerRole;

    final accountLabel = canCreateClient ? 'Client Account' : 'Freelancer Account';
    final description = canCreateClient
        ? 'Hire, manage and pay as a different company. Each client company has its own freelancers, payment methods and reports.'
        : 'Apply to jobs and build your portfolio as a freelancer. Use this account to showcase your experience and skills.';
    final buttonLabel =
        canCreateClient ? 'New Client Account' : 'New Freelancer Account';
    final helpText = canCreateClient
        ? 'Your company name will NOT appear on job posts unless you have previously worked with the talent or agency on WorkByte.'
        : 'Your name will NOT appear on job applications until you complete your freelancer profile.';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Accounts',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Creating a new account allows you to use WorkByte in different ways, while still having just one login.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          if (hasBothRoles) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Both accounts active',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Switch between Freelancer and Company from the side menu.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF6B7280),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else if (canCreateClient || canCreateFreelancer) ...[
            Text(
              accountLabel,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onCreateAccount,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  buttonLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              helpText,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
