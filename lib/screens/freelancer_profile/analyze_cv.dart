import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import '../../services/cv_analysis_service.dart';
import '../../providers/auth_provider.dart';
import 'analyze_cv_result.dart';

class AnalyzingCVScreen extends StatefulWidget {
  final File file;

  const AnalyzingCVScreen({Key? key, required this.file}) : super(key: key);

  @override
  State<AnalyzingCVScreen> createState() => _AnalyzingCVScreenState();
}

class _AnalyzingCVScreenState extends State<AnalyzingCVScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _sparkleController;
  int _currentStep = 0;

  static const Color _primaryColor = Color(0xFF4F46E5);
  static const Color _cardBg = Color(0xFFE0E7FF);

  final List<String> _steps = [
    'Uploading your CV...',
    'Reading document...',
    'Analyzing content...',
    'Evaluating structure...',
    'Generating score...',
  ];

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _startAnalysis();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  Future<void> _startAnalysis() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication required to analyze CV')),
        );
        Navigator.pop(context);
      }
      return;
    }

    final analysisFuture = CvAnalysisService().analyzeCV(token, widget.file);

    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _currentStep = i;
        });
      }
    }

    try {
      final result = await analysisFuture;
      if (!mounted) return;

      final status = (result['scoring'] as String?)?.toUpperCase() ?? 'UNKNOWN';
      final similarity = (result['similarity_score'] as num?)?.toDouble() ?? 0.0;
      final score = (similarity * 100).round();
      final recommendations = List<String>.from(result['recommendations'] ?? []);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CVAnalysisResultScreen(
            score: score,
            status: status,
            recommendations: recommendations,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CV analysis failed: ${e.toString()}')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Analyzing CV',
          style: TextStyle(
            color: _primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background decoration
          _buildBackgroundDecorations(context),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  const SizedBox(height: 32),

                  // AI Animation
                  _buildAIAnimation(),

                  const SizedBox(height: 32),

                  const Text(
                    'AI is analyzing your CV',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'This will take a few moments',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // Progress Steps Card
                  _buildStepsCard(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecorations(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Stack(
      children: [
        // Wavy top background
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: CustomPaint(
            size: Size(width, 140),
            painter: _WavePainter(),
          ),
        ),
        // Large circle top center-right
        Positioned(
          top: -20,
          right: width * 0.15,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE0E7FF).withOpacity(0.6),
            ),
          ),
        ),
        // Dots grid top-right
        Positioned(
          top: 8,
          right: 8,
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
      width: 60,
      height: 60,
      child: GridView.count(
        crossAxisCount: 4,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(16, (_) => dot),
      ),
    );
  }

  Widget _buildAIAnimation() {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer rotating arc
          RotationTransition(
            turns: _rotationController,
            child: CustomPaint(
              size: const Size(150, 150),
              painter: _ArcPainter(color: _primaryColor),
            ),
          ),
          // Outer light circle bg
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE0E7FF),
            ),
          ),
          // Inner sparkle icon
          const Icon(
            Icons.auto_awesome,
            size: 52,
            color: _primaryColor,
          ),
          // Floating sparkle top-left
          _buildFloatingSparkle(top: 12, left: 16, size: 14),
          // Floating sparkle top-right
          _buildFloatingSparkle(top: 16, right: 12, size: 10),
          // Floating sparkle bottom-right
          _buildFloatingSparkle(bottom: 20, right: 20, size: 12),
        ],
      ),
    );
  }

  Widget _buildFloatingSparkle({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: FadeTransition(
        opacity: _sparkleController,
        child: Icon(
          Icons.star,
          size: size,
          color: const Color(0xFFAAAAAA),
        ),
      ),
    );
  }

  Widget _buildStepsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: List.generate(_steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Divider(height: 1, color: Colors.grey.withOpacity(0.2));
          }
          final index = i ~/ 2;
          return _buildStepItem(index);
        }),
      ),
    );
  }

  Widget _buildStepItem(int index) {
    final isCompleted = index < _currentStep;
    final isCurrent = index == _currentStep;
    final isPending = index > _currentStep;

    Color textColor;
    if (isCurrent) {
      textColor = _primaryColor;
    } else if (isCompleted) {
      textColor = Colors.black87;
    } else {
      textColor = Colors.grey[400]!;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          _buildStepIndicator(
            isCompleted: isCompleted,
            isCurrent: isCurrent,
            isPending: isPending,
          ),
          const SizedBox(width: 14),
          Text(
            _steps[index],
            style: TextStyle(
              fontSize: 14,
              color: textColor,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator({
    required bool isCompleted,
    required bool isCurrent,
    required bool isPending,
  }) {
    if (isCompleted) {
      return Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: _primaryColor,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 16, color: Colors.white),
      );
    }

    if (isCurrent) {
      return SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: const AlwaysStoppedAnimation<Color>(_primaryColor),
          backgroundColor: _primaryColor.withOpacity(0.15),
        ),
      );
    }

    // Pending
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final Color color;

  _ArcPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2,
    );

    canvas.drawArc(rect, 0, math.pi * 1.4, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE0E7FF)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, size.height * 0.6);
    path.quadraticBezierTo(
      size.width * 0.25, size.height * 0.85,
      size.width * 0.55, size.height * 0.65,
    );
    path.quadraticBezierTo(
      size.width * 0.8, size.height * 0.45,
      size.width, size.height * 0.55,
    );
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
