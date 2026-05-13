import 'package:workbyte_app/core/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/appeal_provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/appeals/my_appeals_screen.dart';

/// Shows the appeal submission bottom sheet.
///
/// Usage (closed job post):
///   AppealDialog.show(
///     context,
///     targetType: 'job_post',
///     targetId: job.jobPostId,
///     targetLabel: job.jobTitle,
///     closureNote: job.closureNote,
///   );
///
/// Usage (banned account):
///   AppealDialog.show(
///     context,
///     targetType: 'user',
///     targetId: auth.userId!,
///     targetLabel: 'Your Account',
///     closureNote: auth.currentUser!.banMessage,
///   );
class AppealDialog {
  static Future<void> show(
    BuildContext context, {
    required String targetType, // 'user' | 'job_post'
    required String targetId,
    String? targetLabel,
    String? closureNote,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AppealDialogBody(
        targetType: targetType,
        targetId: targetId,
        targetLabel: targetLabel,
        closureNote: closureNote,
      ),
    );
  }
}

class _AppealDialogBody extends StatefulWidget {
  final String targetType;
  final String targetId;
  final String? targetLabel;
  final String? closureNote;

  const _AppealDialogBody({
    required this.targetType,
    required this.targetId,
    this.targetLabel,
    this.closureNote,
  });

  @override
  State<_AppealDialogBody> createState() => _AppealDialogBodyState();
}

class _AppealDialogBodyState extends State<_AppealDialogBody> {
  final TextEditingController _msgCtrl = TextEditingController();
  bool _submitted = false;

  bool get _canSubmit => _msgCtrl.text.trim().length >= 20;

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final provider = context.read<AppealProvider>();
    if (auth.token == null) return;

    final ok = await provider.submitAppeal(
      token: auth.token!,
      targetType: widget.targetType,
      targetId: widget.targetId,
      message: _msgCtrl.text.trim(),
    );

    if (!mounted) return;
    if (ok) setState(() => _submitted = true);
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
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: _submitted ? _buildSuccess() : _buildForm(),
      ),
    );
  }

  // ── Success state ──────────────────────────────────────────────────────────
  Widget _buildSuccess() {
    return Column(
      key: const ValueKey('success'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _DragHandle(),
        const SizedBox(height: 12),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle_rounded,
            color: AppColors.primary,
            size: 38,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Appeal Submitted',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "We've received your appeal and will review it within 3–5 business days. "
          "You'll be notified of our decision.",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: const Color(0xFF7D7D7D),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              context.read<AppealProvider>().reset();
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyAppealsScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              'View My Appeals',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () {
            context.read<AppealProvider>().reset();
            Navigator.pop(context);
          },
          child: Text(
            'Done',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF7D7D7D),
            ),
          ),
        ),
      ],
    );
  }

  // ── Form state ─────────────────────────────────────────────────────────────
  Widget _buildForm() {
    return SingleChildScrollView(
      child: Column(
        key: const ValueKey('form'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DragHandle(),

          // ── header ──
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.gavel_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Submit an Appeal',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    if (widget.targetLabel != null)
                      Text(
                        widget.targetLabel!,
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
                icon: const Icon(Icons.close_rounded, color: Color(0xFF7D7D7D)),
                splashRadius: 20,
              ),
            ],
          ),

          // ── closure note banner ──
          if (widget.closureNote != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFCC02).withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Color(0xFFF57F17),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.closureNote!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF5D4037),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          Text(
            'Your message',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _msgCtrl,
            maxLines: 5,
            maxLength: 1000,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF1A1A2E),
            ),
            decoration: InputDecoration(
              hintText:
                  'Explain why you believe this decision was a mistake. '
                  'Include any relevant context or evidence…',
              hintStyle: GoogleFonts.poppins(
                fontSize: 12,
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
                borderSide: BorderSide(color: AppColors.primary, width: 1.5),
              ),
              counterStyle: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF7D7D7D),
              ),
            ),
          ),

          // ── char hint ──
          if (_msgCtrl.text.trim().isNotEmpty &&
              _msgCtrl.text.trim().length < 20)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Minimum 20 characters required',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFFE53935),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // ── error banner ──
          Consumer<AppealProvider>(
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
          Consumer<AppealProvider>(
            builder: (_, provider, __) => SizedBox(
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
                        'Submit Appeal',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared drag handle ────────────────────────────────────────────────────────
class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      margin: const EdgeInsets.only(top: 12, bottom: 20),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}
