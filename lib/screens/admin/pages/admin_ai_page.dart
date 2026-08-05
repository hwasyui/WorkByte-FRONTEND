import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../providers/admin_provider.dart';
import '../../../widgets/admin/filter_dropdown_bar.dart';
import '../../../widgets/admin/date_range_filter_button.dart';
import '../../../widgets/admin/admin_dialog.dart';
import '../../../widgets/admin/admin_loading.dart';
import '../../../widgets/admin/admin_reason_dialog.dart';
import '../../../widgets/app_toast.dart';
import 'review_moderation_detail_dialog.dart';
import 'red_flag_detail_dialog.dart';

class AdminAiPage extends StatefulWidget {
  const AdminAiPage({super.key});

  @override
  State<AdminAiPage> createState() => _AdminAiPageState();
}

class _AdminAiPageState extends State<AdminAiPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  int _mainTabIndex = 0;
  int _reviewSubIndex = 0;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() {
      if (_tab.indexIsChanging) return;
      setState(() => _mainTabIndex = _tab.index);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final admin = context.read<AdminProvider>();
      admin.loadScamFlags();
      admin.loadModerationItems();
      admin.loadReviewRedFlags();
      admin.loadFlaggedReviews();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Widget _headerDateRangeButton(AdminProvider admin) {
    switch (_mainTabIndex) {
      case 0:
        return DateRangeFilterButton(
          range: admin.scamDateRange,
          onChanged: admin.setScamDateRange,
          accentColor: const Color(0xFFDC2626),
        );
      case 1:
        return DateRangeFilterButton(
          range: admin.moderationDateRange,
          onChanged: admin.setModerationDateRange,
        );
      default:
        switch (_reviewSubIndex) {
          case 0:
            return DateRangeFilterButton(
              range: admin.reviewRedFlagsDateRange,
              onChanged: admin.setReviewRedFlagsDateRange,
              accentColor: const Color(0xFFDC2626),
            );
          case 1:
            return DateRangeFilterButton(
              range: admin.flaggedReviewsDateRange,
              onChanged: admin.setFlaggedReviewsDateRange,
              accentColor: const Color(0xFF7C3AED),
            );
          default:
            return DateRangeFilterButton(
              range: admin.flaggedClientReviewsDateRange,
              onChanged: admin.setFlaggedClientReviewsDateRange,
              accentColor: const Color(0xFF7C3AED),
            );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.smart_toy_rounded,
                      color: Color(0xFF4F46E5),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Analysis',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        Text(
                          'Job Scam Detection, Harmful Text Detection, and Review Integrity',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF9CA3AF),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Consumer<AdminProvider>(
                    builder: (context, admin, _) => _headerDateRangeButton(admin),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TabBar(
                controller: _tab,
                labelStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
                labelColor: const Color(0xFF4F46E5),
                unselectedLabelColor: const Color(0xFF6B7280),
                indicatorColor: const Color(0xFF4F46E5),
                indicatorWeight: 2.5,
                tabs: const [
                  Tab(text: 'Job Scam Detection'),
                  Tab(text: 'Harmful Text Detection'),
                  Tab(text: 'Review Integrity'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              const _ScamTab(),
              const _ModerationTab(),
              _ReviewIntegrityTab(
                onSubIndexChanged: (i) => setState(() => _reviewSubIndex = i),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScamTab extends StatelessWidget {
  const _ScamTab();

  static const _statuses = ['all', 'pending', 'safe', 'removed'];

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        return Column(
          children: [
            const SizedBox(height: 10),
            FilterDropdownBar(
              summaryText: admin.scamStatusFilter == 'all'
                  ? 'All flags'
                  : '${admin.scamStatusFilter[0].toUpperCase()}${admin.scamStatusFilter.substring(1)}',
              hasActiveFilter: admin.scamStatusFilter != 'all',
              accentColor: const Color(0xFFDC2626),
              count: admin.scamFlags.length,
              groups: [
                FilterGroupData(
                  label: 'STATUS',
                  options: _statuses,
                  labelFor: (s) => '${s[0].toUpperCase()}${s.substring(1)}',
                  selected: admin.scamStatusFilter,
                  onSelect: (s) => admin.loadScamFlags(status: s),
                ),
              ],
            ),

            Expanded(
              child: admin.isAiLoading && admin.scamFlags.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF7C3AED),
                      ),
                    )
                  : admin.scamFlags.isEmpty
                  ? _Empty(
                      icon: Icons.verified_rounded,
                      message: 'No scam flags found',
                      sub: 'All job posts look clean',
                    )
                  : RefreshIndicator(
                      color: const Color(0xFF7C3AED),
                      onRefresh: () =>
                          admin.loadScamFlags(status: admin.scamStatusFilter),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: admin.scamFlags.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) =>
                            _ScamCard(flag: admin.scamFlags[i]),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _ScamCard extends StatefulWidget {
  final Map<String, dynamic> flag;
  const _ScamCard({required this.flag});

  @override
  State<_ScamCard> createState() => _ScamCardState();
}

class _ScamCardState extends State<_ScamCard> {
  bool _loading = false;

  Future<void> _act(String action) async {
    setState(() => _loading = true);
    final admin = context.read<AdminProvider>();
    final id = _id(widget.flag);
    final ok = await admin.actionScamFlag(id, action);
    if (mounted) {
      setState(() => _loading = false);
      if (!ok) {
        AppToast.error('Action failed');
      }
    }
  }

  Future<void> _confirmAct(BuildContext ctx, String action) async {
    final isDismiss = action == 'dismiss';
    if (!isDismiss) {
      final recordStrike = ValueNotifier<bool>(true);
      final confirmed = await showAdminConfirmDialog(
        ctx,
        title: 'Remove This Job?',
        message: 'This will close the job post for violating platform policy. This cannot be undone.',
        icon: Icons.delete_outline_rounded,
        confirmLabel: 'Remove Job',
        confirmColor: const Color(0xFFDC2626),
        extra: _ScamStrikeToggle(notifier: recordStrike),
      );
      if (confirmed != true || !mounted) return;
      if (recordStrike.value) {
        _act(action);
      } else {
        _closeJobWithoutStrike();
      }
      return;
    }
    final confirmed = await showAdminConfirmDialog(
      ctx,
      title: 'Mark Job Safe?',
      message: 'This clears the scam flag and keeps the job post live on the platform.',
      icon: Icons.check_circle_outline_rounded,
      confirmLabel: 'Mark Safe',
      confirmColor: const Color(0xFF059669),
    );
    if (confirmed == true) _act(action);
  }

  Future<void> _closeJobWithoutStrike() async {
    setState(() => _loading = true);
    final jobPostId = widget.flag['job_post_id']?.toString() ?? '';
    if (jobPostId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    final ok = await context.read<AdminProvider>().adminCloseJob(jobPostId);
    if (mounted) {
      setState(() => _loading = false);
      if (ok) {
        AppToast.success('Job post closed');
      } else {
        AppToast.error('Failed to close job post');
      }
    }
  }

  void _showDetail(BuildContext ctx) {
    final f = widget.flag;
    final score = (f['scam_score'] as num?)?.toDouble() ?? 0.0;
    final keywords =
        (f['detected_keywords'] as List?)?.map((e) => e.toString()).toList() ??
        [];
    final flaggedText = f['flagged_text']?.toString() ?? '';
    final confirmed = (f['total_scam_confirmed'] as num?)?.toInt() ?? 0;
    final isBanned = f['is_banned'] as bool? ?? false;
    final autoClosed = f['auto_closed'] as bool? ?? false;
    final createdAt = f['created_at']?.toString() ?? '';
    final scoreColor = score >= 0.85
        ? const Color(0xFFDC2626)
        : score >= 0.60
        ? const Color(0xFFD97706)
        : const Color(0xFF059669);

    showDialog(
      context: ctx,
      barrierColor: Colors.black54,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: MediaQuery.of(dialogCtx).size.height * 0.82,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                child: Row(
                  children: [
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogCtx),
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.gpp_bad_outlined, color: scoreColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f['job_title'] as String? ?? 'Untitled Job',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      Text(
                        'Job Scam Detection Details',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
                _ScoreBadge(
                  score: score,
                  color: scoreColor,
                  label: score.toStringAsFixed(3),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFF3F4F6)),
            const SizedBox(height: 12),
            Text(
              'CLIENT',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF9CA3AF),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${f['client_name'] ?? 'Unknown'}  ·  ${f['client_email'] ?? ''}',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF374151),
              ),
            ),
            if (confirmed > 0 || isBanned) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: [
                  if (confirmed > 0)
                    _InfoChip(
                      label: '$confirmed confirmed scam${confirmed > 1 ? 's' : ''}',
                      color: const Color(0xFFDC2626),
                    ),
                  if (isBanned)
                    _InfoChip(label: 'BANNED', color: const Color(0xFF111827)),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Text(
              'ANALYSIS',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF9CA3AF),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _InfoChip(
                  label: 'Score: ${score.toStringAsFixed(3)}',
                  color: scoreColor,
                ),
                if (autoClosed)
                  _InfoChip(
                    label: 'Auto-closed',
                    color: const Color(0xFFD97706),
                  ),
              ],
            ),
            if (keywords.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: keywords.map((kw) => _KeywordChip(text: kw)).toList(),
              ),
            ],
            if (flaggedText.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'FLAGGED CONTENT',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF9CA3AF),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Text(
                  flaggedText,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF991B1B),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            if (createdAt.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Flagged at: ${createdAt.split('T').first}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.flag;
    final score = (f['scam_score'] as num?)?.toDouble() ?? 0.0;
    final status = f['status'] as String? ?? 'pending';
    final keywords =
        (f['detected_keywords'] as List?)?.map((e) => e.toString()).toList() ??
        [];
    final confirmed = (f['total_scam_confirmed'] as num?)?.toInt() ?? 0;
    final isBanned = f['is_banned'] as bool? ?? false;

    final scoreColor = score >= 0.85
        ? const Color(0xFFDC2626)
        : score >= 0.60
        ? const Color(0xFFD97706)
        : const Color(0xFF059669);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.work_rounded, color: scoreColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  f['job_title'] as String? ?? 'Untitled Job',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _ScoreBadge(score: score, color: scoreColor, label: 'Score: ${score.toStringAsFixed(3)}'),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: 14,
                color: Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${f['client_name'] ?? 'Unknown'} - ${f['client_email'] ?? ''}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (confirmed > 0)
                _InfoChip(
                  label: '$confirmed confirmed scam${confirmed > 1 ? 's' : ''}',
                  color: const Color(0xFFDC2626),
                ),
              if (isBanned) ...[
                const SizedBox(width: 6),
                _InfoChip(label: 'BANNED', color: const Color(0xFF111827)),
              ],
            ],
          ),

          if (keywords.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: keywords
                  .take(6)
                  .map((kw) => _KeywordChip(text: kw))
                  .toList(),
            ),
          ],

          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _showDetail(context),
            child: Row(
              children: [
                Text(
                  'View full details',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF7C3AED),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.open_in_new_rounded,
                  size: 12,
                  color: Color(0xFF7C3AED),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (status == 'pending')
            _loading
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _ActionButton(
                        label: 'Mark Safe',
                        icon: Icons.check_circle_outline_rounded,
                        color: const Color(0xFF059669),
                        onTap: () => _confirmAct(context, 'dismiss'),
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        label: 'Remove Job',
                        icon: Icons.delete_outline_rounded,
                        color: const Color(0xFFDC2626),
                        filled: true,
                        onTap: () => _confirmAct(context, 'uphold'),
                      ),
                    ],
                  )
          else
            _StatusPill(status: status),
        ],
      ),
    );
  }
}

class _ModerationTab extends StatelessWidget {
  const _ModerationTab();

  static const _statuses = ['all', 'pending', 'approved', 'rejected'];

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        return Column(
          children: [
            const SizedBox(height: 10),
            FilterDropdownBar(
              summaryText: admin.moderationStatusFilter == 'all'
                  ? 'All flags'
                  : '${admin.moderationStatusFilter[0].toUpperCase()}${admin.moderationStatusFilter.substring(1)}',
              hasActiveFilter: admin.moderationStatusFilter != 'all',
              accentColor: const Color(0xFF4F46E5),
              count: admin.moderationItems.length,
              groups: [
                FilterGroupData(
                  label: 'STATUS',
                  options: _statuses,
                  labelFor: (s) => '${s[0].toUpperCase()}${s.substring(1)}',
                  selected: admin.moderationStatusFilter,
                  onSelect: (s) => admin.loadModerationItems(status: s),
                ),
              ],
            ),

            Expanded(
              child: admin.isAiLoading && admin.moderationItems.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF7C3AED),
                      ),
                    )
                  : admin.moderationItems.isEmpty
                  ? _Empty(
                      icon: Icons.shield_rounded,
                      message: 'No flags found',
                      sub: 'All job posts look clean',
                    )
                  : RefreshIndicator(
                      color: const Color(0xFF7C3AED),
                      onRefresh: () => admin.loadModerationItems(
                        status: admin.moderationStatusFilter,
                      ),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: admin.moderationItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) =>
                            _ModerationCard(item: admin.moderationItems[i]),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _ModerationCard extends StatefulWidget {
  final Map<String, dynamic> item;
  const _ModerationCard({required this.item});

  @override
  State<_ModerationCard> createState() => _ModerationCardState();
}

class _ModerationCardState extends State<_ModerationCard> {
  bool _loading = false;
  bool _labelsExpanded = false;

  Future<void> _act(String action) async {
    final isEngagedJob = action == 'approve'
        && (widget.item['content_type'] as String? ?? '') == 'job_post'
        && widget.item['is_engaged'] == true;
    if (isEngagedJob) {
      final confirmed = await _confirmCloseEngaged(context);
      if (confirmed != true || !mounted) return;
    }
    setState(() => _loading = true);
    final admin = context.read<AdminProvider>();
    final id = _id(widget.item);
    final ok = await admin.actionModerationItem(id, action);
    if (mounted) {
      setState(() => _loading = false);
      if (!ok) {
        AppToast.error('Action failed');
      }
    }
  }

  Future<void> _confirmAct(BuildContext ctx, String action) async {
    final isApprove = action == 'approve';
    final confirmed = await showAdminConfirmDialog(
      ctx,
      title: isApprove ? 'Confirm This Flag?' : 'Dismiss This Flag?',
      message: isApprove
          ? 'This confirms the flagged content violates platform policy. The job post will be closed.'
          : 'This dismisses the flag. No violation will be recorded and the content stays live.',
      icon: isApprove ? Icons.flag_rounded : Icons.check_circle_outline_rounded,
      confirmLabel: isApprove ? 'Confirm Flag' : 'Dismiss',
      confirmColor: isApprove ? const Color(0xFFDC2626) : const Color(0xFF059669),
    );
    if (confirmed == true) _act(action);
  }

  Future<bool?> _confirmCloseEngaged(BuildContext ctx) {
    return showAdminConfirmDialog(
      ctx,
      title: 'Job Has an Active Contract',
      message: 'This job already has an active contract or an engaged freelancer — '
          'there is an ongoing commitment on it. Confirming this flag will close '
          'the job and end that live work. Are you sure you want to close it?',
      icon: Icons.handshake_outlined,
      confirmLabel: 'Close Job',
      confirmColor: const Color(0xFFDC2626),
    );
  }

  void _showDetail(BuildContext ctx) {
    final item = widget.item;
    final contentType = item['content_type'] as String? ?? '';
    final flaggedText =
        item['flagged_text_excerpt'] as String? ??
        item['flagged_text'] as String? ??
        '';
    final createdAt = item['created_at']?.toString() ?? '';
    final adminNote = item['admin_note']?.toString() ?? '';
    final status = item['status'] as String? ?? 'pending';

    final jobTitle = (item['job_title'] as String?)?.trim() ?? '';
    final userEmail = (item['user_email'] as String?)?.trim() ?? '';
    final clientName = (item['client_name'] as String?)?.trim() ?? '';
    final headline = jobTitle.isNotEmpty ? jobTitle : _typeLabel(contentType);

    final labelScores = _labels.map((l) {
      final key = l['key'] as String;
      final score = key == 'toxicity'
          ? [
              (item['toxic_score'] as num?)?.toDouble() ?? 0.0,
              (item['severe_toxic_score'] as num?)?.toDouble() ?? 0.0,
            ].reduce((a, b) => a > b ? a : b)
          : (item[key] as num?)?.toDouble() ?? 0.0;
      return {'meta': l, 'score': score};
    }).toList();

    final topLabel = _topLabel(labelScores);
    final topScore = topLabel['score'] as double;
    final topMeta = topLabel['meta'] as Map<String, Object?>;
    final scoreColor = _severityColor(topScore, topMeta['key'] as String);

    showDialog(
      context: ctx,
      barrierColor: Colors.black54,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: MediaQuery.of(dialogCtx).size.height * 0.82,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                child: Row(
                  children: [
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogCtx),
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_typeIcon(contentType), color: scoreColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headline,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (userEmail.isNotEmpty || clientName.isNotEmpty)
                        Text(
                          clientName.isNotEmpty ? '$clientName - $userEmail' : userEmail,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF9CA3AF),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFF3F4F6)),
            const SizedBox(height: 12),
            Text(
              'HARM SCORES',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF9CA3AF),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            _LabelsBreakdown(labelScores: labelScores),
            if (flaggedText.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'FLAGGED CONTENT',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF9CA3AF),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Text(
                  flaggedText,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF991B1B),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            if (adminNote.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'ADMIN NOTE',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF9CA3AF),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                adminNote,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
            if (createdAt.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Flagged at: ${createdAt.split('T').first}  ·  Status: ${status[0].toUpperCase()}${status.substring(1)}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _labels = [
    {
      'key': 'toxicity',
      'name': 'Toxicity',
      'desc': 'General toxic, rude, or severely harmful language',
    },
    {
      'key': 'obscene_score',
      'name': 'Obscene',
      'desc': 'Obscene, profane, explicit, or vulgar language',
    },
    {
      'key': 'threat_score',
      'name': 'Threat',
      'desc': 'Threats of violence, intimidation, or physical harm',
    },
    {
      'key': 'insult_score',
      'name': 'Insult',
      'desc': 'Insulting, demeaning, or personally abusive language',
    },
    {
      'key': 'identity_hate_score',
      'name': 'Identity Hate',
      'desc': 'Hate speech targeting protected identity characteristics',
    },
  ];

  static const _labelThresholds = <String, double>{
    'toxicity': 0.50,
    'obscene_score': 0.38,
    'threat_score': 0.58,
    'insult_score': 0.28,
    'identity_hate_score': 0.38,
  };

  static const _autoCloseThreshold = 0.88;

  static Map<String, Object> _topLabel(List<Map<String, Object>> labelScores) {
    var best = labelScores.first;
    for (final e in labelScores) {
      if ((e['score'] as double) > (best['score'] as double)) best = e;
    }
    return best;
  }

  static Color _severityColor(double topScore, String topKey) {
    if (topScore >= _autoCloseThreshold) return const Color(0xFFDC2626);
    if (topScore >= (_labelThresholds[topKey] ?? 0.5)) {
      return const Color(0xFFD97706);
    }
    return const Color(0xFF059669);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final contentType = item['content_type'] as String? ?? '';
    final status = item['status'] as String? ?? 'pending';
    final flaggedText =
        item['flagged_text_excerpt'] as String? ??
        item['flagged_text'] as String? ??
        '';

    final jobTitle = (item['job_title'] as String?)?.trim() ?? '';
    final userEmail = (item['user_email'] as String?)?.trim() ?? '';
    final clientName = (item['client_name'] as String?)?.trim() ?? '';
    final headline = jobTitle.isNotEmpty ? jobTitle : _typeLabel(contentType);

    final labelScores = _labels.map((l) {
      final key = l['key'] as String;
      final score = key == 'toxicity'
          ? [
              (item['toxic_score'] as num?)?.toDouble() ?? 0.0,
              (item['severe_toxic_score'] as num?)?.toDouble() ?? 0.0,
            ].reduce((a, b) => a > b ? a : b)
          : (item[key] as num?)?.toDouble() ?? 0.0;
      return {'meta': l, 'score': score};
    }).toList();

    final topLabel = _topLabel(labelScores);
    final topScore = topLabel['score'] as double;
    final topMeta = topLabel['meta'] as Map<String, Object?>;
    final scoreColor = _severityColor(topScore, topMeta['key'] as String);

    final activeLabels = labelScores.where((e) {
      final key = (e['meta'] as Map<String, Object?>)['key'] as String;
      return (e['score'] as double) >= (_labelThresholds[key] ?? 0.5);
    }).toList();
    if (activeLabels.isEmpty) activeLabels.add(topLabel);
    activeLabels.sort(
      (a, b) => (b['score'] as double).compareTo(a['score'] as double),
    );
    const maxChips = 3;
    final shownLabels = activeLabels.take(maxChips).toList();
    final hiddenLabelCount = activeLabels.length - shownLabels.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                  color: scoreColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _typeIcon(contentType),
                  color: scoreColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            headline,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF111827),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item['is_engaged'] == true) ...[
                          const SizedBox(width: 6),
                          const Tooltip(
                            message:
                                'Has an active contract / engaged freelancer',
                            child: Icon(
                              Icons.handshake_outlined,
                              size: 15,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (userEmail.isNotEmpty || clientName.isNotEmpty)
                      Text(
                        clientName.isNotEmpty ? '$clientName - $userEmail' : userEmail,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF9CA3AF),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final e in shownLabels)
                      _LabelChip(
                        text:
                            '${(e['meta'] as Map<String, Object?>)['name']} '
                            '${(e['score'] as double).toStringAsFixed(2)}',
                        color: _severityColor(
                          e['score'] as double,
                          (e['meta'] as Map<String, Object?>)['key'] as String,
                        ),
                      ),
                    if (hiddenLabelCount > 0)
                      _LabelChip(
                        text: '+$hiddenLabelCount',
                        color: const Color(0xFF6B7280),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => setState(() => _labelsExpanded = !_labelsExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.analytics_outlined,
                    size: 14,
                    color: Color(0xFF7C3AED),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'All 5 label scores and reasons',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF7C3AED),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _labelsExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: const Color(0xFF9CA3AF),
                  ),
                ],
              ),
            ),
          ),

          if (_labelsExpanded) ...[
            const SizedBox(height: 8),
            _LabelsBreakdown(labelScores: labelScores),
          ],

          if (flaggedText.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Text(
                '"$flaggedText"',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF991B1B),
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],

          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _showDetail(context),
            child: Row(
              children: [
                Text(
                  'View full details',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF7C3AED),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.open_in_new_rounded,
                  size: 12,
                  color: Color(0xFF7C3AED),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (status == 'pending')
            _loading
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _ActionButton(
                        label: 'Dismiss',
                        icon: Icons.check_circle_outline_rounded,
                        color: const Color(0xFF059669),
                        onTap: () => _confirmAct(context, 'reject'),
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        label: 'Confirm Flag',
                        icon: Icons.flag_rounded,
                        color: const Color(0xFFDC2626),
                        filled: true,
                        onTap: () => _confirmAct(context, 'approve'),
                      ),
                    ],
                  )
          else
            _ModerationStatusPill(status: status),
        ],
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'job_post':
        return 'Job Post';
      default:
        return type.isNotEmpty ? type : 'Content';
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'job_post':
        return Icons.work_outline_rounded;
      default:
        return Icons.description_outlined;
    }
  }
}

class _LabelsBreakdown extends StatelessWidget {
  final List<Map<String, Object?>> labelScores;
  const _LabelsBreakdown({required this.labelScores});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: labelScores.map((e) {
        final meta = e['meta'] as Map<String, Object?>;
        final v = e['score'] as double;
        final lColor = v >= 0.5
            ? const Color(0xFFDC2626)
            : v >= 0.3
            ? const Color(0xFFD97706)
            : const Color(0xFF6B7280);
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: lColor.withOpacity(0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: lColor.withOpacity(0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      meta['name'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: lColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        v.toStringAsFixed(3),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: lColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: v.clamp(0.0, 1.0),
                    backgroundColor: lColor.withOpacity(0.1),
                    color: lColor,
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  meta['desc'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ScamStrikeToggle extends StatefulWidget {
  final ValueNotifier<bool> notifier;
  const _ScamStrikeToggle({required this.notifier});

  @override
  State<_ScamStrikeToggle> createState() => _ScamStrikeToggleState();
}

class _ScamStrikeToggleState extends State<_ScamStrikeToggle> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => widget.notifier.value = !widget.notifier.value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: widget.notifier.value,
              onChanged: (v) => setState(() => widget.notifier.value = v ?? true),
              activeColor: const Color(0xFFDC2626),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Record a scam strike against the client (repeated confirmed scams lead to an automatic ban)',
                  style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6B7280), height: 1.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final double score;
  final Color color;
  final String label;
  const _ScoreBadge({
    required this.score,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _LabelChip extends StatelessWidget {
  final String text;
  final Color color;
  const _LabelChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _KeywordChip extends StatelessWidget {
  final String text;
  const _KeywordChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: const Color(0xFF374151),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  const _InfoChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: filled ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: filled ? Colors.white : color),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: filled ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'safe' || 'approved' => const Color(0xFF059669),
      'removed' || 'rejected' => const Color(0xFFDC2626),
      _ => const Color(0xFF6B7280),
    };
    final icon = switch (status) {
      'safe' || 'approved' => Icons.check_circle_rounded,
      'removed' || 'rejected' => Icons.cancel_rounded,
      _ => Icons.hourglass_empty_rounded,
    };
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          status.toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ModerationStatusPill extends StatelessWidget {
  final String status;
  const _ModerationStatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'approved' => const Color(0xFFDC2626),
      'rejected' => const Color(0xFF059669),
      _ => const Color(0xFF6B7280),
    };
    final icon = switch (status) {
      'approved' => Icons.flag_rounded,
      'rejected' => Icons.check_circle_rounded,
      _ => Icons.hourglass_empty_rounded,
    };
    final label = switch (status) {
      'approved' => 'Confirmed',
      'rejected' => 'Dismissed',
      _ => status[0].toUpperCase() + status.substring(1),
    };
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;
  const _Empty({required this.icon, required this.message, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: const Color(0xFFD1D5DB)),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewIntegrityTab extends StatefulWidget {
  final ValueChanged<int> onSubIndexChanged;
  const _ReviewIntegrityTab({required this.onSubIndexChanged});

  @override
  State<_ReviewIntegrityTab> createState() => _ReviewIntegrityTabState();
}

class _ReviewIntegrityTabState extends State<_ReviewIntegrityTab> {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadFlaggedClientReviews();
    });
  }

  void _selectTab(int index) {
    setState(() => _tabIndex = index);
    widget.onSubIndexChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Consumer<AdminProvider>(
            builder: (context, admin, _) => Row(
              children: [
                Expanded(
                  child: _ReviewIntegrityToggle(
                    label: 'Red Flags '
                        '(${_totalCount(admin.reviewRedFlagsPagination, admin.reviewRedFlags.length)})',
                    selected: _tabIndex == 0,
                    onTap: () => _selectTab(0),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _ReviewIntegrityToggle(
                    label: 'Freelancer '
                        '(${_totalCount(admin.flaggedReviewsPagination, admin.flaggedReviews.length)})',
                    selected: _tabIndex == 1,
                    onTap: () => _selectTab(1),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _ReviewIntegrityToggle(
                    label: 'Client '
                        '(${_totalCount(admin.flaggedClientReviewsPagination, admin.flaggedClientReviews.length)})',
                    selected: _tabIndex == 2,
                    onTap: () => _selectTab(2),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: switch (_tabIndex) {
            0 => const _RedFlagsList(),
            1 => const _FlaggedReviewsList(),
            _ => const _FlaggedClientReviewsList(),
          },
        ),
      ],
    );
  }
}

class _ReviewIntegrityToggle extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ReviewIntegrityToggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF4F46E5) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}

class _RedFlagsList extends StatelessWidget {
  const _RedFlagsList();

  static const _resolved = ['all', 'open', 'resolved'];
  static const _sorts = ['triggered_at', 'severity'];

  String _resolvedLabel(String s) => switch (s) {
        'open' => 'Open',
        'resolved' => 'Resolved',
        _ => 'All',
      };

  String _sortLabel(String s) => switch (s) {
        'severity' => 'Severity',
        _ => 'Most recent',
      };

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        final total = _totalCount(
          admin.reviewRedFlagsPagination,
          admin.reviewRedFlags.length,
        );
        final page = _page(admin.reviewRedFlagsPagination);
        final totalPages = _totalPages(admin.reviewRedFlagsPagination);
        return Column(
          children: [
            const SizedBox(height: 10),
            FilterDropdownBar(
              summaryText: admin.reviewRedFlagsResolvedFilter == 'all'
                  ? 'All alerts'
                  : _resolvedLabel(admin.reviewRedFlagsResolvedFilter),
              hasActiveFilter: admin.reviewRedFlagsResolvedFilter != 'all',
              accentColor: const Color(0xFFDC2626),
              count: total,
              groups: [
                FilterGroupData(
                  label: 'STATUS',
                  options: _resolved,
                  labelFor: _resolvedLabel,
                  selected: admin.reviewRedFlagsResolvedFilter,
                  onSelect: (s) => admin.loadReviewRedFlags(resolvedFilter: s),
                ),
                FilterGroupData(
                  label: 'SORT',
                  options: _sorts,
                  labelFor: _sortLabel,
                  selected: admin.reviewRedFlagsSortBy,
                  onSelect: admin.setReviewRedFlagsSort,
                ),
              ],
            ),
            Expanded(
              child: admin.isRedFlagsLoading && admin.reviewRedFlags.isEmpty
                  ? const AdminSkeletonList()
                  : admin.reviewRedFlags.isEmpty
                      ? const _Empty(
                          icon: Icons.shield_outlined,
                          message: 'No red flags',
                          sub: 'No trust score drops detected',
                        )
                      : RefreshIndicator(
                          color: const Color(0xFF7C3AED),
                          onRefresh: () => admin.loadReviewRedFlags(),
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: admin.reviewRedFlags.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (ctx, i) =>
                                _RedFlagCard(alert: admin.reviewRedFlags[i]),
                          ),
                        ),
            ),
            _Pagination(
              page: page,
              totalPages: totalPages,
              onPageChange: (p) => admin.loadReviewRedFlags(page: p),
            ),
          ],
        );
      },
    );
  }
}

class _RedFlagCard extends StatelessWidget {
  final Map<String, dynamic> alert;
  const _RedFlagCard({required this.alert});

  Color _severityColor(String severity) {
    switch (severity) {
      case 'high':
        return const Color(0xFFDC2626);
      case 'medium':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Future<void> _resolve(BuildContext context) async {
    final admin = context.read<AdminProvider>();
    final id = _redFlagId(alert);
    final outcome = await showAdminReasonDialog(
      context,
      title: 'Resolve this alert?',
      submitLabel: 'Resolve',
      accentColor: const Color(0xFF059669),
      icon: Icons.check_circle_outline_rounded,
      onSubmit: (reason) => admin.resolveReviewRedFlag(id, reason: reason),
    );
    if (outcome != null && outcome.success && context.mounted) {
      if (outcome.resolutionRecorded == false) {
        AppToast.error('Resolved, but note NOT stored — migration pending.');
      } else {
        AppToast.success('Alert resolved.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectName = alert['subject_name']?.toString() ?? 'Unknown';
    final subjectType = alert['subject_type']?.toString() ?? 'freelancer';
    final message = alert['message']?.toString() ?? '';
    final severity = alert['severity']?.toString() ?? 'low';
    final trustScore = (alert['current_trust_score'] as num?)?.toDouble();
    final totalReviews = (alert['subject_total_reviews'] as num?)?.toInt();
    final openHeld = (alert['open_held_reviews'] as num?)?.toInt() ?? 0;
    final ageHours = alert['age_hours'] as num?;
    final resolved = alert['is_resolved'] == true;

    return GestureDetector(
      onTap: () =>
          showRedFlagDetailDialog(context, alertId: _redFlagId(alert)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _InfoChip(
                  label: subjectType == 'client' ? 'CLIENT' : 'FREELANCER',
                  color: subjectType == 'client'
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFF2563EB),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    subjectName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ),
                _ScoreBadge(
                  score: 0,
                  color: _severityColor(severity),
                  label: severity.toUpperCase(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (trustScore != null)
                  _MetaChip(
                    icon: Icons.speed_rounded,
                    label: 'Trust ${trustScore.toStringAsFixed(2)}',
                  ),
                if (totalReviews != null)
                  _MetaChip(
                    icon: Icons.rate_review_outlined,
                    label: '$totalReviews reviews',
                  ),
                if (openHeld > 0)
                  _InfoChip(
                    label: '$openHeld held',
                    color: const Color(0xFFD97706),
                  ),
                if (ageHours != null)
                  _MetaChip(
                    icon: Icons.schedule_outlined,
                    label: _ageLabel(ageHours),
                  ),
              ],
            ),
            if (!resolved) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: _ActionButton(
                  label: 'Mark Resolved',
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF059669),
                  onTap: () => _resolve(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

const _flaggedHoldLevels = ['all', 'flagged', 'suppressed'];
const _flaggedSorts = ['created_at', 'authenticity', 'disagreement'];

String _holdLevelLabel(String s) => switch (s) {
      'flagged' => 'Flagged',
      'suppressed' => 'Suppressed',
      _ => 'All',
    };

String _flaggedSortLabel(String s) => switch (s) {
      'authenticity' => 'Authenticity',
      'disagreement' => 'Disagreement',
      _ => 'Most recent',
    };

class _FlaggedReviewsList extends StatelessWidget {
  const _FlaggedReviewsList();

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        return _FlaggedReviewsScaffold(
          isClient: false,
          items: admin.flaggedReviews,
          loading: admin.isFlaggedReviewsLoading,
          pagination: admin.flaggedReviewsPagination,
          holdFilter: admin.flaggedReviewStatusFilter,
          sortBy: admin.flaggedReviewSortBy,
          onHoldSelect: (s) => admin.loadFlaggedReviews(status: s),
          onSortSelect: admin.setFlaggedReviewSort,
          onPageChange: (p) => admin.loadFlaggedReviews(page: p),
          onRefresh: () => admin.loadFlaggedReviews(),
        );
      },
    );
  }
}

class _FlaggedClientReviewsList extends StatelessWidget {
  const _FlaggedClientReviewsList();

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        return _FlaggedReviewsScaffold(
          isClient: true,
          items: admin.flaggedClientReviews,
          loading: admin.isFlaggedClientReviewsLoading,
          pagination: admin.flaggedClientReviewsPagination,
          holdFilter: admin.flaggedClientReviewStatusFilter,
          sortBy: admin.flaggedClientReviewSortBy,
          onHoldSelect: (s) => admin.loadFlaggedClientReviews(status: s),
          onSortSelect: admin.setFlaggedClientReviewSort,
          onPageChange: (p) => admin.loadFlaggedClientReviews(page: p),
          onRefresh: () => admin.loadFlaggedClientReviews(),
        );
      },
    );
  }
}

class _FlaggedReviewsScaffold extends StatelessWidget {
  final bool isClient;
  final List<Map<String, dynamic>> items;
  final bool loading;
  final Map<String, dynamic> pagination;
  final String holdFilter;
  final String sortBy;
  final ValueChanged<String> onHoldSelect;
  final ValueChanged<String> onSortSelect;
  final ValueChanged<int> onPageChange;
  final Future<void> Function() onRefresh;

  const _FlaggedReviewsScaffold({
    required this.isClient,
    required this.items,
    required this.loading,
    required this.pagination,
    required this.holdFilter,
    required this.sortBy,
    required this.onHoldSelect,
    required this.onSortSelect,
    required this.onPageChange,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final total = _totalCount(pagination, items.length);
    return Column(
      children: [
        const SizedBox(height: 10),
        FilterDropdownBar(
          summaryText:
              holdFilter == 'all' ? 'All holds' : _holdLevelLabel(holdFilter),
          hasActiveFilter: holdFilter != 'all',
          accentColor: const Color(0xFFDC2626),
          count: total,
          groups: [
            FilterGroupData(
              label: 'HOLD LEVEL',
              options: _flaggedHoldLevels,
              labelFor: _holdLevelLabel,
              selected: holdFilter,
              onSelect: onHoldSelect,
            ),
            FilterGroupData(
              label: 'SORT',
              options: _flaggedSorts,
              labelFor: _flaggedSortLabel,
              selected: sortBy,
              onSelect: onSortSelect,
            ),
          ],
        ),
        Expanded(
          child: loading && items.isEmpty
              ? const AdminSkeletonList()
              : items.isEmpty
                  ? _Empty(
                      icon: Icons.rate_review_outlined,
                      message: isClient
                          ? 'No held-back client reviews'
                          : 'No held-back reviews',
                      sub: 'All submitted reviews passed AI checks',
                    )
                  : RefreshIndicator(
                      color: const Color(0xFF7C3AED),
                      onRefresh: onRefresh,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) =>
                            _FlaggedReviewCard(review: items[i], isClient: isClient),
                      ),
                    ),
        ),
        _Pagination(
          page: _page(pagination),
          totalPages: _totalPages(pagination),
          onPageChange: onPageChange,
        ),
      ],
    );
  }
}

class _FlaggedReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  final bool isClient;
  const _FlaggedReviewCard({required this.review, required this.isClient});

  Future<void> _publish(BuildContext context) async {
    final admin = context.read<AdminProvider>();
    final id = _id(review);
    final outcome = await showAdminReasonDialog(
      context,
      title: 'Publish this review anyway?',
      submitLabel: 'Publish',
      accentColor: const Color(0xFF059669),
      icon: Icons.public_rounded,
      warningText: 'This publishes the review immediately — it becomes visible '
          'to both parties and cannot be un-published.',
      onSubmit: (reason) => isClient
          ? admin.overridePublishClientReview(id, reason: reason)
          : admin.overridePublishReview(id, reason: reason),
    );
    if (outcome != null && outcome.success && context.mounted) {
      AppToast.success('Review published.');
    }
  }

  Future<void> _uphold(BuildContext context) async {
    final admin = context.read<AdminProvider>();
    final id = _id(review);
    final outcome = await showAdminReasonDialog(
      context,
      title: 'Uphold this hold?',
      submitLabel: 'Uphold hold',
      accentColor: const Color(0xFFDC2626),
      icon: Icons.gpp_maybe_rounded,
      onSubmit: (reason) => isClient
          ? admin.upholdClientReview(id, reason: reason)
          : admin.upholdReview(id, reason: reason),
    );
    if (outcome != null && outcome.success && context.mounted) {
      AppToast.success('Hold upheld — review suppressed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectName = (isClient
            ? review['client_name']
            : review['freelancer_name'])
        ?.toString() ??
        (isClient ? 'Unknown client' : 'Unknown freelancer');
    final reviewerName = review['reviewer_name']?.toString();
    final comment = review['overall_comment']?.toString() ?? '';
    final avgStars = (review['avg_stars'] as num?)?.toDouble();
    final ratingCount = (review['rating_count'] as num?)?.toInt();
    final flagReasonCount = (review['flag_reason_count'] as num?)?.toInt() ??
        (review['flag_reasons'] is List
            ? (review['flag_reasons'] as List).length
            : 0);
    final authenticityScore =
        (review['authenticity_score'] as num?)?.toDouble();
    final isFlaggedFake = review['is_flagged_fake'] == true;
    final isFlaggedCoerced = review['is_flagged_coerced'] == true;
    final analysisUnavailable = review['analysis_unavailable'] == true;
    final holdLevel = review['hold_level']?.toString() ??
        review['status']?.toString() ??
        'flagged';

    return GestureDetector(
      onTap: () => showReviewModerationDialog(
        context,
        id: _id(review),
        isClientReview: isClient,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subjectName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      if (reviewerName != null)
                        Text(
                          'by $reviewerName',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                    ],
                  ),
                ),
                _HoldLevelPill(holdLevel: holdLevel),
              ],
            ),
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                comment,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF374151),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (avgStars != null)
                  _MetaChip(
                    icon: Icons.star_rounded,
                    label:
                        '${avgStars.toStringAsFixed(1)}${ratingCount != null ? ' ($ratingCount)' : ''}',
                  ),
                if (analysisUnavailable)
                  const _InfoChip(
                    label: 'ANALYSIS UNAVAILABLE',
                    color: Color(0xFFD97706),
                  )
                else ...[
                  if (authenticityScore != null)
                    _InfoChip(
                      label:
                          'Authenticity ${(authenticityScore * 100).round()}%',
                      color: authenticityScore < 0.5
                          ? const Color(0xFFDC2626)
                          : const Color(0xFFD97706),
                    ),
                  if (isFlaggedFake)
                    const _InfoChip(label: 'FAKE', color: Color(0xFFDC2626)),
                  if (isFlaggedCoerced)
                    const _InfoChip(label: 'COERCED', color: Color(0xFFDC2626)),
                ],
                if (flagReasonCount > 0)
                  _MetaChip(
                    icon: Icons.flag_outlined,
                    label: '$flagReasonCount reason'
                        '${flagReasonCount == 1 ? '' : 's'}',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ActionButton(
                  label: 'Uphold',
                  icon: Icons.gpp_maybe_outlined,
                  color: const Color(0xFFDC2626),
                  onTap: () => _uphold(context),
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  label: 'Publish Anyway',
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF059669),
                  onTap: () => _publish(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HoldLevelPill extends StatelessWidget {
  final String holdLevel;
  const _HoldLevelPill({required this.holdLevel});

  @override
  Widget build(BuildContext context) {
    final suppressed = holdLevel == 'suppressed';
    final color =
        suppressed ? const Color(0xFFDC2626) : const Color(0xFFD97706);
    final icon =
        suppressed ? Icons.block_rounded : Icons.flag_rounded;
    final label = suppressed ? 'Suppressed' : 'Flagged';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

String _id(Map<String, dynamic> item) =>
    (item['id'] ?? item['flag_id'] ?? item['moderation_id'] ?? '').toString();

String _redFlagId(Map<String, dynamic> item) =>
    (item['id'] ?? item['alert_id'] ?? '').toString();

int _totalCount(Map<String, dynamic> pagination, int fallback) =>
    (pagination['total'] as num?)?.toInt() ?? fallback;

int _page(Map<String, dynamic> pagination) =>
    (pagination['page'] as num?)?.toInt() ?? 1;

int _totalPages(Map<String, dynamic> pagination) =>
    (pagination['total_pages'] as num?)?.toInt() ?? 1;

String _ageLabel(num hours) {
  final h = hours.round();
  if (h < 1) return 'just now';
  if (h < 24) return '${h}h ago';
  final d = (h / 24).floor();
  return '${d}d ago';
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF6B7280)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  final int page;
  final int totalPages;
  final ValueChanged<int> onPageChange;

  const _Pagination({
    required this.page,
    required this.totalPages,
    required this.onPageChange,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page $page of $totalPages',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF6B7280),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: page > 1 ? () => onPageChange(page - 1) : null,
                color: const Color(0xFF7C3AED),
                iconSize: 20,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed:
                    page < totalPages ? () => onPageChange(page + 1) : null,
                color: const Color(0xFF7C3AED),
                iconSize: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
