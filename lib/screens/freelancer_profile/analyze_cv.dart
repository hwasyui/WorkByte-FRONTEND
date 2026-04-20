import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:async';
import '../../services/cv_analysis_service.dart';
import '../../providers/auth_provider.dart';
import 'analyze_cv_result.dart';

class AnalyzingCVScreen extends StatefulWidget {
  final File file;
  
  const AnalyzingCVScreen({Key? key, required this.file}) : super(key: key);

  @override
  State<AnalyzingCVScreen> createState() => _AnalyzingCVScreenState();
}

class _AnalyzingCVScreenState extends State<AnalyzingCVScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int _currentStep = 0;
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
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    _startAnalysis();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Animated Circle
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: RotationTransition(
                      turns: _animationController,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF008B8B),
                        ),
                        backgroundColor: Colors.grey[200],
                      ),
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF008B8B).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 40,
                      color: Color(0xFF008B8B),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              const Text(
                'AI is analyzing your CV',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              Text(
                'This will take a few moments',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // Progress Steps
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: List.generate(_steps.length, (index) {
                    final isActive = index <= _currentStep;
                    final isCurrent = index == _currentStep;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isActive 
                                  ? const Color(0xFF008B8B)
                                  : Colors.grey[300],
                              shape: BoxShape.circle,
                            ),
                            child: isActive && !isCurrent
                                ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : isCurrent
                                    ? const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        ),
                                      )
                                    : null,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _steps[index],
                            style: TextStyle(
                              fontSize: 14,
                              color: isActive 
                                  ? Colors.black87
                                  : Colors.grey[400],
                              fontWeight: isCurrent 
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}