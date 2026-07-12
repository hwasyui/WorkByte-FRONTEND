import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/harmful_block_dialog.dart';
import '../../../providers/admin_provider.dart';
import '../../../widgets/admin/filter_dropdown_bar.dart';

class AdminAiPage extends StatefulWidget {
  const AdminAiPage({super.key});

  @override
  State<AdminAiPage> createState() => _AdminAiPageState();
}

class _AdminAiPageState extends State<AdminAiPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ────────────────────────────────────────────────────────
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
                  Column(
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
                        'Scam detection & harmful text detection',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Consumer<AdminProvider>(
                    builder: (_, admin, __) {
                      final scam = admin.pendingScamFlags;
                      final mod = admin.unreviewedModerationItems;
                      if (scam == 0 && mod == 0) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${scam + mod} need attention',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFD97706),
                          ),
                        ),
                      );
                    },
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
                  Tab(text: 'Scam Detection'),
                  Tab(text: 'Harmful Text Audit'),
                  Tab(text: 'Review Integrity'),
                ],
              ),
            ],
          ),
        ),

        // ── Tab views ─────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: const [_ScamTab(), _ModerationTab(), _ReviewIntegrityTab()],
          ),
        ),
      ],
    );
  }
}

// ─── Scam Detection Tab ───────────────────────────────────────────────────────

class _ScamTab extends StatelessWidget {
  const _ScamTab();

  static const _statuses = ['all', 'pending', 'safe', 'removed'];

  void _showAiInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
                decoration: const BoxDecoration(
                  color: Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.security_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Job Scam Detection AI',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E1B4B),
                            ),
                          ),
                          Text(
                            'How the model works',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF7C3AED),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF7C3AED),
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _ModalSection(
                        title: 'Model',
                        content:
                            'BAAI/bge-base-en-v1.5 encodes each job post into a 768-dimensional semantic embedding that captures meaning beyond keywords. A Random Forest classifier then predicts a scam probability score from 0.0 (clean) to 1.0 (highly suspicious). Detected keywords are extracted alongside the score to explain each decision.',
                      ),
                      const SizedBox(height: 14),
                      const _ModalSection(
                        title: 'Dataset',
                        content:
                            'Trained on a labeled dataset of real job postings split into two classes — Legitimate and Scam. Legitimate samples are genuine job ads from real employers; scam samples are fraudulent posts with fake salaries, vague roles, unrealistic offers, or phishing intent. Class balance was maintained during training.',
                      ),
                      const SizedBox(height: 14),
                      const _ModalSection(
                        title: 'How it works',
                        content:
                            'The full text of a job post (title + description) is cleaned and encoded by BGE-base into a fixed-length embedding vector. Random Forest scores the vector and outputs a confidence score. Posts above the high-confidence threshold are auto-closed immediately. Posts in the medium-risk range are queued here for admin review, with flagged keywords surfaced so reviewers can decide quickly.',
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '2 Dataset Labels',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const _ScamLabelRow(
                        name: 'Legitimate',
                        desc:
                            'Genuine job ads with clear responsibilities, realistic salaries, verifiable company info, and standard hiring processes.',
                        color: Color(0xFF059669),
                        bgColor: Color(0xFFF0FDF4),
                        borderColor: Color(0xFFBBF7D0),
                      ),
                      const _ScamLabelRow(
                        name: 'Scam',
                        desc:
                            'Fraudulent posts using fake salaries, vague job roles, unrealistic offers, suspicious links, or phishing tactics designed to deceive applicants.',
                        color: Color(0xFFDC2626),
                        bgColor: Color(0xFFFEF2F2),
                        borderColor: Color(0xFFFECACA),
                      ),
                    ],
                  ),
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
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        return Column(
          children: [
            // Sub-header with "About this AI" button
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4F46E5),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Powered by SBERT - Random Forest',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF4F46E5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showAiInfo(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 13,
                            color: Color(0xFF4F46E5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'About this AI',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF4F46E5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

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
  bool _closing = false;

  Future<void> _act(String action) async {
    setState(() => _loading = true);
    final admin = context.read<AdminProvider>();
    final id = _id(widget.flag);
    final ok = await admin.actionScamFlag(id, action);
    if (mounted) {
      setState(() => _loading = false);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Action failed', style: GoogleFonts.poppins()),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _confirmClose(BuildContext ctx) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Close Job Post',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          'This will close the job post as an admin override. No scam strike is recorded against the client.',
          style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF6B7280))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Close Job',
              style: GoogleFonts.poppins(
                color: const Color(0xFF7C3AED),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _closing = true);
    final jobPostId = widget.flag['job_post_id']?.toString() ?? '';
    if (jobPostId.isEmpty) {
      setState(() => _closing = false);
      return;
    }
    final ok = await context.read<AdminProvider>().adminCloseJob(jobPostId);
    if (mounted) {
      setState(() => _closing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          ok ? 'Job post closed' : 'Failed to close job post',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: ok ? const Color(0xFF059669) : const Color(0xFFDC2626),
      ));
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
                        'Scam Detection Details',
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
              _ScoreBadge(score: score, color: scoreColor, label: 'Scam Score'),
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
                        onTap: () => _act('approve'),
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        label: 'Remove Job',
                        icon: Icons.delete_outline_rounded,
                        color: const Color(0xFFDC2626),
                        filled: true,
                        onTap: () => _act('remove'),
                      ),
                    ],
                  )
          else
            _StatusPill(status: status),
          if (status != 'removed') ...[
            const SizedBox(height: 8),
            _closing
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
                : _AdminOverrideBar(
                    label: 'Close Job',
                    icon: Icons.block_rounded,
                    color: const Color(0xFF7C3AED),
                    onTap: () => _confirmClose(context),
                  ),
          ],
        ],
      ),
    );
  }
}

// ─── Harmful Text Detection Tab ──────────────────────────────────────────────

class _ModerationTab extends StatelessWidget {
  const _ModerationTab();

  // Audit trail is read-only history; filter by whether an admin has looked at a
  // row yet, not by an action status (there is no approve/reject step anymore).
  static const _reviewedFilters = ['all', 'unreviewed', 'reviewed'];
  static const _reviewedLabels = {
    'all': 'All',
    'unreviewed': 'Unreviewed',
    'reviewed': 'Reviewed',
  };
  static const _types = [
    'all',
    'job_post',
    'freelancer_profile',
    'client_profile',
    'portfolio',
    'education',
    'work_experience',
    'proposal',
  ];
  static const _typeLabels = {
    'all': 'All',
    'job_post': 'Job Post',
    'freelancer_profile': 'Freelancer',
    'client_profile': 'Client',
    'portfolio': 'Portfolio',
    'education': 'Education',
    'work_experience': 'Work Exp.',
    'proposal': 'Proposal',
  };

  void _showManualScan(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const _ManualScanDialog(),
    );
  }

  void _showAiInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Modal header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
                decoration: const BoxDecoration(
                  color: Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.psychology_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Harmful Text Detection AI',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E1B4B),
                            ),
                          ),
                          Text(
                            'How the model works',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF7C3AED),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF7C3AED),
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Modal body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ModalSection(
                        title: 'Model',
                        content:
                            'A fine-tuned BERT toxicity classifier, selected over RoBERTa and DistilBERT alternatives on macro F1 (0.85) plus a tiebreak on false-positive behaviour. Each of the five harm labels has its own tuned threshold rather than one global cutoff. Short fields (names, titles, skill names) are checked against a deterministic keyword list instead — a 1-4 word field gives the model nothing to condition on, so it matches vocabulary rather than meaning.',
                      ),
                      const SizedBox(height: 14),
                      _ModalSection(
                        title: 'How it works',
                        content:
                            'Every submission is cleaned and scored, and each label gets a probability between 0.0 and 1.0. Most fields (profile bio, DM messages, contract text, reviews) are checked before anything is written — a flagged submission is rejected outright and never saved. A few fields (job posts, proposals, portfolio, education, work experience) save immediately and get scanned in the background within seconds, flipping to blocked if flagged. Either way, nothing waits in a queue for a human decision.',
                      ),
                      const SizedBox(height: 14),
                      _ModalSection(
                        title: 'This screen is an audit log',
                        content:
                            'Blocking happens automatically at the source, so this list is a read-only history of what was flagged — not an action queue. You can mark a row as reviewed (bookkeeping only) and browse by content type. If you decide real action is warranted, use the dedicated Close Job or Restrict Account override on the row.',
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '5 Harm Labels',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const _ToxicLabelRow(
                        name: 'Toxicity',
                        desc:
                            'General toxic or rude language that may be hurtful or harmful.',
                      ),
                      const _ToxicLabelRow(
                        name: 'Obscene',
                        desc:
                            'Obscene or profane language, explicit sexual content, or vulgarity.',
                      ),
                      const _ToxicLabelRow(
                        name: 'Threat',
                        desc:
                            'Explicit threats of violence or harm directed at individuals or groups.',
                      ),
                      const _ToxicLabelRow(
                        name: 'Insult',
                        desc:
                            'Insulting, demeaning, or disrespectful language directed toward others.',
                      ),
                      const _ToxicLabelRow(
                        name: 'Identity Hate',
                        desc:
                            'Hate speech targeting identity: race, ethnicity, gender, religion, sexual orientation, nationality, or disability.',
                      ),
                    ],
                  ),
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
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        // Same filter bar, same slot, regardless of view - only the groups
        // (and what "active"/"summary" means) change, since By-user is a
        // grouped aggregate (flagged_count/max_score per user) with no single
        // reviewed-status or severity score per row the way List has.
        final byUserView = admin.moderationByUserView;
        final hasActiveFilter = byUserView
            ? admin.moderationTypeFilter != 'all' || admin.moderationByUserSort != 'most_flagged'
            : admin.moderationReviewedFilter != 'all' ||
                admin.moderationTypeFilter != 'all' ||
                admin.moderationSeverityFilter != 'all' ||
                admin.moderationSort != 'recent';
        final filterSummaryText = hasActiveFilter
            ? 'Filters active'
            : (byUserView ? 'All users' : 'All entries');
        final filterGroups = byUserView
            ? [
                FilterGroupData(
                  label: 'CONTENT TYPE',
                  options: _types,
                  labelFor: (t) => _typeLabels[t] ?? t,
                  selected: admin.moderationTypeFilter,
                  onSelect: (t) => admin.loadModerationByUser(contentType: t),
                ),
                FilterGroupData(
                  label: 'SORT BY',
                  options: moderationByUserSortOptions.keys.toList(),
                  labelFor: (s) => moderationByUserSortLabels[s] ?? s,
                  selected: admin.moderationByUserSort,
                  onSelect: (s) => admin.loadModerationByUser(sort: s),
                ),
              ]
            : [
                FilterGroupData(
                  label: 'REVIEW STATE',
                  options: _reviewedFilters,
                  labelFor: (s) => _reviewedLabels[s] ?? s,
                  selected: admin.moderationReviewedFilter,
                  onSelect: (s) => admin.loadModerationItems(reviewed: s),
                ),
                FilterGroupData(
                  label: 'CONTENT TYPE',
                  options: _types,
                  labelFor: (t) => _typeLabels[t] ?? t,
                  selected: admin.moderationTypeFilter,
                  onSelect: (t) => admin.loadModerationItems(contentType: t),
                ),
                FilterGroupData(
                  label: 'SEVERITY',
                  options: moderationSeverityRanges.keys.toList(),
                  labelFor: (s) => moderationSeverityLabels[s] ?? s,
                  selected: admin.moderationSeverityFilter,
                  onSelect: (s) => admin.loadModerationItems(severity: s),
                ),
                FilterGroupData(
                  label: 'SORT BY',
                  options: moderationSortOptions.keys.toList(),
                  labelFor: (s) => moderationSortLabels[s] ?? s,
                  selected: admin.moderationSort,
                  onSelect: (s) => admin.loadModerationItems(sort: s),
                ),
              ];
        return Column(
          children: [
            // ── Harmful text detection sub-header with info button ──────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4F46E5),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Powered by BERT - F1 0.85',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF4F46E5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showManualScan(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            size: 13,
                            color: Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Manual scan',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showAiInfo(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 13,
                            color: Color(0xFF4F46E5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'About this AI',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF4F46E5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Single shared filter bar for both List and By-user views - the
            // groups (and what "active"/"summary" means) are computed above
            // since By-user is a grouped aggregate (flagged_count/max_score
            // per user) with no single reviewed-status or severity score per
            // row the way List has.
            FilterDropdownBar(
              summaryText: filterSummaryText,
              hasActiveFilter: hasActiveFilter,
              accentColor: const Color(0xFF4F46E5),
              groups: filterGroups,
            ),

            // ── View toggle (flat list / grouped by repeat offender) + bulk
            // "mark all reviewed" for whatever filtered view is on screen ──
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  _ViewToggle(
                    byUser: admin.moderationByUserView,
                    onChanged: admin.setModerationByUserView,
                  ),
                  const Spacer(),
                  if (!admin.moderationByUserView)
                    _BulkReviewButton(
                      contentType: admin.moderationTypeFilter,
                    ),
                ],
              ),
            ),

            Expanded(
              child: admin.moderationByUserView
                  ? _ModerationByUserList(admin: admin)
                  : (admin.isAiLoading && admin.moderationItems.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF7C3AED),
                          ),
                        )
                      : admin.moderationItems.isEmpty
                      ? _Empty(
                          icon: Icons.shield_rounded,
                          message: 'No audit entries found',
                          sub: 'Nothing has been flagged for this filter',
                        )
                      : RefreshIndicator(
                          color: const Color(0xFF7C3AED),
                          onRefresh: () => admin.loadModerationItems(
                            reviewed: admin.moderationReviewedFilter,
                            contentType: admin.moderationTypeFilter,
                            severity: admin.moderationSeverityFilter,
                          ),
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: admin.moderationItems.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (ctx, i) =>
                                _ModerationCard(item: admin.moderationItems[i]),
                          ),
                        )),
            ),
          ],
        );
      },
    );
  }
}

/// Segmented toggle between the flat audit-trail list and the by-user grouped
/// view (GET /admin/moderation vs GET /admin/moderation/by-user).
class _ViewToggle extends StatelessWidget {
  final bool byUser;
  final ValueChanged<bool> onChanged;
  const _ViewToggle({required this.byUser, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ViewToggleOption(
            label: 'List',
            icon: Icons.list_alt_rounded,
            selected: !byUser,
            onTap: () => onChanged(false),
          ),
          _ViewToggleOption(
            label: 'By user',
            icon: Icons.groups_rounded,
            selected: byUser,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ViewToggleOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ViewToggleOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: selected
                  ? const Color(0xFF4F46E5)
                  : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? const Color(0xFF4F46E5)
                    : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Calls POST /admin/moderation/review-all for whatever content-type/severity
/// filter is currently active. Bookkeeping only, same as marking one row.
class _BulkReviewButton extends StatefulWidget {
  final String contentType;
  const _BulkReviewButton({required this.contentType});

  @override
  State<_BulkReviewButton> createState() => _BulkReviewButtonState();
}

class _BulkReviewButtonState extends State<_BulkReviewButton> {
  bool _loading = false;

  Future<void> _run() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Mark all reviewed',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          'This marks every currently-unreviewed row matching the active filters '
          'as reviewed. Bookkeeping only — it does not remove content or '
          'restrict anyone.',
          style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF6B7280))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Mark all reviewed',
              style: GoogleFonts.poppins(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    final count = await context.read<AdminProvider>().bulkReviewModeration();
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          count != null ? 'Marked $count row${count == 1 ? '' : 's'} reviewed' : 'Bulk review failed',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: count != null ? const Color(0xFF059669) : const Color(0xFFDC2626),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)),
      );
    }
    return _ActionButton(
      label: 'Mark all reviewed',
      icon: Icons.done_all_rounded,
      color: const Color(0xFF4F46E5),
      onTap: _run,
    );
  }
}

/// GET /admin/moderation/by-user - one card per flagged user, sorted by
/// flagged_count, so repeat offenders surface without scrolling the flat list.
class _ModerationByUserList extends StatelessWidget {
  final AdminProvider admin;
  const _ModerationByUserList({required this.admin});

  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }

  Widget _buildBody() {
    if (admin.isModerationByUserLoading && admin.moderationByUser.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
      );
    }
    if (admin.moderationByUser.isEmpty) {
      return _Empty(
        icon: Icons.groups_rounded,
        message: 'No flagged users found',
        sub: 'Nothing has been flagged for this filter',
      );
    }
    return RefreshIndicator(
      color: const Color(0xFF7C3AED),
      onRefresh: () => admin.loadModerationByUser(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: admin.moderationByUser.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) =>
            _ModerationByUserCard(item: admin.moderationByUser[i]),
      ),
    );
  }
}

class _ModerationByUserCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ModerationByUserCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final userId = item['user_id']?.toString() ?? '';
    final email = item['user_email']?.toString() ?? (userId.isNotEmpty ? userId : 'Unknown user');
    final flaggedCount = (item['flagged_count'] as num?)?.toInt() ?? 0;
    final unreviewedCount = (item['unreviewed_count'] as num?)?.toInt() ?? 0;
    final maxScore = (item['max_score'] as num?)?.toDouble() ?? 0.0;
    final lastFlaggedAt = item['last_flagged_at']?.toString() ?? '';
    final scoreColor = maxScore >= 3.0
        ? const Color(0xFFDC2626)
        : maxScore >= 1.5
        ? const Color(0xFFD97706)
        : const Color(0xFF6B7280);

    return GestureDetector(
      onTap: userId.isEmpty
          ? null
          : () => showDialog(
                context: context,
                builder: (_) => _UserModerationDetailDialog(userId: userId, email: email),
              ),
      child: Container(
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
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: scoreColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.person_outline_rounded, color: scoreColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    email,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _InfoChip(label: '$flaggedCount flagged', color: const Color(0xFF6B7280)),
                      const SizedBox(width: 6),
                      if (unreviewedCount > 0)
                        _InfoChip(label: '$unreviewedCount unreviewed', color: const Color(0xFFD97706)),
                    ],
                  ),
                  if (lastFlaggedAt.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Last flagged: ${lastFlaggedAt.split('T').first}',
                      style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF9CA3AF)),
                    ),
                  ],
                ],
              ),
            ),
            _ScoreBadge(
              score: (maxScore / 5.0).clamp(0.0, 1.0),
              color: scoreColor,
              label: 'Max ${maxScore.toStringAsFixed(2)}/5.0',
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}

/// Opened by tapping a By-user card: that one user's own flagged entries,
/// filterable independently (REVIEW STATE / CONTENT TYPE / SEVERITY) of the
/// flat list view underneath - the drill-down GET /admin/moderation?user_id=
/// makes possible.
class _UserModerationDetailDialog extends StatefulWidget {
  final String userId;
  final String email;
  const _UserModerationDetailDialog({required this.userId, required this.email});

  @override
  State<_UserModerationDetailDialog> createState() => _UserModerationDetailDialogState();
}

class _UserModerationDetailDialogState extends State<_UserModerationDetailDialog> {
  static const _reviewedFilters = ['all', 'unreviewed', 'reviewed'];
  static const _reviewedLabels = {'all': 'All', 'unreviewed': 'Unreviewed', 'reviewed': 'Reviewed'};
  static const _types = [
    'all', 'job_post', 'freelancer_profile', 'client_profile',
    'portfolio', 'education', 'work_experience', 'proposal',
  ];
  static const _typeLabels = {
    'all': 'All', 'job_post': 'Job Post', 'freelancer_profile': 'Freelancer',
    'client_profile': 'Client', 'portfolio': 'Portfolio', 'education': 'Education',
    'work_experience': 'Work Exp.', 'proposal': 'Proposal',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadModerationForUser(widget.userId);
    });
  }

  @override
  void dispose() {
    // Don't clear on every rebuild - only once this dialog is actually gone,
    // so the next frame's Consumer isn't racing an empty list mid-close.
    context.read<AdminProvider>().closeUserModerationDetail();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        child: Consumer<AdminProvider>(
          builder: (context, admin, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.email,
                              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Flagged entries for this user',
                              style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF9CA3AF)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        splashRadius: 16,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FilterDropdownBar(
                    summaryText: admin.userDetailReviewedFilter != 'all' ||
                            admin.userDetailTypeFilter != 'all' ||
                            admin.userDetailSeverityFilter != 'all' ||
                            admin.userDetailSort != 'recent'
                        ? 'Filters active'
                        : 'All entries',
                    hasActiveFilter: admin.userDetailReviewedFilter != 'all' ||
                        admin.userDetailTypeFilter != 'all' ||
                        admin.userDetailSeverityFilter != 'all' ||
                        admin.userDetailSort != 'recent',
                    accentColor: const Color(0xFF4F46E5),
                    groups: [
                      FilterGroupData(
                        label: 'REVIEW STATE',
                        options: _reviewedFilters,
                        labelFor: (s) => _reviewedLabels[s] ?? s,
                        selected: admin.userDetailReviewedFilter,
                        onSelect: (s) => admin.loadModerationForUser(widget.userId, reviewed: s),
                      ),
                      FilterGroupData(
                        label: 'CONTENT TYPE',
                        options: _types,
                        labelFor: (t) => _typeLabels[t] ?? t,
                        selected: admin.userDetailTypeFilter,
                        onSelect: (t) => admin.loadModerationForUser(widget.userId, contentType: t),
                      ),
                      FilterGroupData(
                        label: 'SEVERITY',
                        options: moderationSeverityRanges.keys.toList(),
                        labelFor: (s) => moderationSeverityLabels[s] ?? s,
                        selected: admin.userDetailSeverityFilter,
                        onSelect: (s) => admin.loadModerationForUser(widget.userId, severity: s),
                      ),
                      FilterGroupData(
                        label: 'SORT BY',
                        options: moderationSortOptions.keys.toList(),
                        labelFor: (s) => moderationSortLabels[s] ?? s,
                        selected: admin.userDetailSort,
                        onSelect: (s) => admin.loadModerationForUser(widget.userId, sort: s),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: admin.isUserDetailLoading && admin.userDetailItems.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
                          ),
                        )
                      : admin.userDetailItems.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(32),
                              child: _Empty(
                                icon: Icons.shield_rounded,
                                message: 'No entries for this filter',
                                sub: 'Try a different content type or severity',
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                              itemCount: admin.userDetailItems.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (ctx, i) =>
                                  _ModerationCard(item: admin.userDetailItems[i]),
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// POST /admin/moderation/scan - manually run the scanner against arbitrary
/// text, e.g. to test whether a phrase would be flagged, or to backfill a
/// scan for content that predates moderation. content_type is restricted to
/// job_post/freelancer_profile/client_profile by the backend.
class _ManualScanDialog extends StatefulWidget {
  const _ManualScanDialog();

  @override
  State<_ManualScanDialog> createState() => _ManualScanDialogState();
}

class _ManualScanDialogState extends State<_ManualScanDialog> {
  final _textController = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    if (_textController.text.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _result = null;
    });
    final result = await context
        .read<AdminProvider>()
        .detectHarmfulText(_textController.text.trim());
    if (!mounted) return;
    setState(() {
      _loading = false;
      _result = result ?? {'error': 'Scan failed'};
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Manual Scan',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      splashRadius: 16,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Runs the model directly against any text - useful to test whether a '
                  'phrase would be flagged. Nothing is saved anywhere.',
                  style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6B7280)),
                ),
                const SizedBox(height: 16),
                _ScanTextField(controller: _textController, hint: 'Text to scan', maxLines: 4),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _run,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text('Run scan', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  ),
                ),
                if (_result != null) ...[
                  const SizedBox(height: 14),
                  _ScanResultCard(result: _result!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  const _ScanTextField({required this.controller, required this.hint, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.poppins(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF9CA3AF)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
    );
  }
}

class _ScanResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  const _ScanResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    if (result['error'] != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Text(
          result['error'].toString(),
          style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF991B1B)),
        ),
      );
    }

    final isHarmful = result['is_harmful'] == true;
    final labels = (result['labels'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
    final scores = result['scores'] is Map
        ? Map<String, dynamic>.from(result['scores'] as Map)
        : const <String, dynamic>{};

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHarmful ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHarmful ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isHarmful ? Icons.flag_rounded : Icons.check_circle_outline_rounded,
                size: 16,
                color: isHarmful ? const Color(0xFFDC2626) : const Color(0xFF059669),
              ),
              const SizedBox(width: 8),
              Text(
                isHarmful
                    ? 'Flagged for ${describeLabels(labels)}'
                    : 'Clean - no label crossed its threshold',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isHarmful ? const Color(0xFF991B1B) : const Color(0xFF166534),
                ),
              ),
            ],
          ),
          if (scores.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: scores.entries.map((e) {
                final v = (e.value as num?)?.toDouble() ?? 0.0;
                return _KeywordChip(text: '${harmfulLabelDisplayNames[e.key] ?? e.key}: ${v.toStringAsFixed(2)}');
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Moderation Card ──────────────────────────────────────────────────────────

class _ModerationCard extends StatefulWidget {
  final Map<String, dynamic> item;
  const _ModerationCard({required this.item});

  @override
  State<_ModerationCard> createState() => _ModerationCardState();
}

class _ModerationCardState extends State<_ModerationCard> {
  bool _loading = false;
  bool _labelsExpanded = false;
  bool _closing = false;

  // Bookkeeping only: mark this audit-trail row as reviewed, with an optional note.
  // Does not take any action on the underlying content.
  Future<void> _markReviewed() async {
    final note = await _promptReviewNote(context);
    if (note == null || !mounted) return; // dialog cancelled
    setState(() => _loading = true);
    final admin = context.read<AdminProvider>();
    final id = _id(widget.item);
    final ok = await admin.reviewModerationItem(
      id,
      note: note.trim().isEmpty ? null : note.trim(),
    );
    if (mounted) {
      setState(() => _loading = false);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark reviewed', style: GoogleFonts.poppins()),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  /// Optional-note dialog. Returns the entered text (possibly empty) on confirm,
  /// or null if the admin cancelled.
  Future<String?> _promptReviewNote(BuildContext ctx) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Mark as reviewed',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This is bookkeeping only — it records that you looked at this entry. '
              'It does not remove content or restrict anyone.',
              style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6B7280)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              minLines: 1,
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Optional note',
                hintStyle: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF9CA3AF)),
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF6B7280))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dCtx, controller.text),
            child: Text(
              'Mark reviewed',
              style: GoogleFonts.poppins(
                color: const Color(0xFF4F46E5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmOverride(BuildContext ctx) async {
    final item = widget.item;
    final contentType = item['content_type'] as String? ?? '';
    final isJob = contentType == 'job_post';
    final actionLabel = isJob ? 'Close Job Post' : 'Restrict Account';
    final actionDesc = isJob
        ? 'This will close the job post as an admin override, bypassing the harmful text detection flow.'
        : 'This will restrict the user account as an admin override.';

    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          actionLabel,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          actionDesc,
          style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: const Color(0xFF6B7280)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              actionLabel,
              style: GoogleFonts.poppins(
                color: const Color(0xFFDC2626),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _closing = true);
    final admin = context.read<AdminProvider>();
    bool ok;
    if (isJob) {
      final contentId = item['content_id']?.toString() ?? '';
      ok = contentId.isNotEmpty ? await admin.adminCloseJob(contentId) : false;
    } else {
      final userId = item['user_id']?.toString() ?? '';
      ok = userId.isNotEmpty ? await admin.adminCloseAccount(userId) : false;
    }
    if (mounted) {
      setState(() => _closing = false);
      final msg = isJob
          ? (ok ? 'Job post closed' : 'Failed to close job post')
          : (ok ? 'Account restricted' : 'Failed to restrict account');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: GoogleFonts.poppins()),
        backgroundColor: ok ? const Color(0xFF059669) : const Color(0xFFDC2626),
      ));
    }
  }

  void _showDetail(BuildContext ctx) {
    final item = widget.item;
    final totalScore = (item['total_score'] as num?)?.toDouble() ?? 0.0;
    final contentType = item['content_type'] as String? ?? '';
    final flaggedText =
        item['flagged_text_excerpt'] as String? ??
        item['flagged_text'] as String? ??
        '';
    final createdAt = item['created_at']?.toString() ?? '';
    final adminNote = item['admin_note']?.toString() ?? '';
    final status = item['status'] as String? ?? 'pending';

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

    final displayTotal = labelScores.fold<double>(
      0.0,
      (sum, e) => sum + (e['score'] as double),
    );
    final scoreColor = totalScore >= 1.5
        ? const Color(0xFFDC2626)
        : totalScore >= 0.5
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
                        _typeLabel(contentType),
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      if ((item['user_email'] as String?)?.isNotEmpty == true)
                        Text(
                          item['user_email'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                    ],
                  ),
                ),
                _ScoreBadge(
                  score: displayTotal / 5.0,
                  color: scoreColor,
                  label: '${displayTotal.toStringAsFixed(2)}/5.0',
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

  // Label definitions matching the current five-label toxicity model.
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

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final totalScore = (item['total_score'] as num?)?.toDouble() ?? 0.0;
    final contentType = item['content_type'] as String? ?? '';
    final reviewedAt = item['reviewed_at']?.toString() ?? '';
    final reviewed = reviewedAt.isNotEmpty;
    final adminNote = item['admin_note']?.toString() ?? '';
    final flaggedText =
        item['flagged_text_excerpt'] as String? ??
        item['flagged_text'] as String? ??
        '';

    final scoreColor = totalScore >= 1.5
        ? const Color(0xFFDC2626)
        : totalScore >= 0.5
        ? const Color(0xFFD97706)
        : const Color(0xFF059669);

    // Build the list of all 5 label scores. Older queue rows may still carry
    // severe_toxic_score; fold it into Toxicity so the UI matches the model.
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

    // Top triggered labels (score >= 0.3) for the summary chips
    final activeLabels = labelScores
        .where((e) => (e['score'] as double) >= 0.3)
        .toList();
    final displayTotal = labelScores.fold<double>(
      0.0,
      (sum, e) => sum + (e['score'] as double),
    );

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
          // ── Row 1: content type icon + score badge ───────────────────
          Row(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _typeLabel(contentType),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    if ((item['user_email'] as String?)?.isNotEmpty == true)
                      Text(
                        item['user_email'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF9CA3AF),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              _ScoreBadge(
                score: displayTotal / 5.0,
                color: scoreColor,
                label: 'Score ${displayTotal.toStringAsFixed(2)}/5.0',
              ),
            ],
          ),

          // ── Active label chips (summary) ─────────────────────────────
          if (activeLabels.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: activeLabels.map((e) {
                final meta = e['meta'] as Map<String, Object?>;
                final v = e['score'] as double;
                return _KeywordChip(
                  text: '${meta['name']}: ${v.toStringAsFixed(2)}',
                );
              }).toList(),
            ),
          ],

          // Expandable 5-label breakdown
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

          // ── Flagged text excerpt ─────────────────────────────────────
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

          // ── Reviewed note (bookkeeping) ──────────────────────────────
          if (reviewed && adminNote.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.sticky_note_2_outlined,
                        size: 13,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Reviewer note',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    adminNote,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Actions ──────────────────────────────────────────────────
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
          // Review state: unreviewed rows get a "Mark reviewed" action (bookkeeping
          // only); reviewed rows show a passive "Reviewed" pill with the date.
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
              : reviewed
                  ? _ReviewedPill(reviewedAt: reviewedAt)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _ActionButton(
                          label: 'Mark reviewed',
                          icon: Icons.done_all_rounded,
                          color: const Color(0xFF4F46E5),
                          onTap: _markReviewed,
                        ),
                      ],
                    ),
          const SizedBox(height: 8),
          _closing
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
              : _AdminOverrideBar(
                  label: contentType == 'job_post' ? 'Close Job' : 'Restrict Account',
                  icon: Icons.block_rounded,
                  color: const Color(0xFFDC2626),
                  onTap: () => _confirmOverride(context),
                ),
        ],
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'job_post':
        return 'Job Post';
      case 'freelancer_profile':
        return 'Freelancer Profile';
      case 'client_profile':
        return 'Client Profile';
      default:
        return type.isNotEmpty ? type : 'Content';
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'job_post':
        return Icons.work_outline_rounded;
      case 'freelancer_profile':
        return Icons.person_outline_rounded;
      case 'client_profile':
        return Icons.business_center_outlined;
      default:
        return Icons.description_outlined;
    }
  }
}

// ─── Label breakdown widget ───────────────────────────────────────────────────

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

// ─── AI info modal helpers ────────────────────────────────────────────────────

class _ToxicLabelRow extends StatelessWidget {
  final String name;
  final String desc;
  const _ToxicLabelRow({required this.name, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF3E8FF).withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE9D5FF)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 3),
              decoration: const BoxDecoration(
                color: Color(0xFF7C3AED),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
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
    );
  }
}

class _ModalSection extends StatelessWidget {
  final String title;
  final String content;
  const _ModalSection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFF6B7280),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _ScamLabelRow extends StatelessWidget {
  final String name;
  final String desc;
  final Color color;
  final Color bgColor;
  final Color borderColor;

  const _ScamLabelRow({
    required this.name,
    required this.desc,
    required this.color,
    required this.bgColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 3),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
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
    );
  }
}

// ─── Admin override action bar ────────────────────────────────────────────────

class _AdminOverrideBar extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AdminOverrideBar({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Admin override',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: const Color(0xFF9CA3AF),
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 12, color: color),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
          status[0].toUpperCase() + status.substring(1),
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

/// Passive "Reviewed" indicator for an audit-trail row an admin has already
/// looked at. Shows the review date when available. No action, no side effect.
class _ReviewedPill extends StatelessWidget {
  final String reviewedAt;
  const _ReviewedPill({required this.reviewedAt});

  @override
  Widget build(BuildContext context) {
    final date = reviewedAt.contains('T')
        ? reviewedAt.split('T').first
        : (reviewedAt.length >= 10 ? reviewedAt.substring(0, 10) : reviewedAt);
    const color = Color(0xFF059669);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Icon(Icons.done_all_rounded, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          date.isNotEmpty ? 'Reviewed · $date' : 'Reviewed',
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

// ─── Review Integrity tab ─────────────────────────────────────────────────────
//
// Surfaces two things the review/rating AI pipeline already computes but the
// app never showed anywhere: RedFlagAlert (trust score drops) and reviews
// held back from publishing (overall_pass=false) because the LLM + the three
// trained review_ml models (authenticity, sentiment-rating mismatch,
// sentiment) flagged them.

class _ReviewIntegrityTab extends StatefulWidget {
  const _ReviewIntegrityTab();

  @override
  State<_ReviewIntegrityTab> createState() => _ReviewIntegrityTabState();
}

class _ReviewIntegrityTabState extends State<_ReviewIntegrityTab> {
  // 0 = red flags (freelancers + clients) | 1 = held-back freelancer reviews
  // | 2 = held-back client reviews
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadFlaggedClientReviews();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            children: [
              const Icon(
                Icons.psychology_alt_outlined,
                size: 14,
                color: Color(0xFF4F46E5),
              ),
              const SizedBox(width: 8),
              Text(
                'Powered by SBERT + 3 trained models (authenticity, mismatch, sentiment)',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFF4F46E5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Consumer<AdminProvider>(
            builder: (context, admin, _) => Row(
              children: [
                Expanded(
                  child: _ReviewIntegrityToggle(
                    label: 'Red Flags (${admin.reviewRedFlags.length})',
                    selected: _tabIndex == 0,
                    onTap: () => setState(() => _tabIndex = 0),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _ReviewIntegrityToggle(
                    label: 'Freelancer (${admin.flaggedReviews.length})',
                    selected: _tabIndex == 1,
                    onTap: () => setState(() => _tabIndex = 1),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _ReviewIntegrityToggle(
                    label: 'Client (${admin.flaggedClientReviews.length})',
                    selected: _tabIndex == 2,
                    onTap: () => setState(() => _tabIndex = 2),
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

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        if (admin.isReviewIntegrityLoading && admin.reviewRedFlags.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
          );
        }
        if (admin.reviewRedFlags.isEmpty) {
          return const _Empty(
            icon: Icons.shield_outlined,
            message: 'No red flags',
            sub: 'No freelancer trust score drops detected',
          );
        }
        return RefreshIndicator(
          color: const Color(0xFF7C3AED),
          onRefresh: () => admin.loadReviewRedFlags(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: admin.reviewRedFlags.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) =>
                _RedFlagCard(alert: admin.reviewRedFlags[i]),
          ),
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

  @override
  Widget build(BuildContext context) {
    final subjectName =
        alert['subject_name']?.toString() ?? 'Unknown';
    final subjectType = alert['subject_type']?.toString() ?? 'freelancer';
    final message = alert['message']?.toString() ?? '';
    final severity = alert['severity']?.toString() ?? 'low';

    return Container(
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
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: _ActionButton(
              label: 'Mark Resolved',
              icon: Icons.check_circle_outline,
              color: const Color(0xFF059669),
              onTap: () =>
                  context.read<AdminProvider>().resolveReviewRedFlag(_id(alert)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlaggedReviewsList extends StatelessWidget {
  const _FlaggedReviewsList();

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        if (admin.isReviewIntegrityLoading && admin.flaggedReviews.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
          );
        }
        if (admin.flaggedReviews.isEmpty) {
          return const _Empty(
            icon: Icons.rate_review_outlined,
            message: 'No held-back reviews',
            sub: 'All submitted reviews passed AI checks',
          );
        }
        return RefreshIndicator(
          color: const Color(0xFF7C3AED),
          onRefresh: () => admin.loadFlaggedReviews(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: admin.flaggedReviews.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) =>
                _FlaggedReviewCard(review: admin.flaggedReviews[i]),
          ),
        );
      },
    );
  }
}

class _FlaggedReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  const _FlaggedReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final freelancerName =
        review['freelancer_name']?.toString() ?? 'Unknown freelancer';
    final comment = review['overall_comment']?.toString() ?? '';
    final flagReasonsRaw = review['flag_reasons'];
    final flagReasons = flagReasonsRaw is List
        ? flagReasonsRaw.map((e) => e.toString()).toList()
        : <String>[];
    final authenticityScore = (review['authenticity_score'] as num?)
        ?.toDouble();
    final isFlaggedFake = review['is_flagged_fake'] == true;
    final isFlaggedCoerced = review['is_flagged_coerced'] == true;
    final status = review['status']?.toString() ?? 'flagged';

    return Container(
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
                child: Text(
                  freelancerName,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
              _StatusPill(status: status),
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
            children: [
              if (authenticityScore != null)
                _InfoChip(
                  label: 'Authenticity ${(authenticityScore * 100).round()}%',
                  color: authenticityScore < 0.5
                      ? const Color(0xFFDC2626)
                      : const Color(0xFFD97706),
                ),
              if (isFlaggedFake)
                const _InfoChip(label: 'FAKE', color: Color(0xFFDC2626)),
              if (isFlaggedCoerced)
                const _InfoChip(label: 'COERCED', color: Color(0xFFDC2626)),
            ],
          ),
          if (flagReasons.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...flagReasons.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.flag_outlined,
                      size: 13,
                      color: Color(0xFFD97706),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        r,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: _ActionButton(
              label: 'Publish Anyway',
              icon: Icons.check_circle_outline,
              color: const Color(0xFF059669),
              onTap: () =>
                  context.read<AdminProvider>().overridePublishReview(_id(review)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlaggedClientReviewsList extends StatelessWidget {
  const _FlaggedClientReviewsList();

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        if (admin.isReviewIntegrityLoading &&
            admin.flaggedClientReviews.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
          );
        }
        if (admin.flaggedClientReviews.isEmpty) {
          return const _Empty(
            icon: Icons.rate_review_outlined,
            message: 'No held-back client reviews',
            sub: 'All submitted client reviews passed AI checks',
          );
        }
        return RefreshIndicator(
          color: const Color(0xFF7C3AED),
          onRefresh: () => admin.loadFlaggedClientReviews(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: admin.flaggedClientReviews.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) =>
                _FlaggedClientReviewCard(review: admin.flaggedClientReviews[i]),
          ),
        );
      },
    );
  }
}

class _FlaggedClientReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  const _FlaggedClientReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final clientName = review['client_name']?.toString() ?? 'Unknown client';
    final comment = review['overall_comment']?.toString() ?? '';
    final flagReasonsRaw = review['flag_reasons'];
    final flagReasons = flagReasonsRaw is List
        ? flagReasonsRaw.map((e) => e.toString()).toList()
        : <String>[];
    final authenticityScore = (review['authenticity_score'] as num?)
        ?.toDouble();
    final isFlaggedFake = review['is_flagged_fake'] == true;
    final isFlaggedCoerced = review['is_flagged_coerced'] == true;
    final status = review['status']?.toString() ?? 'flagged';

    return Container(
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
                child: Text(
                  clientName,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
              _StatusPill(status: status),
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
            children: [
              if (authenticityScore != null)
                _InfoChip(
                  label: 'Authenticity ${(authenticityScore * 100).round()}%',
                  color: authenticityScore < 0.5
                      ? const Color(0xFFDC2626)
                      : const Color(0xFFD97706),
                ),
              if (isFlaggedFake)
                const _InfoChip(label: 'FAKE', color: Color(0xFFDC2626)),
              if (isFlaggedCoerced)
                const _InfoChip(label: 'COERCED', color: Color(0xFFDC2626)),
            ],
          ),
          if (flagReasons.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...flagReasons.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.flag_outlined,
                      size: 13,
                      color: Color(0xFFD97706),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        r,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: _ActionButton(
              label: 'Publish Anyway',
              icon: Icons.check_circle_outline,
              color: const Color(0xFF059669),
              onTap: () => context
                  .read<AdminProvider>()
                  .overridePublishClientReview(_id(review)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _id(Map<String, dynamic> item) =>
    (item['id'] ?? item['flag_id'] ?? item['moderation_id'] ?? '').toString();
