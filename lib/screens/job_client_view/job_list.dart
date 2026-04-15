import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_post_provider.dart';
import '../../providers/profile_provider.dart';
import '../dashboard/dashboard.dart';

class JobListScreen extends StatefulWidget {
  const JobListScreen({super.key});

  @override
  JobListScreenState createState() => JobListScreenState();
}

class JobListScreenState extends State<JobListScreen> {
  static const Color _primary = Color(0xFF00AAA8);

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allJobs = [];
  List<Map<String, dynamic>> _filteredJobs = [];
  bool _isLoading = true;
  String _sortOption = 'Latest';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearch);
    // ← defer fetch until after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchJobs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchJobs() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final token = auth.token!;

      // ← Use clientId from clientProfile, not userId from auth
      final clientId = context.read<ProfileProvider>().clientProfile!.clientId;

      final provider = context.read<JobPostProvider>();
      final jobs = await provider.fetchMyJobPosts(token, clientId);

      setState(() {
        _allJobs = jobs ?? [];
        _filteredJobs = List.from(_allJobs);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _onSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredJobs = _allJobs
          .where(
            (job) => (job['job_title'] as String? ?? '').toLowerCase().contains(
              query,
            ),
          )
          .toList();
    });
  }

  void _onSortChanged(String value) {
    setState(() {
      _sortOption = value;
      _allJobs.sort(
        (a, b) => value == 'Latest'
            ? (b['created_at'] ?? '').compareTo(a['created_at'] ?? '')
            : (a['created_at'] ?? '').compareTo(b['created_at'] ?? ''),
      );
      _filteredJobs.sort(
        (a, b) => value == 'Latest'
            ? (b['created_at'] ?? '').compareTo(a['created_at'] ?? '')
            : (a['created_at'] ?? '').compareTo(b['created_at'] ?? ''),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ── Back button + title ────────────────────────────────
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        ),
                        icon: const Icon(
                          Icons.chevron_left,
                          color: Color(0xFF1A1A1A),
                          size: 28,
                        ),
                      ),
                      const Text(
                        'My jobs',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                  // ── Sort dropdown ──────────────────────────────────────
                  GestureDetector(
                    onTap: () => _showSortSheet(),
                    child: Row(
                      children: [
                        Text(
                          _sortOption,
                          style: const TextStyle(
                            color: Color(0xFF7D7D7D),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.sort,
                          color: Color(0xFF7D7D7D),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ── Search bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search jobs...',
                    hintStyle: const TextStyle(
                      color: Color(0xFFB5B4B4),
                      fontSize: 13,
                    ),
                    suffixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF7D7D7D),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // ── Job list ────────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00AAA8),
                      ),
                    )
                  : _filteredJobs.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      color: _primary,
                      onRefresh: _fetchJobs,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _filteredJobs.length,
                        itemBuilder: (context, index) =>
                            _buildJobCard(_filteredJobs[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Job card ──────────────────────────────────────────────────────────────
  Widget _buildJobCard(Map<String, dynamic> job) {
    final isTeam = (job['project_type'] ?? '') == 'team';
    final teamCount = job['team_count'] ?? job['member_count'] ?? '';
    final deadline = job['deadline'] ?? job['created_at'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title ────────────────────────────────────────────────────
          Text(
            job['job_title'] ?? 'Untitled',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          // ── Meta row ─────────────────────────────────────────────────
          Row(
            children: [
              Text(
                job['category'] ?? job['job_category'] ?? 'General',
                style: const TextStyle(color: Color(0xFF7D7D7D), fontSize: 12),
              ),
              if (isTeam && teamCount != '') ...[
                const SizedBox(width: 12),
                const Icon(
                  Icons.people_outline,
                  size: 14,
                  color: Color(0xFF7D7D7D),
                ),
                const SizedBox(width: 4),
                Text(
                  teamCount.toString(),
                  style: const TextStyle(
                    color: Color(0xFF7D7D7D),
                    fontSize: 12,
                  ),
                ),
              ],
              if (deadline.isNotEmpty) ...[
                const SizedBox(width: 12),
                Text(
                  _formatDate(deadline.toString()),
                  style: const TextStyle(
                    color: Color(0xFF7D7D7D),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          // ── Project type badge ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: _primary),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isTeam ? 'Team' : 'Individual',
              style: const TextStyle(
                color: Color(0xFF00AAA8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // ── Bidding row ──────────────────────────────────────────────
          Row(
            children: [
              // Placeholder avatars
              SizedBox(
                width: 60,
                height: 28,
                child: Stack(
                  children: [
                    _placeholderAvatar(0),
                    _placeholderAvatar(1),
                    _placeholderAvatar(2),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '+${job['bid_count'] ?? job['proposal_count'] ?? 0} bidding',
                style: const TextStyle(color: Color(0xFF7D7D7D), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _placeholderAvatar(int index) {
    final colors = [
      const Color(0xFFB0C4DE),
      const Color(0xFF98D8C8),
      const Color(0xFFDEB0C4),
    ];
    return Positioned(
      left: index * 18.0,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: colors[index],
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Icon(Icons.person, size: 14, color: Colors.white),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_outline, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No jobs posted yet',
            style: TextStyle(
              color: Color(0xFF7D7D7D),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your posted jobs will appear here.',
            style: TextStyle(color: Color(0xFFB5B4B4), fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Sort bottom sheet ─────────────────────────────────────────────────────
  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sort by',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 16),
            for (final option in ['Latest', 'Oldest'])
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(option, style: const TextStyle(fontSize: 13)),
                trailing: _sortOption == option
                    ? const Icon(Icons.check, color: Color(0xFF00AAA8))
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _onSortChanged(option);
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }
}
