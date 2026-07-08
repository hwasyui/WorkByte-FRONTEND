import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/job_categories.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_post_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/proposal_provider.dart';
import '../../providers/saved_items_provider.dart';
import '../../models/job_post_model.dart';
import '../../models/proposal_model.dart';
import '../../services/job_post_service.dart';
import '../../widgets/pagination_bar.dart';
import 'job_detail.dart';

class JobListScreen extends StatefulWidget {
  final String? initialQuery;
  final String? categoryFilter;

  const JobListScreen({super.key, this.initialQuery, this.categoryFilter});

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _AppliedJobItem {
  final ProposalModel proposal;
  final JobPostModel job;

  const _AppliedJobItem({required this.proposal, required this.job});
}

class _JobListScreenState extends State<JobListScreen> {
  static const Color _primary = AppColors.primary;
  static const int _pageSize = 10;

  final TextEditingController _searchController = TextEditingController();

  List<JobPostModel> _allJobs = [];
  List<JobPostModel> _filteredJobs = [];

  List<_AppliedJobItem> _appliedJobs = [];
  List<_AppliedJobItem> _filteredAppliedJobs = [];

  bool _isLoading = true;
  bool _isLoadingApplied = false;

  int _selectedTabIndex = 0;
  String _sortOption = 'Latest';
  int _currentPage = 1;
  String? _projectTypeFilter;
  String? _experienceLevelFilter;
  String? _activeCategoryFilter;

  final Map<String, int> _positionCounts = {};
  final Map<String, String?> _clientProfilePictures = {};

  bool get _showingApplied => _isFreelancer && _selectedTabIndex == 1;

  bool get _isFreelancer {
    return context.read<ProfileProvider>().isFreelancer;
  }

  int get _totalPages {
    final count = _showingApplied
        ? _filteredAppliedJobs.length
        : _filteredJobs.length;
    return count == 0 ? 1 : (count / _pageSize).ceil();
  }

  List<JobPostModel> get _pagedJobs {
    final start = (_currentPage - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, _filteredJobs.length);
    return start < _filteredJobs.length
        ? _filteredJobs.sublist(start, end)
        : [];
  }

  List<_AppliedJobItem> get _pagedAppliedJobs {
    final start = (_currentPage - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, _filteredAppliedJobs.length);
    return start < _filteredAppliedJobs.length
        ? _filteredAppliedJobs.sublist(start, end)
        : [];
  }

  int get _activeFilterCount =>
      (_projectTypeFilter != null ? 1 : 0) +
      (_experienceLevelFilter != null ? 1 : 0) +
      (_sortOption != 'Latest' ? 1 : 0);

  @override
  void initState() {
    super.initState();
    _activeCategoryFilter = widget.categoryFilter;

    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
    }

    _searchController.addListener(_onSearch);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchJobs());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchJobs() async {
    setState(() => _isLoading = true);

    try {
      final token = context.read<AuthProvider>().token!;

      await context.read<JobPostProvider>().fetchAllJobPosts(token);
      if (!mounted) return;

      final posts = context.read<JobPostProvider>().jobPosts;
      _allJobs = List<JobPostModel>.from(posts);

      if (!_isFreelancer) {
        _selectedTabIndex = 0;
        _appliedJobs = [];
        _filteredAppliedJobs = [];
      }

      if (_isFreelancer) {
        await _fetchAppliedJobs(token);
      }

      if (!mounted) return;
      setState(() {
        _currentPage = 1;
        _applySortAndFilter();
        _isLoading = false;
      });

      await _loadTeamPositionCounts(token);
      await _loadClientProfilePictures(token);
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAppliedJobs(String token) async {
    setState(() => _isLoadingApplied = true);

    try {
      final profileProvider = context.read<ProfileProvider>();
      final freelancerId = profileProvider.freelancerProfile?.freelancerId;

      if (freelancerId == null || freelancerId.toString().isEmpty) {
        _appliedJobs = [];
        return;
      }

      final proposalProvider = context.read<ProposalProvider>();
      final jobService = JobPostService();

      await proposalProvider.fetchProposalsByFreelancer(
        token: token,
        freelancerId: freelancerId.toString(),
      );

      final proposals = proposalProvider.proposals;

      final results = await Future.wait(
        proposals.map((proposal) async {
          try {
            late final JobPostModel job;

            try {
              job = _allJobs.firstWhere(
                (j) => j.jobPostId == proposal.jobPostId,
              );
            } catch (_) {
              job = await jobService.getJobPost(token, proposal.jobPostId);
            }

            return _AppliedJobItem(proposal: proposal, job: job);
          } catch (_) {
            return null;
          }
        }),
      );

      _appliedJobs = results.whereType<_AppliedJobItem>().toList();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingApplied = false;
          _applySortAndFilter();
        });
      }
    }
  }

  Future<void> _loadTeamPositionCounts(String token) async {
    final service = JobPostService();

    final jobs = [..._allJobs, ..._appliedJobs.map((item) => item.job)];

    final teamJobs = jobs.where(
      (job) => (job.projectType ?? '').toLowerCase() == 'team',
    );

    final results = await Future.wait(
      teamJobs.map((job) async {
        try {
          final roles = await service.getJobRoles(token, job.jobPostId);
          final total = roles.fold<int>(
            0,
            (sum, role) => sum + role.positionsAvailable,
          );
          return MapEntry(job.jobPostId, total);
        } catch (_) {
          return null;
        }
      }),
    );

    if (!mounted) return;

    setState(() {
      _positionCounts.clear();
      for (final entry in results.whereType<MapEntry<String, int>>()) {
        _positionCounts[entry.key] = entry.value;
      }
      _applySortAndFilter();
    });
  }

  Future<void> _loadClientProfilePictures(String token) async {
    final profileProvider = context.read<ProfileProvider>();

    final clientIds = [
      ..._allJobs.map((job) => job.clientId),
      ..._appliedJobs.map((item) => item.job.clientId),
    ].where((id) => id.isNotEmpty).toSet();

    for (final clientId in clientIds) {
      if (_clientProfilePictures.containsKey(clientId)) continue;

      try {
        final client = await profileProvider.fetchClientById(
          token: token,
          clientId: clientId,
        );
        if (!mounted) return;
        _clientProfilePictures[clientId] = client?.profilePictureUrl;
      } catch (_) {
        _clientProfilePictures[clientId] = null;
      }
    }

    if (!mounted) return;
    setState(() {});
  }

  void _onSearch() {
    setState(() {
      _currentPage = 1;
      _applySortAndFilter();
    });
  }

  void _onSortChanged(String value) {
    setState(() {
      _sortOption = value;
      _currentPage = 1;
      _applySortAndFilter();
    });
  }

  void _clearCategoryFilter() {
    setState(() {
      _activeCategoryFilter = null;
      _currentPage = 1;
      _applySortAndFilter();
    });
  }

  void _applySortAndFilter() {
    final query = _searchController.text.toLowerCase();

    _filteredJobs = _allJobs.where((job) {
      final matchesQuery =
          job.jobTitle.toLowerCase().contains(query) ||
          (job.clientName ?? '').toLowerCase().contains(query);

      final matchesCategory =
          _activeCategoryFilter == null ||
          job.projectCategory.toLowerCase() ==
              _activeCategoryFilter!.toLowerCase();

      final matchesType =
          _projectTypeFilter == null ||
          job.projectType.toLowerCase() == _projectTypeFilter!.toLowerCase();

      final matchesLevel =
          _experienceLevelFilter == null ||
          (job.experienceLevel ?? '').toLowerCase() ==
              _experienceLevelFilter!.toLowerCase();

      return matchesQuery && matchesCategory && matchesType && matchesLevel;
    }).toList();

    _filteredAppliedJobs = _appliedJobs.where((item) {
      final job = item.job;
      final proposal = item.proposal;

      final matchesQuery =
          job.jobTitle.toLowerCase().contains(query) ||
          (job.clientName ?? '').toLowerCase().contains(query) ||
          proposal.status.toLowerCase().contains(query);

      final matchesCategory =
          _activeCategoryFilter == null ||
          job.projectCategory.toLowerCase() ==
              _activeCategoryFilter!.toLowerCase();

      final matchesType =
          _projectTypeFilter == null ||
          job.projectType.toLowerCase() == _projectTypeFilter!.toLowerCase();

      final matchesLevel =
          _experienceLevelFilter == null ||
          (job.experienceLevel ?? '').toLowerCase() ==
              _experienceLevelFilter!.toLowerCase();

      return matchesQuery && matchesCategory && matchesType && matchesLevel;
    }).toList();

    _filteredJobs.sort(
      (a, b) => _sortOption == 'Latest'
          ? (b.createdAt ?? '').compareTo(a.createdAt ?? '')
          : (a.createdAt ?? '').compareTo(b.createdAt ?? ''),
    );

    _filteredAppliedJobs.sort(
      (a, b) => _sortOption == 'Latest'
          ? (b.proposal.submittedAt ?? '').compareTo(
              a.proposal.submittedAt ?? '',
            )
          : (a.proposal.submittedAt ?? '').compareTo(
              b.proposal.submittedAt ?? '',
            ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      _projectTypeFilter = null;
      _experienceLevelFilter = null;
      _sortOption = 'Latest';
      _currentPage = 1;
      _applySortAndFilter();
    });
  }

  void _showFilterSheet() {
    String tempSort = _sortOption;
    String? tempType = _projectTypeFilter;
    String? tempLevel = _experienceLevelFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          Widget filterSection(
            String title,
            List<String?> values,
            List<String> labels,
            String? selected,
            void Function(String?) onSelect,
          ) {
            return Column(
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
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(values.length, (i) {
                    final isSelected = selected == values[i];

                    return GestureDetector(
                      onTap: () => setSheetState(() => onSelect(values[i])),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : const Color(0xFFE0E0E0),
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          labels[i],
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF555555),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          }

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Filter & Sort',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        setSheetState(() {
                          tempSort = 'Latest';
                          tempType = null;
                          tempLevel = null;
                        });
                      },
                      child: Text(
                        'Clear all',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                filterSection(
                  'Sort By',
                  [null, 'Oldest'],
                  ['Latest', 'Oldest'],
                  tempSort == 'Latest' ? null : tempSort,
                  (v) => tempSort = v ?? 'Latest',
                ),
                const SizedBox(height: 20),
                filterSection(
                  'Project Type',
                  [null, 'individual', 'team'],
                  ['All', 'Individual', 'Team'],
                  tempType,
                  (v) => tempType = v,
                ),
                const SizedBox(height: 20),
                filterSection(
                  'Experience Level',
                  [null, 'entry', 'intermediate', 'expert'],
                  ['All', 'Entry Level', 'Intermediate', 'Expert'],
                  tempLevel,
                  (v) => tempLevel = v,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _sortOption = tempSort;
                        _projectTypeFilter = tempType;
                        _experienceLevelFilter = tempLevel;
                        _currentPage = 1;
                        _applySortAndFilter();
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Apply Filters',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isFiltered = _activeCategoryFilter != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            if (_isFreelancer) _buildJobTabs(),
            if (isFiltered) _buildCategoryFilterChip(),
            _buildSearchAndFilterBar(),
            if (_activeFilterCount > 0) _buildActiveFilterChips(),
            Expanded(child: _buildListSection()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
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
          Text(
            'Available Jobs',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobTabs() {
    Widget tab(String label, int index, int count) {
      final selected = _selectedTabIndex == index;

      return Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedTabIndex = index;
              _currentPage = 1;
              _applySortAndFilter();
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: selected ? _primary : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? _primary : const Color(0xFFE8E8EF),
              ),
            ),
            child: Center(
              child: Text(
                '$label ($count)',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : const Color(0xFF6B7280),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(29, 0, 29, 0),
      child: Row(
        children: [
          tab('Available', 0, _filteredJobs.length),
          const SizedBox(width: 10),
          tab('Applied', 1, _filteredAppliedJobs.length),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterChip() {
    final resultCount = _showingApplied
        ? _filteredAppliedJobs.length
        : _filteredJobs.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(29, 12, 29, 0),
      child: Row(
        children: [
          Icon(
            kCategoryIcons[_activeCategoryFilter] ??
                Icons.label_outline_rounded,
            size: 14,
            color: _primary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _primary.withValues(alpha: 0.18)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    kCategoryLabels[_activeCategoryFilter] ??
                        _activeCategoryFilter!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _clearCategoryFilter,
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: _primary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$resultCount result${resultCount == 1 ? '' : 's'}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    final bool isFiltered = _activeCategoryFilter != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(29, 12, 29, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFF0F0F1)),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF333333),
                      ),
                      decoration: InputDecoration(
                        hintText: _showingApplied
                            ? 'Search applied jobs...'
                            : isFiltered
                            ? 'Search in ${kCategoryLabels[_activeCategoryFilter] ?? _activeCategoryFilter}...'
                            : 'Search jobs...',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF7D7D7D),
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const Icon(Icons.search, color: Color(0xFF7D7D7D), size: 22),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _showFilterSheet,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: _activeFilterCount > 0
                        ? AppColors.primary
                        : Colors.white,
                    border: Border.all(
                      color: _activeFilterCount > 0
                          ? AppColors.primary
                          : const Color(0xFFF0F0F1),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    color: _activeFilterCount > 0
                        ? Colors.white
                        : const Color(0xFF7D7D7D),
                    size: 22,
                  ),
                ),
                if (_activeFilterCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5252),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$_activeFilterCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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

  Widget _buildActiveFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(29, 10, 29, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          if (_sortOption != 'Latest')
            _activeChip(
              _sortOption,
              () => setState(() {
                _sortOption = 'Latest';
                _currentPage = 1;
                _applySortAndFilter();
              }),
            ),
          if (_projectTypeFilter != null)
            _activeChip(
              _projectTypeFilter == 'team' ? 'Team' : 'Individual',
              () => setState(() {
                _projectTypeFilter = null;
                _currentPage = 1;
                _applySortAndFilter();
              }),
            ),
          if (_experienceLevelFilter != null)
            _activeChip(
              {
                    'entry': 'Entry Level',
                    'intermediate': 'Intermediate',
                    'expert': 'Expert',
                  }[_experienceLevelFilter] ??
                  _experienceLevelFilter!,
              () => setState(() {
                _experienceLevelFilter = null;
                _currentPage = 1;
                _applySortAndFilter();
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildListSection() {
    final loading = _isLoading || (_showingApplied && _isLoadingApplied);

    return Column(
      children: [
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator(color: _primary))
              : _showingApplied
              ? _filteredAppliedJobs.isEmpty
                    ? _buildAppliedEmptyState()
                    : RefreshIndicator(
                        color: _primary,
                        onRefresh: _fetchJobs,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(29, 16, 29, 16),
                          itemCount: _pagedAppliedJobs.length,
                          itemBuilder: (context, index) =>
                              _buildAppliedJobCard(_pagedAppliedJobs[index]),
                        ),
                      )
              : _filteredJobs.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: _primary,
                  onRefresh: _fetchJobs,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(29, 16, 29, 16),
                    itemCount: _pagedJobs.length,
                    itemBuilder: (context, index) =>
                        _buildJobCard(_pagedJobs[index]),
                  ),
                ),
        ),
        if (!loading &&
            ((_showingApplied && _filteredAppliedJobs.isNotEmpty) ||
                (!_showingApplied && _filteredJobs.isNotEmpty)) &&
            _totalPages > 1)
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
    );
  }

  Widget _activeChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close_rounded,
              size: 13,
              color: AppColors.primary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(JobPostModel job) {
    final isTeam = (job.projectType ?? '').toLowerCase() == 'team';
    final proposalCount = job.proposalCount;
    final positionCount = isTeam
        ? (_positionCounts[job.jobPostId] ?? job.roleCount)
        : 1;
    final clientAvatarUrl = _clientProfilePictures[job.clientId];

    return Consumer<SavedItemsProvider>(
      builder: (context, saved, _) {
        final isSaved = saved.isJobSaved(job.jobPostId);

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFEEEEF5)),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _clientAvatar(clientAvatarUrl),
                const SizedBox(width: 14),
                Expanded(
                  child: _jobCardMainInfo(
                    job: job,
                    positionCount: positionCount,
                    proposalCount: proposalCount,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => saved.toggleSaveJob(job),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isSaved
                          ? AppColors.secondary
                          : const Color(0xFFF8F8FA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFEEEEF5)),
                    ),
                    child: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      size: 20,
                      color: _primary,
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

  Widget _buildAppliedJobCard(_AppliedJobItem item) {
    final proposal = item.proposal;
    final job = item.job;
    final isTeam = (job.projectType ?? '').toLowerCase() == 'team';
    final proposalCount = job.proposalCount;
    final positionCount = isTeam
        ? (_positionCounts[job.jobPostId] ?? job.roleCount)
        : 1;
    final clientAvatarUrl = _clientProfilePictures[job.clientId];

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFEEEEF5)),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _clientAvatar(clientAvatarUrl),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          job.jobTitle,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A2E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _proposalStatusChip(proposal.status),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    job.clientName ?? 'Client',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF7D7D7D),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  _categoryChip(job.projectCategory),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.group_outlined,
                        size: 15,
                        color: _primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$positionCount position${positionCount == 1 ? '' : 's'}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF7D7D7D),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.gavel, size: 15, color: _primary),
                      const SizedBox(width: 4),
                      Text(
                        '$proposalCount bid${proposalCount == 1 ? '' : 's'}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF7D7D7D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.payments_outlined,
                              size: 15,
                              color: _primary,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                'Proposed Budget: ${proposal.proposedBudget.toStringAsFixed(0)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF374151),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if ((proposal.proposedDuration ?? '').isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule_outlined,
                                size: 15,
                                color: _primary,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  'Duration: ${proposal.proposedDuration}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Applied ${_formatAppliedDate(proposal.submittedAt)}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _jobCardMainInfo({
    required JobPostModel job,
    required int positionCount,
    required int proposalCount,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          job.jobTitle,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A2E),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          job.clientName ?? 'Client',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFF7D7D7D),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        _categoryChip(job.projectCategory),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.group_outlined, size: 15, color: _primary),
            const SizedBox(width: 4),
            Text(
              '$positionCount position${positionCount == 1 ? '' : 's'}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF7D7D7D),
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.gavel, size: 15, color: _primary),
            const SizedBox(width: 4),
            Text(
              '$proposalCount bid${proposalCount == 1 ? '' : 's'}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF7D7D7D),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _proposalStatusChip(String status) {
    final normalized = status.toLowerCase();

    final config = {
      'pending': ['Pending', const Color(0xFFF59E0B), const Color(0xFFFFF7E6)],
      'accepted': [
        'Accepted',
        const Color(0xFF16A34A),
        const Color(0xFFEAF8EF),
      ],
      'rejected': [
        'Rejected',
        const Color(0xFFDC2626),
        const Color(0xFFFDECEC),
      ],
      'withdrawn': [
        'Withdrawn',
        const Color(0xFF6B7280),
        const Color(0xFFF3F4F6),
      ],
    };

    final item = config[normalized] ?? config['pending']!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: item[2] as Color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        item[0] as String,
        style: GoogleFonts.poppins(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: item[1] as Color,
        ),
      ),
    );
  }

  Widget _clientAvatar(String? avatarUrl) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: avatarUrl != null && avatarUrl.isNotEmpty
            ? Image.network(
                avatarUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(
                    Icons.business_rounded,
                    size: 28,
                    color: _primary,
                  ),
                ),
              )
            : const Center(
                child: Icon(Icons.business_rounded, size: 28, color: _primary),
              ),
      ),
    );
  }

  Widget _categoryChip(String category) {
    final label = kCategoryLabels[category.toLowerCase()] ?? 'General';
    final icon =
        kCategoryIcons[category.toLowerCase()] ?? Icons.work_outline_rounded;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: _primary),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _primary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final isFiltered = _activeCategoryFilter != null;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFiltered
                ? (kCategoryIcons[_activeCategoryFilter] ?? Icons.work_outline)
                : Icons.work_outline,
            size: 56,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered
                ? 'No ${kCategoryLabels[_activeCategoryFilter] ?? _activeCategoryFilter} jobs'
                : 'No jobs available',
            style: GoogleFonts.poppins(
              color: const Color(0xFF7D7D7D),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFiltered
                ? 'Try clearing the filter or check back later.'
                : 'Check back later for new opportunities.',
            style: GoogleFonts.poppins(
              color: const Color(0xFFB5B4B4),
              fontSize: 12,
            ),
          ),
          if (isFiltered) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _clearCategoryFilter,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Clear filter',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _primary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppliedEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 58,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No applied jobs yet',
            style: GoogleFonts.poppins(
              color: const Color(0xFF7D7D7D),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Jobs you apply to will appear here.',
            style: GoogleFonts.poppins(
              color: const Color(0xFFB5B4B4),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAppliedDate(String? raw) {
    if (raw == null || raw.isEmpty) return 'recently';

    try {
      final date = DateTime.parse(raw);
      final diff = DateTime.now().difference(date);

      if (diff.inDays == 0) return 'today';
      if (diff.inDays == 1) return 'yesterday';
      if (diff.inDays < 7) return '${diff.inDays} days ago';

      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return 'recently';
    }
  }
}
