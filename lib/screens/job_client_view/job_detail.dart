import 'package:workbyte_app/services/dm_service.dart';
import 'package:workbyte_app/widgets/appeal_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/colors.dart';
import '../../models/job_post_model.dart';
import '../../models/job_role_model.dart';
import '../../models/job_role_skill_model.dart';
import '../../models/skill_model.dart';
import '../../models/job_file_model.dart';
import '../../models/client_model.dart';
import '../../models/proposal_model.dart';
import '../../models/proposal_file_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/job_post_provider.dart';
import '../../providers/proposal_provider.dart';
import '../../providers/proposal_file_provider.dart';
import '../../providers/contract_provider.dart';
import '../../providers/skill_provider.dart';
import '../../services/proposal_service.dart';
import '../../models/freelancer_model.dart';
import '../../widgets/job_detail_header.dart';
import '../../widgets/job_detail_tab_bar.dart';
import '../contract/generate_contract_screen.dart';
import '../people_list/people_list_screen.dart';
import '../../core/utils/helpers.dart';

class ClientJobDetailScreen extends StatefulWidget {
  final JobPostModel job;

  const ClientJobDetailScreen({super.key, required this.job});

  @override
  State<ClientJobDetailScreen> createState() => _ClientJobDetailScreenState();
}

class _ClientJobDetailScreenState extends State<ClientJobDetailScreen> {
  static const Color _primary = AppColors.primary;

  int _selectedTab = 0;

  final Set<String> _expandedProposalIds = {};

  ClientModel? _client;
  bool _clientLoading = true;

  List<JobRoleModel> _roles = [];
  bool _rolesLoading = true;

  List<ProposalModel> _proposals = [];
  bool _proposalsLoading = true;

  Map<String, List<JobRoleSkillModel>> _roleSkillsMap = {};
  List<SkillModel> _allSkills = [];
  List<JobFileModel> _jobFiles = [];
  bool _filesLoading = true;

  List<String> get _tabs => [
    'Bidding (${widget.job.proposalCount})',
    'Workers (0)',
    'Details',
  ];

  List<String> get _tags {
    final tags = <String>[];
    if (widget.job.deadline != null) tags.add(widget.job.deadline!);
    tags.add(_capitalize(widget.job.projectType));
    if (widget.job.experienceLevel != null) {
      tags.add(_capitalize(widget.job.experienceLevel!));
    }
    if (widget.job.projectScope != null) {
      tags.add(_capitalize(widget.job.projectScope!));
    }
    return tags;
  }

  String _roleTitle(String? jobRoleId) {
    if (jobRoleId == null) return '';
    try {
      return _roles.firstWhere((r) => r.jobRoleId == jobRoleId).roleTitle;
    } catch (_) {
      return 'Role Applied';
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchClient();
      _fetchRoles();
      _fetchProposals();
      _fetchAllSkills();
      _fetchJobFiles();
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
    if (!mounted) return;
    setState(() {
      _roles = context.read<JobPostProvider>().jobRoles;
      _rolesLoading = false;
    });
    await _fetchRoleSkills(token);
  }

  Future<void> _fetchRoleSkills(String token) async {
    final provider = context.read<JobPostProvider>();
    for (final role in _roles) {
      await provider.fetchRoleSkills(token, role.jobRoleId);
    }
    if (!mounted) return;
    setState(() {
      _roleSkillsMap = {
        for (final role in _roles)
          role.jobRoleId: provider.skillsForRole(role.jobRoleId),
      };
    });
  }

  Future<void> _fetchAllSkills() async {
    final token = context.read<AuthProvider>().token!;
    await context.read<SkillProvider>().fetchAllSkills(token);
    if (!mounted) return;
    setState(() {
      _allSkills = context.read<SkillProvider>().skills;
    });
  }

  Future<void> _fetchJobFiles() async {
    final token = context.read<AuthProvider>().token!;
    await context.read<JobPostProvider>().fetchJobFiles(
      token,
      widget.job.jobPostId,
    );
    if (!mounted) return;
    setState(() {
      _jobFiles = context.read<JobPostProvider>().filesForJob(
        widget.job.jobPostId,
      );
      _filesLoading = false;
    });
  }

  Future<void> _openJobFile(JobFileModel file) async {
    final token = context.read<AuthProvider>().token;
    await openDocumentFromUrl(context, file.fileUrl, token: token, fileName: file.fileName);
  }

  Future<void> _fetchProposals() async {
    final token = context.read<AuthProvider>().token!;

    await context.read<ProposalProvider>().fetchProposalsByJob(
      token: token,
      jobPostId: widget.job.jobPostId,
    );

    if (!mounted) return;

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

    if (!mounted) return;

    setState(() {
      _proposals = enriched;
      _proposalsLoading = false;
    });

    await context.read<ProposalFileProvider>().fetchFilesForProposals(
      token,
      enriched.map((p) => p.proposalId).toList(),
    );
  }

  Future<void> _acceptBid(ProposalModel proposal) async {
    final token = context.read<AuthProvider>().token!;

    final freelancerName = proposal.freelancerName?.trim().isNotEmpty == true
        ? proposal.freelancerName!.trim()
        : 'this freelancer';

    final confirmed = await _showActionDialog(
      title: 'Accept Bid',
      message:
          'Accept the bid from $freelancerName and continue to contract setup?',
      primaryLabel: 'Continue',
      secondaryLabel: 'Cancel',
      icon: Icons.verified_rounded,
      accent: _primary,
    );

    if (confirmed != true || !mounted) return;

    final success = await context.read<ProposalProvider>().acceptProposal(
      token: token,
      proposalId: proposal.proposalId,
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to accept bid.',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _proposals = _proposals
          .map(
            (p) => p.proposalId == proposal.proposalId
                ? p.copyWith(status: 'accepted')
                : p,
          )
          .toList();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Bid accepted. Continue with contract setup.',
          style: GoogleFonts.poppins(fontSize: 12),
        ),
        backgroundColor: _primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    _createAndNavigateToContract(proposal);
  }

  Future<void> _rejectBid(ProposalModel proposal) async {
    final token = context.read<AuthProvider>().token!;

    final freelancerName = proposal.freelancerName?.trim().isNotEmpty == true
        ? proposal.freelancerName!.trim()
        : 'this freelancer';

    final confirmed = await _showActionDialog(
      title: 'Reject Bid',
      message:
          'Reject the bid from $freelancerName? This action will mark the proposal as rejected.',
      primaryLabel: 'Reject bid',
      secondaryLabel: 'Cancel',
      icon: Icons.close_rounded,
      accent: Colors.redAccent,
    );

    if (confirmed != true || !mounted) return;

    final success = await context.read<ProposalProvider>().rejectProposal(
      token: token,
      proposalId: proposal.proposalId,
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to reject bid.',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() {
      _proposals = _proposals
          .map(
            (p) => p.proposalId == proposal.proposalId
                ? p.copyWith(status: 'rejected')
                : p,
          )
          .toList();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Bid rejected.',
          style: GoogleFonts.poppins(fontSize: 12),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _createAndNavigateToContract(ProposalModel proposal) async {
    final token = context.read<AuthProvider>().token!;
    final contractProvider = context.read<ContractProvider>();

    try {
      final contractData = {
        'job_post_id': widget.job.jobPostId,
        'job_role_id': proposal.jobRoleId,
        'proposal_id': proposal.proposalId,
        'freelancer_id': proposal.freelancerId,
        'client_id': widget.job.clientId,
        'contract_title': 'Contract for ${widget.job.jobTitle}',
        'role_title': _roleTitle(proposal.jobRoleId),
        'agreed_budget': proposal.proposedBudget,
        'budget_currency': 'IDR',
        'payment_structure': 'full_payment',
        'status': 'active',
        'start_date': DateTime.now().toString().substring(0, 10),
      };

      final contract = await contractProvider.createContract(
        token,
        contractData,
      );

      if (!mounted) return;

      if (contract != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GenerateContractScreen(
              contractId: contract.contractId,
              initialContract: contract,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to create contract: ${contractProvider.error}',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: ${e.toString()}',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _viewFreelancerProfile(ProposalModel proposal) async {
    final token = context.read<AuthProvider>().token!;
    final profileProvider = context.read<ProfileProvider>();

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final FreelancerModel? freelancer = await profileProvider
          .fetchFreelancerById(
            token: token,
            freelancerId: proposal.freelancerId,
          );
      if (!mounted) return;
      Navigator.pop(context);

      if (freelancer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not load profile.',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PeopleProfileScreen(isClient: false, freelancer: freelancer),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not load profile.',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _messageBidder(ProposalModel proposal) async {
    final token = context.read<AuthProvider>().token!;
    final currentUserId =
        context.read<AuthProvider>().currentUser?.userId ?? '';

    final controller = TextEditingController();
    final send = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 40,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Close button
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: const Icon(
                        Icons.close,
                        size: 20,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Icon + Title + Subtitle
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEEEBFF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Message ${proposal.freelancerName ?? 'Freelancer'}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: const Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Introduce yourself and discuss the project.',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Textarea
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0EEFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: controller,
                          maxLines: 6,
                          maxLength: 500,
                          onChanged: (_) => setModalState(() {}),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF111827),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Write your message...',
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFFB0ABCF),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.fromLTRB(
                              16,
                              16,
                              16,
                              0,
                            ),
                            counterText: '',
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                          child: Row(
                            children: [
                              const Spacer(),
                              const Icon(
                                Icons.attach_file_rounded,
                                size: 20,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 10),
                              const Icon(
                                Icons.sentiment_satisfied_alt_outlined,
                                size: 20,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${controller.text.length}/500',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Professional note
                  Row(
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Be professional and respectful when messaging.',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  const SizedBox(height: 16),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context, true),
                          icon: const Icon(
                            Icons.send_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Send',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (send != true || !mounted) return;
    if (controller.text.trim().isEmpty) return;

    try {
      final freelancer = await context
          .read<ProfileProvider>()
          .fetchFreelancerById(
            token: token,
            freelancerId: proposal.freelancerId,
          );

      if (!mounted) return;

      if (freelancer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Freelancer profile not found.',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final result = await DMService().startThread(
        token: token,
        participantId: freelancer.userId,
        jobPostId: proposal.jobPostId,
        messageText: controller.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.alreadyExists
                ? 'Conversation already exists.'
                : 'Message sent!',
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

  Future<void> _openFile(ProposalFileModel file) async {
    final token = context.read<AuthProvider>().token;
    await openDocumentFromUrl(context, file.fileUrl, token: token, fileName: file.fileName);
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _projectCategoryLabel(String? value) {
    if (value == null || value.trim().isEmpty) return 'General';

    const labels = {
      'mobile_dev': 'Mobile Dev',
      'backend_dev': 'Backend Dev',
      'web_dev': 'Web Dev',
      'ui_ux_design': 'UI/UX Design',
      'graphic_design': 'Graphic Design',
      'copywriting': 'Copywriting',
      'data_analytics': 'Data Analytics',
      'video_editing': 'Video Editing',
      'general': 'General',
    };

    final key = value.trim().toLowerCase();
    return labels[key] ?? 'General';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final avatarUrl = _client?.profilePictureUrl;

    // 👇 NEW: closed status flags
    final isClosed = widget.job.status.toLowerCase() == 'closed';
    final isOwnJob = auth.userId != null && auth.userId == widget.job.clientId;
    final isScamClosure = isClosed && widget.job.closureReason == 'scam';

    final companyLogo = _clientLoading
        ? const SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          )
        : (avatarUrl != null && avatarUrl.isNotEmpty)
        ? ClipOval(
            child: Image.network(
              avatarUrl,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _clientAvatarFallback(),
            ),
          )
        : _clientAvatarFallback();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            JobDetailHeader(
              companyLogo: companyLogo,
              posterName: _clientLoading
                  ? '...'
                  : (_client?.displayName ?? 'Client'),
              username: _clientLoading
                  ? ''
                  : (_client?.websiteUrl?.isNotEmpty == true
                        ? _client!.websiteUrl!
                        : ''),
              jobTitle: widget.job.jobTitle,
              category: _projectCategoryLabel(widget.job.projectCategory),
              tags: _tags,
              // 👇 NEW: no report button on own job post
              onReport: null,
            ),

            // ── Closed job banner — only for the owner ──
            if (isClosed && isOwnJob)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isScamClosure
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isScamClosure
                          ? const Color(0xFFFCA5A5)
                          : const Color(0xFFFFCC02).withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isScamClosure
                              ? const Color(0xFFFFE4E6)
                              : const Color(0xFFFFF3CD),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isScamClosure
                              ? Icons.gpp_bad_rounded
                              : Icons.gavel_rounded,
                          color: isScamClosure
                              ? const Color(0xFFDC2626)
                              : const Color(0xFFF57F17),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Title row with closed-at date ──
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    isScamClosure
                                        ? 'Job flagged by AI scam detection'
                                        : 'This job post has been closed',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isScamClosure
                                          ? const Color(0xFF7F1D1D)
                                          : const Color(0xFF5D4037),
                                    ),
                                  ),
                                ),
                                if (widget.job.closedAt != null)
                                  Text(
                                    _formatDate(widget.job.closedAt!),
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: const Color(0xFF9E9E9E),
                                    ),
                                  ),
                              ],
                            ),

                            // ── Scam-specific explanation ──
                            if (isScamClosure) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Our AI detected patterns associated with fraudulent job listings and automatically closed this post. If this was a legitimate job, submit an appeal for admin review.',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF991B1B),
                                  height: 1.45,
                                ),
                              ),
                            ],

                            // ── Closure reason badge ──
                            if (widget.job.closureReason != null &&
                                widget.job.closureReason!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isScamClosure
                                      ? const Color(0xFFFEE2E2)
                                      : const Color(0xFFFFE0B2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _formatClosureReason(
                                    widget.job.closureReason!,
                                  ),
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isScamClosure
                                        ? const Color(0xFFDC2626)
                                        : const Color(0xFFE65100),
                                  ),
                                ),
                              ),
                            ],

                            // ── Closure note ──
                            if (widget.job.closureNote != null &&
                                widget.job.closureNote!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                widget.job.closureNote!,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF7D7D7D),
                                  height: 1.4,
                                ),
                              ),
                            ],

                            const SizedBox(height: 10),

                            // ── Appeal CTA ──
                            GestureDetector(
                              onTap: () => AppealDialog.show(
                                context,
                                targetType: 'job_post',
                                targetId: widget.job.jobPostId,
                                targetLabel: widget.job.jobTitle,
                                closureNote:
                                    widget.job.closureNote ??
                                    widget.job.closureReason,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: isScamClosure
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFFF57F17),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Submit an Appeal',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Tab bar — unchanged ──
            Padding(
              padding: const EdgeInsets.fromLTRB(27, 20, 27, 0),
              child: JobDetailTabBar(
                tabs: _tabs,
                selectedIndex: _selectedTab,
                onTabSelected: (i) => setState(() => _selectedTab = i),
              ),
            ),
            if (_selectedTab == 0) _buildBiddingTab(),
            if (_selectedTab == 1) _buildWorkersTab(),
            if (_selectedTab == 2) _buildDetailsTab(),
          ],
        ),
      ),
    );
  }

  Widget _clientAvatarFallback() => Container(
    width: 64,
    height: 64,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.secondary,
    ),
    child: const Icon(Icons.business, size: 32, color: AppColors.primary),
  );

  Widget _buildBiddingTab() {
    if (_proposalsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
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
    final roleTitle = _roleTitle(proposal.jobRoleId);
    final isExpanded = _expandedProposalIds.contains(proposal.proposalId);

    final files = context.watch<ProposalFileProvider>().filesForProposal(
      proposal.proposalId,
    );

    final canDecide = !isAccepted && !isRejected;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isAccepted
              ? AppColors.primary.withValues(alpha: 0.20)
              : isRejected
              ? Colors.red.withValues(alpha: 0.14)
              : const Color(0xFFEDEEF2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF3F4F6),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child:
                      (proposal.freelancerAvatarUrl != null &&
                          proposal.freelancerAvatarUrl!.isNotEmpty)
                      ? Image.network(
                          proposal.freelancerAvatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _avatarFallback(),
                        )
                      : _avatarFallback(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        proposal.freelancerName ?? 'Freelancer',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        proposal.submittedAt != null
                            ? _formatDate(proposal.submittedAt!)
                            : 'Recently submitted',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF8A8F98),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (isAccepted)
                  _modernStatusBadge(
                    label: 'Accepted',
                    textColor: AppColors.primary,
                    bgColor: AppColors.primary.withValues(alpha: 0.10),
                  )
                else if (isRejected)
                  _modernStatusBadge(
                    label: 'Rejected',
                    textColor: Colors.redAccent,
                    bgColor: Colors.redAccent.withValues(alpha: 0.10),
                  )
                else
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE8EAF0)),
                    ),
                    child: const Icon(
                      Icons.push_pin_outlined,
                      size: 18,
                      color: Color(0xFF8A8F98),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 14),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (roleTitle.isNotEmpty)
                  _softChip(roleTitle, icon: Icons.work_outline_rounded),
                _softChip(
                  'Rp ${proposal.proposedBudget.toStringAsFixed(0)}',
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ],
            ),

            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEDEFF3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    proposal.coverLetter.trim().isEmpty
                        ? 'No cover letter provided.'
                        : proposal.coverLetter,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: const Color(0xFF374151),
                      height: 1.65,
                    ),
                    maxLines: isExpanded ? null : 4,
                    overflow: isExpanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                  ),
                  if (proposal.coverLetter.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedProposalIds.remove(proposal.proposalId);
                          } else {
                            _expandedProposalIds.add(proposal.proposalId);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          isExpanded ? 'Show less' : 'Read more',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (files.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...files.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _attachmentRow(f),
                ),
              ),
            ],

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _utilityActionButton(
                    icon: Icons.mail_outline_rounded,
                    label: 'Message',
                    onTap: () => _messageBidder(proposal),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _utilityActionButton(
                    icon: Icons.person_outline_rounded,
                    label: 'Profile',
                    onTap: () => _viewFreelancerProfile(proposal),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFEEF0F4)),
            const SizedBox(height: 14),

            if (canDecide)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: () => _acceptBid(proposal),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(
                          'Accept bid',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: () => _rejectBid(proposal),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: Text(
                      'Reject',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isAccepted
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : Colors.redAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    isAccepted
                        ? 'This bid has been accepted'
                        : 'This bid has been rejected',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isAccepted ? AppColors.primary : Colors.redAccent,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _modernStatusBadge({
    required String label,
    required Color textColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _softChip(String label, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FB),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE9ECF2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: const Color(0xFF7C82A1)),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF5B6178),
            ),
          ),
        ],
      ),
    );
  }

  Widget _utilityActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE9EDF3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: const Color(0xFF667085)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475467),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attachmentRow(ProposalFileModel file) {
    IconData icon;
    Color accent;

    if (file.isPdf) {
      icon = Icons.picture_as_pdf_rounded;
      accent = const Color(0xFFE74C3C);
    } else if (file.isImage) {
      icon = Icons.image_outlined;
      accent = const Color(0xFF8E6CEF);
    } else {
      icon = Icons.attach_file_rounded;
      accent = AppColors.primary;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openFile(file),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE9EDF3)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF25324B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          file.isPdf
                              ? 'PDF Document'
                              : file.isImage
                              ? 'Image File'
                              : 'Attachment',
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            color: const Color(0xFF8A8F98),
                          ),
                        ),
                        if (file.formattedSize.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                              color: Color(0xFFC4C7CF),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            file.formattedSize,
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              color: const Color(0xFF8A8F98),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE6EAF0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Open',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF667085),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.open_in_new_rounded,
                      size: 14,
                      color: Color(0xFF667085),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showActionDialog({
    required String title,
    required String message,
    required String primaryLabel,
    required IconData icon,
    required Color accent,
    String secondaryLabel = 'Cancel',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 30, color: accent),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B7280),
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          secondaryLabel,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          primaryLabel,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _avatarFallback() => Container(
    width: 44,
    height: 44,
    color: const Color(0xFFF0F0F1),
    child: const Icon(Icons.person, color: Color(0xFF7D7D7D), size: 24),
  );

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
          const SizedBox(height: 28),
          _sectionTitle('Terms'),
          const SizedBox(height: 12),
          _termRow('Project Type', _capitalize(widget.job.projectType)),
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
          _sectionTitle(
            'Roles & Skills${_rolesLoading ? '' : ' (${_roles.length})'}',
          ),
          const SizedBox(height: 12),
          _buildRolesSection(),
          if (!_filesLoading && _jobFiles.isNotEmpty) ...[
            const SizedBox(height: 28),
            _sectionTitle('Attachments (${_jobFiles.length})'),
            const SizedBox(height: 12),
            ..._jobFiles.map((f) => _buildJobFileRow(f)),
          ],
        ],
      ),
    );
  }

  Widget _buildRolesSection() {
    if (_rolesLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    if (_roles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No roles specified.',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFF7D7D7D),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    return Column(children: _roles.map((r) => _buildRoleCard(r)).toList());
  }

  Widget _buildRoleCard(JobRoleModel role) {
    final skills = _roleSkillsMap[role.jobRoleId] ?? [];
    final skillLookup = {for (final s in _allSkills) s.skillId: s};

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F0F1)),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.work_outline,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role.roleTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _miniChip(
                            role.isRequired ? 'Required' : 'Optional',
                            role.isRequired
                                ? _primary
                                : const Color(0xFF7D7D7D),
                          ),
                          _miniChip(
                            role.budgetType == 'hourly'
                                ? 'Hourly'
                                : role.budgetType == 'negotiable'
                                ? 'Negotiable'
                                : 'Fixed',
                            const Color(0xFF7D7D7D),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      role.roleBudget != null
                          ? '${role.budgetCurrency} ${_formatNumber(role.roleBudget!)}'
                          : 'Negotiable',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                    ),
                    if (role.roleBudget != null)
                      Text(
                        role.budgetType == 'hourly'
                            ? '/hour'
                            : role.budgetType == 'negotiable'
                            ? 'Negotiable'
                            : 'fixed',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: const Color(0xFF7D7D7D),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (role.roleDescription != null &&
                role.roleDescription!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                role.roleDescription!,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF7D7D7D),
                  height: 1.6,
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(color: Color(0xFFF0F0F1), height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.group_outlined,
                  size: 14,
                  color: Color(0xFF7D7D7D),
                ),
                const SizedBox(width: 6),
                Text(
                  '${role.positionsAvailable} position${role.positionsAvailable > 1 ? 's' : ''} available',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF7D7D7D),
                  ),
                ),
                if (role.positionsFilled > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    '· ${role.positionsFilled} filled',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: _primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Required Skills',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            if (skills.isEmpty)
              Text(
                'No specific skills listed.',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFFB5B4B4),
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: skills.map((s) {
                  final skill = skillLookup[s.skillId];
                  final name = skill?.skillName ?? s.skillId;
                  final importance = s.importanceLevel;
                  final isRequired = s.isRequired;
                  return _skillChip(name, isRequired, importance);
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobFileRow(JobFileModel file) {
    final IconData icon;
    switch (file.fileTypeIcon) {
      case 'pdf':
        icon = Icons.picture_as_pdf_outlined;
      case 'image':
        icon = Icons.image_outlined;
      case 'word':
        icon = Icons.description_outlined;
      case 'archive':
        icon = Icons.folder_zip_outlined;
      default:
        icon = Icons.attach_file;
    }

    return GestureDetector(
      onTap: () => _openJobFile(file),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _primary.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: _primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.fileName,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (file.fileSizeFormatted.isNotEmpty)
                    Text(
                      '${file.fileType.toUpperCase()} · ${file.fileSizeFormatted}',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: const Color(0xFF7D7D7D),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'View',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _primary,
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _miniChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 9,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    ),
  );

  Widget _skillChip(String name, bool isRequired, String? importance) {
    final color = isRequired ? _primary : const Color(0xFF7D7D7D);
    final importanceLabel = importance != null && importance.isNotEmpty
        ? ' · ${importance[0].toUpperCase()}${importance.substring(1)}'
        : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRequired ? Icons.star_rounded : Icons.star_border_rounded,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '$name$importanceLabel',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return n.toStringAsFixed(0);
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

  String _formatClosureReason(String reason) {
    const labels = {
      'spam': 'Spam',
      'scam': 'Scam / Fraud',
      'inappropriate_content': 'Inappropriate Content',
      'duplicate': 'Duplicate Listing',
      'policy_violation': 'Policy Violation',
      'other': 'Other',
    };
    return labels[reason.toLowerCase()] ??
        reason
            .replaceAll('_', ' ')
            .split(' ')
            .map(
              (w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}',
            )
            .join(' ');
  }
}
