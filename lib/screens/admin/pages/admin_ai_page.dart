import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../providers/admin_provider.dart';

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
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.smart_toy_rounded,
                      color: Color(0xFF7C3AED),
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
                        'Scam detection & content moderation',
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
                labelColor: const Color(0xFF7C3AED),
                unselectedLabelColor: const Color(0xFF6B7280),
                indicatorColor: const Color(0xFF7C3AED),
                indicatorWeight: 2.5,
                tabs: const [
                  Tab(text: 'Scam Detection'),
                  Tab(text: 'Content Moderation'),
                ],
              ),
            ],
          ),
        ),

        // ── Tab views ─────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: const [
              _ScamTab(),
              _ModerationTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Scam Detection Tab ───────────────────────────────────────────────────────

class _ScamTab extends StatelessWidget {
  const _ScamTab();

  static const _statuses = ['pending', 'safe', 'removed', 'all'];

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        return Column(
          children: [
            // Filter chips
            _FilterBar(
              options: _statuses,
              selected: admin.scamStatusFilter,
              onSelect: (s) => admin.loadScamFlags(status: s),
              accentColor: const Color(0xFFDC2626),
            ),

            // List
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
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Action failed', style: GoogleFonts.poppins()),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.flag;
    final score = (f['scam_score'] as num?)?.toDouble() ?? 0.0;
    final status = f['status'] as String? ?? 'pending';
    final keywords = (f['detected_keywords'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
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
          // Row 1: title + score badge
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

          // Row 2: client info
          Row(
            children: [
              const Icon(Icons.person_outline_rounded,
                  size: 14, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${f['client_name'] ?? 'Unknown'} · ${f['client_email'] ?? ''}',
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

          // Row 3: keywords
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

          // Row 4: status indicator or action buttons
          const SizedBox(height: 12),
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
        ],
      ),
    );
  }
}

// ─── Content Moderation Tab ───────────────────────────────────────────────────

class _ModerationTab extends StatelessWidget {
  const _ModerationTab();

  static const _statuses = ['pending', 'approved', 'rejected', 'all'];
  static const _types = ['all', 'job_post', 'freelancer_profile', 'client_profile'];
  static const _typeLabels = {
    'all': 'All',
    'job_post': 'Job Post',
    'freelancer_profile': 'Freelancer',
    'client_profile': 'Client',
  };

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        return Column(
          children: [
            _FilterBar(
              options: _statuses,
              selected: admin.moderationStatusFilter,
              onSelect: (s) => admin.loadModerationItems(status: s),
              accentColor: const Color(0xFF7C3AED),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _types.map((t) {
                    final selected = admin.moderationTypeFilter == t;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => admin.loadModerationItems(contentType: t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF7C3AED)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF7C3AED)
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Text(
                            _typeLabels[t] ?? t,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: selected
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
            ),
            const SizedBox(height: 4),
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
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (ctx, i) => _ModerationCard(
                              item: admin.moderationItems[i],
                            ),
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

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final totalScore = (item['total_score'] as num?)?.toDouble() ?? 0.0;
    final contentType = _typeLabel(item['content_type'] as String? ?? '');
    final status = item['status'] as String? ?? 'pending';
    final flaggedText = item['flagged_text_excerpt'] as String? ??
        item['flagged_text'] as String? ??
        '';

    final scoreColor = totalScore >= 1.5
        ? const Color(0xFFDC2626)
        : totalScore >= 0.5
            ? const Color(0xFFD97706)
            : const Color(0xFF059669);

    const labelKeys = [
      'toxic',
      'severe_toxic',
      'obscene',
      'threat',
      'insult',
      'identity_hate',
    ];
    final activeLabels = labelKeys
        .where((k) => ((item[k] as num?)?.toDouble() ?? 0) >= 0.3)
        .toList();

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
          // Row 1: content type + score
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
                  _typeIcon(item['content_type'] as String? ?? ''),
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
                      contentType,
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
                score: totalScore / 6.0,
                color: scoreColor,
                label: 'Score ${totalScore.toStringAsFixed(2)}/6.0',
              ),
            ],
          ),

          // Active labels
          if (activeLabels.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: activeLabels.map((k) {
                final v = (item[k] as num?)?.toDouble() ?? 0.0;
                return _KeywordChip(
                  text: '${k.replaceAll('_', ' ')}: ${v.toStringAsFixed(2)}',
                );
              }).toList(),
            ),
          ],

          // Flagged text excerpt
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

          // Actions
          const SizedBox(height: 12),
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
                        label: 'Approve',
                        icon: Icons.check_circle_outline_rounded,
                        color: const Color(0xFF059669),
                        onTap: () => _act('approve'),
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        label: 'Reject',
                        icon: Icons.block_rounded,
                        color: const Color(0xFFDC2626),
                        filled: true,
                        onTap: () => _act('reject'),
                      ),
                    ],
                  )
          else
            _StatusPill(status: status),
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

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;
  final Color accentColor;

  const _FilterBar({
    required this.options,
    required this.selected,
    required this.onSelect,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: options.map((opt) {
            final active = opt == selected;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onSelect(opt),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? accentColor : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active ? accentColor : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Text(
                    opt[0].toUpperCase() + opt.substring(1),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: active ? Colors.white : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final double score;
  final Color color;
  final String label;
  const _ScoreBadge({required this.score, required this.color, required this.label});

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
