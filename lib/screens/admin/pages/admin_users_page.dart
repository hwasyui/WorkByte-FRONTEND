import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/admin_provider.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _freelancerPage = 1;
  int _clientPage = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final admin = context.read<AdminProvider>();
      admin.loadFreelancersPage(1);
      admin.loadClientsPage(1);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        return Column(
          children: [
            // Summary chips
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  _SummaryChip(
                    label: 'Total',
                    value: admin.totalUsers.toString(),
                    color: const Color(0xFF4F46E5),
                  ),
                  const SizedBox(width: 8),
                  _SummaryChip(
                    label: 'Freelancers',
                    value: admin.totalFreelancers.toString(),
                    color: const Color(0xFF059669),
                  ),
                  const SizedBox(width: 8),
                  _SummaryChip(
                    label: 'Clients',
                    value: admin.totalClients.toString(),
                    color: const Color(0xFF0891B2),
                  ),
                ],
              ),
            ),

            // Tab bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF4F46E5),
                unselectedLabelColor: const Color(0xFF6B7280),
                indicatorColor: const Color(0xFF4F46E5),
                labelStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
                tabs: [
                  Tab(text: 'Freelancers (${admin.totalFreelancers})'),
                  Tab(text: 'Clients (${admin.totalClients})'),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _UsersList(
                    users: admin.tableFreelancers,
                    isLoading: admin.isTableLoading,
                    type: 'Freelancer',
                    color: const Color(0xFF059669),
                    pagination: admin.freelancerPagination,
                    currentPage: _freelancerPage,
                    onPageChange: (p) {
                      setState(() => _freelancerPage = p);
                      admin.loadFreelancersPage(p);
                    },
                    subtitleBuilder: (u) {
                      final rate = u['estimated_rate'];
                      if (rate == null) return 'Rate not set';
                      final currency = u['rate_currency'] ?? 'USD';
                      final time = u['rate_time'] ?? 'hr';
                      return '$currency ${rate.toString()} / $time';
                    },
                  ),
                  _UsersList(
                    users: admin.tableClients,
                    isLoading: admin.isTableLoading,
                    type: 'Client',
                    color: const Color(0xFF0891B2),
                    pagination: admin.clientPagination,
                    currentPage: _clientPage,
                    onPageChange: (p) {
                      setState(() => _clientPage = p);
                      admin.loadClientsPage(p);
                    },
                    subtitleBuilder: (u) {
                      final posted = u['total_jobs_posted'] ?? 0;
                      final completed = u['total_projects_completed'] ?? 0;
                      return '$posted jobs posted · $completed completed';
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _UsersList extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  final bool isLoading;
  final String type;
  final Color color;
  final Map<String, dynamic> pagination;
  final int currentPage;
  final ValueChanged<int> onPageChange;
  final String Function(Map<String, dynamic>) subtitleBuilder;

  const _UsersList({
    required this.users,
    required this.isLoading,
    required this.type,
    required this.color,
    required this.pagination,
    required this.currentPage,
    required this.onPageChange,
    required this.subtitleBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
      );
    }

    if (users.isEmpty) {
      return Center(
        child: Text(
          'No ${type.toLowerCase()}s found',
          style: GoogleFonts.poppins(color: const Color(0xFF9CA3AF)),
        ),
      );
    }

    final total = (pagination['total'] as num?)?.toInt() ?? 0;
    final totalPages = (pagination['total_pages'] as num?)?.toInt() ?? 1;

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _UserCard(
              user: users[i],
              type: type,
              color: color,
              subtitleBuilder: subtitleBuilder,
            ),
          ),
        ),

        // Pagination
        if (totalPages > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$total total',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: currentPage > 1
                          ? () => onPageChange(currentPage - 1)
                          : null,
                      color: const Color(0xFF4F46E5),
                      iconSize: 20,
                    ),
                    Text(
                      '$currentPage / $totalPages',
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: currentPage < totalPages
                          ? () => onPageChange(currentPage + 1)
                          : null,
                      color: const Color(0xFF4F46E5),
                      iconSize: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final String type;
  final Color color;
  final String Function(Map<String, dynamic>) subtitleBuilder;

  const _UserCard({
    required this.user,
    required this.type,
    required this.color,
    required this.subtitleBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final name = (user['full_name'] as String?)?.isNotEmpty == true
        ? user['full_name'] as String
        : 'Unknown';
    final joined = _fmt(user['created_at']?.toString());

    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        barrierColor: Colors.black54,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          clipBehavior: Clip.antiAlias,
          child: _UserDetailSheet(user: user, type: type, color: color),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(0.12),
              child: Text(
                name[0].toUpperCase(),
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: color),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF111827)),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitleBuilder(user),
                    style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            Text(joined, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF9CA3AF))),
          ],
        ),
      ),
    );
  }
}

class _UserDetailSheet extends StatefulWidget {
  final Map<String, dynamic> user;
  final String type;
  final Color color;

  const _UserDetailSheet({required this.user, required this.type, required this.color});

  @override
  State<_UserDetailSheet> createState() => _UserDetailSheetState();
}

class _UserDetailSheetState extends State<_UserDetailSheet> {
  bool _closing = false;
  bool _loadingProfile = false;
  Map<String, dynamic>? _fullProfile;

  String get _userId => (widget.user['user_id'] ?? widget.user['id'])?.toString() ?? '';
  String get _freelancerId => widget.user['freelancer_id']?.toString() ?? '';
  bool get _isFreelancer => widget.type == 'Freelancer';

  @override
  void initState() {
    super.initState();
    if (_isFreelancer && _freelancerId.isNotEmpty) {
      _loadFullProfile();
    }
  }

  Future<void> _loadFullProfile() async {
    setState(() => _loadingProfile = true);
    final profile = await context.read<AdminProvider>().loadFreelancerFullProfile(_freelancerId);
    if (mounted) setState(() { _fullProfile = profile; _loadingProfile = false; });
  }

  Future<void> _handleClose() async {
    if (_userId.isEmpty) return;
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Close Account?', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will restrict the user\'s account. They will no longer be able to access the platform.',
                style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF6B7280)),
              ),
              const SizedBox(height: 16),
              Text(
                'Reason / message for user *',
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                onChanged: (_) => setDlgState(() {}),
                style: GoogleFonts.poppins(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. Violation of community guidelines…',
                  hintStyle: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF9CA3AF)),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFDC2626))),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF6B7280))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: reasonCtrl.text.trim().isEmpty
                    ? const Color(0xFFDC2626).withOpacity(0.4)
                    : const Color(0xFFDC2626),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              onPressed: reasonCtrl.text.trim().isEmpty ? null : () => Navigator.pop(ctx, true),
              child: Text('Close Account', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _closing = true);
    final ok = await context.read<AdminProvider>().adminCloseAccount(
      _userId,
      reason: reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim(),
    );
    if (mounted) {
      setState(() => _closing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Account closed successfully' : 'Failed to close account', style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: ok ? const Color(0xFF059669) : const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      if (ok) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final fp = _fullProfile;
    final freelancer = fp != null ? (fp['freelancer'] as Map<String, dynamic>? ?? user) : user;
    final name = (freelancer['full_name'] as String?)?.isNotEmpty == true ? freelancer['full_name'] as String : 'Unknown';
    final email = freelancer['email'] as String? ?? user['email'] as String? ?? '';
    final bio = freelancer['bio'] as String? ?? '';
    final joined = _fmt(freelancer['created_at']?.toString() ?? user['created_at']?.toString());

    final skills = fp != null ? (fp['skills'] as List? ?? []) : [];
    final specialities = fp != null ? (fp['specialities'] as List? ?? []) : [];
    final education = fp != null ? (fp['education'] as List? ?? []) : [];
    final workExp = fp != null ? (fp['work_experience'] as List? ?? []) : [];
    final portfolio = fp != null ? (fp['portfolio'] as List? ?? []) : [];
    final totalRatings = fp != null ? (fp['total_ratings'] as num?)?.toInt() ?? 0 : 0;
    final avgRating = fp != null ? (fp['average_rating'] as num?)?.toDouble() : null;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // dialog drag handle / close row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              children: [
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF6B7280)),
                  splashRadius: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: [
                // ── Profile header ──────────────────────────────────────
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: widget.color.withOpacity(0.12),
                      child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: widget.color)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
                          if (email.isNotEmpty)
                            Text(email, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6B7280))),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: widget.color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text(widget.type, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: widget.color)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 5),
                    Text('Joined $joined', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6B7280))),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: Color(0xFFF3F4F6)),

                // ── FREELANCER details ───────────────────────────────────
                if (_isFreelancer) ...[
                  if (_loadingProfile) ...[
                    const SizedBox(height: 24),
                    const Center(child: CircularProgressIndicator(color: Color(0xFF059669), strokeWidth: 2)),
                    const SizedBox(height: 8),
                    Center(child: Text('Loading full profile...', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF9CA3AF)))),
                  ] else ...[
                    // Rate
                    if (freelancer['estimated_rate'] != null) ...[
                      const SizedBox(height: 14),
                      _UserSectionLabel('RATE'),
                      const SizedBox(height: 4),
                      Text(
                        '${freelancer['rate_currency'] ?? 'USD'} ${freelancer['estimated_rate']} / ${freelancer['rate_time'] ?? 'hourly'}',
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
                      ),
                    ],
                    // Rating stats
                    if (totalRatings > 0) ...[
                      const SizedBox(height: 14),
                      _UserSectionLabel('RATING'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.star_rounded, size: 18, color: const Color(0xFFFACC15)),
                          const SizedBox(width: 4),
                          Text(
                            avgRating != null ? avgRating.toStringAsFixed(1) : '-',
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                          ),
                          const SizedBox(width: 6),
                          Text('($totalRatings review${totalRatings == 1 ? '' : 's'})', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF9CA3AF))),
                        ],
                      ),
                    ],
                    // Bio
                    if (bio.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _UserSectionLabel('BIO'),
                      const SizedBox(height: 4),
                      Text(bio, style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF374151), height: 1.5)),
                    ],
                    // Skills
                    if (skills.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _UserSectionLabel('SKILLS (${skills.length})'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: (skills as List).map((s) {
                          final m = s as Map;
                          final skillName = m['skill_name']?.toString() ?? '';
                          final level = m['proficiency_level']?.toString() ?? '';
                          final levelColor = level == 'expert' ? const Color(0xFF7C3AED) : level == 'advanced' ? const Color(0xFF059669) : level == 'intermediate' ? const Color(0xFF0891B2) : const Color(0xFF9CA3AF);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: levelColor.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: levelColor.withOpacity(0.25))),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(skillName, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF374151))),
                                if (level.isNotEmpty) ...[
                                  const SizedBox(width: 4),
                                  Text('· $level', style: GoogleFonts.poppins(fontSize: 10, color: levelColor)),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    // Specialities
                    if (specialities.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _UserSectionLabel('SPECIALITIES'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: (specialities as List).map((s) {
                          final m = s as Map;
                          final isPrimary = m['is_primary'] as bool? ?? false;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPrimary ? const Color(0xFF4F46E5).withOpacity(0.08) : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(20),
                              border: isPrimary ? Border.all(color: const Color(0xFF4F46E5).withOpacity(0.3)) : null,
                            ),
                            child: Text(m['speciality_name']?.toString() ?? '', style: GoogleFonts.poppins(fontSize: 12, fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w400, color: isPrimary ? const Color(0xFF4F46E5) : const Color(0xFF374151))),
                          );
                        }).toList(),
                      ),
                    ],
                    // Work Experience
                    if (workExp.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _UserSectionLabel('WORK EXPERIENCE (${workExp.length})'),
                      const SizedBox(height: 8),
                      ...(workExp as List).map((e) {
                        final m = e as Map;
                        final isCurrent = m['is_current'] as bool? ?? false;
                        final start = _fmtDate(m['start_date']?.toString());
                        final end = isCurrent ? 'Present' : _fmtDate(m['end_date']?.toString());
                        return _ProfileEntry(
                          title: m['job_title']?.toString() ?? '',
                          subtitle: m['company_name']?.toString() ?? '',
                          meta: '$start – $end${(m['location'] as String?)?.isNotEmpty == true ? ' · ${m['location']}' : ''}',
                          description: m['description']?.toString(),
                          iconColor: const Color(0xFF0891B2),
                          icon: Icons.work_outline_rounded,
                        );
                      }),
                    ],
                    // Education
                    if (education.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _UserSectionLabel('EDUCATION (${education.length})'),
                      const SizedBox(height: 8),
                      ...(education as List).map((e) {
                        final m = e as Map;
                        final isCurrent = m['is_current'] as bool? ?? false;
                        final start = _fmtDate(m['start_date']?.toString());
                        final end = isCurrent ? 'Present' : _fmtDate(m['end_date']?.toString());
                        final field = (m['field_of_study'] as String?)?.isNotEmpty == true ? ' · ${m['field_of_study']}' : '';
                        final grade = (m['grade'] as String?)?.isNotEmpty == true ? ' · GPA ${m['grade']}' : '';
                        return _ProfileEntry(
                          title: m['degree']?.toString() ?? '',
                          subtitle: m['institution_name']?.toString() ?? '',
                          meta: '$start – $end$field$grade',
                          description: m['description']?.toString(),
                          iconColor: const Color(0xFF7C3AED),
                          icon: Icons.school_outlined,
                        );
                      }),
                    ],
                    // Portfolio
                    if (portfolio.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _UserSectionLabel('PORTFOLIO (${portfolio.length})'),
                      const SizedBox(height: 8),
                      ...(portfolio as List).map((p) {
                        final m = p as Map;
                        final url = m['project_url'] as String?;
                        final date = _fmtDate(m['completion_date']?.toString());
                        return _ProfileEntry(
                          title: m['project_title']?.toString() ?? '',
                          subtitle: url ?? '',
                          meta: date != '-' ? 'Completed $date' : '',
                          description: m['project_description']?.toString(),
                          iconColor: const Color(0xFFD97706),
                          icon: Icons.folder_outlined,
                        );
                      }),
                    ],
                  ],
                ] else ...[
                  // ── CLIENT details ────────────────────────────────────
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _UserSectionLabel('BIO'),
                    const SizedBox(height: 4),
                    Text(bio, style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF374151), height: 1.5)),
                  ],
                  if ((user['company_name'] as String?)?.isNotEmpty == true) ...[
                    const SizedBox(height: 14),
                    _UserSectionLabel('COMPANY'),
                    const SizedBox(height: 4),
                    Text(user['company_name'] as String, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF111827))),
                  ],
                  if ((user['company_description'] as String?)?.isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    Text(user['company_description'] as String, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6B7280), height: 1.5)),
                  ],
                  if ((user['website_url'] as String?)?.isNotEmpty == true) ...[
                    const SizedBox(height: 14),
                    _UserSectionLabel('WEBSITE'),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.link_rounded, size: 14, color: Color(0xFF0891B2)),
                        const SizedBox(width: 6),
                        Expanded(child: Text(user['website_url'] as String, style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF0891B2)), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _UserStatChip(icon: Icons.work_outline_rounded, label: 'Jobs Posted', value: '${user['total_jobs_posted'] ?? 0}'),
                      const SizedBox(width: 16),
                      _UserStatChip(icon: Icons.check_circle_outline_rounded, label: 'Completed', value: '${user['total_projects_completed'] ?? 0}'),
                      if ((user['average_rating_given'] as num?) != null) ...[
                        const SizedBox(width: 16),
                        _UserStatChip(icon: Icons.star_outline_rounded, label: 'Avg Rating', value: (user['average_rating_given'] as num).toStringAsFixed(1)),
                      ],
                    ],
                  ),
                ],

                // ── Close button ─────────────────────────────────────────
                const SizedBox(height: 28),
                const Divider(color: Color(0xFFF3F4F6)),
                const SizedBox(height: 16),
                _closing
                    ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFFDC2626), strokeWidth: 2)))
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _handleClose,
                          icon: const Icon(Icons.person_off_rounded, size: 16),
                          label: Text('Close Account', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(String? d) {
    if (d == null || d.isEmpty) return '-';
    try {
      final dt = DateTime.parse(d);
      return '${dt.month}/${dt.year}';
    } catch (_) { return d.split('T').first; }
  }
}

class _ProfileEntry extends StatelessWidget {
  final String title;
  final String subtitle;
  final String meta;
  final String? description;
  final Color iconColor;
  final IconData icon;

  const _ProfileEntry({
    required this.title,
    required this.subtitle,
    required this.meta,
    this.description,
    required this.iconColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: iconColor.withOpacity(0.12)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF111827))),
                  if (subtitle.isNotEmpty)
                    Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6B7280))),
                  if (meta.isNotEmpty)
                    Text(meta, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF9CA3AF))),
                  if ((description ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(description!, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF4B5563), height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserSectionLabel extends StatelessWidget {
  final String text;
  const _UserSectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF9CA3AF), letterSpacing: 0.5));
  }
}

class _UserStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _UserStatChip({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: const Color(0xFF9CA3AF)),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF9CA3AF))),
          ],
        ),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
      ],
    );
  }
}

String _fmt(String? dateStr) {
  if (dateStr == null) return '-';
  try {
    final dt = DateTime.parse(dateStr);
    return '${dt.day}/${dt.month}/${dt.year}';
  } catch (_) {
    return '-';
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$value ',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            TextSpan(
              text: label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
