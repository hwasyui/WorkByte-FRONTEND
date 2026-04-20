import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../models/contract_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import 'workspace_detail.dart';

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen>
    with SingleTickerProviderStateMixin {
  static final String _baseUrl = (dotenv.env['BACKEND'] ?? '').replaceAll(
    RegExp(r'/$'),
    '',
  );

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<ContractModel> _allContracts = [];
  bool _isLoading = true;
  String _searchQuery = '';

  // active tabs
  static const _tabs = ['Active', 'Completed', 'All'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadContracts());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Data ─────────────────────────────────────────────────────────────────

  String get _viewerRole {
    final profile = context.read<ProfileProvider>();
    return profile.freelancerProfile != null ? 'freelancer' : 'client';
  }

  String get _entityId {
    final profile = context.read<ProfileProvider>();
    if (_viewerRole == 'freelancer') {
      return profile.freelancerProfile?.freelancerId ?? '';
    }
    return profile.clientProfile?.clientId ?? '';
  }

  Future<void> _loadContracts() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token!;
      final role = _viewerRole;
      final id = _entityId;

      final endpoint = role == 'freelancer'
          ? '$_baseUrl/contracts/freelancer/$id'
          : '$_baseUrl/contracts/client/$id';

      final res = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = body['details'] ?? body['data'] ?? [];
        setState(() {
          _allContracts = (list as List)
              .map((e) => ContractModel.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('WorkspaceScreen load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<ContractModel> get _filtered {
    final tabIndex = _tabController.index;
    List<ContractModel> base;

    if (tabIndex == 0) {
      // Active = active, under_review, revision_requested
      base = _allContracts
          .where(
            (c) => [
              'active',
              'under_review',
              'revision_requested',
            ].contains(c.status),
          )
          .toList();
    } else if (tabIndex == 1) {
      // Completed = completed, cancelled, disputed
      base = _allContracts
          .where(
            (c) => ['completed', 'cancelled', 'disputed'].contains(c.status),
          )
          .toList();
    } else {
      base = _allContracts;
    }

    if (_searchQuery.isNotEmpty) {
      base = base
          .where(
            (c) =>
                c.contractTitle.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                (c.roleTitle).toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    return base;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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

  // ── Header ────────────────────────────────────────────────────────────────

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
            onTap: () => _showSortSheet(),
            child: Row(
              children: [
                Text(
                  'Latest',
                  style: AppText.bodySemiBold.copyWith(
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.sort_rounded, size: 20, color: Colors.grey.shade500),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Search ────────────────────────────────────────────────────────────────

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

  // ── Tabs ──────────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final selected = _tabController.index == i;
          return GestureDetector(
            onTap: () => _tabController.animateTo(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? AppColors.primary : Colors.grey.shade200,
                ),
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
    );
  }

  // ── Contract Card ─────────────────────────────────────────────────────────

  Widget _buildContractCard(ContractModel contract) {
    final statusColor = _statusColor(contract.status);
    final statusLabel = _statusLabel(contract.status);
    final role = _viewerRole;

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
          // Status badge + title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status badge
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
                      // Title
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

          // Role tag + budget
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F7F7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      contract.roleTitle,
                      style: AppText.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
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

          // Other party info
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  child: Text(
                    _otherPartyInitial(contract, role),
                    style: AppText.captionSemiBold.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  role == 'freelancer' ? '1 client' : '1 worker',
                  style: AppText.caption.copyWith(color: Colors.grey.shade600),
                ),
                const Spacer(),
                // Start date
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

          // Working Space button
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
                      viewerRole: role,
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
                  'Working Space',
                  style: AppText.bodySemiBold.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty State ───────────────────────────────────────────────────────────

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
                _tabController.index == 0
                    ? 'Active contracts will appear here'
                    : 'Completed contracts will appear here',
                style: AppText.caption.copyWith(color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Sort Sheet ────────────────────────────────────────────────────────────

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sort by', style: AppText.h3),
            const SizedBox(height: 16),
            ...[
              'Latest',
              'Oldest',
              'Budget: High to Low',
              'Budget: Low to High',
            ].map(
              (label) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(label, style: AppText.body),
                onTap: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return const Color(0xFF00AAA8);
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

  String _otherPartyInitial(ContractModel contract, String role) {
    // Placeholder — replace with actual name once you enrich the endpoint
    return role == 'freelancer' ? 'C' : 'F';
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
