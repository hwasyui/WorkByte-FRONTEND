import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../core/constants/admin_colors.dart';
import 'admin_dialog.dart';

class AdminSidebar extends StatelessWidget {
  /// When true, renders a narrow icon-only rail (for tablet-width screens)
  /// instead of the full 240px sidebar with text labels.
  final bool collapsed;

  const AdminSidebar({super.key, this.collapsed = false});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        final width = collapsed ? 76.0 : 240.0;

        final header = collapsed
            ? Padding(
                padding: const EdgeInsets.fromLTRB(0, 32, 0, 8),
                child: Center(
                  child: Image.asset(
                    'assets/workbyte-logo.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/workbyte-logo.png',
                      width: 36,
                      height: 36,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
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
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Admin Portal',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: const Color(0xFF818CF8),
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );

        final logoutRow = Tooltip(
          message: collapsed ? 'Logout' : '',
          child: InkWell(
            onTap: () async {
              final confirmed = await showAdminConfirmDialog(
                context,
                title: 'Log Out?',
                message: 'You will need to sign in again to access the admin dashboard.',
                icon: Icons.logout_rounded,
                confirmLabel: 'Log Out',
                confirmColor: const Color(0xFFDC2626),
              );
              if (confirmed == true) {
                await admin.logout();
              }
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              child: collapsed
                  ? const Center(
                      child: Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFF87171),
                        size: 20,
                      ),
                    )
                  : Row(
                      children: [
                        const Icon(
                          Icons.logout_rounded,
                          color: Color(0xFFF87171),
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
        );

        return Material(
          color: AdminColors.navy,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: width,
            decoration: const BoxDecoration(gradient: AdminColors.sidebarGradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,

                const SizedBox(height: 8),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(
                    color: Colors.white.withOpacity(0.1),
                    height: 24,
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!collapsed) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
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
                        ],

                        _NavItem(
                          icon: Icons.dashboard_rounded,
                          label: 'Dashboard',
                          page: AdminPage.overview,
                          current: admin.currentPage,
                          collapsed: collapsed,
                          onTap: () => admin.setPage(AdminPage.overview),
                        ),
                        _NavItem(
                          icon: Icons.people_rounded,
                          label: 'Users',
                          page: AdminPage.users,
                          current: admin.currentPage,
                          collapsed: collapsed,
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
                          collapsed: collapsed,
                          onTap: () {
                            admin.setPage(AdminPage.jobs);
                            admin.loadJobsPage(1);
                          },
                        ),
                        _NavItem(
                          icon: Icons.report_problem_rounded,
                          label: 'Reports',
                          page: AdminPage.reports,
                          current: admin.currentPage,
                          collapsed: collapsed,
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
                          collapsed: collapsed,
                          badge:
                              (admin.pendingScamFlags + admin.pendingModerationItems) >
                                  0
                              ? admin.pendingScamFlags + admin.pendingModerationItems
                              : null,
                          onTap: () {
                            admin.setPage(AdminPage.ai);
                            admin.loadScamFlags();
                            admin.loadModerationItems();
                          },
                        ),
                        _NavItem(
                          icon: Icons.lock_clock_rounded,
                          label: 'Closed Items',
                          page: AdminPage.closed,
                          current: admin.currentPage,
                          collapsed: collapsed,
                          onTap: () {
                            admin.setPage(AdminPage.closed);
                            admin.loadClosedJobs();
                            admin.loadClosedAccounts();
                          },
                        ),
                        _NavItem(
                          icon: Icons.gavel_rounded,
                          label: 'Appeals',
                          page: AdminPage.appeals,
                          current: admin.currentPage,
                          collapsed: collapsed,
                          badge: admin.pendingAppeals > 0 ? admin.pendingAppeals : null,
                          onTap: () {
                            admin.setPage(AdminPage.appeals);
                            admin.loadAppeals(status: 'all');
                          },
                        ),
                        _NavItem(
                          icon: Icons.balance_rounded,
                          label: 'Disputes',
                          page: AdminPage.disputes,
                          current: admin.currentPage,
                          collapsed: collapsed,
                          badge: admin.pendingDisputesCount > 0
                              ? admin.pendingDisputesCount
                              : null,
                          onTap: () {
                            admin.setPage(AdminPage.disputes);
                            admin.loadDisputedContracts();
                          },
                        ),
                      ],
                    ),
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
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  child: logoutRow,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final AdminPage page;
  final AdminPage current;
  final VoidCallback onTap;
  final int? badge;
  final bool collapsed;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.page,
    required this.current,
    required this.onTap,
    this.badge,
    this.collapsed = false,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final icon = widget.icon;
    final label = widget.label;
    final badge = widget.badge;
    final collapsed = widget.collapsed;
    final isActive = widget.page == widget.current;

    final plainIcon = Icon(
      icon,
      size: 20,
      color: isActive
          ? const Color(0xFF818CF8)
          : Colors.white.withOpacity(0.6),
    );

    // Only the collapsed rail needs a badge stacked on the icon itself
    // (there's no room for the full pill there); the expanded sidebar
    // already shows the count as a trailing pill, so don't double it up.
    final iconWithBadge = Stack(
      clipBehavior: Clip.none,
      children: [
        plainIcon,
        if (badge != null && !isActive)
          Positioned(
            top: -4,
            right: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              constraints: const BoxConstraints(minWidth: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AdminColors.navy, width: 1.5),
              ),
              child: Text(
                badge! > 9 ? '9+' : badge.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );

    final content = collapsed
        ? Center(child: iconWithBadge)
        : Row(
            children: [
              plainIcon,
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive
                        ? Colors.white
                        : Colors.white.withOpacity(0.65),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badge != null && !isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge > 99 ? '99+' : badge.toString(),
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
          );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: collapsed ? 8 : 12, vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: Tooltip(
          message: collapsed ? label : '',
          waitDuration: const Duration(milliseconds: 300),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: EdgeInsets.symmetric(
                horizontal: collapsed ? 0 : 12,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF4F46E5).withOpacity(0.25)
                    : _hovering
                        ? Colors.white.withOpacity(0.06)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: isActive
                    ? Border.all(color: const Color(0xFF6366F1).withOpacity(0.4))
                    : null,
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
