import 'dart:io';

import 'package:url_launcher/url_launcher.dart';
import 'package:workbyte_app/widgets/report_sheet.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../models/client_model.dart';
import '../../models/education_model.dart';
import '../../models/experience_model.dart';
import '../../models/freelancer_model.dart';
import '../../models/freelancer_skill_model.dart';
import '../../models/portfolio_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/saved_items_provider.dart';
import '../../screens/client_history/client_history_screen.dart';
import '../../services/api_service.dart';
import '../../services/portfolio_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/pagination_bar.dart';

class PeopleListScreen extends StatefulWidget {
  final bool showClients;

  const PeopleListScreen({super.key, required this.showClients});

  @override
  State<PeopleListScreen> createState() => _PeopleListScreenState();
}

class _PeopleListScreenState extends State<PeopleListScreen> {
  static const int _pageSize = 10;

  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  List<dynamic> _all = [];
  List<dynamic> _filtered = [];
  final TextEditingController _searchController = TextEditingController();

  int get _totalPages =>
      _filtered.isEmpty ? 1 : (_filtered.length / _pageSize).ceil();

  List<dynamic> get _pagedItems {
    final start = (_currentPage - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, _filtered.length);
    return start < _filtered.length ? _filtered.sublist(start, end) : [];
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearch);
    _loadPeople();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _all.where((p) {
        final name = widget.showClients
            ? (p as ClientModel).displayName.toLowerCase()
            : (p as FreelancerModel).displayName.toLowerCase();
        return name.contains(query);
      }).toList();
      _currentPage = 1;
    });
  }

  // In _loadPeople(), after mapping, add sorting for freelancers:
  Future<void> _loadPeople() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) {
      setState(() {
        _isLoading = false;
        _error = 'Authentication required.';
      });
      return;
    }

    try {
      final rawItems = widget.showClients
          ? await ApiService.getAllClients(auth.token!, pageSize: 100)
          : await ApiService.getAllFreelancers(auth.token!, pageSize: 100);

      final mapped = widget.showClients
          ? rawItems.map((e) => ClientModel.fromJson(e)).toList()
          : rawItems.map((e) => FreelancerModel.fromJson(e)).toList();

      // ── Sort freelancers by weighted review average (descending) ──
      if (!widget.showClients) {
        (mapped as List<FreelancerModel>).sort((a, b) {
          final aScore = a.weightedReviewAvg ?? 0.0;
          final bScore = b.weightedReviewAvg ?? 0.0;
          return bScore.compareTo(aScore);
        });
      }

      setState(() {
        _all = mapped;
        _filtered = List.from(mapped);
        _isLoading = false;
        _currentPage = 1;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load data.';
        _isLoading = false;
      });
      debugPrint('PeopleListScreen error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.showClients ? 'Clients' : 'Freelancers';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                      Text(
                        'All $title',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      if (!widget.showClients &&
                          context.watch<ProfileProvider>().isClient) ...[
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ClientHistoryScreen(),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.16),
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              'History',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_filtered.length}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Search bar
                  Container(
                    height: 48,
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
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFF333333),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search ${title.toLowerCase()}...',
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF9CA3AF),
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Body
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 2,
                            ),
                          )
                        : _error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  size: 48,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _error!,
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF7D7D7D),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  widget.showClients
                                      ? Icons.business_outlined
                                      : Icons.person_outline_rounded,
                                  size: 56,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No ${title.toLowerCase()} found',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF7D7D7D),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Try adjusting your search.',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFFB5B4B4),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: _loadPeople,
                            child: ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              itemCount: _pagedItems.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final person = _pagedItems[index];
                                return widget.showClients
                                    ? _ClientCard(
                                        client: person as ClientModel,
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => PeopleProfileScreen(
                                              isClient: true,
                                              client: person,
                                            ),
                                          ),
                                        ),
                                      )
                                    : _FreelancerCard(
                                        freelancer: person as FreelancerModel,
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => PeopleProfileScreen(
                                              isClient: false,
                                              freelancer: person,
                                            ),
                                          ),
                                        ),
                                      );
                              },
                            ),
                          ),
                  ),
                  if (!_isLoading && _error == null && _totalPages > 1)
                    PaginationBar(
                      currentPage: _currentPage,
                      totalPages: _totalPages,
                      onPrev: _currentPage > 1
                          ? () => setState(() => _currentPage--)
                          : null,
                      onNext: _currentPage < _totalPages
                          ? () => setState(() => _currentPage++)
                          : null,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Freelancer card ────────────────────────────────────────────────────────────
class _FreelancerCard extends StatelessWidget {
  final FreelancerModel freelancer;
  final VoidCallback onTap;

  const _FreelancerCard({required this.freelancer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final double? avg = freelancer.weightedReviewAvg;
    final bool hasRating = avg != null;
    final bool isTopRated = hasRating && avg >= 4.5;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            _Avatar(
              imageUrl: freelancer.profilePictureUrl,
              name: freelancer.displayName,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Name row with optional Top Rated badge ──
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          freelancer.displayName,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A2E),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isTopRated) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3CD),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                size: 10,
                                color: Color(0xFFD4A017),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Top Rated',
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFD4A017),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    freelancer.jobTitle.isNotEmpty && freelancer.jobTitle != '-'
                        ? freelancer.jobTitle
                        : 'Freelancer',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF7D7D7D),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // ── Star rating row ──
                  _StarRating(avg: avg),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.folder_outlined,
                        label: '${freelancer.totalProjects} projects',
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        icon: Icons.attach_money_rounded,
                        label: freelancer.estimatedRate != null
                            ? freelancer.formattedRate
                            : 'Rate not set',
                        isHighlight: freelancer.estimatedRate != null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Client card ────────────────────────────────────────────────────────────────
class _ClientCard extends StatelessWidget {
  final ClientModel client;
  final VoidCallback onTap;

  const _ClientCard({required this.client, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            _Avatar(
              imageUrl: client.profilePictureUrl,
              name: client.displayName,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client.displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Client',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF7D7D7D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.work_outline_rounded,
                        label: '${client.totalJobsPosted} jobs posted',
                      ),
                      if (client.averageRatingGiven != null) ...[
                        const SizedBox(width: 8),
                        _StatChip(
                          icon: Icons.star_rounded,
                          label: client.averageRatingGiven!.toStringAsFixed(1),
                          isHighlight: true,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared avatar widget ───────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String? imageUrl;
  final String name;

  const _Avatar({required this.imageUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    ImageProvider? provider;
    if (hasImage) {
      if (imageUrl!.startsWith('http')) {
        provider = NetworkImage(imageUrl!);
      } else if (File(imageUrl!).existsSync()) {
        provider = FileImage(File(imageUrl!));
      }
    }

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        image: provider != null
            ? DecorationImage(image: provider, fit: BoxFit.cover)
            : null,
      ),
      child: provider == null
          ? Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            )
          : null,
    );
  }
}

// ── Small stat chip ────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isHighlight;

  const _StatChip({
    required this.icon,
    required this.label,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlight ? AppColors.secondary : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isHighlight ? AppColors.primary : const Color(0xFF9CA3AF),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isHighlight ? AppColors.primary : const Color(0xFF7D7D7D),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  final double? avg;

  const _StarRating({this.avg});

  @override
  Widget build(BuildContext context) {
    if (avg == null) {
      return Text(
        'No reviews yet',
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: const Color(0xFFB5B4B4),
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Build 5 stars
        ...List.generate(5, (i) {
          final starValue = i + 1;
          IconData icon;
          Color color;

          if (avg! >= starValue) {
            icon = Icons.star_rounded;
            color = const Color(0xFFFBBC04);
          } else if (avg! >= starValue - 0.5) {
            icon = Icons.star_half_rounded;
            color = const Color(0xFFFBBC04);
          } else {
            icon = Icons.star_outline_rounded;
            color = const Color(0xFFD1D5DB);
          }

          return Icon(icon, size: 14, color: color);
        }),
        const SizedBox(width: 5),
        Text(
          avg!.toStringAsFixed(1),
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }
}

// ── Profile detail screen ──────────────────────────────────────────────────────
class PeopleProfileScreen extends StatefulWidget {
  final bool isClient;
  final ClientModel? client;
  final FreelancerModel? freelancer;

  const PeopleProfileScreen({
    super.key,
    required this.isClient,
    this.client,
    this.freelancer,
  });

  @override
  State<PeopleProfileScreen> createState() => _PeopleProfileScreenState();
}

class _PeopleProfileScreenState extends State<PeopleProfileScreen> {
  List<FreelancerSkillModel> _skills = [];
  List<EducationModel> _educations = [];
  List<ExperienceModel> _experiences = [];
  List<PortfolioModel> _portfolios = [];
  bool _loadingDetails = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isClient && widget.freelancer != null) {
      _fetchFreelancerDetails();
    }
  }

  Future<void> _fetchFreelancerDetails() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    final freelancerId = widget.freelancer!.freelancerId;
    setState(() => _loadingDetails = true);
    final profileService = ProfileService();
    final portfolioService = PortfolioService();
    final results = await Future.wait([
      profileService.getFreelancerSkills(token, freelancerId),
      profileService.getEducations(token, freelancerId),
      profileService.getWorkExperiences(token, freelancerId),
      portfolioService.getPortfoliosByFreelancer(token, freelancerId),
    ]);
    if (mounted) {
      setState(() {
        _skills = results[0] as List<FreelancerSkillModel>;
        _educations = results[1] as List<EducationModel>;
        _experiences = results[2] as List<ExperienceModel>;
        _portfolios = results[3] as List<PortfolioModel>;
        _loadingDetails = false;
      });
    }
  }

  // 👇 NEW: helper to determine target user ID for self-report guard
  String? get _targetUserId {
    if (widget.isClient) return widget.client?.userId;
    return widget.freelancer?.userId;
  }

  // 👇 NEW: opens the report sheet
  void _openReportSheet() {
    ReportSheet.show(
      context,
      reportedType: widget.isClient ? 'client' : 'freelancer',
      reportedUserId: widget.isClient
          ? widget.client?.userId
          : widget.freelancer?.userId,
      targetName: widget.isClient
          ? widget.client?.displayName
          : widget.freelancer?.displayName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.isClient
        ? widget.client?.displayName ?? 'Client'
        : widget.freelancer?.displayName ?? 'Freelancer';
    final avatarUrl = widget.isClient
        ? widget.client?.profilePictureUrl
        : widget.freelancer?.profilePictureUrl;
    final bio = widget.isClient
        ? (widget.client?.bio ?? 'No description available.')
        : (widget.freelancer?.bio ?? 'No description available.');
    final badge = widget.isClient
        ? widget.client?.averageRatingGiven != null
              ? '★ ${widget.client!.averageRatingGiven!.toStringAsFixed(1)}'
              : 'No rating yet'
        : widget.freelancer?.estimatedRate != null
        ? widget.freelancer!.formattedRate
        : 'Rate not set';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            actions: [
              // ── Bookmark (existing) ──
              Consumer<SavedItemsProvider>(
                builder: (context, saved, _) {
                  final isSaved = widget.isClient
                      ? saved.isClientSaved(widget.client?.clientId ?? '')
                      : saved.isFreelancerSaved(
                          widget.freelancer?.freelancerId ?? '',
                        );
                  return GestureDetector(
                    onTap: () {
                      if (widget.isClient && widget.client != null) {
                        saved.toggleSaveClient(widget.client!);
                      } else if (!widget.isClient &&
                          widget.freelancer != null) {
                        saved.toggleSaveFreelancer(widget.freelancer!);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          isSaved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  );
                },
              ),

              // 👇 NEW: Report button — hidden if viewing own profile
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  // Don't show report button on the user's own profile
                  if (_targetUserId != null && _targetUserId == auth.userId) {
                    return const SizedBox.shrink();
                  }
                  return GestureDetector(
                    onTap: _openReportSheet,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(0, 8, 12, 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: const Icon(
                          Icons.flag_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, Color(0xFF6C63FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    _buildAvatar(avatarUrl, name),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row — unchanged
                  Row(
                    children: [
                      if (widget.isClient) ...[
                        Expanded(
                          child: _StatCard(
                            label: 'Jobs Posted',
                            value: '${widget.client?.totalJobsPosted ?? 0}',
                            icon: Icons.work_outline_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Completed',
                            value:
                                '${widget.client?.totalProjectsCompleted ?? 0}',
                            icon: Icons.check_circle_outline_rounded,
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: _StatCard(
                            label: 'Projects',
                            value: '${widget.freelancer?.totalProjects ?? 0}',
                            icon: Icons.folder_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Rate',
                            value: widget.freelancer?.estimatedRate != null
                                ? widget.freelancer!.estimatedRate!
                                      .toStringAsFixed(0)
                                : 'N/A',
                            icon: Icons.attach_money_rounded,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  // About section — unchanged
                  Text(
                    'About',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      bio,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF555555),
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Details section — unchanged
                  Text(
                    'Details',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
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
                        _DetailRow(label: 'Name', value: name),
                        const Divider(height: 20, color: Color(0xFFF0F0F1)),
                        if (widget.isClient) ...[
                          _DetailRow(
                            label: 'Website',
                            value: widget.client?.websiteUrl ?? 'Not provided',
                          ),
                          const Divider(height: 20, color: Color(0xFFF0F0F1)),
                          _DetailRow(label: 'Rating', value: badge),
                        ] else ...[
                          _DetailRow(label: 'Rate', value: badge),
                          if (widget.freelancer?.rateTime != null) ...[
                            const Divider(height: 20, color: Color(0xFFF0F0F1)),
                            _DetailRow(
                              label: 'Period',
                              value: widget.freelancer!.rateTime!,
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),

                  // Freelancer-only sections — unchanged
                  if (!widget.isClient) ...[
                    const SizedBox(height: 20),
                    if (_loadingDetails)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    else ...[
                      _SectionHeader(
                        label: 'Skills',
                        icon: Icons.psychology_outlined,
                      ),
                      const SizedBox(height: 10),
                      if (_skills.isEmpty)
                        _EmptyHint(text: 'No skills listed.')
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _skills.map((s) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                s.skillName ?? s.skillId,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 20),

                      _SectionHeader(
                        label: 'Education',
                        icon: Icons.school_outlined,
                      ),
                      const SizedBox(height: 10),
                      if (_educations.isEmpty)
                        _EmptyHint(text: 'No education added.')
                      else
                        Column(
                          children: _educations.map((e) {
                            final period =
                                '${e.startDate.substring(0, 4)} – ${e.isCurrent ? 'Present' : (e.endDate?.substring(0, 4) ?? '?')}';
                            return _TimelineCard(
                              title: e.degree,
                              subtitle: e.institutionName,
                              trailing: period,
                              description: e.fieldOfStudy,
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 20),

                      _SectionHeader(
                        label: 'Experience',
                        icon: Icons.work_outline_rounded,
                      ),
                      const SizedBox(height: 10),
                      if (_experiences.isEmpty)
                        _EmptyHint(text: 'No work experience added.')
                      else
                        Column(
                          children: _experiences.map((e) {
                            final period =
                                '${e.startDate.substring(0, 4)} – ${e.isCurrent ? 'Present' : (e.endDate?.substring(0, 4) ?? '?')}';
                            return _TimelineCard(
                              title: e.jobTitle,
                              subtitle: e.companyName,
                              trailing: period,
                              description: e.location,
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 20),

                      _SectionHeader(
                        label: 'Portfolio',
                        icon: Icons.work_history_outlined,
                      ),
                      const SizedBox(height: 10),
                      if (_portfolios.isEmpty)
                        _EmptyHint(text: 'No portfolio items yet.')
                      else
                        Column(
                          children: _portfolios.map((p) {
                            return _PortfolioCard(portfolio: p);
                          }).toList(),
                        ),
                    ],
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? url, String name) {
    ImageProvider? provider;
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('http')) {
        provider = NetworkImage(url);
      } else if (File(url).existsSync()) {
        provider = FileImage(File(url));
      }
    }
    return CircleAvatar(
      radius: 44,
      backgroundColor: Colors.white,
      backgroundImage: provider,
      child: provider == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            )
          : null,
    );
  }
}

// ── All helper widgets below are completely unchanged ─────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: const Color(0xFF9CA3AF),
        ),
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailing;
  final String? description;

  const _TimelineCard({
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF555555),
                  ),
                ),
                if (description != null && description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    description!,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            trailing,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
        ),
      ],
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  final PortfolioModel portfolio;
  const _PortfolioCard({required this.portfolio});

  @override
  Widget build(BuildContext context) {
    final hasUrl =
        portfolio.projectUrl != null && portfolio.projectUrl!.isNotEmpty;
    final year = portfolio.completionDate?.year.toString();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.work_history_outlined,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        portfolio.projectTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                    if (year != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        year,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ],
                ),
                if (portfolio.projectDescription != null &&
                    portfolio.projectDescription!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    portfolio.projectDescription!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF555555),
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (hasUrl) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.tryParse(portfolio.projectUrl!);
                      if (uri != null) {
                        // ignore: deprecated_member_use
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.link_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'View project',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
