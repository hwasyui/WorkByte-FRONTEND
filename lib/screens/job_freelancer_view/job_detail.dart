import 'package:workbyte_app/core/constants/colors.dart';
import 'package:workbyte_app/models/client_model.dart';
import 'package:workbyte_app/models/job_file_model.dart';
import 'package:workbyte_app/models/job_post_model.dart';
import 'package:workbyte_app/models/job_role_model.dart';
import 'package:workbyte_app/models/job_role_skill_model.dart';
import 'package:workbyte_app/models/proposal_model.dart';
import 'package:workbyte_app/models/skill_model.dart';
import 'package:workbyte_app/providers/auth_provider.dart';
import 'package:workbyte_app/providers/job_post_provider.dart';
import 'package:workbyte_app/providers/profile_provider.dart';
import 'package:workbyte_app/providers/proposal_provider.dart';
import 'package:workbyte_app/providers/saved_items_provider.dart';
import 'package:workbyte_app/providers/skill_provider.dart';
import 'package:workbyte_app/services/api_service.dart';
import 'package:workbyte_app/services/auth_service.dart';
import 'package:workbyte_app/widgets/appeal_dialog.dart';
import 'package:workbyte_app/widgets/job_detail_header.dart';
import 'package:workbyte_app/widgets/job_detail_tab_bar.dart';
import 'package:workbyte_app/widgets/report_sheet.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../freelancer_profile/freelancer_profile.dart';
import '../people_list/people_list_screen.dart';
import 'submit_proposal.dart';
import '../../core/utils/helpers.dart';

class JobDetailScreen extends StatefulWidget {
  final JobPostModel job;
  const JobDetailScreen({super.key, required this.job});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  static const Color primary = AppColors.primary;

  int selectedTab = 0;
  ClientModel? client;
  bool clientLoading = true;
  List<JobRoleModel> roles = [];
  bool rolesLoading = true;
  bool analyzing = false;
  bool _analysisCancelled = false;
  Map<String, List<JobRoleSkillModel>> roleSkillsMap = {};
  List<SkillModel> allSkills = [];

  List<ProposalModel> myProposals = [];
  bool proposalsLoading = true;

  List<JobFileModel> _jobFiles = [];
  bool _filesLoading = true;

  bool get isTeam => widget.job.projectType.toLowerCase() == 'team';

  List<String> get tabs => [
    'Details',
    'Terms',
    'Bidding (${widget.job.proposalCount})',
  ];

  List<String> get tags {
    final tags = <String>[];
    if (widget.job.deadline != null) tags.add(widget.job.deadline!);
    tags.add(capitalize(widget.job.projectType));
    if (widget.job.experienceLevel != null) {
      tags.add(capitalize(widget.job.experienceLevel!));
    }
    return tags;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchClient();
      fetchRoles();
      fetchAllSkills();
      fetchMyProposals();
      fetchJobFiles();
    });
  }

  Future<void> fetchJobFiles() async {
    final token = context.read<AuthProvider>().token!;
    await context.read<JobPostProvider>().fetchJobFiles(
      token,
      widget.job.jobPostId,
    );
    if (!mounted) return;
    setState(() {
      _jobFiles = context.read<JobPostProvider>().filesForJob(
        widget.job.jobPostId,
      );
      _filesLoading = false;
    });
  }

  Future<void> fetchClient() async {
    final token = context.read<AuthProvider>().token!;
    final client = await context.read<ProfileProvider>().fetchClientById(
      token: token,
      clientId: widget.job.clientId,
    );
    if (mounted) {
      setState(() {
        this.client = client;
        clientLoading = false;
      });
    }
  }

  Future<void> fetchRoles() async {
    final token = context.read<AuthProvider>().token!;
    try {
      final provider = context.read<JobPostProvider>();
      await provider.fetchJobRoles(token, widget.job.jobPostId);
      if (!mounted) return;
      setState(() {
        roles = provider.jobRoles;
        rolesLoading = false;
      });
      await fetchRoleSkills(token);
    } catch (e) {
      debugPrint('fetchRoles error: $e');
      if (mounted) setState(() => rolesLoading = false);
    }
  }

  Future<void> fetchRoleSkills(String token) async {
    final provider = context.read<JobPostProvider>();
    for (final role in roles) {
      await provider.fetchRoleSkills(token, role.jobRoleId);
    }
    if (!mounted) return;
    setState(() {
      roleSkillsMap = {
        for (final role in roles)
          role.jobRoleId: provider.skillsForRole(role.jobRoleId),
      };
    });
  }

  Future<void> fetchAllSkills() async {
    final token = context.read<AuthProvider>().token!;
    await context.read<SkillProvider>().fetchAllSkills(token);
    if (!mounted) return;
    setState(() => allSkills = context.read<SkillProvider>().skills);
  }

  Future<void> fetchMyProposals() async {
    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();

    if (auth.token == null || profile.freelancerProfile == null) {
      if (mounted) {
        setState(() {
          myProposals = [];
          proposalsLoading = false;
        });
      }
      return;
    }

    try {
      await context.read<ProposalProvider>().fetchProposalsByFreelancer(
        token: auth.token!,
        freelancerId: profile.freelancerProfile!.freelancerId,
      );

      if (!mounted) return;

      setState(() {
        myProposals = context.read<ProposalProvider>().proposals;
        proposalsLoading = false;
      });
    } catch (e) {
      debugPrint('fetchMyProposals error: $e');
      if (mounted) {
        setState(() {
          myProposals = [];
          proposalsLoading = false;
        });
      }
    }
  }

  Future<void> openJobFile(JobFileModel file) async {
    final token = context.read<AuthProvider>().token;
    await openDocumentFromUrl(
      context,
      file.fileUrl,
      token: token,
      fileName: file.fileName,
      onRefreshToken: () async {
        final ok = await context.read<AuthProvider>().tryRefresh();
        return ok ? context.read<AuthProvider>().token : null;
      },
    );
  }

  Future<void> analyzeJob() async {
    _analysisCancelled = false;
    setState(() => analyzing = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => _AnalysisLoadingDialog(
        onCancel: () {
          _analysisCancelled = true;
          setState(() => analyzing = false);
          Navigator.of(context, rootNavigator: true).pop();
        },
      ),
    );

    final token = context.read<AuthProvider>().token!;
    Map<String, dynamic>? result;
    try {
      result = await ApiService.analyzeJobMatch(token, widget.job.jobPostId);
    } on SessionExpiredException {
      if (!mounted) return;
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      setState(() => analyzing = false);
      await context.read<AuthProvider>().handleSessionExpired(
        profileProvider: context.read<ProfileProvider>(),
      );
      return;
    }

    if (!mounted) return;
    if (_analysisCancelled) return;

    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    setState(() => analyzing = false);

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Analysis failed. Please try again.')),
      );
      return;
    }
    showAnalysisSheet(result);
  }

  void showAnalysisSheet(Map<String, dynamic> result) {
    final overallScore = (result['overall_match_score'] as num?)?.toInt() ?? 0;
    final recommendation = result['overall_recommendation'] as String? ?? '';
    final reason = result['overall_recommendation_reason'] as String? ?? '';
    final roles = result['roles'] as List? ?? [];

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
                            color: AppColors.primary.withValues(alpha: 0.3),
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
                                ScoreBadge(score: overallScore),
                                const SizedBox(width: 8),
                                RecommendationChip(
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
                              buildRoleAnalysis(Map<String, dynamic>.from(r)),
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

  Widget buildRoleAnalysis(Map<String, dynamic> role) {
    final title = role['role_title'] as String? ?? 'Role';
    final score = (role['match_score'] as num?)?.toInt() ?? 0;
    final rec = role['recommendation'] as String? ?? '';
    final recReason = role['recommendation_reason'] as String? ?? '';

    String str(dynamic e) => e is String
        ? e
        : e is Map
        ? (e['point'] ?? e['text'] ?? e['description'] ?? e.values.first)
                  ?.toString() ??
              e.toString()
        : e.toString();

    final matched = (role['matching_skills'] as List? ?? [])
        .map(str)
        .where((s) => s.isNotEmpty)
        .toList();
    final missing = (role['missing_required_skills'] as List? ?? [])
        .map(str)
        .where((s) => s.isNotEmpty)
        .toList();
    final strengths = (role['strengths'] as List? ?? [])
        .map(str)
        .where((s) => s.isNotEmpty)
        .toList();
    final gaps = (role['gaps'] as List? ?? [])
        .map(str)
        .where((s) => s.isNotEmpty)
        .toList();
    final tips = (role['skill_tips'] as List? ?? [])
        .map(str)
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
              ScoreBadge(score: score),
              const SizedBox(width: 8),
              RecommendationChip(recommendation: rec),
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
            analysisLabel('Matching Skills'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: matched
                  .map((s) => SkillChip(label: s, matched: true))
                  .toList(),
            ),
          ],
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 12),
            analysisLabel('Missing Required Skills'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: missing
                  .map((s) => SkillChip(label: s, matched: false))
                  .toList(),
            ),
          ],
          if (strengths.isNotEmpty) ...[
            const SizedBox(height: 12),
            analysisLabel('Strengths'),
            const SizedBox(height: 6),
            ...strengths.map((s) => bulletItem(s, color: AppColors.primary)),
          ],
          if (gaps.isNotEmpty) ...[
            const SizedBox(height: 8),
            analysisLabel('Gaps'),
            const SizedBox(height: 6),
            ...gaps.map((s) => bulletItem(s, color: const Color(0xFFEF4444))),
          ],
          if (tips.isNotEmpty) ...[
            const SizedBox(height: 8),
            analysisLabel('Skill Tips'),
            const SizedBox(height: 6),
            ...tips.map((s) => bulletItem(s, color: const Color(0xFFF59E0B))),
          ],
        ],
      ),
    );
  }

  Widget analysisLabel(String text) => Text(
    text,
    style: GoogleFonts.poppins(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF7D7D7D),
    ),
  );

  Widget bulletItem(String text, {required Color color}) => Padding(
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

  Widget buildAnalyzeButton() => GestureDetector(
    onTap: analyzing ? null : analyzeJob,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: analyzing
            ? AppColors.primary.withValues(alpha: 0.5)
            : AppColors.primary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            'Analyze',
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

  void onApplyRole(JobRoleModel role) {
    if (hasAppliedToThisJobPost(widget.job.jobPostId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have already applied to this job.')),
      );
      return;
    }

    if (isRoleFilled(role)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This role is already full.')),
      );
      return;
    }

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

  String capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  /// Converts snake_case closure reason from backend into a readable label.
  String _formatClosureReason(String reason) {
    const labels = {
      'spam': 'Spam',
      'scam': 'Scam / Fraud',
      'inappropriate_content': 'Inappropriate Content',
      'duplicate': 'Duplicate Listing',
      'policy_violation': 'Policy Violation',
      'other': 'Other',
    };
    return labels[reason.toLowerCase()] ??
        capitalize(reason.replaceAll('_', ' '));
  }

  bool hasAppliedToThisJobPost(String jobPostId) {
    return myProposals.any((p) => p.jobPostId == jobPostId);
  }

  bool hasAppliedToThisRole(String jobRoleId) {
    return myProposals.any((p) => p.jobRoleId == jobRoleId);
  }

  bool isRoleFilled(JobRoleModel role) {
    return role.positionsFilled >= role.positionsAvailable;
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final saved = context.watch<SavedItemsProvider>();
    final profile = context.watch<ProfileProvider>();
    final auth = context.watch<AuthProvider>();
    final proposalProvider = context.watch<ProposalProvider>();
    // NEW: self-ownership + closed status flags
    final isOwnJob = auth.userId != null && auth.userId == widget.job.clientId;
    final isClosed = widget.job.status?.toLowerCase() == 'closed';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            JobDetailHeader(
              companyLogo: client?.profilePictureUrl != null
                  ? ClipOval(
                      child: Image.network(
                        client!.profilePictureUrl!,
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
              posterName: clientLoading
                  ? '...'
                  : client?.displayName ?? 'Client',
              username: clientLoading ? '' : client?.websiteUrl ?? '',
              jobTitle: widget.job.jobTitle,
              category: capitalize(widget.job.projectCategory),
              tags: tags,
              bookmarked: saved.isJobSaved(widget.job.jobPostId),
              onBookmark: () => saved.toggleSaveJob(widget.job),
              titleTrailing: profile.isClient ? null : buildAnalyzeButton(),
              // 👇 NEW: pass null for own jobs so flag icon is hidden
              onReport: isOwnJob
                  ? null
                  : () => ReportSheet.show(
                      context,
                      reportedType: 'job_post',
                      jobPostId: widget.job.jobPostId,
                      targetName: widget.job.jobTitle,
                    ),
            ),

            // 👇 Closed job appeal banner — only for the owner
            if (isClosed && isOwnJob)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFFCC02).withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3CD),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.gavel_rounded,
                          color: Color(0xFFF57F17),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Title row with closed-at date ──
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'This job post has been closed',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF5D4037),
                                    ),
                                  ),
                                ),
                                if (widget.job.closedAt != null)
                                  Text(
                                    formatDate(widget.job.closedAt!),
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: const Color(0xFF9E9E9E),
                                    ),
                                  ),
                              ],
                            ),

                            // ── Closure reason badge ──
                            if (widget.job.closureReason != null &&
                                widget.job.closureReason!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFE0B2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _formatClosureReason(
                                    widget.job.closureReason!,
                                  ),
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFE65100),
                                  ),
                                ),
                              ),
                            ],

                            // ── Closure note (admin message) ──
                            if (widget.job.closureNote != null &&
                                widget.job.closureNote!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                widget.job.closureNote!,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF7D7D7D),
                                  height: 1.4,
                                ),
                              ),
                            ],

                            const SizedBox(height: 10),

                            // ── Appeal CTA ──
                            GestureDetector(
                              onTap: () => AppealDialog.show(
                                context,
                                targetType: 'job_post',
                                targetId: widget.job.jobPostId,
                                targetLabel: widget.job.jobTitle,
                                closureNote:
                                    widget.job.closureNote ??
                                    widget.job.closureReason,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF57F17),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Submit an Appeal',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Tab bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(27, 20, 27, 0),
              child: JobDetailTabBar(
                tabs: tabs,
                selectedIndex: selectedTab,
                onTabSelected: (i) => setState(() => selectedTab = i),
              ),
            ),

            // ── Tab content ──────────────────────────────────────────
            if (selectedTab == 0) buildDetailsTab(),
            if (selectedTab == 1) buildTermsTab(),
            if (selectedTab == 2) buildBiddingTab(),
          ],
        ),
      ),
    );
  }

  // ── Tab: Details ───────────────────────────────────────────────────────────
  Widget buildDetailsTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(27, 20, 27, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle('Description'),
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
          if (client != null) ...[
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(child: sectionTitle('About the Client')),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PeopleProfileScreen(isClient: true, client: client),
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
              client!.bio?.isNotEmpty == true
                  ? client!.bio!
                  : 'No client bio available.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF7D7D7D),
                height: 18 / 12,
              ),
            ),
          ],
          const SizedBox(height: 28),
          sectionTitle(isTeam ? 'Roles & Skills' : 'Role & Skills'),
          const SizedBox(height: 12),
          buildRolesSection(),
          if (!_filesLoading && _jobFiles.isNotEmpty) ...[
            const SizedBox(height: 28),
            sectionTitle('Attachments (${_jobFiles.length})'),
            const SizedBox(height: 12),
            ..._jobFiles.map((f) => buildJobFileRow(f)),
          ],
        ],
      ),
    );
  }

  // ── Tab: Terms ─────────────────────────────────────────────────────────────
  Widget buildTermsTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(27, 20, 27, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle('Project Terms'),
          const SizedBox(height: 12),
          termCard(
            children: [
              termRow('Project Type', capitalize(widget.job.projectType)),
              if (widget.job.workingDays != null)
                termRow('Working Days', '${widget.job.workingDays} days'),
              if (widget.job.deadline != null)
                termRow('Deadline', widget.job.deadline!),
              if (widget.job.estimatedDuration != null)
                termRow('Estimated Duration', widget.job.estimatedDuration!),
              if (widget.job.experienceLevel != null)
                termRow(
                  'Experience Level',
                  capitalize(widget.job.experienceLevel!),
                ),
              if (widget.job.postedAt != null)
                termRow('Posted At', formatDate(widget.job.postedAt!)),
            ],
          ),
          if (client != null) ...[
            const SizedBox(height: 24),
            sectionTitle('Client Info'),
            const SizedBox(height: 12),
            termCard(
              children: [
                termRow('Name', client!.displayName),
                termRow('Jobs Posted', client!.totalJobsPosted.toString()),
                termRow(
                  'Projects Completed',
                  client!.totalProjectsCompleted.toString(),
                ),
                if (client!.averageRatingGiven != null)
                  termRow(
                    'Avg Rating Given',
                    client!.averageRatingGiven!.toStringAsFixed(1),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Tab: Bidding ───────────────────────────────────────────────────────────
  Widget buildBiddingTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(27, 20, 27, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle('Bidding'),
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

  // ── Roles section ──────────────────────────────────────────────────────────
  Widget buildRolesSection() {
    if (rolesLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (roles.isEmpty) {
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

    return Column(children: roles.map((r) => buildRoleCard(r)).toList());
  }

  Widget buildRoleCard(JobRoleModel role) {
    final skills = roleSkillsMap[role.jobRoleId] ?? [];
    final skillLookup = {for (final s in allSkills) s.skillId: s};

    final alreadyAppliedToJob = hasAppliedToThisJobPost(widget.job.jobPostId);
    final alreadyAppliedToRole = hasAppliedToThisRole(role.jobRoleId);
    final roleFilled = isRoleFilled(role);

    final disableApply = proposalsLoading || alreadyAppliedToJob || roleFilled;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F0F1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                    color: primary.withValues(alpha: 0.1),
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
                          miniChip(
                            role.isRequired ? 'Required' : 'Optional',
                            role.isRequired ? primary : const Color(0xFF7D7D7D),
                          ),
                          miniChip(
                            role.budgetType == 'hourly'
                                ? 'Hourly'
                                : role.budgetType == 'negotiable'
                                ? 'Negotiable'
                                : 'Fixed',
                            const Color(0xFF7D7D7D),
                          ),
                          if (roleFilled)
                            miniChip('Filled', const Color(0xFFD32F2F)),
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
                          ? '${role.budgetCurrency} ${formatNumber(role.roleBudget!)}'
                          : 'Negotiable',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                    if (role.roleBudget != null)
                      Text(
                        role.budgetType == 'hourly'
                            ? '/ hour'
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
                    '${role.positionsAvailable} position${role.positionsAvailable != 1 ? 's' : ''} available',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF7D7D7D),
                    ),
                  ),
                ),
                Text(
                  '${role.positionsFilled} filled',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: roleFilled ? const Color(0xFFD32F2F) : primary,
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
                  return skillChip(name, s.isRequired, s.importanceLevel);
                }).toList(),
              ),

            // Only freelancers see the apply button
            if (!context.read<ProfileProvider>().isClient) ...[
              const SizedBox(height: 14),
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  if (auth.isReportBanned) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFEF9A9A).withValues(alpha: 0.6),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.gavel_rounded,
                            color: Color(0xFFC62828),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your account is restricted. You cannot apply for roles.',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFFC62828),
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => AppealDialog.show(
                              context,
                              targetType: 'user',
                              targetId: auth.userId!,
                              targetLabel: 'Account Restriction',
                              closureNote: auth.banMessage,
                            ).then((_) => auth.refreshUser()),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC62828),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Appeal',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: disableApply
                              ? null
                              : () => onApplyRole(role),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor: const Color(0xFFE0E0E0),
                            disabledForegroundColor: const Color(0xFF9E9E9E),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            proposalsLoading
                                ? 'Loading...'
                                : roleFilled
                                ? 'Role Filled'
                                : alreadyAppliedToJob
                                ? 'Applied'
                                : 'Apply for Role',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      if (roleFilled) ...[
                        const SizedBox(height: 8),
                        Text(
                          'All positions for this role have been filled.',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF7D7D7D),
                          ),
                        ),
                      ] else if (alreadyAppliedToRole) ...[
                        const SizedBox(height: 8),
                        Text(
                          'You applied for this role.',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ] else if (alreadyAppliedToJob) ...[
                        const SizedBox(height: 8),
                        Text(
                          'You already applied for another role in this job.',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF7D7D7D),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildJobFileRow(JobFileModel file) {
    final IconData icon;
    switch (file.fileTypeIcon) {
      case 'pdf':
        icon = Icons.picture_as_pdf_outlined;
      case 'image':
        icon = Icons.image_outlined;
      case 'word':
        icon = Icons.description_outlined;
      case 'archive':
        icon = Icons.folder_zip_outlined;
      default:
        icon = Icons.attach_file;
    }

    return GestureDetector(
      onTap: () => openJobFile(file),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.fileName,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (file.fileSizeFormatted.isNotEmpty)
                    Text(
                      '${file.fileType.toUpperCase()} · ${file.fileSizeFormatted}',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: const Color(0xFF7D7D7D),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'View',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: primary,
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────
  Widget sectionTitle(String title) => Text(
    title,
    style: GoogleFonts.poppins(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF333333),
    ),
  );

  Widget termCard({required List<Widget> children}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFEEEEF5)),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(children: children),
  );

  Widget termRow(String label, String value) => Padding(
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

  Widget miniChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.18)),
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

  Widget skillChip(String label, bool isRequired, String? importance) {
    final color = isRequired ? primary : const Color(0xFF7D7D7D);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        importance != null && importance.isNotEmpty
            ? '$label (${capitalize(importance)})'
            : label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  String formatNumber(num value) {
    final str = value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
    final parts = str.split('.');
    final whole = parts[0];
    final buffer = StringBuffer();
    for (int i = 0; i < whole.length; i++) {
      final reverseIndex = whole.length - i;
      buffer.write(whole[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) buffer.write(',');
    }
    if (parts.length > 1 && parts[1] != '00') {
      return '${buffer.toString()}.${parts[1]}';
    }
    return buffer.toString();
  }

  String formatDate(String raw) {
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

// ── Standalone widget classes (unchanged) ─────────────────────────────────────

class ScoreBadge extends StatelessWidget {
  final int score;
  const ScoreBadge({super.key, required this.score});

  Color get color {
    if (score >= 65) return AppColors.primary;
    if (score >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$score%',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class RecommendationChip extends StatelessWidget {
  final String recommendation;
  const RecommendationChip({super.key, required this.recommendation});

  Color get color {
    switch (recommendation.toLowerCase()) {
      case 'apply':
        return AppColors.primary;
      case 'consider':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFFEF4444);
    }
  }

  String get label {
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class SkillChip extends StatelessWidget {
  final String label;
  final bool matched;
  const SkillChip({super.key, required this.label, required this.matched});

  @override
  Widget build(BuildContext context) {
    final color = matched ? AppColors.primary : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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

class _AnalysisLoadingDialog extends StatefulWidget {
  final VoidCallback onCancel;
  const _AnalysisLoadingDialog({required this.onCancel});

  @override
  State<_AnalysisLoadingDialog> createState() => _AnalysisLoadingDialogState();
}

class _AnalysisLoadingDialogState extends State<_AnalysisLoadingDialog>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late AnimationController _cycleController;
  int _msgIndex = 0;
  int _dotCount = 0;

  static const _messages = [
    'Scanning skill overlap',
    'Reviewing job requirements',
    'Calculating match score',
    'Analyzing your experience',
    'Generating insights',
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _cycleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          _cycleController.reset();
          _cycleController.forward();
          setState(() {
            _dotCount = (_dotCount + 1) % 4;
            if (_dotCount == 0) {
              _msgIndex = (_msgIndex + 1) % _messages.length;
            }
          });
        }
      });
    _cycleController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _cycleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.12),
              blurRadius: 40,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, child) =>
                  Transform.scale(scale: _pulseAnim.value, child: child),
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.primary,
                  size: 38,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '${_messages[_msgIndex]}${'.' * _dotCount}',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Our AI is reviewing the job requirements\nagainst your profile.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF9CA3AF),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                minHeight: 4,
                backgroundColor: const Color(0xFFF3F4F6),
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: widget.onCancel,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6B7280),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              child: Text(
                'Stop Analysis',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
