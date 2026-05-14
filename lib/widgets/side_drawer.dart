import 'dart:io';
import 'package:workbyte_app/providers/notification_provider.dart';
import 'package:workbyte_app/widgets/appeal_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../screens/freelancer_profile/freelancer_profile.dart';
import '../screens/client_profile/client_profile.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/about/about_screen.dart';
import '../screens/auth/login.dart';
import '../screens/appeals/my_appeals_screen.dart'; // 👈 NEW

class SideDrawer extends StatelessWidget {
  const SideDrawer({super.key});

  void _navigateToProfile(BuildContext context) {
    Navigator.pop(context);
    final profile = context.read<ProfileProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => profile.isClient
            ? const ClientProfileScreen()
            : const ProfileScreen(),
      ),
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _navigateToAbout(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AboutScreen()),
    );
  }

  // 👇 NEW
  void _navigateToMyAppeals(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyAppealsScreen()),
    );
  }

  void _logout(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: const Color(0xFFF3F1FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 120,
                width: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDDD8FA),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.primary,
                        size: 36,
                      ),
                    ),
                    const Positioned(
                      top: 6,
                      left: 10,
                      child: Text(
                        '✦',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Positioned(
                      top: 6,
                      right: 10,
                      child: Text(
                        '✦',
                        style: TextStyle(
                          color: Color(0xFFB8B0F0),
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const Positioned(
                      bottom: 8,
                      right: 8,
                      child: Text(
                        '✦',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Positioned(
                      top: 30,
                      left: 2,
                      child: CircleAvatar(
                        radius: 3,
                        backgroundColor: Color(0xFFB8B0F0),
                      ),
                    ),
                    const Positioned(
                      bottom: 26,
                      right: 0,
                      child: CircleAvatar(
                        radius: 2.5,
                        backgroundColor: Color(0xFFB8B0F0),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Logout',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to logout?',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
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
                    child: ElevatedButton(
                      onPressed: () {
                        final auth = dialogContext.read<AuthProvider>();
                        final profile = dialogContext.read<ProfileProvider>();
                        final notification = dialogContext
                            .read<NotificationProvider>();
                        auth.logout(
                          profileProvider: profile,
                          notificationProvider: notification,
                        );
                        Navigator.of(
                          dialogContext,
                          rootNavigator: true,
                        ).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: Text(
                        'Logout',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _switchRole(BuildContext context, String newRole) {
    Navigator.pop(context);
    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();
    final userId = auth.currentUser?.userId;
    if (userId == null || auth.token == null) return;

    profile.switchRole(token: auth.token!, userId: userId, newRole: newRole);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      width: MediaQuery.of(context).size.width * 0.78,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer2<AuthProvider, ProfileProvider>(
              builder: (context, auth, profile, _) {
                final imageUrl = profile.profilePictureUrl;
                Widget displayImage;
                if (imageUrl != null && imageUrl.isNotEmpty) {
                  if (imageUrl.startsWith('http')) {
                    displayImage = Image.network(
                      '$imageUrl?t=${DateTime.now().millisecondsSinceEpoch}',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person,
                        size: 30,
                        color: AppColors.primary,
                      ),
                    );
                  } else if (File(imageUrl).existsSync()) {
                    displayImage = Image.file(
                      File(imageUrl),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person,
                        size: 30,
                        color: AppColors.primary,
                      ),
                    );
                  } else {
                    displayImage = const Icon(
                      Icons.person,
                      size: 30,
                      color: AppColors.primary,
                    );
                  }
                } else {
                  displayImage = const Icon(
                    Icons.person,
                    size: 30,
                    color: AppColors.primary,
                  );
                }

                final hasClientRole = auth.currentUser?.clientId != null;
                final hasFreelancerRole =
                    auth.currentUser?.freelancerId != null;
                final hasBothRoles = hasClientRole && hasFreelancerRole;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: displayImage,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            profile.displayName,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            auth.currentUser?.email ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF6B7280),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          // NEW: ban badge under email
                          if (auth.isReportBanned) ...[
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _navigateToMyAppeals(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEBEE),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFEF9A9A,
                                    ).withValues(alpha: 0.6),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.gavel_rounded,
                                      size: 12,
                                      color: Color(0xFFC62828),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Account Restricted · View Appeals',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFFC62828),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // 👇 Submit Appeal button — compact
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                                final auth = context.read<AuthProvider>();
                                AppealDialog.show(
                                  context,
                                  targetType: 'user',
                                  targetId: auth.currentUser!.userId,
                                  targetLabel: 'Your Account',
                                  closureNote: auth.currentUser!.banMessage,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFC62828),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.edit_note_rounded,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Submit Appeal',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    if (hasBothRoles) ...[
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF3F4F6)),
                        ),
                        child: Column(
                          children: [
                            _AccountTile(
                              name: profile.freelancerDisplayName,
                              roleLabel: 'Freelancer',
                              profilePicUrl:
                                  profile.freelancerProfilePictureUrl,
                              isActive: !profile.isClient,
                              onTap: profile.isClient
                                  ? () => _switchRole(context, 'freelancer')
                                  : null,
                            ),
                            const Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0xFFF3F4F6),
                              indent: 16,
                              endIndent: 16,
                            ),
                            _AccountTile(
                              name: profile.clientDisplayName,
                              roleLabel: 'Company',
                              profilePicUrl: profile.clientProfilePictureUrl,
                              isActive: profile.isClient,
                              onTap: !profile.isClient
                                  ? () => _switchRole(context, 'client')
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),

            const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 8),
            _DrawerItem(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              onTap: () => _navigateToProfile(context),
            ),
            _DrawerItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () => _navigateToSettings(context),
            ),

            // 👇 NEW: My Appeals — always visible so users can track status
            Consumer<AuthProvider>(
              builder: (context, auth, _) => _DrawerItem(
                icon: Icons.policy_outlined,
                label: 'My Appeals',
                onTap: () => _navigateToMyAppeals(context),
                // 👇 shows a red dot badge when account is banned
                badge: auth.isReportBanned ? '!' : null,
              ),
            ),

            _DrawerItem(
              icon: Icons.info_outline_rounded,
              label: 'About Us',
              onTap: () => _navigateToAbout(context),
            ),
            const Spacer(),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
            _DrawerItem(
              icon: Icons.logout_rounded,
              label: 'Logout',
              color: const Color(0xFFDC2626),
              onTap: () => _logout(context),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ── _AccountTile — unchanged ───────────────────────────────────────────────

class _AccountTile extends StatelessWidget {
  final String name;
  final String roleLabel;
  final String? profilePicUrl;
  final bool isActive;
  final VoidCallback? onTap;

  const _AccountTile({
    required this.name,
    required this.roleLabel,
    this.profilePicUrl,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatar;
    if (profilePicUrl != null && profilePicUrl!.isNotEmpty) {
      if (profilePicUrl!.startsWith('http')) {
        avatar = Image.network(
          profilePicUrl!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.person, size: 22, color: AppColors.primary),
        );
      } else if (File(profilePicUrl!).existsSync()) {
        avatar = Image.file(
          File(profilePicUrl!),
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.person, size: 22, color: AppColors.primary),
        );
      } else {
        avatar = const Icon(Icons.person, size: 22, color: AppColors.primary);
      }
    } else {
      avatar = const Icon(Icons.person, size: 22, color: AppColors.primary);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.antiAlias,
              child: avatar,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    roleLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            if (isActive)
              const Icon(
                Icons.check_rounded,
                color: AppColors.primary,
                size: 20,
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9CA3AF),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

// ── _DrawerItem — updated to support optional badge ───────────────────────

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final String? badge; // 👈 NEW

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.badge, // 👈 NEW
  });

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? AppColors.textDark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color != null
                    ? color!.withValues(alpha: 0.1)
                    : AppColors.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: itemColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: itemColor,
                ),
              ),
            ),
            // 👇 NEW: red badge dot for urgent items
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge!,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
