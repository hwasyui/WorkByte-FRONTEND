import 'package:flutter/material.dart';
import 'dart:math' as math;

class CVAnalysisResultScreen extends StatefulWidget {
  final int score;
  final String status;
  final String overallAssessment;
  final String profileMatchAnalysis;
  final List<Map<String, dynamic>> sections;

  const CVAnalysisResultScreen({
    Key? key,
    required this.score,
    required this.status,
    this.overallAssessment = '',
    this.profileMatchAnalysis = '',
    this.sections = const [],
  }) : super(key: key);

  @override
  State<CVAnalysisResultScreen> createState() => _CVAnalysisResultScreenState();
}

class _CVAnalysisResultScreenState extends State<CVAnalysisResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  static const Color _primaryColor = Color(0xFF4F46E5);
  static const Color _lightColor = Color(0xFFE0E7FF);
  static const Color _bgColor = Color(0xFFEEF2FF);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: 0, end: widget.score.toDouble()).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getGradeLabel() {
    switch (widget.status.toLowerCase()) {
      case 'excellent':
        return 'Excellent';
      case 'good':
        return 'Good';
      case 'fair':
        return 'Fair';
      case 'bad':
        return 'Needs Improvement';
      default:
        return widget.status.isNotEmpty
            ? '${widget.status[0].toUpperCase()}${widget.status.substring(1)}'
            : 'Unknown';
    }
  }

  String _getStatusDescription() {
    if (widget.score >= 80) return 'Your CV is well structured and optimized';
    if (widget.score >= 60) return 'Your CV is good with room for improvement';
    if (widget.score >= 40) return 'Your CV needs some improvements';
    return 'Your CV requires major improvements';
  }

  IconData _getStatusIcon() {
    if (widget.score >= 80) return Icons.workspace_premium;
    if (widget.score >= 60) return Icons.shield;
    if (widget.score >= 40) return Icons.trending_up_rounded;
    return Icons.warning_amber_rounded;
  }

  Color _getGradeColor() {
    if (widget.score >= 80) return const Color(0xFF22C55E);
    if (widget.score >= 60) return _primaryColor;
    if (widget.score >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          _buildBackgroundDecorations(context),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Center(
                              child: Text(
                                'CV SCORE',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: _lightColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: _primaryColor,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Center(child: _buildScoreCircle()),

                    const SizedBox(height: 24),

                    _buildStatusBadge(),

                    const SizedBox(height: 20),

                    Divider(color: Colors.grey[200], height: 1),

                    const SizedBox(height: 20),

                    // Overall Assessment
                    if (widget.overallAssessment.isNotEmpty) ...[
                      _buildSectionHeader('Overall Assessment', Icons.summarize_rounded),
                      const SizedBox(height: 12),
                      _buildAssessmentCard(widget.overallAssessment),
                      const SizedBox(height: 20),
                    ],

                    // Profile Match Analysis
                    if (widget.profileMatchAnalysis.isNotEmpty) ...[
                      _buildSectionHeader('Profile Match', Icons.person_search_rounded),
                      const SizedBox(height: 12),
                      _buildAssessmentCard(widget.profileMatchAnalysis),
                      const SizedBox(height: 20),
                    ],

                    // Per-section recommendations
                    if (widget.sections.isNotEmpty) ...[
                      _buildSectionHeader('Recommendations', Icons.tips_and_updates_rounded),
                      const SizedBox(height: 12),
                      ...widget.sections.map(_buildSectionCard),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentCard(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _lightColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _lightColor),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Color(0xFF374151),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(Map<String, dynamic> section) {
    final title = (section['title'] as String?) ?? '';
    final analysis = (section['analysis'] as String?) ?? '';
    final recs = List<String>.from(
      ((section['recommendations'] as List?) ?? []).map((r) => r.toString()),
    );

    final IconData sectionIcon;
    switch (title.toLowerCase()) {
      case 'skills analysis':
        sectionIcon = Icons.build_rounded;
        break;
      case 'work experience':
        sectionIcon = Icons.work_rounded;
        break;
      case 'education':
        sectionIcon = Icons.school_rounded;
        break;
      case 'ats optimization':
        sectionIcon = Icons.smart_toy_rounded;
        break;
      default:
        sectionIcon = Icons.article_rounded;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _lightColor.withOpacity(0.6),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  Icon(sectionIcon, size: 18, color: _primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (analysis.isNotEmpty) ...[
                    Text(
                      analysis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.55,
                        color: Colors.grey[700],
                      ),
                    ),
                    if (recs.isNotEmpty) const SizedBox(height: 12),
                  ],
                  if (recs.isNotEmpty) ...[
                    const Text(
                      'Recommendations',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...recs.map(_buildRecItem),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: _primaryColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCircle() {
    return SizedBox(
      width: 210,
      height: 210,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(top: 22, left: 28, child: _SparkleIcon(size: 20)),
          const Positioned(top: 44, left: 46, child: _SparkleIcon(size: 13)),
          const Positioned(top: 18, right: 22, child: _SparkleIcon(size: 13)),
          const Positioned(bottom: 38, right: 18, child: _SparkleIcon(size: 18)),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(190, 190),
                painter: CircularProgressPainter(
                  progress: _animation.value / 100,
                  progressColor: _getGradeColor(),
                  backgroundColor: _lightColor,
                ),
                child: SizedBox(
                  width: 190,
                  height: 190,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${_animation.value.toInt()}',
                                style: const TextStyle(
                                  fontSize: 54,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const TextSpan(
                                text: '/100',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          'Overall Score',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _getGradeColor().withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _getGradeColor().withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _getGradeColor().withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(_getStatusIcon(), color: _getGradeColor(), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGradeLabel(),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _getGradeColor(),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getStatusDescription(),
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundDecorations(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(
      children: [
        Positioned(
          left: -40,
          top: size.height * 0.3,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _lightColor.withOpacity(0.8),
            ),
          ),
        ),
        Positioned(
          right: -30,
          top: size.height * 0.2,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _lightColor.withOpacity(0.8),
            ),
          ),
        ),
        Positioned(
          top: 20,
          left: 16,
          child: _buildDotsGrid(),
        ),
        Positioned(
          bottom: 20,
          right: 16,
          child: _buildDotsGrid(),
        ),
      ],
    );
  }

  Widget _buildDotsGrid() {
    const dotColor = Color(0xFFA5B4FC);
    const dot = SizedBox(
      width: 4,
      height: 4,
      child: DecoratedBox(
        decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
      ),
    );
    return SizedBox(
      width: 44,
      height: 44,
      child: GridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(9, (_) => dot),
      ),
    );
  }
}

class _SparkleIcon extends StatelessWidget {
  final double size;
  const _SparkleIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.star, size: size, color: Color(0xFFA5B4FC));
  }
}

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;

  CircularProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 18) / 2;
    const strokeWidth = 14.0;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}