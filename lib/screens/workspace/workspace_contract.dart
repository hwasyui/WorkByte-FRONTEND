import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../models/contract_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/contract_provider.dart';
import 'workspace_detail.dart';

class WorkspaceContractScreen extends StatefulWidget {
  /// Provided when opened from a client's job post ("workers on this job").
  /// Left null for the freelancer's full contract list.
  final String? jobPostId;
  final String? jobTitle;

  const WorkspaceContractScreen({super.key, this.jobPostId, this.jobTitle});

  @override
  State<WorkspaceContractScreen> createState() =>
      _WorkspaceContractScreenState();
}

class _WorkspaceContractScreenState extends State<WorkspaceContractScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<ContractModel> _allContracts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortOption = 'Latest';

  static const List<String> _tabs = [
    'Active',
    'Completed',
    'Cancelled',
    'Disputed',
    'All',
  ];
  // add to state fields
  Map<String, String> _nameCache = {};
  static const Map<String, List<String>?> _tabStatusMap = {
    'Active': ['active', 'under_review', 'revision_requested'],
    'Completed': ['completed'],
    'Cancelled': ['cancelled'],
    'Disputed': ['disputed'],
    'All': null,
  };

  bool get _isClient => context.read<ProfileProvider>().isClient;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this)
      ..addListener(() {
        if (mounted) setState(() {});
      });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadContracts());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContracts() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token!;
      final profile = context.read<ProfileProvider>();
      final contractProvider = context.read<ContractProvider>();

      if (profile.isClient) {
        final clientId = profile.clientProfile?.clientId ?? '';
        await contractProvider.fetchContractsByClient(token, clientId);
        final all = contractProvider.contracts;
        _allContracts = widget.jobPostId == null
            ? all
            : all.where((c) => c.jobPostId == widget.jobPostId).toList();

        // Resolve freelancer names
        final ids = _allContracts
            .map((c) => c.freelancerId)
            .toSet()
            .where((id) => id.isNotEmpty && !_nameCache.containsKey(id))
            .toList();
        if (ids.isNotEmpty) {
          final results = await Future.wait(
            ids.map(
              (id) =>
                  profile.fetchFreelancerById(token: token, freelancerId: id),
            ),
          );
          for (int i = 0; i < ids.length; i++) {
            final f = results[i];
            if (f != null) _nameCache[ids[i]] = f.displayName;
          }
        }
      } else {
        final freelancerId = profile.freelancerProfile?.freelancerId ?? '';
        await contractProvider.fetchContractsByFreelancer(token, freelancerId);
        _allContracts = contractProvider.contracts;

        // Resolve client names
        final ids = _allContracts
            .map((c) => c.clientId)
            .toSet()
            .where((id) => id.isNotEmpty && !_nameCache.containsKey(id))
            .toList();
        if (ids.isNotEmpty) {
          final results = await Future.wait(
            ids.map(
              (id) => profile.fetchClientById(token: token, clientId: id),
            ),
          );
          for (int i = 0; i < ids.length; i++) {
            final c = results[i];
            if (c != null) _nameCache[ids[i]] = c.displayName;
          }
        }
      }
    } catch (e) {
      debugPrint('WorkspaceContractScreen load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<ContractModel> get _filtered {
    final selectedTab = _tabs[_tabController.index];
    final selectedStatuses = _tabStatusMap[selectedTab];

    List<ContractModel> base = selectedStatuses == null
        ? List<ContractModel>.from(_allContracts)
        : _allContracts
              .where((c) => selectedStatuses.contains(c.status))
              .toList();

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      base = base.where((c) {
        return c.contractTitle.toLowerCase().contains(query) ||
            c.roleTitle.toLowerCase().contains(query);
      }).toList();
    }

    switch (_sortOption) {
      case 'Oldest':
        base.sort((a, b) => (a.createdAt ?? '').compareTo(b.createdAt ?? ''));
        break;
      case 'Budget: High to Low':
        base.sort((a, b) => b.agreedBudget.compareTo(a.agreedBudget));
        break;
      case 'Budget: Low to High':
        base.sort((a, b) => a.agreedBudget.compareTo(b.agreedBudget));
        break;
      default:
        base.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
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
            _buildTabBar(),
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
                      onRefresh: _loadContracts,
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
                                  _buildContractCard(_filtered[i]),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final title = widget.jobTitle ?? 'My Contracts';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
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
                Expanded(
                  child: Text(
                    title,
                    style: AppText.h2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
            hintText: 'Search contracts...',
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

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          onTap: (_) => setState(() {}),
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(24),
          ),
          dividerColor: Colors.transparent,
          labelPadding: const EdgeInsets.symmetric(horizontal: 6),
          padding: EdgeInsets.zero,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          tabs: List.generate(_tabs.length, (i) {
            final selected = _tabController.index == i;
            return Tab(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: selected
                      ? null
                      : Border.all(color: Colors.grey.shade200),
                  color: selected ? Colors.transparent : Colors.white,
                ),
                child: Text(
                  _tabs[i],
                  style: AppText.captionSemiBold.copyWith(
                    color: selected ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildContractCard(ContractModel contract) {
    final statusColor = _statusColor(contract.status);
    final statusLabel = _statusLabel(contract.status);
    final isClient = _isClient;
    final otherPartyId = isClient ? contract.freelancerId : contract.clientId;
    final otherPartyName =
        _nameCache[otherPartyId] ?? (isClient ? 'Freelancer' : 'Client');
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor.withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          statusLabel,
                          style: AppText.overline.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        contract.contractTitle,
                        style: AppText.h3,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 220),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    contract.roleTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${contract.budgetCurrency} ${contract.agreedBudget.toStringAsFixed(0)}',
                    style: AppText.caption.copyWith(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  child: Text(
                    otherPartyName.isNotEmpty
                        ? otherPartyName[0].toUpperCase()
                        : '?',
                    style: AppText.captionSemiBold.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    otherPartyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(contract.startDate),
                      style: AppText.caption.copyWith(
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkspaceDetailScreen(
                      contract: contract,
                      viewerRole: isClient ? 'client' : 'freelancer',
                    ),
                  ),
                ).then((_) => _loadContracts()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'View Details',
                  style: AppText.bodySemiBold.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final currentTab = _tabs[_tabController.index];
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
                'No contracts yet',
                style: AppText.h3.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                currentTab == 'All'
                    ? 'All contracts will appear here'
                    : '$currentTab contracts will appear here',
                style: AppText.caption.copyWith(color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showSortSheet() {
    const options = [
      'Latest',
      'Oldest',
      'Budget: High to Low',
      'Budget: Low to High',
    ];
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
      case 'cancelled':
        return Colors.grey;
      case 'disputed':
        return Colors.redAccent;
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
      default:
        return status;
    }
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return '—';
    try {
      final d = DateTime.parse(date);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return date;
    }
  }
}
