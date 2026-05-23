import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/admin_provider.dart';

class AdminJobsPage extends StatefulWidget {
  const AdminJobsPage({super.key});

  @override
  State<AdminJobsPage> createState() => _AdminJobsPageState();
}

class _AdminJobsPageState extends State<AdminJobsPage> {
  int _currentPage = 1;
  String _statusFilter = 'all';
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  final List<String> _statuses = ['all', 'draft', 'active', 'closed', 'filled'];

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _currentPage = 1);
      context.read<AdminProvider>().loadJobsPage(
        1,
        status: _statusFilter == 'all' ? null : _statusFilter,
        search: q.isEmpty ? null : q,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadJobsPage(1);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        final total = (admin.jobPagination['total'] as num?)?.toInt() ?? 0;
        final totalPages =
            (admin.jobPagination['total_pages'] as num?)?.toInt() ?? 1;

        return Column(
          children: [
            // Filter bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(
                  bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.filter_list_rounded,
                        size: 15,
                        color: Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Filter by Status',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF9CA3AF),
                          letterSpacing: 0.4,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$total jobs',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _SearchField(
                    controller: _searchCtrl,
                    onChanged: _onSearchChanged,
                    hint: 'Search jobs by title…',
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _statuses.map((status) {
                        final isActive = _statusFilter == status;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _statusFilter = status;
                                _currentPage = 1;
                              });
                              admin.loadJobsPage(
                                1,
                                status: status == 'all' ? null : status,
                                search: _searchCtrl.text.isEmpty ? null : _searchCtrl.text,
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFF4F46E5)
                                    : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(20),
                                border: isActive
                                    ? null
                                    : Border.all(
                                        color: const Color(0xFFE5E7EB),
                                        width: 1,
                                      ),
                              ),
                              child: Text(
                                _label(status),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isActive
                                      ? Colors.white
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Jobs list
            Expanded(
              child: admin.isTableLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4F46E5),
                      ),
                    )
                  : admin.tableJobs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.work_off_rounded,
                            size: 48,
                            color: Color(0xFFD1D5DB),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No jobs found',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFF4F46E5),
                      onRefresh: () => admin.loadJobsPage(
                        _currentPage,
                        status: _statusFilter == 'all' ? null : _statusFilter,
                        search: _searchCtrl.text.isEmpty ? null : _searchCtrl.text,
                      ),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: admin.tableJobs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) =>
                            _JobCard(job: admin.tableJobs[i]),
                      ),
                    ),
            ),

            // Pagination
            if (totalPages > 1)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Page $_currentPage of $totalPages',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded),
                          onPressed: _currentPage > 1
                              ? () {
                                  setState(() => _currentPage--);
                                  admin.loadJobsPage(
                                    _currentPage,
                                    status: _statusFilter == 'all' ? null : _statusFilter,
                                    search: _searchCtrl.text.isEmpty ? null : _searchCtrl.text,
                                  );
                                }
                              : null,
                          color: const Color(0xFF4F46E5),
                          iconSize: 20,
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded),
                          onPressed: _currentPage < totalPages
                              ? () {
                                  setState(() => _currentPage++);
                                  admin.loadJobsPage(
                                    _currentPage,
                                    status: _statusFilter == 'all' ? null : _statusFilter,
                                    search: _searchCtrl.text.isEmpty ? null : _searchCtrl.text,
                                  );
                                }
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
      },
    );
  }

  String _label(String s) => s
      .split('_')
      .map(
        (part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}

class _JobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  const _JobCard({required this.job});

  Color get _statusColor {
    switch (job['status']) {
      case 'active':
        return const Color(0xFF059669);
      case 'filled':
        return const Color(0xFF0891B2);
      case 'closed':
        return const Color(0xFFDC2626);
      case 'draft':
        return const Color(0xFF9CA3AF);
      default:
        return const Color(0xFFD97706);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = job['status'] as String? ?? 'draft';
    final color = _statusColor;
    final proposals = job['proposal_count'] ?? 0;
    final views = job['view_count'] ?? 0;
    final category = (job['project_category'] as String? ?? '').replaceAll('_', ' ');
    final postedAt = _formatDate(job['posted_at'] as String? ?? job['created_at'] as String?);

    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        barrierColor: Colors.black54,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          clipBehavior: Clip.antiAlias,
          child: _JobDetailSheet(job: job),
        ),
      ),
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    job['job_title'] as String? ?? 'Untitled',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.replaceAll('_', ' '),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              category,
              style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6B7280)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _InfoChip(icon: Icons.description_outlined, label: '$proposals proposals'),
                const SizedBox(width: 12),
                _InfoChip(icon: Icons.visibility_outlined, label: '$views views'),
                const Spacer(),
                Text(
                  postedAt,
                  style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ],
        ),
      ),
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

class _JobDetailSheet extends StatefulWidget {
  final Map<String, dynamic> job;
  const _JobDetailSheet({required this.job});

  @override
  State<_JobDetailSheet> createState() => _JobDetailSheetState();
}

class _JobDetailSheetState extends State<_JobDetailSheet> {
  bool _closing = false;

  String get _jobPostId =>
      (widget.job['job_post_id'] ?? widget.job['id'])?.toString() ?? '';

  Future<void> _handleClose() async {
    if (_jobPostId.isEmpty) return;

    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Close Job Post?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will permanently close the job post. Freelancers will no longer be able to apply.',
                style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF6B7280)),
              ),
              const SizedBox(height: 16),
              Text(
                'Reason / closure note *',
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                onChanged: (_) => setDlgState(() {}),
                style: GoogleFonts.poppins(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. Job post violates platform policy…',
                  hintStyle: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF9CA3AF)),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFDC2626))),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF6B7280))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: reasonCtrl.text.trim().isEmpty
                    ? const Color(0xFFDC2626).withOpacity(0.4)
                    : const Color(0xFFDC2626),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              onPressed: reasonCtrl.text.trim().isEmpty ? null : () => Navigator.pop(ctx, true),
              child: Text('Close Job', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _closing = true);
    final ok = await context.read<AdminProvider>().adminCloseJob(
      _jobPostId,
      reason: reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim(),
    );
    if (mounted) {
      setState(() => _closing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          ok ? 'Job closed successfully' : 'Failed to close job',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        backgroundColor: ok ? const Color(0xFF059669) : const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      if (ok) Navigator.pop(context);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active': return const Color(0xFF059669);
      case 'filled': return const Color(0xFF0891B2);
      case 'closed': return const Color(0xFFDC2626);
      case 'draft': return const Color(0xFF9CA3AF);
      default: return const Color(0xFFD97706);
    }
  }

  String _fmt(String? d) {
    if (d == null) return '-';
    try {
      final dt = DateTime.parse(d);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) { return '-'; }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final status = job['status'] as String? ?? 'draft';
    final color = _statusColor(status);
    final category = (job['project_category'] as String? ?? '').replaceAll('_', ' ');
    final proposals = job['proposal_count'] ?? 0;
    final views = job['view_count'] ?? 0;
    final postedAt = _fmt(job['posted_at'] as String? ?? job['created_at'] as String?);
    final canClose = status != 'closed';

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // close button row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              children: [
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF6B7280)),
                  splashRadius: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: [
                Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.work_rounded, color: color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job['job_title'] as String? ?? 'Untitled Job',
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                          ),
                          if (category.isNotEmpty)
                            Text(category, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF9CA3AF))),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        status.replaceAll('_', ' '),
                        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFF3F4F6)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _DetailStat(icon: Icons.description_outlined, label: 'Proposals', value: proposals.toString()),
                    const SizedBox(width: 24),
                    _DetailStat(icon: Icons.visibility_outlined, label: 'Views', value: views.toString()),
                    const SizedBox(width: 24),
                    _DetailStat(icon: Icons.calendar_today_outlined, label: 'Posted', value: postedAt),
                  ],
                ),
                if ((job['client_name'] as String?)?.isNotEmpty == true ||
                    (job['client_email'] as String?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 16),
                  _SheetSectionLabel('CLIENT'),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          [job['client_name'], job['client_email']].where((e) => (e as String?)?.isNotEmpty == true).join(' · '),
                          style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF374151)),
                        ),
                      ),
                    ],
                  ),
                ],
                if ((job['project_type'] as String?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 16),
                  _SheetSectionLabel('PROJECT TYPE'),
                  const SizedBox(height: 4),
                  Text((job['project_type'] as String).replaceAll('_', ' '), style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF374151))),
                ],
                if ((job['experience_level'] as String?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 16),
                  _SheetSectionLabel('EXPERIENCE LEVEL'),
                  const SizedBox(height: 4),
                  Text((job['experience_level'] as String).replaceAll('_', ' '), style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF374151))),
                ],
                if (((job['description'] ?? job['job_description']) as String?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 16),
                  _SheetSectionLabel('DESCRIPTION'),
                  const SizedBox(height: 4),
                  Text(
                    job['description'] as String? ?? job['job_description'] as String? ?? '',
                    style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF374151), height: 1.5),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (canClose) ...[
                  const SizedBox(height: 24),
                  const Divider(color: Color(0xFFF3F4F6)),
                  const SizedBox(height: 16),
                  _closing
                      ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFFDC2626), strokeWidth: 2)))
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _handleClose,
                            icon: const Icon(Icons.block_rounded, size: 16),
                            label: Text('Close Job Post', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                          ),
                        ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: const Color(0xFF9CA3AF)),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF9CA3AF))),
          ],
        ),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF111827))),
      ],
    );
  }
}

class _SheetSectionLabel extends StatelessWidget {
  final String text;
  const _SheetSectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF9CA3AF), letterSpacing: 0.5),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (_, value, __) => TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.poppins(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF9CA3AF)),
          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF9CA3AF)),
          suffixIcon: value.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF9CA3AF)),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                  splashRadius: 16,
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF4F46E5)),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}
