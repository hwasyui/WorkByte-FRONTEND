import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../models/contract_model.dart';
import '../../providers/auth_provider.dart';
import 'workspace_detail.dart';

class JobRoleModel {
  final String jobRoleId;
  final String jobPostId;
  final String roleTitle;
  final double? roleBudget;
  final String budgetCurrency;
  final String? roleDescription;
  final int positionsAvailable;
  final int positionsFilled;
  final bool isRequired;
  final int displayOrder;

  const JobRoleModel({
    required this.jobRoleId,
    required this.jobPostId,
    required this.roleTitle,
    this.roleBudget,
    this.budgetCurrency = 'USD',
    this.roleDescription,
    this.positionsAvailable = 1,
    this.positionsFilled = 0,
    this.isRequired = true,
    this.displayOrder = 0,
  });

  factory JobRoleModel.fromJson(Map<String, dynamic> json) => JobRoleModel(
    jobRoleId: json['job_role_id'] as String? ?? '',
    jobPostId: json['job_post_id'] as String? ?? '',
    roleTitle: json['role_title'] as String? ?? '',
    roleBudget: (json['role_budget'] as num?)?.toDouble(),
    budgetCurrency: json['budget_currency'] as String? ?? 'USD',
    roleDescription: json['role_description'] as String?,
    positionsAvailable: json['positions_available'] as int? ?? 1,
    positionsFilled: json['positions_filled'] as int? ?? 0,
    isRequired: json['is_required'] as bool? ?? true,
    displayOrder: json['display_order'] as int? ?? 0,
  );
}

class ProjectWorkspaceScreen extends StatefulWidget {
  final String jobPostId;
  final String jobTitle;
  final List<ContractModel> contracts;
  final String viewerRole;

  const ProjectWorkspaceScreen({
    super.key,
    required this.jobPostId,
    required this.jobTitle,
    required this.contracts,
    required this.viewerRole,
  });

  @override
  State<ProjectWorkspaceScreen> createState() => _ProjectWorkspaceScreenState();
}

class _ProjectWorkspaceScreenState extends State<ProjectWorkspaceScreen> {
  static final String _baseUrl = (dotenv.env['BACKEND'] ?? '').replaceAll(
    RegExp(r'/$'),
    '',
  );

  List<JobRoleModel> _roles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRoles());
  }

  Future<void> _loadRoles() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token!;
      final res = await http.get(
        Uri.parse('$_baseUrl/job-roles/job-post/${widget.jobPostId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = body['details'] ?? body['data'] ?? [];
        setState(() {
          _roles =
              (list as List)
                  .map((e) => JobRoleModel.fromJson(e as Map<String, dynamic>))
                  .toList()
                ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        });
      }
    } catch (e) {
      debugPrint('ProjectWorkspaceScreen load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Find contract(s) for a given role
  List<ContractModel> _contractsForRole(JobRoleModel role) {
    return widget.contracts
        .where((c) => c.jobRoleId == role.jobRoleId)
        .toList();
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
            _buildProjectInfo(),
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
                      onRefresh: _loadRoles,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        itemCount: _roles.length,
                        itemBuilder: (_, i) => _buildRoleCard(_roles[i]),
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
              'Project Workspace',
              style: AppText.h2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectInfo() {
    final activeCount = widget.contracts
        .where(
          (c) => [
            'active',
            'under_review',
            'revision_requested',
          ].contains(c.status),
        )
        .length;
    final totalContracts = widget.contracts.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
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
            Text(widget.jobTitle, style: AppText.h3),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.people_outline_rounded,
                  size: 15,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 6),
                Text(
                  '$totalContracts worker${totalContracts != 1 ? 's' : ''} hired',
                  style: AppText.caption.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.work_outline_rounded,
                  size: 15,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 6),
                Text(
                  '$activeCount active',
                  style: AppText.caption.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard(JobRoleModel role) {
    final contracts = _contractsForRole(role);
    final isFilled = contracts.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFilled
              ? AppColors.primary.withOpacity(0.2)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Role title + filled badge
                Row(
                  children: [
                    Expanded(child: Text(role.roleTitle, style: AppText.h3)),
                    if (isFilled)
                      _buildStatusBadge('Filled', const Color(0xFF4CAF50))
                    else
                      _buildStatusBadge('Open', Colors.grey),
                  ],
                ),
                const SizedBox(height: 8),

                // Positions
                Row(
                  children: [
                    Icon(
                      Icons.group_outlined,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${role.positionsFilled}/${role.positionsAvailable} positions filled',
                      style: AppText.caption.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (role.roleBudget != null) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.attach_money_rounded,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      Text(
                        '${role.budgetCurrency} ${role.roleBudget!.toStringAsFixed(0)}',
                        style: AppText.caption.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),

                if (role.roleDescription != null &&
                    role.roleDescription!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    role.roleDescription!,
                    style: AppText.caption.copyWith(
                      color: Colors.grey.shade500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Freelancer avatars if filled
                if (isFilled) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  ...contracts.map((c) => _buildFreelancerRow(c)),
                ],
              ],
            ),
          ),

          // Enter workspace button — only if filled
          if (isFilled) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: contracts.length == 1
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WorkspaceDetailScreen(
                              contract: contracts.first,
                              viewerRole: widget.viewerRole,
                            ),
                          ),
                        ).then((_) => _loadRoles()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Enter Workspace',
                          style: AppText.bodySemiBold.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  // Multiple contracts for same role — show per-freelancer buttons
                  : Column(
                      children: contracts.map((c) {
                        final name = widget.viewerRole == 'client'
                            ? (c.freelancerName ?? 'Freelancer')
                            : (c.clientName ?? 'Client');
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => WorkspaceDetailScreen(
                                    contract: c,
                                    viewerRole: widget.viewerRole,
                                  ),
                                ),
                              ).then((_) => _loadRoles()),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: AppColors.primary.withOpacity(0.5),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: Text(
                                '$name\'s Workspace',
                                style: AppText.bodySemiBold.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ] else ...[
            // Locked state
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'No contract yet',
                      style: AppText.bodySemiBold.copyWith(
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFreelancerRow(ContractModel contract) {
    final name = widget.viewerRole == 'client'
        ? (contract.freelancerName ?? 'Freelancer')
        : (contract.clientName ?? 'Client');
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final statusColor = _statusColor(contract.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withOpacity(0.15),
            child: Text(
              initial,
              style: AppText.captionSemiBold.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: AppText.captionSemiBold)),
          _buildStatusBadge(_statusLabel(contract.status), statusColor),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: AppText.overline.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

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
        return 'Revision';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}
