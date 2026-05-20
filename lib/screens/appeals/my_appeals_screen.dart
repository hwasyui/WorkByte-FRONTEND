import 'package:workbyte_app/core/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/appeal_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/appeal_model.dart';

class MyAppealsScreen extends StatefulWidget {
  const MyAppealsScreen({super.key});

  @override
  State<MyAppealsScreen> createState() => _MyAppealsScreenState();
}

class _MyAppealsScreenState extends State<MyAppealsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token;
      if (token != null) context.read<AppealProvider>().fetchMyAppeals(token);
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final token = context.read<AuthProvider>().token;
    if (token != null)
      await context.read<AppealProvider>().fetchMyAppeals(token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF333333),
        elevation: 0,
        centerTitle: false,
        title: Text(
          'My Appeals',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: TabBar(
              controller: _tabCtrl,
              labelStyle: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
              labelColor: AppColors.primary,
              unselectedLabelColor: const Color(0xFF7D7D7D),
              indicatorColor: AppColors.primary,
              indicatorWeight: 2.5,
              tabs: const [
                Tab(text: 'Pending'),
                Tab(text: 'Resolved'),
                Tab(text: 'Account'),
              ],
            ),
          ),
        ),
      ),
      body: Consumer<AppealProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) return _buildSkeletonList();

          if (provider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEEEE),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.cloud_off_rounded,
                        color: Color(0xFFE53935),
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load appeals',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      provider.error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF7D7D7D),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _refresh,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Retry',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return TabBarView(
            controller: _tabCtrl,
            children: [
              _AppealList(
                appeals: provider.pendingAppeals,
                onRefresh: _refresh,
                emptyTitle: 'No pending appeals',
                emptySubtitle:
                    'Appeals you submit will appear here while under review.',
                emptyIcon: Icons.hourglass_empty_rounded,
              ),
              _AppealList(
                appeals: provider.resolvedAppeals,
                onRefresh: _refresh,
                emptyTitle: 'No resolved appeals',
                emptySubtitle:
                    'Appeals that have been reviewed will show here.',
                emptyIcon: Icons.task_alt_rounded,
              ),
              _AppealList(
                appeals: provider.accountAppeals,
                onRefresh: _refresh,
                emptyTitle: 'No account appeals',
                emptySubtitle:
                    'If your account is closed, you can submit an appeal here.',
                emptyIcon: Icons.account_circle_outlined,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const _AppealCardSkeleton(),
    );
  }
}

// ── Appeal list ───────────────────────────────────────────────────────────────
class _AppealList extends StatelessWidget {
  final List<AppealModel> appeals;
  final Future<void> Function() onRefresh;
  final String emptyTitle;
  final String emptySubtitle;
  final IconData emptyIcon;

  const _AppealList({
    required this.appeals,
    required this.onRefresh,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (appeals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(emptyIcon, color: AppColors.primary, size: 34),
              ),
              const SizedBox(height: 16),
              Text(
                emptyTitle,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                emptySubtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF7D7D7D),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: appeals.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _AppealCard(appeal: appeals[i]),
      ),
    );
  }
}

// ── Appeal card ───────────────────────────────────────────────────────────────
class _AppealCard extends StatelessWidget {
  final AppealModel appeal;
  const _AppealCard({required this.appeal});

  @override
  Widget build(BuildContext context) {
    final status = _StatusMeta.of(appeal.status);
    final isJobPost = appeal.targetType == 'job_post';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── colored header strip ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: status.bgColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isJobPost ? Icons.work_rounded : Icons.person_rounded,
                    size: 19,
                    color: status.accentColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isJobPost
                            ? (appeal.jobTitle ?? 'Job Post')
                            : 'Account Appeal',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: status.accentColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatDate(appeal.createdAt),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: status.accentColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: appeal.status, meta: status),
              ],
            ),
          ),

          // ── message body ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR MESSAGE',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF9E9E9E),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  appeal.message,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF333333),
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // ── admin note (resolved only) ──
          if (appeal.adminNote != null && appeal.adminNote!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: status.bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 15,
                      color: status.accentColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin Response',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: status.accentColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            appeal.adminNote!,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: status.accentColor.withValues(alpha: 0.85),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // ── actioned date ──
          if (appeal.actionedAt != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Resolved on ${_formatDate(appeal.actionedAt!)}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFF9E9E9E),
                ),
              ),
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  final _StatusMeta meta;
  const _StatusBadge({required this.status, required this.meta});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(meta.icon, size: 12, color: meta.accentColor),
          const SizedBox(width: 4),
          Text(
            meta.label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: meta.accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton card ─────────────────────────────────────────────────────────────
class _AppealCardSkeleton extends StatelessWidget {
  const _AppealCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 58,
            decoration: const BoxDecoration(
              color: Color(0xFFF0F0F0),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(width: double.infinity, height: 12),
                const SizedBox(height: 6),
                _SkeletonBox(width: 200, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  const _SkeletonBox({required this.width, required this.height});

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: const Color(0xFFF0F0F0),
      borderRadius: BorderRadius.circular(6),
    ),
  );
}

// ── Status metadata ───────────────────────────────────────────────────────────
class _StatusMeta {
  final String label;
  final Color bgColor;
  final Color accentColor;
  final IconData icon;

  const _StatusMeta({
    required this.label,
    required this.bgColor,
    required this.accentColor,
    required this.icon,
  });

  static _StatusMeta of(String status) {
    switch (status) {
      case 'approved':
        return const _StatusMeta(
          label: 'Approved',
          bgColor: Color(0xFFE8F5E9),
          accentColor: Color(0xFF2E7D32),
          icon: Icons.check_circle_rounded,
        );
      case 'rejected':
        return const _StatusMeta(
          label: 'Rejected',
          bgColor: Color(0xFFFFEBEE),
          accentColor: Color(0xFFB71C1C),
          icon: Icons.cancel_rounded,
        );
      default: // pending
        return _StatusMeta(
          label: 'Under Review',
          bgColor: AppColors.secondary,
          accentColor: AppColors.primary,
          icon: Icons.hourglass_top_rounded,
        );
    }
  }
}
