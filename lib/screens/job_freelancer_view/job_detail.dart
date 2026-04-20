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
import '../../services/api_service.dart';
import '../../widgets/job_detail_header.dart';
import '../../widgets/job_detail_tab_bar.dart';
import '../../widgets/role_card.dart';
import 'submit_proposal.dart';

class JobDetailScreen extends StatefulWidget {
  final JobPostModel job;

  const JobDetailScreen({super.key, required this.job});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  int _selectedTab = 0;
  ClientModel? _client;
  bool _clientLoading = true;
  List<JobRoleModel> _roles = [];
  bool _rolesLoading = true;
  bool _analyzing = false;

  bool get _isTeam => widget.job.projectType.toLowerCase() == 'team';

  List<String> get _tabs => [
    'Details',
    'Terms',
    'Bidding (${widget.job.proposalCount})',
  ];

  List<String> get _tags {
    final tags = <String>[];
    tags.add(_isTeam ? 'Team' : 'Individual');
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
    if (mounted) {
      setState(() {
        _client = client;
        _clientLoading = false;
      });
    }
  }

  Future<void> _fetchRoles() async {
    final token = context.read<AuthProvider>().token!;
    try {
      final roles = await JobPostService().getJobRoles(
        token,
        widget.job.jobPostId,
      );
      if (mounted) {
        setState(() {
          _roles = roles;
          _rolesLoading = false;
        });
      }
    } catch (e) {
      debugPrint('_fetchRoles error: $e');
      if (mounted) setState(() => _rolesLoading = false);
    }
  }

  Future<void> _analyzeJob() async {
    setState(() => _analyzing = true);
    final token = context.read<AuthProvider>().token!;
    final result = await ApiService.analyzeJobMatch(token, widget.job.jobPostId);
    if (!mounted) return;
    setState(() => _analyzing = false);
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Analysis failed. Please try again.')),
      );
      return;
    }
    _showAnalysisSheet(result);
  }

  void _showAnalysisSheet(Map<String, dynamic> result) {
    final overallScore = (result['overall_match_score'] as num?)?.toInt() ?? 0;
    final recommendation = result['overall_recommendation'] as String? ?? '';
    final reason = result['overall_recommendation_reason'] as String? ?? '';
    final roles = (result['roles'] as List?) ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header ──
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Color(0xFF00AAA8), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'AI Match Analysis',
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF333333)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Overall score ──
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FAFA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF00AAA8).withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Overall Match',
                                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF7D7D7D)),
                                ),
                                const Spacer(),
                                _ScoreBadge(score: overallScore),
                                const SizedBox(width: 8),
                                _RecommendationChip(recommendation: recommendation),
                              ],
                            ),
                            if (reason.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(reason, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF555555), height: 1.5)),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Per-role breakdown ──
                      if (roles.isNotEmpty) ...[
                        Text('Role Breakdown', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF333333))),
                        const SizedBox(height: 12),
                        ...roles.map((r) => _buildRoleAnalysis(Map<String, dynamic>.from(r))),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleAnalysis(Map<String, dynamic> role) {
    final title = role['role_title'] as String? ?? 'Role';
    final score = (role['match_score'] as num?)?.toInt() ?? 0;
    final rec = role['recommendation'] as String? ?? '';
    final recReason = role['recommendation_reason'] as String? ?? '';
    String _str(dynamic e) => e is String ? e : (e is Map ? (e['point'] ?? e['text'] ?? e['description'] ?? e.values.first)?.toString() ?? '' : e.toString());
    final matched = (role['matching_skills'] as List? ?? []).map(_str).where((s) => s.isNotEmpty).toList();
    final missing = (role['missing_required_skills'] as List? ?? []).map(_str).where((s) => s.isNotEmpty).toList();
    final strengths = (role['strengths'] as List? ?? []).map(_str).where((s) => s.isNotEmpty).toList();
    final gaps = (role['gaps'] as List? ?? []).map(_str).where((s) => s.isNotEmpty).toList();
    final tips = (role['skill_tips'] as List? ?? []).map(_str).where((s) => s.isNotEmpty).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF333333))),
              ),
              _ScoreBadge(score: score),
              const SizedBox(width: 8),
              _RecommendationChip(recommendation: rec),
            ],
          ),
          if (recReason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(recReason, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF7D7D7D), height: 1.5)),
          ],
          if (matched.isNotEmpty) ...[
            const SizedBox(height: 12),
            _analysisLabel('Matching Skills'),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: matched.map((s) => _SkillChip(label: s, matched: true)).toList()),
          ],
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 12),
            _analysisLabel('Missing Required Skills'),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: missing.map((s) => _SkillChip(label: s, matched: false)).toList()),
          ],
          if (strengths.isNotEmpty) ...[
            const SizedBox(height: 12),
            _analysisLabel('Strengths'),
            const SizedBox(height: 6),
            ...strengths.map((s) => _bulletItem(s, color: const Color(0xFF00AAA8))),
          ],
          if (gaps.isNotEmpty) ...[
            const SizedBox(height: 8),
            _analysisLabel('Gaps'),
            const SizedBox(height: 6),
            ...gaps.map((s) => _bulletItem(s, color: const Color(0xFFEF4444))),
          ],
          if (tips.isNotEmpty) ...[
            const SizedBox(height: 8),
            _analysisLabel('Skill Tips'),
            const SizedBox(height: 6),
            ...tips.map((s) => _bulletItem(s, color: const Color(0xFFF59E0B))),
          ],
        ],
      ),
    );
  }

  Widget _analysisLabel(String text) => Text(
    text,
    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF7D7D7D)),
  );

  Widget _bulletItem(String text, {required Color color}) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF555555), height: 1.5))),
      ],
    ),
  );

  Widget _buildAnalyzeButton() {
    return GestureDetector(
      onTap: _analyzing ? null : _analyzeJob,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF00AAA8),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_analyzing)
              const SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
              )
            else
              const Icon(Icons.auto_awesome, size: 11, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              _analyzing ? 'Analyzing...' : 'Analyze',
              style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  void _onApplyRole(JobRoleModel role) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubmitProposalScreen(job: widget.job, role: role),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _formatBudget(JobRoleModel role) {
    if (role.roleBudget == null) return 'Negotiable';
    return '${role.budgetCurrency} ${role.roleBudget!.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────
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
              username: _clientLoading ? '' : (_client?.websiteUrl ?? ''),
              jobTitle: widget.job.jobTitle,
              category: _capitalize(widget.job.projectScope),
              tags: _tags,
              titleTrailing: Consumer<ProfileProvider>(
                builder: (context, profile, _) {
                  if (profile.isClient) return const SizedBox.shrink();
                  return _buildAnalyzeButton();
                },
              ),
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
            if (_selectedTab == 2) _buildBiddingTab(),
          ],
        ),
      ),
    );
  }

  // ── Details tab ──────────────────────────────────────────────────────────
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
          // ── Section title changes based on type ──────────────────
          _sectionTitle(_isTeam ? 'Roles' : 'Role'),
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
                  onApply: () => _onApplyRole(role),
                ),
              );
            }),

        ],
      ),
    );
  }

  // ── Terms tab ────────────────────────────────────────────────────────────
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

  // ── Bidding tab ──────────────────────────────────────────────────────────
  Widget _buildBiddingTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          'Bidding content coming soon',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: const Color(0xFF7D7D7D),
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
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

// ── Score badge ──────────────────────────────────────────────────────────────
class _ScoreBadge extends StatelessWidget {
  final int score;
  const _ScoreBadge({required this.score});

  Color get _color {
    if (score >= 65) return const Color(0xFF00AAA8);
    if (score >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$score%',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _color),
      ),
    );
  }
}

// ── Recommendation chip ───────────────────────────────────────────────────────
class _RecommendationChip extends StatelessWidget {
  final String recommendation;
  const _RecommendationChip({required this.recommendation});

  Color get _color {
    switch (recommendation.toLowerCase()) {
      case 'apply': return const Color(0xFF00AAA8);
      case 'consider': return const Color(0xFFF59E0B);
      default: return const Color(0xFFEF4444);
    }
  }

  String get _label {
    switch (recommendation.toLowerCase()) {
      case 'apply': return 'Apply';
      case 'consider': return 'Consider';
      default: return 'Skip';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Text(
        _label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _color),
      ),
    );
  }
}

// ── Skill chip ───────────────────────────────────────────────────────────────
class _SkillChip extends StatelessWidget {
  final String label;
  final bool matched;
  const _SkillChip({required this.label, required this.matched});

  @override
  Widget build(BuildContext context) {
    final color = matched ? const Color(0xFF00AAA8) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color),
      ),
    );
  }
}
