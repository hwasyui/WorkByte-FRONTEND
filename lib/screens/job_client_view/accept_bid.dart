import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../models/proposal_model.dart';
import '../../models/job_post_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contract_provider.dart';
import '../../providers/proposal_provider.dart';
import '../../providers/job_post_provider.dart';
import '../contract/generate_contract_screen.dart;

class AcceptBidScreen extends StatefulWidget {
  final String proposalId;
  final ProposalModel? proposal;

  const AcceptBidScreen({
    super.key,
    required this.proposalId,
    this.proposal,
  });

  @override
  State<AcceptBidScreen> createState() => _AcceptBidScreenState();
}

class _AcceptBidScreenState extends State<AcceptBidScreen> {
  static const Color _primary = Color(0xFF00AAA8);

  ProposalModel? _proposal;
  JobPostModel? _jobPost;
  bool _loading = true;
  bool _accepting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _proposal = widget.proposal;
    _fetchProposal();
  }

  Future<void> _fetchProposal() async {
    if (_proposal != null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    final token = context.read<AuthProvider>().token!;
    final proposalProvider = context.read<ProposalProvider>();
    final jobPostProvider = context.read<JobPostProvider>();

    try {
      await proposalProvider.fetchProposalById(token, widget.proposalId);
      if (mounted) {
        _proposal = proposalProvider.currentProposal;
        
        // Fetch job post data
        if (_proposal != null) {
          await jobPostProvider.fetchJobPostById(token, _proposal!.jobPostId);
          _jobPost = jobPostProvider.currentJobPost;
        }
        
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _acceptProposal() async {
    if (_proposal == null || _jobPost == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Proposal or job post data not available', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final token = context.read<AuthProvider>().token!;
    final contractProvider = context.read<ContractProvider>();
    final proposalProvider = context.read<ProposalProvider>();

    setState(() => _accepting = true);

    try {
      // Step 1: Create contract from proposal and job post
      final contractData = {
        'job_post_id': _proposal!.jobPostId,
        'job_role_id': _proposal!.jobRoleId,
        'proposal_id': _proposal!.proposalId,
        'freelancer_id': _proposal!.freelancerId,
        'client_id': _jobPost!.clientId,
        'contract_title': _jobPost!.jobTitle,
        'role_title': _proposal!.jobRoleId != null ? 'Project Role' : null,
        'agreed_budget': _proposal!.proposedBudget,
        'budget_currency': _jobPost!.budgetCurrency ?? 'IDR',
        'payment_structure': 'full_payment',
        'status': 'active',
        'start_date': DateTime.now().toString().substring(0, 10), // YYYY-MM-DD
      };

      final contract = await contractProvider.createContract(token, contractData);

      if (contract == null) {
        throw Exception('Failed to create contract');
      }

      if (!mounted) return;

      // Step 2: Update proposal status to 'accepted'
      await proposalProvider.updateProposalStatus(
        token,
        widget.proposalId,
        'accepted',
      );

      if (!mounted) return;

      setState(() => _accepting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Proposal accepted! Opening contract generation...', style: GoogleFonts.poppins()),
          backgroundColor: _primary,
        ),
      );

      // Step 3: Navigate to GenerateContractScreen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => GenerateContractScreen(
              contractId: contract.contractId,
              initialContract: contract,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _accepting = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept proposal: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Review & Accept Bid',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Text(
                          _error!,
                          style: GoogleFonts.poppins(color: Colors.red, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_proposal != null) ...[
                      // Freelancer Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Freelancer',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _proposal!.freelancerName ?? 'N/A',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Project Details
                      _buildSection(
                        'Project Details',
                        [
                          _buildInfoRow('Title', _proposal!.jobTitle),
                          const SizedBox(height: 8),
                          _buildInfoRow('Role', _proposal!.roleTitle ?? 'N/A'),
                          const SizedBox(height: 8),
                          _buildInfoRow('Duration', _proposal!.proposedDuration ?? 'N/A'),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Budget Info
                      _buildSection(
                        'Budget Proposal',
                        [
                          _buildInfoRow(
                            'Proposed Amount',
                            '${_proposal!.budgetCurrency} ${_proposal!.proposedBudget.toStringAsFixed(2)}',
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow('Payment Structure', _proposal!.paymentStructure),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Cover Letter
                      _buildSection(
                        'Proposal Message',
                        [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.withOpacity(0.2)),
                            ),
                            child: Text(
                              _proposal!.coverLetter ?? 'No message provided',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Status
                      if (_proposal!.status.isNotEmpty) ...[
                        _buildSection(
                          'Current Status',
                          [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _getStatusColor(_proposal!.status).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _proposal!.status.toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusColor(_proposal!.status),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Action Buttons
                      ElevatedButton(
                        onPressed: _accepting ? null : _acceptProposal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          minimumSize: const Size(double.infinity, 48),
                          disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                        ),
                        child: _accepting
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              )
                            : Text(
                                'Accept & Generate Contract',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _accepting ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                        ),
                        child: Text(
                          'Decline',
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
