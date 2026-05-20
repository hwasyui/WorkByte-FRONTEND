import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../core/constants/colors.dart';
import '../../widgets/admin/admin_sidebar.dart';
import 'pages/admin_overview_page.dart';
import 'pages/admin_users_page.dart';
import 'pages/admin_jobs_page.dart';
import 'pages/admin_reports_page.dart';
import 'pages/admin_ai_page.dart';
import 'pages/admin_closed_page.dart';
import '../auth/login.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key});

  static const List<Widget> _pages = [
    AdminOverviewPage(),
    AdminUsersPage(),
    AdminJobsPage(),
    AdminReportsPage(),
    AdminAiPage(),
    AdminClosedPage(),
  ];

  static const List<String> _titles = [
    'Dashboard',
    'User Management',
    'Job Management',
    'Reports',
    'AI Analysis',
    'Closed Items',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        final idx = admin.currentPage.index;

        if (kIsWeb) {
          return Scaffold(
            backgroundColor: const Color(0xFFF3F4F6),
            body: Row(
              children: [
                const AdminSidebar(),
                Expanded(child: _pages[idx]),
              ],
            ),
          );
        }

        // Mobile: drawer-based layout
        return Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E1B4B),
            foregroundColor: Colors.white,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titles[idx],
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'WorkByte Admin',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: const Color(0xFF818CF8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                onPressed: () =>
                    context.read<AdminProvider>().loadOverviewData(),
                tooltip: 'Refresh',
              ),
            ],
          ),
          drawer: _MobileDrawer(
            selectedIndex: idx,
            onSelect: (i) => admin.setPage(AdminPage.values[i]),
          ),
          body: IndexedStack(index: idx, children: _pages),
        );
      },
    );
  }
}

class _MobileDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _MobileDrawer({required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFF1E1B4B),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WorkByte',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Admin Portal',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF818CF8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(
                  color: Colors.white.withOpacity(0.1),
                  height: 24,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                child: Text(
                  'NAVIGATION',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF818CF8),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              _DrawerItem(
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                isSelected: selectedIndex == 0,
                onTap: () {
                  onSelect(0);
                  Navigator.pop(context);
                },
              ),
              _DrawerItem(
                icon: Icons.people_rounded,
                label: 'Users',
                isSelected: selectedIndex == 1,
                onTap: () {
                  onSelect(1);
                  context.read<AdminProvider>().loadFreelancersPage(1);
                  context.read<AdminProvider>().loadClientsPage(1);
                  Navigator.pop(context);
                },
              ),
              _DrawerItem(
                icon: Icons.work_rounded,
                label: 'Jobs',
                isSelected: selectedIndex == 2,
                onTap: () {
                  onSelect(2);
                  context.read<AdminProvider>().loadJobsPage(1);
                  Navigator.pop(context);
                },
              ),
              _DrawerItem(
                icon: Icons.flag_rounded,
                label: 'Reports',
                isSelected: selectedIndex == 3,
                badge: context.read<AdminProvider>().pendingReports > 0
                    ? context.read<AdminProvider>().pendingReports
                    : null,
                onTap: () {
                  onSelect(3);
                  context.read<AdminProvider>().loadReports();
                  Navigator.pop(context);
                },
              ),
              _DrawerItem(
                icon: Icons.smart_toy_rounded,
                label: 'AI Analysis',
                isSelected: selectedIndex == 4,
                badge:
                    context.read<AdminProvider>().pendingScamFlags +
                            context
                                .read<AdminProvider>()
                                .pendingModerationItems >
                        0
                    ? context.read<AdminProvider>().pendingScamFlags +
                          context.read<AdminProvider>().pendingModerationItems
                    : null,
                onTap: () {
                  onSelect(4);
                  context.read<AdminProvider>().loadScamFlags();
                  context.read<AdminProvider>().loadModerationItems();
                  Navigator.pop(context);
                },
              ),
              _DrawerItem(
                icon: Icons.lock_clock_rounded,
                label: 'Closed Items',
                isSelected: selectedIndex == 5,
                onTap: () {
                  onSelect(5);
                  context.read<AdminProvider>().loadClosedJobs();
                  context.read<AdminProvider>().loadClosedAccounts();
                  Navigator.pop(context);
                },
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(
                  color: Colors.white.withOpacity(0.1),
                  height: 24,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  leading: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFF87171),
                    size: 20,
                  ),
                  title: Text(
                    'Logout',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFF87171),
                    ),
                  ),
                  onTap: () async {
                    await context.read<AdminProvider>().logout();
                    await context.read<AuthProvider>().logout(
                      profileProvider: context.read<ProfileProvider>(),
                    );
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? badge;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: isSelected
              ? BorderSide(color: const Color(0xFF6366F1).withOpacity(0.4))
              : BorderSide.none,
        ),
        tileColor: isSelected
            ? const Color(0xFF4F46E5).withOpacity(0.25)
            : Colors.transparent,
        leading: Icon(
          icon,
          size: 20,
          color: isSelected
              ? const Color(0xFF818CF8)
              : Colors.white.withOpacity(0.6),
        ),
        title: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.65),
          ),
        ),
        trailing: isSelected
            ? Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF818CF8),
                  shape: BoxShape.circle,
                ),
              )
            : badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge! > 99 ? '99+' : badge.toString(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
