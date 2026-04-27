import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../models/client_model.dart';
import '../../models/freelancer_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../screens/client_history/client_history_screen.dart';
import '../../services/api_service.dart';

class PeopleListScreen extends StatefulWidget {
  final bool showClients;

  const PeopleListScreen({super.key, required this.showClients});

  @override
  State<PeopleListScreen> createState() => _PeopleListScreenState();
}

class _PeopleListScreenState extends State<PeopleListScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _all = [];
  List<dynamic> _filtered = [];
  final TextEditingController _searchController = TextEditingController();

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
    });
  }

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

      setState(() {
        _all = mapped;
        _filtered = List.from(mapped);
        _isLoading = false;
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
                      if (!widget.showClients && context.watch<ProfileProvider>().isClient) ...[
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ClientHistoryScreen(),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: AppColors.primary.withOpacity(0.16)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                        const Icon(Icons.search_rounded, size: 20, color: Color(0xFF9CA3AF)),
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
                              Icon(Icons.error_outline_rounded,
                                  size: 48, color: Colors.grey.shade300),
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
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                itemCount: _filtered.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final person = _filtered[index];
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
                  Text(
                    freelancer.displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                    ),
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
        image: provider != null ? DecorationImage(image: provider, fit: BoxFit.cover) : null,
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

  const _StatChip({required this.icon, required this.label, this.isHighlight = false});

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

// ── Profile detail screen ──────────────────────────────────────────────────────
class PeopleProfileScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final name = isClient ? client?.displayName ?? 'Client' : freelancer?.displayName ?? 'Freelancer';
    final avatarUrl = isClient ? client?.profilePictureUrl : freelancer?.profilePictureUrl;
    final bio = isClient
        ? (client?.bio ?? 'No description available.')
        : (freelancer?.bio ?? 'No description available.');
    final badge = isClient
        ? client?.averageRatingGiven != null
            ? '★ ${client!.averageRatingGiven!.toStringAsFixed(1)}'
            : 'No rating yet'
        : freelancer?.estimatedRate != null
            ? freelancer!.formattedRate
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
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
              ),
            ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                  // Stats row
                  Row(
                    children: [
                      if (isClient) ...[
                        Expanded(
                          child: _StatCard(
                            label: 'Jobs Posted',
                            value: '${client?.totalJobsPosted ?? 0}',
                            icon: Icons.work_outline_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Completed',
                            value: '${client?.totalProjectsCompleted ?? 0}',
                            icon: Icons.check_circle_outline_rounded,
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: _StatCard(
                            label: 'Projects',
                            value: '${freelancer?.totalProjects ?? 0}',
                            icon: Icons.folder_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Rate',
                            value: freelancer?.estimatedRate != null
                                ? freelancer!.estimatedRate!.toStringAsFixed(0)
                                : 'N/A',
                            icon: Icons.attach_money_rounded,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  // About section
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

                  // Details section
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
                        if (isClient) ...[
                          _DetailRow(
                            label: 'Website',
                            value: client?.websiteUrl ?? 'Not provided',
                          ),
                          const Divider(height: 20, color: Color(0xFFF0F0F1)),
                          _DetailRow(label: 'Rating', value: badge),
                        ] else ...[
                          _DetailRow(label: 'Rate', value: badge),
                          if (freelancer?.rateTime != null) ...[
                            const Divider(height: 20, color: Color(0xFFF0F0F1)),
                            _DetailRow(label: 'Period', value: freelancer!.rateTime!),
                          ],
                        ],
                      ],
                    ),
                  ),
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.icon});

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
