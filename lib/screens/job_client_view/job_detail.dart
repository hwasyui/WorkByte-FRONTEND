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

class ClientJobDetailScreen extends StatefulWidget {
  final JobPostModel job;

  const ClientJobDetailScreen({super.key, required this.job});

  @override
  State<ClientJobDetailScreen> createState() => _ClientJobDetailScreenState();
}

class _ClientJobDetailScreenState extends State<ClientJobDetailScreen> {
  static const Color _primary = AppColors.primary;

  int _selectedTab = 0;

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
    tags.add(_capitalize(widget.job.projectScope));
    if (widget.job.experienceLevel != null) {
      tags.add(_capitalize(widget.job.experienceLevel!));
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
    final uri = Uri.parse(file.fileUrl);
    try {
      final canOpen = await canLaunchUrl(uri);
      if (canOpen) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open file.',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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

    final proceedToContract = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Generate Contract',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Proceed to generate contract terms?',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Later',
              style: GoogleFonts.poppins(color: const Color(0xFF7D7D7D)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Generate',
              style: GoogleFonts.poppins(
                color: _primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (!mounted) return;

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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Bid accepted!',
          style: GoogleFonts.poppins(fontSize: 12),
        ),
        backgroundColor: _primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    setState(() {
      _proposals = _proposals
          .map(
            (p) => p.proposalId == proposal.proposalId
                ? p.copyWith(status: 'accepted')
                : p,
          )
          .toList();
    });

    if (proceedToContract != true) return;

    if (!mounted) return;
    _createAndNavigateToContract(proposal);
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
      final FreelancerModel? freelancer =
          await profileProvider.fetchFreelancerById(
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
          builder: (_) => PeopleProfileScreen(
            isClient: false,
            freelancer: freelancer,
          ),
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
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
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
                      child: const Icon(Icons.close,
                          size: 20, color: Color(0xFF6B7280)),
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
                                16, 16, 16, 0),
                            counterText: '',
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(12, 4, 12, 10),
                          child: Row(
                            children: [
                              const Spacer(),
                              const Icon(Icons.attach_file_rounded,
                                  size: 20, color: AppColors.primary),
                              const SizedBox(width: 10),
                              const Icon(
                                  Icons.sentiment_satisfied_alt_outlined,
                                  size: 20,
                                  color: AppColors.primary),
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
                      const Icon(Icons.shield_outlined,
                          size: 16, color: AppColors.primary),
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
                                color: AppColors.primary, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
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
                          icon: const Icon(Icons.send_rounded,
                              size: 18, color: Colors.white),
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
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
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

  Future<void> _openFile(ProposalFileModel file) async {
    final uri = Uri.parse(file.fileUrl);

    try {
      final canOpen = await canLaunchUrl(uri);
      if (canOpen) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open file. Try downloading it manually.',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    final avatarUrl = _client?.profilePictureUrl;
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
              category: _capitalize(widget.job.projectScope),
              tags: _tags,
            ),
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

    final files = context.watch<ProposalFileProvider>().filesForProposal(
      proposal.proposalId,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAccepted
              ? AppColors.primary.withOpacity(0.3)
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipOval(
                  child:
                      (proposal.freelancerAvatarUrl != null &&
                          proposal.freelancerAvatarUrl!.isNotEmpty)
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
                  child: Text(
                    proposal.freelancerName ?? 'Freelancer',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF333333),
                    ),
                  ),
                ),
                if (isAccepted)
                  _statusBadge('Accepted', _primary)
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

            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (roleTitle.isNotEmpty) _roleChip(roleTitle),
                _budgetChip(
                  'Rp. ${proposal.proposedBudget.toStringAsFixed(0)}',
                ),
              ],
            ),

            const SizedBox(height: 10),

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

            if (files.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...files.map((f) => _attachmentRow(f)),
            ],

            const SizedBox(height: 6),

            if (proposal.submittedAt != null)
              Text(
                _formatDate(proposal.submittedAt!),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: const Color(0xFF7D7D7D),
                ),
              ),

            const SizedBox(height: 14),

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
                    onTap: () => _viewFreelancerProfile(proposal),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _attachmentRow(ProposalFileModel file) {
    IconData icon;
    if (file.isPdf) {
      icon = Icons.picture_as_pdf_outlined;
    } else if (file.isImage) {
      icon = Icons.image_outlined;
    } else {
      icon = Icons.attach_file;
    }

    return GestureDetector(
      onTap: () => _openFile(file),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
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
                  if (file.formattedSize.isNotEmpty)
                    Text(
                      file.formattedSize,
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

  Widget _roleChip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: _primary.withOpacity(0.08),
      border: Border.all(color: _primary.withOpacity(0.4)),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.work_outline, size: 11, color: AppColors.primary),
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
    ),
  );

  Widget _budgetChip(String label) => Container(
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
    return Column(
      children: _roles.map((r) => _buildRoleCard(r)).toList(),
    );
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
                            role.budgetType == 'hourly' ? 'Hourly' : 'Fixed',
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
                        role.budgetType == 'hourly' ? '/hour' : 'fixed',
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
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: AppColors.primary,
            ),
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
}
