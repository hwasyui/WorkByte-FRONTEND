import 'package:app/core/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/report_provider.dart';
import '../providers/auth_provider.dart';

/// Shows the report bottom sheet.
///
/// Usage:
///   ReportSheet.show(
///     context,
///     reportedType: 'freelancer',
///     reportedUserId: freelancer.userId,
///     targetName: freelancer.displayName,
///   );
class ReportSheet {
  static Future<void> show(
    BuildContext context, {
    required String reportedType, // 'freelancer' | 'client' | 'job_post'
    String? reportedUserId,
    String? jobPostId,
    String? targetName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReportSheetBody(
        reportedType: reportedType,
        reportedUserId: reportedUserId,
        jobPostId: jobPostId,
        targetName: targetName,
      ),
    );
  }
}

class _ReportSheetBody extends StatefulWidget {
  final String reportedType;
  final String? reportedUserId;
  final String? jobPostId;
  final String? targetName;

  const _ReportSheetBody({
    required this.reportedType,
    this.reportedUserId,
    this.jobPostId,
    this.targetName,
  });

  @override
  State<_ReportSheetBody> createState() => _ReportSheetBodyState();
}

class _ReportSheetBodyState extends State<_ReportSheetBody>
    with SingleTickerProviderStateMixin {
  final Set<String> _selected = {};
  final TextEditingController _customCtrl = TextEditingController();
  bool _showCustomField = false;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  static const Map<String, _ReasonMeta> _reasonMeta = {
    'spam': _ReasonMeta(
      Icons.block_rounded,
      'Spam',
      'Repeated or irrelevant content',
    ),
    'scam': _ReasonMeta(
      Icons.warning_amber_rounded,
      'Scam / Fraud',
      'Misleading or fraudulent activity',
    ),
    'harassment': _ReasonMeta(
      Icons.sentiment_very_dissatisfied_rounded,
      'Harassment',
      'Threatening or abusive behaviour',
    ),
    'inappropriate_content': _ReasonMeta(
      Icons.remove_circle_outline,
      'Inappropriate',
      'Content that violates guidelines',
    ),
    'fake_profile': _ReasonMeta(
      Icons.person_off_rounded,
      'Fake Profile',
      'This account appears to be fake',
    ),
    'impersonation': _ReasonMeta(
      Icons.manage_accounts_rounded,
      'Impersonation',
      'Pretending to be someone else',
    ),
    'other': _ReasonMeta(
      Icons.more_horiz_rounded,
      'Other',
      'Something not listed here',
    ),
  };

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token;
      if (token != null) context.read<ReportProvider>().fetchReasons(token);
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _customCtrl.dispose();
    super.dispose();
  }

  void _toggleReason(String reason) {
    setState(() {
      if (_selected.contains(reason)) {
        _selected.remove(reason);
      } else {
        _selected.add(reason);
      }
      if (reason == 'other') {
        _showCustomField = _selected.contains('other');
        if (_showCustomField) {
          _fadeCtrl.forward();
        } else {
          _fadeCtrl.reverse();
          _customCtrl.clear();
        }
      }
    });
  }

  bool get _canSubmit =>
      _selected.isNotEmpty &&
      (!_selected.contains('other') || _customCtrl.text.trim().isNotEmpty);

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final provider = context.read<ReportProvider>();
    if (auth.token == null) return;

    final ok = await provider.submitReport(
      token: auth.token!,
      reportedType: widget.reportedType,
      reportedUserId: widget.reportedUserId,
      jobPostId: widget.jobPostId,
      selectedReasons: _selected.toList(),
      customReason: _customCtrl.text.trim().isEmpty
          ? null
          : _customCtrl.text.trim(),
    );

    if (!mounted) return;
    if (ok) {
      provider.reset();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Report submitted. Thank you for keeping the community safe.',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomPad),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── drag handle ──
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── header ──
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEEE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.flag_rounded,
                    color: Color(0xFFE53935),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report ${_typeLabel(widget.reportedType)}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      if (widget.targetName != null)
                        Text(
                          widget.targetName!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF7D7D7D),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF7D7D7D),
                  ),
                  splashRadius: 20,
                ),
              ],
            ),

            const SizedBox(height: 6),
            Text(
              'Why are you reporting this? Select all that apply.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF7D7D7D),
              ),
            ),
            const SizedBox(height: 16),

            // ── reason tiles ──
            Consumer<ReportProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                }

                final displayReasons = provider.reasons.isNotEmpty
                    ? provider.reasons
                    : _reasonMeta.keys.toList();

                return Column(
                  children: displayReasons.map((reason) {
                    final meta =
                        _reasonMeta[reason] ??
                        const _ReasonMeta(Icons.info_outline, 'Other', '');
                    final isSelected = _selected.contains(reason);
                    return _ReasonTile(
                      icon: meta.icon,
                      label: meta.label,
                      subtitle: meta.subtitle,
                      selected: isSelected,
                      onTap: () => _toggleReason(reason),
                    );
                  }).toList(),
                );
              },
            ),

            // ── custom reason field (animates in when 'other' selected) ──
            FadeTransition(
              opacity: _fadeAnim,
              child: SizeTransition(
                sizeFactor: _fadeAnim,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextField(
                    controller: _customCtrl,
                    maxLines: 3,
                    maxLength: 300,
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF1A1A2E),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Describe the issue in detail…',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFFBDBDBD),
                      ),
                      filled: true,
                      fillColor: AppColors.secondary,
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                      counterStyle: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF7D7D7D),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── error banner ──
            Consumer<ReportProvider>(
              builder: (_, provider, __) {
                if (provider.error == null) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEEE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 16,
                        color: Color(0xFFE53935),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.error!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFFE53935),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // ── submit button ──
            Consumer<ReportProvider>(
              builder: (_, provider, __) {
                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (_canSubmit && !provider.isSubmitting)
                        ? _submit
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.primary.withValues(
                        alpha: 0.35,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: provider.isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Submit Report',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'freelancer':
        return 'Freelancer';
      case 'client':
        return 'Client';
      case 'job_post':
        return 'Job Post';
      default:
        return 'User';
    }
  }
}

// ── Reason Tile ───────────────────────────────────────────────────────────────
class _ReasonTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ReasonTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.07)
              : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                icon,
                size: 18,
                color: selected ? AppColors.primary : const Color(0xFF9E9E9E),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? AppColors.primary
                          : const Color(0xFF1A1A2E),
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF7D7D7D),
                      ),
                    ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: selected
                  ? Icon(
                      Icons.check_circle_rounded,
                      key: const ValueKey('checked'),
                      color: AppColors.primary,
                      size: 20,
                    )
                  : Icon(
                      Icons.circle_outlined,
                      key: const ValueKey('unchecked'),
                      color: const Color(0xFFDDDDDD),
                      size: 20,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Internal data class ───────────────────────────────────────────────────────
class _ReasonMeta {
  final IconData icon;
  final String label;
  final String subtitle;
  const _ReasonMeta(this.icon, this.label, this.subtitle);
}
