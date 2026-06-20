import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

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
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final admin = context.read<AdminProvider>();
      admin.loadScamFlags();
      admin.loadModerationItems();
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
                      final mod = admin.pendingModerationItems;
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
                          '${scam + mod} pending review',
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
                  Tab(text: 'Harmful Text Detection'),
                ],
              ),
            ],
          ),
        ),

        // ── Tab views ─────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: const [_ScamTab(), _ModerationTab()],
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

  static const _statuses = ['all', 'pending', 'approved', 'rejected'];
  static const _types = [
    'all',
    'job_post',
    'freelancer_profile',
    'client_profile',
  ];
  static const _typeLabels = {
    'all': 'All',
    'job_post': 'Job Post',
    'freelancer_profile': 'Freelancer',
    'client_profile': 'Client',
  };

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
                            'A RoBERTa toxicity classifier fine-tuned for platform moderation. It achieves an F1 macro score of 0.72 and runs inference in about 55 ms. The model scores each submission across five harm categories: Toxicity, Obscene, Threat, Insult, and Identity Hate, then routes anything above the threshold to admin review.',
                      ),
                      const SizedBox(height: 14),
                      _ModalSection(
                        title: 'How it works',
                        content:
                            'Each submission is cleaned and tokenized before scoring. Every label gets a score between 0.0 and 1.0. If any label crosses the moderation threshold, the content is flagged. Reviewers also see a plain-language reason for each triggered label so they can judge the case quickly.',
                      ),
                      const SizedBox(height: 14),
                      _ModalSection(
                        title: 'Auto-actions',
                        content:
                            'Pending items expire after 30 days. High-risk submissions have their flag auto-confirmed and the content is removed. Low-risk submissions have their flag auto-dismissed and the content stays live. Stricter score thresholds apply to job posts compared to profile bios.',
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
                    'Powered by RoBERTa - F1 0.72',
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
              summaryText: admin.moderationStatusFilter != 'all' || admin.moderationTypeFilter != 'all'
                  ? 'Filters active'
                  : 'All content',
              hasActiveFilter: admin.moderationStatusFilter != 'all' || admin.moderationTypeFilter != 'all',
              accentColor: const Color(0xFF4F46E5),
              groups: [
                FilterGroupData(
                  label: 'STATUS',
                  options: _statuses,
                  labelFor: (s) => '${s[0].toUpperCase()}${s.substring(1)}',
                  selected: admin.moderationStatusFilter,
                  onSelect: (s) => admin.loadModerationItems(status: s),
                ),
                FilterGroupData(
                  label: 'CONTENT TYPE',
                  options: _types,
                  labelFor: (t) => _typeLabels[t] ?? t,
                  selected: admin.moderationTypeFilter,
                  onSelect: (t) => admin.loadModerationItems(contentType: t),
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
                      message: 'No flagged content found',
                      sub: 'All content is within guidelines',
                    )
                  : RefreshIndicator(
                      color: const Color(0xFF7C3AED),
                      onRefresh: () => admin.loadModerationItems(
                        status: admin.moderationStatusFilter,
                        contentType: admin.moderationTypeFilter,
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

  Future<void> _act(String action) async {
    setState(() => _loading = true);
    final admin = context.read<AdminProvider>();
    final id = _id(widget.item);
    final ok = await admin.actionModerationItem(id, action);
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

  static const _defaultBlockedMessages = {
    'job_post':
        'This job post was removed due to a content policy violation. '
        'Submit an appeal if you believe this was a mistake.',
    'freelancer_profile':
        'Your profile content was flagged for violating our community guidelines. '
        'Please review our content policy and update your profile accordingly.',
    'client_profile':
        'Your profile content was flagged for violating our community guidelines. '
        'Please review our content policy and update your profile accordingly.',
  };

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final totalScore = (item['total_score'] as num?)?.toDouble() ?? 0.0;
    final contentType = item['content_type'] as String? ?? '';
    final status = item['status'] as String? ?? 'pending';
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

    final defaultMsg =
        _defaultBlockedMessages[contentType] ??
        'This content was removed due to a policy violation. '
            'Submit an appeal if you believe this was a mistake.';

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

          // ── Default blocked message (shown when flag confirmed) ──────
          if (status == 'approved') ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.message_outlined,
                        size: 13,
                        color: Color(0xFFD97706),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Message shown to user',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    defaultMsg,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF92400E),
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
                        onTap: () => _act('reject'),
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        label: 'Confirm Flag',
                        icon: Icons.flag_rounded,
                        color: const Color(0xFFDC2626),
                        filled: true,
                        onTap: () => _act('approve'),
                      ),
                    ],
                  )
          else
            _ModerationStatusPill(status: status),
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

class _ModerationStatusPill extends StatelessWidget {
  final String status;
  const _ModerationStatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    // approved = flag confirmed → content removed (red)
    // rejected = flag dismissed → content stays (green)
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

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _id(Map<String, dynamic> item) =>
    (item['id'] ?? item['flag_id'] ?? item['moderation_id'] ?? '').toString();
