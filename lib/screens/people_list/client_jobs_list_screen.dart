import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../models/job_post_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../job_freelancer_view/job_detail.dart';

class ClientJobsListScreen extends StatefulWidget {
  final String clientId;
  final String clientName;

  const ClientJobsListScreen({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  State<ClientJobsListScreen> createState() => _ClientJobsListScreenState();
}

class _ClientJobsListScreenState extends State<ClientJobsListScreen> {
  static const Color _primary = AppColors.primary;

  List<JobPostModel> _jobs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadJobs());
  }

  Future<void> _loadJobs() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      setState(() {
        _error = 'You need to be signed in to view jobs.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final jobsList = await ApiService.getClientPostedJobs(
        token,
        widget.clientId,
      );

      final jobs = jobsList
          .map((job) => JobPostModel.fromJson(job))
          .where((job) => job.status.toLowerCase() != 'draft')
          .toList();

      if (!mounted) return;
      setState(() {
        _jobs = jobs;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load jobs: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  ({String label, Color color}) _jobStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return (label: 'Active', color: const Color(0xFF16A34A));
      case 'filled':
        return (label: 'Filled', color: _primary);
      case 'closed':
        return (label: 'Closed', color: const Color(0xFFE11D48));
      default:
        return (label: status, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Jobs by ${widget.clientName}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadJobs,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No jobs posted yet',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.clientName} hasn\'t posted any jobs yet',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _primary,
      onRefresh: _loadJobs,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${_jobs.length} job${_jobs.length == 1 ? '' : 's'} posted',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ..._jobs.map(
            (job) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildJobCard(job),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(JobPostModel job) {
    final status = _jobStatusInfo(job.status);
    final roleCount = job.roleCount > 0 ? job.roleCount : 1;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFEEEEF5)),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.work_outline_rounded,
                color: _primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          job.jobTitle,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A2E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: status.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status.label,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: status.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          job.projectType == 'team' ? 'Team' : 'Individual',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.group_outlined,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '$roleCount role${roleCount != 1 ? 's' : ''}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF7D7D7D),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.article_outlined,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${job.proposalCount} proposal${job.proposalCount != 1 ? 's' : ''}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF7D7D7D),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
