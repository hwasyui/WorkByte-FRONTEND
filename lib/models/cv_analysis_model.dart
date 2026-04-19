class CVAnalysisResult {
  final String score; // "good", "enough", "bad"
  final String scoreExplanation;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> recommendations;
  final List<String> skillsExtracted;
  final String experienceLevel; // "entry", "mid", "senior", "expert"
  final int completenessScore; // 0-100
  final Map<String, dynamic>? profileComparison;
  final int cvTextLength;
  final String fileProcessed;

  const CVAnalysisResult({
    required this.score,
    required this.scoreExplanation,
    required this.strengths,
    required this.weaknesses,
    required this.recommendations,
    required this.skillsExtracted,
    required this.experienceLevel,
    required this.completenessScore,
    this.profileComparison,
    required this.cvTextLength,
    required this.fileProcessed,
  });

  factory CVAnalysisResult.fromJson(Map<String, dynamic> json) {
    final analysis = json['analysis'] as Map<String, dynamic>;
    return CVAnalysisResult(
      score: analysis['score'] as String? ?? 'unknown',
      scoreExplanation: analysis['score_explanation'] as String? ?? '',
      strengths: List<String>.from(analysis['strengths'] ?? []),
      weaknesses: List<String>.from(analysis['weaknesses'] ?? []),
      recommendations: List<String>.from(analysis['recommendations'] ?? []),
      skillsExtracted: List<String>.from(analysis['skills_extracted'] ?? []),
      experienceLevel: analysis['experience_level'] as String? ?? 'unknown',
      completenessScore: analysis['completeness_score'] as int? ?? 0,
      profileComparison: json['profile_comparison'] as Map<String, dynamic>?,
      cvTextLength: json['cv_text_length'] as int? ?? 0,
      fileProcessed: json['file_processed'] as String? ?? '',
    );
  }

  String get scoreDisplay {
    switch (score.toLowerCase()) {
      case 'good':
        return 'Good';
      case 'enough':
        return 'Sufficient';
      case 'bad':
        return 'Needs Improvement';
      default:
        return 'Unknown';
    }
  }

  String get scoreColor {
    switch (score.toLowerCase()) {
      case 'good':
        return 'green';
      case 'enough':
        return 'orange';
      case 'bad':
        return 'red';
      default:
        return 'grey';
    }
  }

  String get experienceLevelDisplay {
    switch (experienceLevel.toLowerCase()) {
      case 'entry':
        return 'Entry Level';
      case 'mid':
        return 'Mid Level';
      case 'senior':
        return 'Senior Level';
      case 'expert':
        return 'Expert Level';
      default:
        return 'Unknown';
    }
  }
}

class CVTextExtraction {
  final String extractedText;
  final int textLength;
  final String fileName;

  const CVTextExtraction({
    required this.extractedText,
    required this.textLength,
    required this.fileName,
  });

  factory CVTextExtraction.fromJson(Map<String, dynamic> json) {
    return CVTextExtraction(
      extractedText: json['extracted_text'] as String? ?? '',
      textLength: json['text_length'] as int? ?? 0,
      fileName: json['file_name'] as String? ?? '',
    );
  }
}