import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../models/job_post_model.dart';
import '../../models/job_role_model.dart';
import '../../models/job_role_skill_model.dart';
import '../../models/skill_model.dart';
import '../../models/client_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/saved_items_provider.dart';
import '../../providers/job_post_provider.dart';
import '../../providers/skill_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/job_detail_header.dart';
import '../../widgets/job_detail_tab_bar.dart';
import '../freelancer_profile/freelancer_profile.dart';
import '../people_list/people_list_screen.dart';
import 'submit_proposal.dart';

class JobDetailScreen extends StatefulWidget {
  final JobPostModel job;

  const JobDetailScreen({super.key, required this.job});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  static const Color _primary = AppColors.primary;

  int _selectedTab = 0;
  ClientModel? _client;
  bool _clientLoading = true;
  List<JobRoleModel> _roles = [];
  bool _rolesLoading = true;
  bool _analyzing = false;

  Map<String, List<JobRoleSkillModel>> _roleSkillsMap = {};
  List<SkillModel> _allSkills = [];

  bool get _isTeam => widget.job.projectType.toLowerCase() == 'team';

  List<String> get _tabs => [
    'Details',
    'Terms',
    'Bidding (${widget.job.proposalCount})',
  ];

  List<String> get _tags {
    final tags = <String>[];
    if (widget.job.deadline != null) tags.add(widget.job.deadline!);
    tags.add(_capitalize(widget.job.projectType));
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
      _fetchAllSkills();
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
      final provider = context.read<JobPostProvider>();

      await provider.fetchJobRoles(token, widget.job.jobPostId);

      if (!mounted) return;

      setState(() {
        _roles = provider.jobRoles;
        _rolesLoading = false;
      });

      await _fetchRoleSkills(token);
    } catch (e) {
      debugPrint('_fetchRoles error: $e');
      if (mounted) setState(() => _rolesLoading = false);
    }
  }

  Future<void> _fetchRoleSkills(String token) async {
    final provider = context.read<JobPostProvider>();

    for (final role in _roles) {
      await provider.fetchRoleSkills(token, role.jobRoleId);
    }

    if (!mounted) return;

    setState(() {
      _roleSkillsMap = {
        for (final role in _roles)
          role.jobRoleId: provider.skillsForRole(role.jobRoleId),
      };
    });
  }

  Future<void> _fetchAllSkills() async {
    final token = context.read<AuthProvider>().token!;
    await context.read<SkillProvider>().fetchAllSkills(token);

    if (!mounted) return;

    setState(() {
      _allSkills = context.read<SkillProvider>().skills;
    });
  }

  Future<void> _analyzeJob() async {
    setState(() => _analyzing = true);
    final token = context.read<AuthProvider>().token!;
    final result = await ApiService.analyzeJobMatch(
      token,
      widget.job.jobPostId,
    );

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
                  color: AppColors.secondary,
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
                      Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AI Match Analysis',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FAFA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Overall Match',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF7D7D7D),
                                  ),
                                ),
                                const Spacer(),
                                _ScoreBadge(score: overallScore),
                                const SizedBox(width: 8),
                                _RecommendationChip(
                                  recommendation: recommendation,
                                ),
                              ],
                            ),
                            if (reason.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                reason,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF555555),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (roles.isNotEmpty) ...[
                        Text(
                          'Role Breakdown',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...roles.map(
                          (r) =>
                              _buildRoleAnalysis(Map<String, dynamic>.from(r)),
                        ),
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

    String _str(dynamic e) => e is String
        ? e
        : (e is Map
              ? (e['point'] ?? e['text'] ?? e['description'] ?? e.values.first)
                        ?.toString() ??
                    ''
              : e.toString());

    final matched = (role['matching_skills'] as List? ?? [])
        .map(_str)
        .where((s) => s.isNotEmpty)
        .toList();

    final missing = (role['missing_required_skills'] as List? ?? [])
        .map(_str)
        .where((s) => s.isNotEmpty)
        .toList();

    final strengths = (role['strengths'] as List? ?? [])
        .map(_str)
        .where((s) => s.isNotEmpty)
        .toList();

    final gaps = (role['gaps'] as List? ?? [])
        .map(_str)
        .where((s) => s.isNotEmpty)
        .toList();

    final tips = (role['skill_tips'] as List? ?? [])
        .map(_str)
        .where((s) => s.isNotEmpty)
        .toList();

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
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF333333),
                  ),
                ),
              ),
              _ScoreBadge(score: score),
              const SizedBox(width: 8),
              _RecommendationChip(recommendation: rec),
            ],
          ),
          if (recReason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              recReason,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF7D7D7D),
                height: 1.5,
              ),
            ),
          ],
          if (matched.isNotEmpty) ...[
            const SizedBox(height: 12),
            _analysisLabel('Matching Skills'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: matched
                  .map((s) => _SkillChip(label: s, matched: true))
                  .toList(),
            ),
          ],
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 12),
            _analysisLabel('Missing Required Skills'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: missing
                  .map((s) => _SkillChip(label: s, matched: false))
                  .toList(),
            ),
          ],
          if (strengths.isNotEmpty) ...[
            const SizedBox(height: 12),
            _analysisLabel('Strengths'),
            const SizedBox(height: 6),
            ...strengths.map((s) => _bulletItem(s, color: AppColors.primary)),
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
    style: GoogleFonts.poppins(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF7D7D7D),
    ),
  );

  Widget _bulletItem(String text, {required Color color}) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFF555555),
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildAnalyzeButton() {
    return GestureDetector(
      onTap: _analyzing ? null : _analyzeJob,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_analyzing)
              const SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Colors.white,
                ),
              )
            else
              const Icon(Icons.auto_awesome, size: 11, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              _analyzing ? 'Analyzing...' : 'Analyze',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onApplyRole(JobRoleModel role) {
    final profile = context.read<ProfileProvider>();
    if (!profile.isProfileComplete) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Profile Incomplete',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          content: Text(
            'Please complete your profile before applying to jobs.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF7D7D7D),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: const Color(0xFF7D7D7D)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              child: Text(
                'Complete Now',
                style: GoogleFonts.poppins(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubmitProposalScreen(job: widget.job, role: role),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    final saved = context.watch<SavedItemsProvider>();
    final profile = context.watch<ProfileProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            JobDetailHeader(
              companyLogo: _client?.profilePictureUrl != null
                  ? ClipOval(
                      child: Image.network(
                        _client!.profilePictureUrl!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.business,
                            size: 32,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.business,
                        size: 32,
                        color: AppColors.primary,
                      ),
                    ),
              posterName: _clientLoading
                  ? '...'
                  : (_client?.displayName ?? 'Client'),
              username: _clientLoading ? '' : (_client?.websiteUrl ?? ''),
              jobTitle: widget.job.jobTitle,
              category: _capitalize(widget.job.projectCategory),
              tags: _tags,
              bookmarked: saved.isJobSaved(widget.job.jobPostId),
              onBookmark: () => saved.toggleSaveJob(widget.job),
              titleTrailing: profile.isClient ? null : _buildAnalyzeButton(),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(27, 20, 27, 0),
              child: JobDetailTabBar(
                tabs: _tabs,
                selectedIndex: _selectedTab,
                onTabSelected: (i) => setState(() => _selectedTab = i),
              ),
            ),

            if (_selectedTab == 0) _buildDetailsTab(),
            if (_selectedTab == 1) _buildTermsTab(),
            if (_selectedTab == 2) _buildBiddingTab(),
          ],
        ),
      ),
    );
  }

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
          if (_client != null) ...[
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(child: _sectionTitle('About the Client')),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PeopleProfileScreen(isClient: true, client: _client),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'View Profile',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _client!.bio?.isNotEmpty == true
                  ? _client!.bio!
                  : 'No client bio available.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF7D7D7D),
                height: 18 / 12,
              ),
            ),
          ],
          const SizedBox(height: 28),
          _sectionTitle(_isTeam ? 'Roles' : 'Role'),
          const SizedBox(height: 12),
          _buildRolesSection(),
        ],
      ),
    );
  }

  Widget _buildTermsTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(27, 20, 27, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Project Terms'),
          const SizedBox(height: 12),
          _termCard(
            children: [
              _termRow('Project Type', _capitalize(widget.job.projectType)),
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
            ],
          ),
          if (_client != null) ...[
            const SizedBox(height: 24),
            _sectionTitle('Client Info'),
            const SizedBox(height: 12),
            _termCard(
              children: [
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
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBiddingTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(27, 20, 27, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Bidding'),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFEEEEF5)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Bidding content coming soon',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF7D7D7D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRolesSection() {
    if (_rolesLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_roles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No roles specified.',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFF7D7D7D),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(children: _roles.map((r) => _buildRoleCard(r)).toList());
  }

  Widget _buildRoleCard(JobRoleModel role) {
    final skills = _roleSkillsMap[role.jobRoleId] ?? [];
    final skillLookup = {for (final s in _allSkills) s.skillId: s};

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F0F1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.work_outline,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role.roleTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _miniChip(
                            role.isRequired ? 'Required' : 'Optional',
                            role.isRequired
                                ? _primary
                                : const Color(0xFF7D7D7D),
                          ),
                          _miniChip(
                            role.budgetType == 'hourly'
                                ? 'Hourly'
                                : role.budgetType == 'negotiable'
                                ? 'Negotiable'
                                : 'Fixed',
                            const Color(0xFF7D7D7D),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      role.roleBudget != null
                          ? '${role.budgetCurrency} ${_formatNumber(role.roleBudget!)}'
                          : 'Negotiable',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                    ),
                    if (role.roleBudget != null)
                      Text(
                        role.budgetType == 'hourly'
                            ? '/hour'
                            : role.budgetType == 'negotiable'
                            ? 'Negotiable'
                            : 'fixed',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: const Color(0xFF7D7D7D),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (role.roleDescription != null &&
                role.roleDescription!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                role.roleDescription!,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF7D7D7D),
                  height: 1.6,
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(color: Color(0xFFF0F0F1), height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.group_outlined,
                  size: 14,
                  color: Color(0xFF7D7D7D),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${role.positionsAvailable} position${role.positionsAvailable > 1 ? 's' : ''} available',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF7D7D7D),
                    ),
                  ),
                ),
                if (role.positionsFilled > 0)
                  Text(
                    '${role.positionsFilled} filled',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: _primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Required Skills',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            if (skills.isEmpty)
              Text(
                'No specific skills listed.',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFFB5B4B4),
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: skills.map((s) {
                  final skill = skillLookup[s.skillId];
                  final name = skill?.skillName ?? s.skillId;
                  final importance = s.importanceLevel;
                  final isRequired = s.isRequired;
                  return _skillChip(name, isRequired, importance);
                }).toList(),
              ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _onApplyRole(role),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Apply for Role',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
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

  Widget _termCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFEEEEF5)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _termRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
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

  Widget _miniChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _skillChip(String label, bool isRequired, String? importance) {
    final color = isRequired ? _primary : const Color(0xFF7D7D7D);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Text(
        importance != null && importance.isNotEmpty
            ? '$label · ${_capitalize(importance)}'
            : label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  String _formatNumber(num value) {
    final str = value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
    final parts = str.split('.');
    final whole = parts[0];
    final buffer = StringBuffer();

    for (int i = 0; i < whole.length; i++) {
      final reverseIndex = whole.length - i;
      buffer.write(whole[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write(',');
      }
    }

    if (parts.length > 1 && parts[1] != '00') {
      return '${buffer.toString()}.${parts[1]}';
    }

    return buffer.toString();
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

class _ScoreBadge extends StatelessWidget {
  final int score;
  const _ScoreBadge({required this.score});

  Color get _color {
    if (score >= 65) return AppColors.primary;
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
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _color,
        ),
      ),
    );
  }
}

class _RecommendationChip extends StatelessWidget {
  final String recommendation;
  const _RecommendationChip({required this.recommendation});

  Color get _color {
    switch (recommendation.toLowerCase()) {
      case 'apply':
        return AppColors.primary;
      case 'consider':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFFEF4444);
    }
  }

  String get _label {
    switch (recommendation.toLowerCase()) {
      case 'apply':
        return 'Apply';
      case 'consider':
        return 'Consider';
      default:
        return 'Skip';
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
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;
  final bool matched;
  const _SkillChip({required this.label, required this.matched});

  @override
  Widget build(BuildContext context) {
    final color = matched ? AppColors.primary : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
