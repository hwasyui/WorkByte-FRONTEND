import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/guideline_content.dart';
import '../../providers/auth_provider.dart';
import '../../providers/guideline_provider.dart';

class GuidelinesScreen extends StatefulWidget {
  final String activeRole; // 'freelancer' | 'client'

  const GuidelinesScreen({super.key, required this.activeRole});

  @override
  State<GuidelinesScreen> createState() => _GuidelinesScreenState();
}

class _GuidelinesScreenState extends State<GuidelinesScreen> {
  bool _isSaving = false;

  Future<void> _acknowledgeAndClose() async {
    final auth = context.read<AuthProvider>();
    final guideline = context.read<GuidelineProvider>();
    final userId = auth.currentUser?.userId;

    if (userId != null && auth.token != null) {
      setState(() => _isSaving = true);
      await guideline.acknowledge(
        token: auth.token!,
        userId: userId,
        sections: ['general', widget.activeRole],
      );
      if (!mounted) return;
      setState(() => _isSaving = false);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final roleSection = widget.activeRole == 'client'
        ? GuidelineContent.client
        : GuidelineContent.freelancer;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textDark,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Guidelines',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          _GuidelineSectionCard(section: GuidelineContent.general),
          const SizedBox(height: 16),
          _GuidelineSectionCard(section: roleSection),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _acknowledgeAndClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    )
                  : Text(
                      'Got it',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GuidelineSectionCard extends StatelessWidget {
  final GuidelineSection section;

  const _GuidelineSectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            color: section.accentColor.withValues(alpha: 0.07),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: section.accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    section.icon,
                    size: 18,
                    color: section.accentColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  section.title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: section.accentColor,
                  ),
                ),
              ],
            ),
          ),
          for (int i = 0; i < section.topics.length; i++) ...[
            _GuidelineTopicTile(
              index: i + 1,
              topic: section.topics[i],
              accentColor: section.accentColor,
            ),
            if (i < section.topics.length - 1)
              const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFF3F4F6),
                indent: 16,
                endIndent: 16,
              ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// A single collapsed-by-default "question" row that expands to reveal its
/// detail steps, marked with a dot bullet only (no numbering) to avoid
/// double markers. The leading circle shows the topic's position within its
/// section, tinted with the section's accent color.
class _GuidelineTopicTile extends StatelessWidget {
  final int index;
  final GuidelineTopic topic;
  final Color accentColor;

  const _GuidelineTopicTile({
    required this.index,
    required this.topic,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(16, 0, 12, 0),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 20, 16),
        expandedAlignment: Alignment.centerLeft,
        iconColor: accentColor,
        collapsedIconColor: const Color(0xFFB0B4BB),
        leading: Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$index',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
        ),
        title: Text(
          topic.question,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        children: topic.steps
            .map(
              (step) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Icon(
                        Icons.circle,
                        size: 5,
                        color: accentColor.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        step,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF374151),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
