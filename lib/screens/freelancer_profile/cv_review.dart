import 'package:workbyte_app/models/cv_suggested_profile.dart';
import 'package:workbyte_app/services/cv_analysis_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CvReviewScreen extends StatefulWidget {
  final String token;
  final CvSuggestedProfile profile;
  final bool isInitial;
  final Map<String, dynamic>? analysisData;

  const CvReviewScreen({
    super.key,
    required this.token,
    required this.profile,
    required this.isInitial,
    this.analysisData,
  });

  @override
  State<CvReviewScreen> createState() => _CvReviewScreenState();
}

class _CvReviewScreenState extends State<CvReviewScreen> {
  final _service = CvAnalysisService();

  bool _applyBio = true;
  bool _applySkills = true;
  bool _applyWorkExperience = true;
  bool _applyEducation = true;
  bool _isApplying = false;
  String? _errorMessage;

  static const _primary = Color(0xFF4F46E5);
  static const _secondary = Color(0xFFE0E7FF);
  static const _bg = Color(0xFFF9F9F9);
  static const _textDark = Color(0xFF111827);
  static const _textMuted = Color(0xFF6B7280);

  bool get _anySectionSelected =>
      _applyBio ||
      _applySkills ||
      _applyWorkExperience ||
      _applyEducation;

  Future<void> _applyToProfile() async {
    setState(() {
      _isApplying = true;
      _errorMessage = null;
    });
    try {
      await _service.applyProfile(
        token: widget.token,
        profile: widget.profile,
        applyBio: _applyBio,
        applySkills: _applySkills,
        applyWorkExperience: _applyWorkExperience,
        applyEducation: _applyEducation
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profile updated successfully! 🎉',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: _primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(
        () => _errorMessage = e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Review CV Suggestions',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Score banner — update mode only
          if (!widget.isInitial && widget.analysisData != null)
            _ScoreBanner(data: widget.analysisData!),

          // Hint bar
          Container(
            width: double.infinity,
            color: _secondary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 15,
                  color: _primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Toggle sections you want to apply to your profile.',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: _primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Section list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              children: [
                if (p.suggestedBio != null && p.suggestedBio!.isNotEmpty)
                  _SectionCard(
                    title: 'Professional Bio',
                    icon: Icons.person_outline_rounded,
                    isEnabled: _applyBio,
                    onToggle: (v) => setState(() => _applyBio = v),
                    child: Text(
                      p.suggestedBio!,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: _textMuted,
                        height: 1.5,
                      ),
                    ),
                  ),
                if (p.skills.isNotEmpty)
                  _SectionCard(
                    title: 'Skills',
                    icon: Icons.code_rounded,
                    count: p.skills.length,
                    isEnabled: _applySkills,
                    onToggle: (v) => setState(() => _applySkills = v),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: p.skills
                          .map((s) => _SkillChip(label: s))
                          .toList(),
                    ),
                  ),
                if (p.workExperience.isNotEmpty)
                  _SectionCard(
                    title: 'Work Experience',
                    icon: Icons.work_outline_rounded,
                    count: p.workExperience.length,
                    isEnabled: _applyWorkExperience,
                    onToggle: (v) => setState(() => _applyWorkExperience = v),
                    child: Column(
                      children: p.workExperience
                          .map((e) => _ExperienceItem(exp: e))
                          .toList(),
                    ),
                  ),
                if (p.education.isNotEmpty)
                  _SectionCard(
                    title: 'Education',
                    icon: Icons.school_outlined,
                    count: p.education.length,
                    isEnabled: _applyEducation,
                    onToggle: (v) => setState(() => _applyEducation = v),
                    child: Column(
                      children: p.education
                          .map((e) => _EducationItem(edu: e))
                          .toList(),
                    ),
                  ),
                const SizedBox(height: 90),
              ],
            ),
          ),
        ],
      ),

      // Bottom apply bar
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEF9A9A)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFFC62828),
                    ),
                  ),
                ),
              ],
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: (_isApplying || !_anySectionSelected)
                      ? null
                      : _applyToProfile,
                  icon: _isApplying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                  label: Text(
                    _isApplying ? 'Applying...' : 'Apply to My Profile',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    disabledBackgroundColor: _primary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Score Banner ──────────────────────────────────────────────────────────────

class _ScoreBanner extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ScoreBanner({required this.data});

  Color _gradeColor(String grade) {
    switch (grade.toLowerCase()) {
      case 'excellent':
        return const Color(0xFF16A34A);
      case 'good':
        return const Color(0xFF2563EB);
      case 'fair':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFFDC2626);
    }
  }

  @override
  Widget build(BuildContext context) {
    final overall = data['overall_score'] as int? ?? 0;
    final grade = (data['overall_grade'] as String? ?? '').toUpperCase();
    final ats = data['ats_score'] as int? ?? 0;
    final resume = data['resume_score'] as int? ?? 0;

    return Container(
      color: const Color(0xFF4F46E5),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _BannerStat(
            label: 'Overall',
            value: '$overall',
            sub: grade,
            subColor: _gradeColor(grade),
            highlight: true,
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          _BannerStat(label: 'Resume', value: '$resume', sub: 'score'),
          Container(width: 1, height: 40, color: Colors.white24),
          _BannerStat(label: 'ATS', value: '$ats', sub: 'compliance'),
        ],
      ),
    );
  }
}

class _BannerStat extends StatelessWidget {
  final String label, value, sub;
  final Color? subColor;
  final bool highlight;
  const _BannerStat({
    required this.label,
    required this.value,
    required this.sub,
    this.subColor,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: highlight ? 28 : 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          sub,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: subColor ?? Colors.white60,
          ),
        ),
      ],
    );
  }
}

// ── Section Card ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final int? count;
  final bool isEnabled;
  final ValueChanged<bool> onToggle;
  final Widget child;

  static const _primary = Color(0xFF4F46E5);
  static const _secondary = Color(0xFFE0E7FF);

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.isEnabled,
    required this.onToggle,
    required this.child,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: isEnabled ? 1.0 : 0.5,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEnabled
                ? _primary.withValues(alpha: 0.25)
                : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isEnabled ? _secondary : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color: isEnabled ? _primary : const Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        if (count != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: isEnabled
                                  ? _secondary
                                  : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$count',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isEnabled
                                    ? _primary
                                    : const Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      value: isEnabled,
                      onChanged: onToggle,
                      activeColor: _primary,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
            if (isEnabled) ...[
              Divider(height: 1, color: _primary.withValues(alpha: 0.1)),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: child,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Skill Chip ────────────────────────────────────────────────────────────────

class _SkillChip extends StatelessWidget {
  final String label;
  const _SkillChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E7FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF4F46E5),
        ),
      ),
    );
  }
}

// ── Experience Item ───────────────────────────────────────────────────────────

class _ExperienceItem extends StatelessWidget {
  final SuggestedWorkExperience exp;
  const _ExperienceItem({required this.exp});

  @override
  Widget build(BuildContext context) {
    final dateRange = exp.isCurrent
        ? '${exp.startDate} – Present'
        : '${exp.startDate}${exp.endDate != null ? ' – ${exp.endDate}' : ''}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E7FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.work_outline_rounded,
              size: 16,
              color: Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exp.jobTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                Text(
                  exp.companyName +
                      (exp.location != null ? ' · ${exp.location}' : ''),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                Text(
                  dateRange,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
                if (exp.description != null && exp.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    exp.description!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
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

// ── Education Item ────────────────────────────────────────────────────────────

class _EducationItem extends StatelessWidget {
  final SuggestedEducation edu;
  const _EducationItem({required this.edu});

  @override
  Widget build(BuildContext context) {
    final dateRange = edu.isCurrent
        ? '${edu.startDate} – Present'
        : '${edu.startDate}${edu.endDate != null ? ' – ${edu.endDate}' : ''}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E7FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.school_outlined,
              size: 16,
              color: Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  edu.institutionName,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                Text(
                  edu.degree +
                      (edu.fieldOfStudy != null
                          ? ' · ${edu.fieldOfStudy}'
                          : ''),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                Text(
                  dateRange,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
                if (edu.grade != null && edu.grade!.isNotEmpty)
                  Text(
                    'GPA / Grade: ${edu.grade}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
