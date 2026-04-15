import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../models/job_post_model.dart';
import '../../models/job_role_model.dart';
import '../../models/client_model.dart';
import '../../models/proposal_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/job_post_provider.dart';
import '../../providers/proposal_provider.dart';
import '../../services/proposal_service.dart';
import '../../widgets/job_detail_header.dart';
import '../../widgets/job_detail_tab_bar.dart';

class ClientJobDetailScreen extends StatefulWidget {
  final JobPostModel job;

  const ClientJobDetailScreen({super.key, required this.job});

  @override
  State<ClientJobDetailScreen> createState() => _ClientJobDetailScreenState();
}

class _ClientJobDetailScreenState extends State<ClientJobDetailScreen> {
  static const Color _primary = Color(0xFF00AAA8);

  int _selectedTab = 0;

  ClientModel? _client;
  bool _clientLoading = true;

  List<JobRoleModel> _roles = [];
  bool _rolesLoading = true;

  List<ProposalModel> _proposals = [];
  bool _proposalsLoading = true;

  List<String> get _tabs => [
    'Bidding (${widget.job.proposalCount})',
    'Workers (0)',
    'Details',
  ];

  List<String> get _tags {
    final tags = <String>[];
    if (widget.job.deadline != null) tags.add(widget.job.deadline!);
    tags.add(_capitalize(widget.job.projectType));
    tags.add(_capitalize(widget.job.projectScope));
    if (widget.job.experienceLevel != null) {
      tags.add(_capitalize(widget.job.experienceLevel!));
    }
    return tags;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchClient();
      _fetchRoles();
      _fetchProposals();
    });
  }

  Future<void> _fetchClient() async {
    final token = context.read<AuthProvider>().token!;
    final client = await context.read<ProfileProvider>().fetchClientById(
      token: token,
      clientId: widget.job.clientId,
    );
    if (mounted) {
      setState(() {
        _client = client;
        _clientLoading = false;
      });
    }
  }

  Future<void> _fetchRoles() async {
    final token = context.read<AuthProvider>().token!;
    await context.read<JobPostProvider>().fetchJobRoles(
      token,
      widget.job.jobPostId,
    );
    if (mounted) {
      setState(() {
        _roles = context.read<JobPostProvider>().jobRoles;
        _rolesLoading = false;
      });
    }
  }

  Future<void> _fetchProposals() async {
    final token = context.read<AuthProvider>().token!;

    // 1. Fetch raw proposals
    await context.read<ProposalProvider>().fetchProposalsByJob(
      token: token,
      jobPostId: widget.job.jobPostId,
    );

    if (!mounted) return;

    // 2. Enrich each with freelancer profile in parallel
    final raw = context.read<ProposalProvider>().proposals;
    final profileProvider = context.read<ProfileProvider>();

    final enriched = await Future.wait(
      raw.map((p) async {
        final freelancer = await profileProvider.fetchFreelancerById(
          token: token,
          freelancerId: p.freelancerId,
        );
        if (freelancer == null) return p;
        return p.copyWith(
          freelancerName: freelancer.displayName,
          freelancerAvatarUrl: freelancer.profilePictureUrl,
        );
      }),
    );

    if (mounted) {
      setState(() {
        _proposals = enriched;
        _proposalsLoading = false;
      });
    }
  }

  Future<void> _acceptBid(ProposalModel proposal) async {
    final token = context.read<AuthProvider>().token!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Accept Bid',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Accept bid from ${proposal.freelancerName ?? 'this freelancer'}?',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: const Color(0xFF7D7D7D)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Accept',
              style: GoogleFonts.poppins(
                color: _primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await context.read<ProposalProvider>().acceptProposal(
      token: token,
      proposalId: proposal.proposalId,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Bid accepted!' : 'Failed to accept bid.',
          style: GoogleFonts.poppins(fontSize: 12),
        ),
        backgroundColor: success ? _primary : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    if (success) {
      // Refresh local list to reflect new status
      setState(() {
        _proposals = _proposals
            .map(
              (p) => p.proposalId == proposal.proposalId
                  ? p.copyWith(status: 'accepted')
                  : p,
            )
            .toList();
      });
    }
  }

  Future<void> _messageBidder(ProposalModel proposal) async {
    final token = context.read<AuthProvider>().token!;
    final currentUserId =
        context.read<AuthProvider>().currentUser?.userId ?? '';

    // Show a quick compose dialog
    final controller = TextEditingController();
    final send = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Message ${proposal.freelancerName ?? 'Freelancer'}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        content: TextField(
          controller: controller,
          maxLines: 4,
          style: GoogleFonts.poppins(fontSize: 12),
          decoration: InputDecoration(
            hintText: 'Write your message...',
            hintStyle: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFFB5B4B4),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFF0F0F1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF00AAA8)),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: const Color(0xFF7D7D7D)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Send',
              style: GoogleFonts.poppins(
                color: _primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (send != true || !mounted) return;
    if (controller.text.trim().isEmpty) return;

    final service = context.read<ProposalProvider>();
    // ProposalService handles the message POST
    try {
      await ProposalService().sendMessage(
        token,
        senderId: currentUserId,
        receiverId: proposal.freelancerId,
        messageText: controller.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Message sent!',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          backgroundColor: _primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to send message.',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Teal header ────────────────────────────────────────────
            JobDetailHeader(
              companyLogo: _client?.profilePictureUrl != null
                  ? ClipOval(
                      child: Image.network(
                        _client!.profilePictureUrl!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(
                      Icons.business,
                      size: 40,
                      color: Color(0xFF00AAA8),
                    ),
              posterName: _clientLoading
                  ? '...'
                  : (_client?.displayName ?? 'Client'),
              username: _clientLoading
                  ? ''
                  : (_client?.websiteUrl ??
                        '@${widget.job.clientId.substring(0, 8)}'),
              jobTitle: widget.job.jobTitle,
              category: _capitalize(widget.job.projectScope),
              tags: _tags,
            ),

            // ── Tab bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(27, 20, 27, 0),
              child: JobDetailTabBar(
                tabs: _tabs,
                selectedIndex: _selectedTab,
                onTabSelected: (i) => setState(() => _selectedTab = i),
              ),
            ),

            // ── Tab content ────────────────────────────────────────────
            if (_selectedTab == 0) _buildBiddingTab(),
            if (_selectedTab == 1) _buildWorkersTab(),
            if (_selectedTab == 2) _buildDetailsTab(),
          ],
        ),
      ),
    );
  }

  // ── Bidding Tab ────────────────────────────────────────────────────────────
  Widget _buildBiddingTab() {
    if (_proposalsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF00AAA8)),
        ),
      );
    }

    if (_proposals.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text(
            'No bids yet.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF7D7D7D),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        children: [
          ..._proposals.map((p) => _buildProposalCard(p)),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF7D7D7D),
                size: 18,
              ),
              label: Text(
                'Load more',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF7D7D7D),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProposalCard(ProposalModel proposal) {
    final isAccepted = proposal.status == 'accepted';
    final isRejected = proposal.status == 'rejected';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAccepted
              ? const Color(0xFF00AAA8).withOpacity(0.3)
              : const Color(0xFFF0F0F1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
            // ── Freelancer row ───────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipOval(
                  child: proposal.freelancerAvatarUrl != null
                      ? Image.network(
                          proposal.freelancerAvatarUrl!,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _avatarFallback(),
                        )
                      : _avatarFallback(),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        proposal.freelancerName ?? 'Freelancer',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                if (isAccepted)
                  _statusBadge('Accepted', const Color(0xFF00AAA8))
                else if (isRejected)
                  _statusBadge('Rejected', Colors.red)
                else
                  const Icon(
                    Icons.push_pin_outlined,
                    size: 20,
                    color: Color(0xFF7D7D7D),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Role + Budget chips ──────────────────────────────────
            Row(
              children: [
                if (proposal.jobRoleId != null) _chip('Role Applied'),
                const SizedBox(width: 8),
                _chip('Rp. ${proposal.proposedBudget.toStringAsFixed(0)}'),
              ],
            ),

            const SizedBox(height: 10),

            // ── Cover letter ─────────────────────────────────────────
            Text(
              proposal.coverLetter,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF333333),
                height: 1.6,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 6),

            // ── Timestamp ────────────────────────────────────────────
            if (proposal.submittedAt != null)
              Text(
                _formatDate(proposal.submittedAt!),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: const Color(0xFF7D7D7D),
                ),
              ),

            const SizedBox(height: 14),

            // ── Action buttons ───────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    icon: Icons.check,
                    label: 'Accept bid',
                    onTap: isAccepted || isRejected
                        ? null
                        : () => _acceptBid(proposal),
                    muted: isAccepted || isRejected,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionButton(
                    icon: Icons.mail_outline,
                    label: 'Message',
                    onTap: () => _messageBidder(proposal),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionButton(
                    icon: Icons.person_outline,
                    label: 'Profile',
                    onTap: () {
                      // TODO: navigate to freelancer public profile
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback() => Container(
    width: 44,
    height: 44,
    color: const Color(0xFFF0F0F1),
    child: const Icon(Icons.person, color: Color(0xFF7D7D7D), size: 24),
  );

  Widget _statusBadge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3)),
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

  Widget _chip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFF0F0F1)),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF333333)),
    ),
  );

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool muted = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: muted ? const Color(0xFFB5B4B4) : _primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Workers Tab ────────────────────────────────────────────────────────────
  Widget _buildWorkersTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          'No workers yet.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: const Color(0xFF7D7D7D),
          ),
        ),
      ),
    );
  }

  // ── Details Tab ────────────────────────────────────────────────────────────
  Widget _buildDetailsTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(27, 20, 27, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Description'),
          const SizedBox(height: 12),
          Text(
            widget.job.jobDescription,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF333333),
              height: 20 / 13,
            ),
          ),
          if (_client?.bio != null) ...[
            const SizedBox(height: 28),
            _sectionTitle('About the Client'),
            const SizedBox(height: 8),
            Text(
              _client!.bio!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF7D7D7D),
                height: 18 / 12,
              ),
            ),
          ],
          const SizedBox(height: 28),
          _sectionTitle('Terms'),
          const SizedBox(height: 12),
          _termRow('Project Type', _capitalize(widget.job.projectType)),
          _termRow('Project Scope', _capitalize(widget.job.projectScope)),
          if (widget.job.workingDays != null)
            _termRow('Working Days', '${widget.job.workingDays} days'),
          if (widget.job.deadline != null)
            _termRow('Deadline', widget.job.deadline!),
          if (widget.job.estimatedDuration != null)
            _termRow('Estimated Duration', widget.job.estimatedDuration!),
          if (widget.job.experienceLevel != null)
            _termRow(
              'Experience Level',
              _capitalize(widget.job.experienceLevel!),
            ),
          if (widget.job.postedAt != null)
            _termRow('Posted At', _formatDate(widget.job.postedAt!)),
          if (!_rolesLoading && _roles.isNotEmpty) ...[
            const SizedBox(height: 8),
            _sectionTitle('Roles'),
            const SizedBox(height: 12),
            ..._roles.map(
              (r) => _termRow(
                r.roleTitle,
                r.roleBudget != null
                    ? 'Rp. ${r.roleBudget!.toStringAsFixed(0)}'
                    : 'Negotiable',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: GoogleFonts.poppins(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF333333),
    ),
  );

  Widget _termRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160,
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

  String _formatDate(String raw) {
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
      return '${dt.day} ${months[dt.month - 1]} ${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }
}
