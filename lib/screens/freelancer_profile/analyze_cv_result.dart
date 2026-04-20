import 'package:flutter/material.dart';
import 'dart:math' as math;

class CVAnalysisResultScreen extends StatefulWidget {
  final int score;
  final String status;
  final List<String> recommendations;
  
  const CVAnalysisResultScreen({
    Key? key,
    required this.score,
    required this.status,
    this.recommendations = const [],
  }) : super(key: key);

  @override
  State<CVAnalysisResultScreen> createState() => _CVAnalysisResultScreenState();
}

class _CVAnalysisResultScreenState extends State<CVAnalysisResultScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

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

  Color _getStatusColor() {
    if (widget.score >= 75) {
      return const Color(0xFF4CAF50); // Green
    } else if (widget.score >= 50) {
      return const Color(0xFFFFA726); // Amber
    } else {
      return const Color(0xFFEF5350); // Red
    }
  }

  String _getStatusDescription() {
    if (widget.score >= 75) {
      return 'Your CV is well structured';
    } else if (widget.score >= 50) {
      return 'Your CV needs some improvements';
    } else {
      return 'Your CV requires major improvements';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 40), // Space for close button
                    
                    // Main Content Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!, width: 0.5),
                      ),
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          // CV Score Label
                          const Text(
                            'CV SCORE',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                              letterSpacing: 0.5,
                            ),
                          ),
                      
                      const SizedBox(height: 16),
                      
                      // Circular Progress
                      SizedBox(
                        width: 160,
                        height: 160,
                        child: AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: CircularProgressPainter(
                                progress: _animation.value / 100,
                                progressColor: const Color(0xFF008B8B),
                                backgroundColor: const Color(0xFFE8F4F8),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${_animation.value.toInt()}%',
                                      style: const TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Match',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              widget.status,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: _getStatusColor(),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _getStatusDescription(),
                              style: TextStyle(
                                fontSize: 13,
                                color: _getStatusColor().withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Divider
                      Divider(color: Colors.grey[300], height: 1, thickness: 0.5),
                      
                      const SizedBox(height: 24),
                      
                      // Suggestions Section
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Suggestions for improvement',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Suggestion Items
                      if (widget.recommendations.isEmpty) ...[
                        _buildSuggestionItem(
                          'Add more quantifiable achievements in your work experience',
                        ),
                        _buildSuggestionItem(
                          'Include specific metrics and results from your projects',
                        ),
                        _buildSuggestionItem(
                          'Consider adding a brief professional summary at the top',
                        ),
                        _buildSuggestionItem(
                          'Highlight relevant certifications and courses',
                        ),
                      ] else ...widget.recommendations
                          .map((text) => _buildSuggestionItem(text))
                          .toList(),
                    ],
                  ),
                ),
              ],
            ),
            ),
          ),
          // Close Button (X)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Color(0xFF008B8B),
                  size: 24,
                ),
                onPressed: () => Navigator.pop(context),
                splashRadius: 24,
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildSuggestionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF008B8B),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Circular Progress
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
    final radius = (size.width - 12) / 2;
    final strokeWidth = 12.0;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}