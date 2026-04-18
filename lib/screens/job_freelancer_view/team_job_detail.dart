import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../models/job_post_model.dart';
import '../../models/job_role_model.dart';
import '../../models/client_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/job_post_service.dart';
import '../../widgets/job_detail_header.dart';
import '../../widgets/job_detail_tab_bar.dart';
import '../../widgets/role_card.dart';
import '../../widgets/bidding_bottom_sheet.dart';

class TeamJobDetailScreen extends StatefulWidget {
  final JobPostModel job;

  const TeamJobDetailScreen({super.key, required this.job});

  @override
  State<TeamJobDetailScreen> createState() => _TeamJobDetailScreenState();
}

class _TeamJobDetailScreenState extends State<TeamJobDetailScreen> {
  int _selectedTab = 0;

  ClientModel? _client;
  bool _clientLoading = true;
  List<JobRoleModel> _roles = [];
  bool _rolesLoading = true;

  List<String> get _tabs => [
    'Details',
    'Terms',
    'Bidding (${widget.job.proposalCount})',
  ];

  List<String> get _tags {
    final tags = <String>[];
    if (widget.job.deadline != null) tags.add(widget.job.deadline!);
    if (widget.job.workingDays != null) {
      tags.add('${widget.job.workingDays} days');
    }
    tags.add(_capitalize(widget.job.projectScope));
    if (widget.job.experienceLevel != null) {
      tags.add(_capitalize(widget.job.experienceLevel!));
    }
    return tags;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchClient();
      _fetchRoles();
    });
  }

  Future<void> _fetchClient() async {
    final token = context.read<AuthProvider>().token!;
    final client = await context.read<ProfileProvider>().fetchClientById(
      token: token,
      clientId: widget.job.clientId,
    );
    if (mounted)
      setState(() {
        _client = client;
        _clientLoading = false;
      });
  }

  Future<void> _fetchRoles() async {
    final token = context.read<AuthProvider>().token!;

    try {
      // Fetch directly from service — bypass shared provider state
      final roles = await JobPostService().getJobRoles(
        token,
        widget.job.jobPostId,
      );
      debugPrint('Fetched ${roles.length} roles for ${widget.job.jobPostId}');
      if (mounted) {
        setState(() {
          _roles = roles;
          _rolesLoading = false;
        });
      }
    } catch (e) {
      debugPrint('_fetchRoles error: $e');
      if (mounted) {
        setState(() => _rolesLoading = false);
      }
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _formatBudget(JobRoleModel role) {
    if (role.roleBudget == null) return 'Negotiable';
    return 'Rp. ${role.roleBudget!.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Teal header ──────────────────────────────────────────
            JobDetailHeader(
              companyLogo: _client?.profilePictureUrl != null
                  ? ClipOval(
                      child: Image.network(
                        _client!.profilePictureUrl!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(
                      Icons.business,
                      size: 40,
                      color: Color(0xFF00AAA8),
                    ),
              posterName: _clientLoading
                  ? '...'
                  : (_client?.displayName ?? 'Client'),
              username: _clientLoading
                  ? ''
                  : (_client?.websiteUrl ??
                        '#${widget.job.clientId.substring(0, 8)}'),
              jobTitle: widget.job.jobTitle,
              category: _capitalize(widget.job.projectScope),
              tags: _tags,
            ),

            // ── Tab bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(27, 20, 27, 0),
              child: JobDetailTabBar(
                tabs: _tabs,
                selectedIndex: _selectedTab,
                onTabSelected: (i) => setState(() => _selectedTab = i),
              ),
            ),

            // ── Tab content ──────────────────────────────────────────
            if (_selectedTab == 0) _buildDetailsTab(),
            if (_selectedTab == 1) _buildTermsTab(),
            if (_selectedTab == 2) _buildPlaceholderTab('Bidding'),
          ],
        ),
      ),
    );
  }

  // ── Details tab ────────────────────────────────────────────────────────────
  Widget _buildDetailsTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(27, 20, 27, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Description'),
          const SizedBox(height: 12),
          Text(
            widget.job.jobDescription,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF333333),
              height: 20 / 13,
            ),
          ),

          if (_client?.bio != null) ...[
            const SizedBox(height: 28),
            _sectionTitle('About the Client'),
            const SizedBox(height: 8),
            Text(
              _client!.bio!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF7D7D7D),
                height: 18 / 12,
              ),
            ),
          ],

          const SizedBox(height: 28),
          _sectionTitle('Roles'),
          const SizedBox(height: 12),

          // ── Roles list ───────────────────────────────────────────
          if (_rolesLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(color: Color(0xFF00AAA8)),
              ),
            )
          else if (_roles.isEmpty)
            Text(
              'No roles listed for this job.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF7D7D7D),
              ),
            )
          else
            ...List.generate(_roles.length, (i) {
              final role = _roles[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: RoleCard(
                  roleTitle: role.roleTitle,
                  roleDescription:
                      role.roleDescription ?? 'No description provided.',
                  salary: _formatBudget(role),
                  onApply: () => showBiddingBottomSheet(context),
                ),
              );
            }),
        ],
      ),
    );
  }

  // ── Terms tab ──────────────────────────────────────────────────────────────
  Widget _buildTermsTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(27, 20, 27, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _termRow('Project Type', _capitalize(widget.job.projectType)),
          _termRow('Project Scope', _capitalize(widget.job.projectScope)),
          if (widget.job.workingDays != null)
            _termRow('Working Days', '${widget.job.workingDays} days'),
          if (widget.job.deadline != null)
            _termRow('Deadline', widget.job.deadline!),
          if (widget.job.estimatedDuration != null)
            _termRow('Estimated Duration', widget.job.estimatedDuration!),
          if (widget.job.experienceLevel != null)
            _termRow(
              'Experience Level',
              _capitalize(widget.job.experienceLevel!),
            ),
          if (widget.job.postedAt != null)
            _termRow('Posted At', _formatDate(widget.job.postedAt!)),
          if (_client != null) ...[
            const SizedBox(height: 8),
            _sectionTitle('Client Info'),
            const SizedBox(height: 12),
            _termRow('Name', _client!.displayName),
            _termRow('Jobs Posted', _client!.totalJobsPosted.toString()),
            _termRow(
              'Projects Completed',
              _client!.totalProjectsCompleted.toString(),
            ),
            if (_client!.averageRatingGiven != null)
              _termRow(
                'Avg Rating Given',
                _client!.averageRatingGiven!.toStringAsFixed(1),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholderTab(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          '$label content coming soon',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: const Color(0xFF7D7D7D),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: GoogleFonts.poppins(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF333333),
    ),
  );

  Widget _termRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF7D7D7D),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
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
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }
}
