import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/admin_provider.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _freelancerPage = 1;
  int _clientPage = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final admin = context.read<AdminProvider>();
      admin.loadFreelancersPage(1);
      admin.loadClientsPage(1);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        return Column(
          children: [
            // Summary chips
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  _SummaryChip(
                    label: 'Total',
                    value: admin.totalUsers.toString(),
                    color: const Color(0xFF4F46E5),
                  ),
                  const SizedBox(width: 8),
                  _SummaryChip(
                    label: 'Freelancers',
                    value: admin.totalFreelancers.toString(),
                    color: const Color(0xFF059669),
                  ),
                  const SizedBox(width: 8),
                  _SummaryChip(
                    label: 'Clients',
                    value: admin.totalClients.toString(),
                    color: const Color(0xFF0891B2),
                  ),
                ],
              ),
            ),

            // Tab bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF4F46E5),
                unselectedLabelColor: const Color(0xFF6B7280),
                indicatorColor: const Color(0xFF4F46E5),
                labelStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
                tabs: [
                  Tab(text: 'Freelancers (${admin.totalFreelancers})'),
                  Tab(text: 'Clients (${admin.totalClients})'),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _UsersList(
                    users: admin.tableFreelancers,
                    isLoading: admin.isTableLoading,
                    type: 'Freelancer',
                    color: const Color(0xFF059669),
                    pagination: admin.freelancerPagination,
                    currentPage: _freelancerPage,
                    onPageChange: (p) {
                      setState(() => _freelancerPage = p);
                      admin.loadFreelancersPage(p);
                    },
                    subtitleBuilder: (u) {
                      final rate = u['estimated_rate'];
                      if (rate == null) return 'Rate not set';
                      final currency = u['rate_currency'] ?? 'USD';
                      final time = u['rate_time'] ?? 'hr';
                      return '$currency ${rate.toString()} / $time';
                    },
                  ),
                  _UsersList(
                    users: admin.tableClients,
                    isLoading: admin.isTableLoading,
                    type: 'Client',
                    color: const Color(0xFF0891B2),
                    pagination: admin.clientPagination,
                    currentPage: _clientPage,
                    onPageChange: (p) {
                      setState(() => _clientPage = p);
                      admin.loadClientsPage(p);
                    },
                    subtitleBuilder: (u) {
                      final posted = u['total_jobs_posted'] ?? 0;
                      final completed = u['total_projects_completed'] ?? 0;
                      return '$posted jobs posted · $completed completed';
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _UsersList extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  final bool isLoading;
  final String type;
  final Color color;
  final Map<String, dynamic> pagination;
  final int currentPage;
  final ValueChanged<int> onPageChange;
  final String Function(Map<String, dynamic>) subtitleBuilder;

  const _UsersList({
    required this.users,
    required this.isLoading,
    required this.type,
    required this.color,
    required this.pagination,
    required this.currentPage,
    required this.onPageChange,
    required this.subtitleBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
      );
    }

    if (users.isEmpty) {
      return Center(
        child: Text(
          'No ${type.toLowerCase()}s found',
          style: GoogleFonts.poppins(color: const Color(0xFF9CA3AF)),
        ),
      );
    }

    final total = (pagination['total'] as num?)?.toInt() ?? 0;
    final totalPages = (pagination['total_pages'] as num?)?.toInt() ?? 1;

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final user = users[i];
              final name = (user['full_name'] as String?)?.isNotEmpty == true
                  ? user['full_name'] as String
                  : 'Unknown';
              final joined = _formatDate(user['created_at']?.toString());

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: color.withOpacity(0.12),
                      child: Text(
                        name[0].toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF111827),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            subtitleBuilder(user),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      joined,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Pagination
        if (totalPages > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$total total',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: currentPage > 1
                          ? () => onPageChange(currentPage - 1)
                          : null,
                      color: const Color(0xFF4F46E5),
                      iconSize: 20,
                    ),
                    Text(
                      '$currentPage / $totalPages',
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: currentPage < totalPages
                          ? () => onPageChange(currentPage + 1)
                          : null,
                      color: const Color(0xFF4F46E5),
                      iconSize: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '-';
    }
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$value ',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            TextSpan(
              text: label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
