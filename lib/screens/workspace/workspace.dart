import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:workbyte_app/screens/workspace/workspace_contract.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/job_categories.dart';
import '../../core/constants/text_styles.dart';
import '../../models/job_post_model.dart';
import '../../models/contract_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/contract_provider.dart';
import '../../providers/job_post_provider.dart';

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String _searchQuery = '';
  String _sortOption = 'Latest';
  Map<String, String> _freelancerNames = {};
  final Map<String, String?> _freelancerAvatars = {};

  List<JobPostModel> _jobsWithContracts = [];
  Map<String, List<ContractModel>> _contractsByJob = {};

  /// Statuses where the client is the one holding things up, listed in the
  /// order they should be surfaced on a card.
  static const List<String> _attentionStatuses = [
    'disputed',
    'revision_requested',
    'under_review',
  ];

  /// Everything else, in the order a space usually moves through.
  static const List<String> _quietStatuses = [
    'active',
    'pending',
    'completed',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token!;
      final profile = context.read<ProfileProvider>();
      final clientId = profile.clientProfile?.clientId ?? '';

      final contractProvider = context.read<ContractProvider>();
      final jobPostProvider = context.read<JobPostProvider>();

      await Future.wait([
        contractProvider.fetchContractsByClient(token, clientId),
        jobPostProvider.fetchClientJobPosts(token, clientId),
      ]);

      final contracts = contractProvider.contracts;
      final Map<String, List<ContractModel>> grouped = {};
      for (final c in contracts) {
        grouped.putIfAbsent(c.jobPostId, () => []).add(c);
      }

      final jobs = jobPostProvider.jobPosts
          .where((j) => grouped.containsKey(j.jobPostId))
          .toList();

      final uniqueFreelancerIds = contracts.map((c) => c.freelancerId).toSet();
      final missingIds = uniqueFreelancerIds
          .where((id) => id.isNotEmpty && !_freelancerNames.containsKey(id))
          .toList();

      if (missingIds.isNotEmpty) {
        final results = await Future.wait(
          missingIds.map(
            (id) => profile.fetchFreelancerById(token: token, freelancerId: id),
          ),
        );
        for (int i = 0; i < missingIds.length; i++) {
          final f = results[i];
          if (f != null) {
            _freelancerNames[missingIds[i]] = f.displayName;
            _freelancerAvatars[missingIds[i]] = f.profilePictureUrl;
          }
        }
      }

      setState(() {
        _contractsByJob = grouped;
        _jobsWithContracts = jobs;
      });
    } catch (e) {
      debugPrint('WorkspaceScreen load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<JobPostModel> get _filtered {
    List<JobPostModel> base = List<JobPostModel>.from(_jobsWithContracts);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      base = base.where((j) => j.jobTitle.toLowerCase().contains(q)).toList();
    }

    int workerCount(JobPostModel j) =>
        _contractsByJob[j.jobPostId]?.length ?? 0;

    switch (_sortOption) {
      case 'Oldest':
        base.sort(
          (a, b) => (a.postedAt ?? a.createdAt ?? '').compareTo(
            b.postedAt ?? b.createdAt ?? '',
          ),
        );
        break;
      case 'Most Workers':
        base.sort((a, b) => workerCount(b).compareTo(workerCount(a)));
        break;
      case 'Fewest Workers':
        base.sort((a, b) => workerCount(a).compareTo(workerCount(b)));
        break;
      default:
        base.sort(
          (a, b) => (b.postedAt ?? b.createdAt ?? '').compareTo(
            a.postedAt ?? a.createdAt ?? '',
          ),
        );
    }

    return base;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _load,
                      child: _filtered.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                12,
                                20,
                                24,
                              ),
                              itemCount: _filtered.length,
                              itemBuilder: (_, i) =>
                                  _buildJobCard(_filtered[i]),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 18,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(width: 12),
              Text('Working Spaces', style: AppText.h2),
            ],
          ),
          GestureDetector(
            onTap: _showSortSheet,
            child: Row(
              children: [
                Text(
                  _sortOption,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: AppText.body,
          decoration: InputDecoration(
            hintText: 'Search working spaces...',
            hintStyle: AppText.body.copyWith(color: Colors.grey.shade400),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Colors.grey.shade400,
              size: 22,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJobCard(JobPostModel job) {
    final contracts = _contractsByJob[job.jobPostId] ?? [];
    final statusCounts = _statusCounts(contracts);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openWorkspaceContracts(job),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.work_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.jobTitle,
                            style: AppText.h3,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            categoryLabel(job.projectCategory),
                            style: AppText.caption.copyWith(
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: Colors.grey.shade100),
                const SizedBox(height: 14),
                if (statusCounts.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final entry in statusCounts)
                        _statusChip(entry.key, entry.value),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                Row(
                  children: [
                    _buildAvatarStack(contracts),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${contracts.length} ${contracts.length == 1 ? 'worker' : 'workers'}',
                        style: AppText.captionSemiBold.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Working Space',
                            style: AppText.captionSemiBold.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// How many contracts sit in each status, attention-first so a card reads as
  /// a worklist rather than a tally.
  List<MapEntry<String, int>> _statusCounts(List<ContractModel> contracts) {
    final counts = <String, int>{};
    for (final c in contracts) {
      counts[c.status] = (counts[c.status] ?? 0) + 1;
    }

    final entries = <MapEntry<String, int>>[];
    for (final status in [..._attentionStatuses, ..._quietStatuses]) {
      final count = counts.remove(status);
      if (count != null) entries.add(MapEntry(status, count));
    }
    // A status the app does not know about still gets shown, just last.
    for (final status in counts.keys.toList()..sort()) {
      entries.add(MapEntry(status, counts[status]!));
    }
    return entries;
  }

  Widget _statusChip(String status, int count) {
    final color = _statusColor(status);
    final needsAttention = _attentionStatuses.contains(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(needsAttention ? 0.14 : 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(needsAttention ? 0.45 : 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$count ${_statusLabel(status)}',
            style: AppText.overline.copyWith(
              color: color,
              fontWeight: needsAttention ? FontWeight.w700 : FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return AppColors.primary;
      case 'under_review':
        return const Color(0xFF2196F3);
      case 'revision_requested':
        return const Color(0xFFFF9800);
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'disputed':
        return Colors.redAccent;
      case 'pending':
        return const Color(0xFF9E9E9E);
      case 'cancelled':
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'under_review':
        return 'Under Review';
      case 'revision_requested':
        return 'Revision Requested';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'disputed':
        return 'Disputed';
      case 'pending':
        return 'Pending';
      default:
        return status;
    }
  }

  Widget _buildAvatarStack(List<ContractModel> contracts) {
    const maxShown = 3;
    final shown = contracts.take(maxShown).toList();
    final overflow = contracts.length - shown.length;

    return SizedBox(
      height: 32,
      width: (shown.length * 22.0) + 10 + (overflow > 0 ? 22 : 0),
      child: Stack(
        children: [
          for (int i = 0; i < shown.length; i++)
            Positioned(
              left: i * 22.0,
              child: _workerAvatar(
                _freelancerNames[shown[i].freelancerId],
                _freelancerAvatars[shown[i].freelancerId],
              ),
            ),
          if (overflow > 0)
            Positioned(
              left: shown.length * 22.0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade200,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$overflow',
                  style: AppText.overline.copyWith(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// The worker's own picture when there is one, their initial otherwise.
  Widget _workerAvatar(String? name, String? avatarUrl) {
    final provider = _avatarImage(avatarUrl);
    if (provider != null) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          image: DecorationImage(image: provider, fit: BoxFit.cover),
        ),
      );
    }
    return _initialAvatar(name);
  }

  /// Profile pictures come back either as a remote URL or, for a picture that
  /// has not been uploaded yet, a local file path.
  ImageProvider? _avatarImage(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final value = url.trim();
    if (value.startsWith('http')) return NetworkImage(value);
    final file = File(value);
    return file.existsSync() ? FileImage(file) : null;
  }

  Widget _initialAvatar(String? name) {
    final initial = (name != null && name.trim().isNotEmpty)
        ? name.trim()[0].toUpperCase()
        : 'F';
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withOpacity(0.15),
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: AppText.captionSemiBold.copyWith(color: AppColors.primary),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.work_outline_rounded,
                  size: 48,
                  color: AppColors.primary.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No working spaces yet',
                style: AppText.h3.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                'Jobs with hired freelancers will appear here',
                style: AppText.caption.copyWith(color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openWorkspaceContracts(JobPostModel job) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkspaceContractScreen(
          jobPostId: job.jobPostId,
          jobTitle: job.jobTitle,
        ),
      ),
    ).then((_) => _load());
  }

  void _showSortSheet() {
    const options = ['Latest', 'Oldest', 'Most Workers', 'Fewest Workers'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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
            Text(
              'Sort by',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((option) {
                final isSelected = _sortOption == option;
                return GestureDetector(
                  onTap: () {
                    setState(() => _sortOption = option);
                    Navigator.pop(context);
                  },
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
                      option,
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
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
