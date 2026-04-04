import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/colors.dart';

/// Reusable bidding bottom sheet shown when the user taps Apply on any job.
/// Displays Bid amount, Subject, and Message fields with a "Bidding Job" button.
void showBiddingBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _BiddingBottomSheet(),
  );
}

class _BiddingBottomSheet extends StatefulWidget {
  const _BiddingBottomSheet();

  @override
  State<_BiddingBottomSheet> createState() => _BiddingBottomSheetState();
}

class _BiddingBottomSheetState extends State<_BiddingBottomSheet> {
  final _bidController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _bidController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF9F9F9),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      padding: EdgeInsets.fromLTRB(25, 12, 25, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 170,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDCD8D8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Bid field
          _FieldLabel(label: 'Bid'),
          const SizedBox(height: 8),
          _InputBox(
            controller: _bidController,
            hintText: 'Rp.',
            hintStyle: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),

          // Subject field
          _FieldLabel(label: 'Subject'),
          const SizedBox(height: 8),
          _InputBox(
            controller: _subjectController,
            hintText: 'I can revamp your website',
          ),
          const SizedBox(height: 16),

          // Messages field
          _FieldLabel(label: 'Messages'),
          const SizedBox(height: 8),
          _InputBox(
            controller: _messageController,
            hintText:
                'Hi Alexa,\nI see your detail project and i confindece can do to revamp your project....',
            maxLines: 6,
          ),
          const SizedBox(height: 24),

          // Bidding Job button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Bidding Job',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Field label ───────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF7D7D7D),
      ),
    );
  }
}

// ── Input box ─────────────────────────────────────────────────────────────────
class _InputBox extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final TextStyle? hintStyle;

  const _InputBox({
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
    this.hintStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF0F0F1)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle:
              hintStyle ??
              GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFFB6B5B5),
              ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: InputBorder.none,
        ),
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: const Color(0xFF333333),
        ),
      ),
    );
  }
}
