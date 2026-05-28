import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../models/ai_job_match_model.dart';
import '../../models/job_post_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../job_freelancer_view/job_detail.dart';
import '../job_freelancer_view/job_list.dart';

const int _kPageSize = 10;
const int _kFetchLimit = 50;

class RecommendedJobsScreen extends StatefulWidget {
  final List<AIJobMatchModel>? initialJobs;

  const RecommendedJobsScreen({super.key, this.initialJobs});

  @override
  State<RecommendedJobsScreen> createState() => _RecommendedJobsScreenState();
}

class _RecommendedJobsScreenState extends State<RecommendedJobsScreen> {
  List<AIJobMatchModel> _jobs = [];
  bool _isLoading = true;
  bool _noEmbedding = false;
  bool _noSkills = false;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    if (widget.initialJobs != null && widget.initialJobs!.isNotEmpty) {
      _jobs = List.from(widget.initialJobs!);
      _isLoading = false;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadJobs());
    }
  }

  Future<void> _loadJobs() async {
    setState(() => _isLoading = true);
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final result = await ApiService.getAIJobRecommendations(
        token,
        limit: _kFetchLimit,
      );
      if (!mounted) return;
      if (result.isEmpty) {
        setState(() {
          _noEmbedding = true;
          _isLoading = false;
        });
        return;
      }
      final matches = result['matches'] as List? ?? [];
      final debug = result['_debug'] as Map?;
      final skillCount =
          (debug?['freelancer_skill_count'] as num?)?.toInt() ?? 1;
      if (matches.isEmpty && skillCount == 0) {
        setState(() {
          _noSkills = true;
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _jobs = matches
            .map((m) => AIJobMatchModel.fromJson(Map<String, dynamic>.from(m)))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Error loading recommended jobs: $e');
    }
  }

  int get _totalPages => (_jobs.isEmpty ? 1 : (_jobs.length / _kPageSize).ceil());

  List<AIJobMatchModel> get _pageJobs {
    final start = (_currentPage - 1) * _kPageSize;
    final end = (start + _kPageSize).clamp(0, _jobs.length);
    if (start >= _jobs.length) return [];
    return _jobs.sublist(start, end);
  }

  bool get _isPastResults => _currentPage > _totalPages;

  Future<void> _tapJob(AIJobMatchModel match) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    final data = await ApiService.getJobPostById(token, match.jobPostId);
    if (!mounted || data == null) return;
    final job = JobPostModel.fromJson(data);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'How Recommendations Work',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _InfoStep(
                step: '1',
                color: const Color(0xFF4F46E5),
                title: 'Semantic Search',
                body:
                    'Your profile is encoded into a vector and compared against all open job descriptions to find the top 100 closest semantic matches.',
              ),
              const SizedBox(height: 12),
              _InfoStep(
                step: '2',
                color: const Color(0xFF059669),
                title: 'Skill Filtering',
                body:
                    'Jobs are filtered by skill overlap. Any job where your skill match falls below 20% of the required skills is removed.',
              ),
              const SizedBox(height: 12),
              _InfoStep(
                step: '3',
                color: const Color(0xFFD97706),
                title: 'AI Ranking',
                body:
                    'A CatBoost ML model scores remaining jobs across 13 features — skills, experience level, rate fit, and portfolio relevance — and ranks them by predicted match quality.',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Each job shows why it ranked high (✓ match reasons) and what may be holding it back (⚠ gap signals), powered by SHAP explanations from the ML model.',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF4F46E5),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Got it',
              style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── App bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Recommended for You',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _showInfoDialog,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Subtitle ──
            if (!_isLoading && !_noEmbedding && _jobs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                child: Text(
                  '${_jobs.length} personalized match${_jobs.length == 1 ? '' : 'es'} · AI-ranked',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // ── Body ──
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    )
                  : _noEmbedding
                  ? _buildNoEmbeddingState()
                  : _noSkills
                  ? _buildNoSkillsState()
                  : _jobs.isEmpty
                  ? _buildEmptyState()
                  : _isPastResults
                  ? _buildEndOfResultsState()
                  : _buildJobList(),
            ),

            // ── Pagination bar ──
            if (!_isLoading && !_noEmbedding && _jobs.isNotEmpty)
              _buildPaginationBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildJobList() {
    final page = _pageJobs;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadJobs,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        itemCount: page.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _RecommendedJobCard(
          job: page[index],
          onTap: () => _tapJob(page[index]),
        ),
      ),
    );
  }

  Widget _buildPaginationBar() {
    final isFirst = _currentPage == 1;
    final isLast = _isPastResults || _currentPage >= _totalPages;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _PaginationButton(
            label: '← Prev',
            enabled: !isFirst,
            onTap: () => setState(() => _currentPage--),
          ),
          Text(
            _isPastResults
                ? 'End'
                : 'Page $_currentPage of $_totalPages',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF555555),
            ),
          ),
          _PaginationButton(
            label: 'Next →',
            enabled: !isLast,
            highlighted: true,
            onTap: () => setState(() => _currentPage++),
          ),
        ],
      ),
    );
  }

  Widget _buildEndOfResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "You've seen all your personalized matches.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Browse all open jobs to discover more opportunities.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF7D7D7D),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const JobListScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Browse all open jobs →',
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
      ),
    );
  }

  Widget _buildNoEmbeddingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Complete your profile to unlock recommendations',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your skills, experience, and portfolio so our AI can match you with the best jobs.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF7D7D7D),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSkillsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium_outlined,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Add skills to get recommendations',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Our AI needs at least one skill on your profile to match you with relevant jobs.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF7D7D7D),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'No recommendations yet',
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: const Color(0xFF9CA3AF),
        ),
      ),
    );
  }
}

// ── Recommended job card ──────────────────────────────────────────────────────
class _RecommendedJobCard extends StatelessWidget {
  final AIJobMatchModel job;
  final VoidCallback onTap;

  const _RecommendedJobCard({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasShap = job.matchReasons.isNotEmpty || job.penaltyReasons.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.business_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.jobTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        job.clientName ?? 'Client',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (hasShap)
                  GestureDetector(
                    onTap: () => _showShapSheet(context, job),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  )
                else
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Color(0xFFD1D5DB),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Tags row ──
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _Tag(
                  label: job.projectType.toUpperCase(),
                  color: AppColors.primary,
                  bg: AppColors.secondary,
                ),
                _Tag(
                  label: job.projectScope.toUpperCase(),
                  color: AppColors.primary,
                  bg: AppColors.secondary,
                ),
                _Tag(
                  label:
                      '${job.proposalCount} proposal${job.proposalCount != 1 ? 's' : ''}',
                  color: const Color(0xFF6B7280),
                  bg: const Color(0xFFF3F4F6),
                ),
                if (job.skillOverlapPct > 0)
                  _Tag(
                    label:
                        '${job.skillOverlapPct.toStringAsFixed(0)}% skill match',
                    color: const Color(0xFF059669),
                    bg: const Color(0xFFD1FAE5),
                  ),
              ],
            ),

          ],
        ),
      ),
    );
  }
}

void _showShapSheet(BuildContext context, AIJobMatchModel job) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (_, sc) => Container(
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
                controller: sc,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: AppColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Why this job was recommended',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF333333),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job.jobTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                    if (job.matchReasons.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Strengths',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...job.matchReasons.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 14,
                                color: Color(0xFF059669),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  r,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: const Color(0xFF333333),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (job.penaltyReasons.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Considerations',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...job.penaltyReasons.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                size: 14,
                                color: Color(0xFFD97706),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  r,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: const Color(0xFF333333),
                                    height: 1.5,
                                  ),
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
            ),
          ],
        ),
      ),
    ),
  );
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const _Tag({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
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
}

class _PaginationButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool highlighted;
  final VoidCallback onTap;

  const _PaginationButton({
    required this.label,
    required this.enabled,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color fg = enabled
        ? (highlighted ? Colors.white : AppColors.primary)
        : const Color(0xFFD1D5DB);
    final Color bg = enabled
        ? (highlighted ? AppColors.primary : AppColors.secondary)
        : const Color(0xFFF9FAFB);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }
}

// ── Info step widget used in dialog ──────────────────────────────────────────
class _InfoStep extends StatelessWidget {
  final String step;
  final Color color;
  final String title;
  final String body;

  const _InfoStep({
    required this.step,
    required this.color,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            step,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
