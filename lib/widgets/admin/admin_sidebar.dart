import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        return Material(
          color: const Color(0xFF1E1B4B),
          child: Container(
            width: 240,
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo / Header
                Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WorkByte',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        Text(
                          'Admin Portal',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: const Color(0xFF818CF8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: Colors.white.withOpacity(0.1), height: 24),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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

              _NavItem(
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                page: AdminPage.overview,
                current: admin.currentPage,
                onTap: () => admin.setPage(AdminPage.overview),
              ),
              _NavItem(
                icon: Icons.people_rounded,
                label: 'Users',
                page: AdminPage.users,
                current: admin.currentPage,
                onTap: () {
                  admin.setPage(AdminPage.users);
                  admin.loadFreelancersPage(1);
                },
              ),
              _NavItem(
                icon: Icons.work_rounded,
                label: 'Jobs',
                page: AdminPage.jobs,
                current: admin.currentPage,
                onTap: () {
                  admin.setPage(AdminPage.jobs);
                  admin.loadJobsPage(1);
                },
              ),
              _NavItem(
                icon: Icons.flag_rounded,
                label: 'Reports',
                page: AdminPage.reports,
                current: admin.currentPage,
                badge: admin.pendingReports > 0 ? admin.pendingReports : null,
                onTap: () {
                  admin.setPage(AdminPage.reports);
                  admin.loadReports();
                },
              ),
              _NavItem(
                icon: Icons.smart_toy_rounded,
                label: 'AI Analysis',
                page: AdminPage.ai,
                current: admin.currentPage,
                badge: (admin.pendingScamFlags + admin.pendingModerationItems) > 0
                    ? admin.pendingScamFlags + admin.pendingModerationItems
                    : null,
                onTap: () {
                  admin.setPage(AdminPage.ai);
                  admin.loadScamFlags();
                  admin.loadModerationItems();
                },
              ),

              const Spacer(),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: Colors.white.withOpacity(0.1), height: 24),
              ),

              // Logout
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                child: InkWell(
                  onTap: () async {
                    await admin.logout();
                    // AdminGate otomatis menampilkan AdminLoginScreen
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          color: const Color(0xFFF87171),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Logout',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFF87171),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final AdminPage page;
  final AdminPage current;
  final VoidCallback onTap;
  final int? badge;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.page,
    required this.current,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = page == current;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF4F46E5).withOpacity(0.25)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isActive
                ? Border.all(color: const Color(0xFF6366F1).withOpacity(0.4))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive
                    ? const Color(0xFF818CF8)
                    : Colors.white.withOpacity(0.6),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive
                      ? Colors.white
                      : Colors.white.withOpacity(0.65),
                ),
              ),
              const Spacer(),
              if (badge != null && !isActive)
                Container(
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
              else if (isActive)
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF818CF8),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
