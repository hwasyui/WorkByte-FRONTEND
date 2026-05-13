class SuggestedWorkExperience {
  final String jobTitle;
  final String companyName;
  final String? location;
  final String startDate;
  final String? endDate;
  final bool isCurrent;
  final String? description;

  SuggestedWorkExperience({
    required this.jobTitle,
    required this.companyName,
    this.location,
    required this.startDate,
    this.endDate,
    this.isCurrent = false,
    this.description,
  });

  factory SuggestedWorkExperience.fromJson(Map<String, dynamic> json) =>
      SuggestedWorkExperience(
        jobTitle: json['job_title'] as String? ?? '',
        companyName: json['company_name'] as String? ?? '',
        location: json['location'] as String?,
        startDate: json['start_date']?.toString() ?? '',
        endDate: json['end_date']?.toString(),
        isCurrent: json['is_current'] as bool? ?? false,
        description: json['description'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'job_title': jobTitle,
    'company_name': companyName,
    'location': location,
    'start_date': startDate,
    'end_date': endDate,
    'is_current': isCurrent,
    'description': description,
  };
}

class SuggestedEducation {
  final String institutionName;
  final String degree;
  final String? fieldOfStudy;
  final String startDate;
  final String? endDate;
  final bool isCurrent;
  final String? grade;

  SuggestedEducation({
    required this.institutionName,
    required this.degree,
    this.fieldOfStudy,
    required this.startDate,
    this.endDate,
    this.isCurrent = false,
    this.grade,
  });

  factory SuggestedEducation.fromJson(Map<String, dynamic> json) =>
      SuggestedEducation(
        institutionName: json['institution_name'] as String? ?? '',
        degree: json['degree'] as String? ?? '',
        fieldOfStudy: json['field_of_study'] as String?,
        startDate: json['start_date']?.toString() ?? '',
        endDate: json['end_date']?.toString(),
        isCurrent: json['is_current'] as bool? ?? false,
        grade: json['grade'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'institution_name': institutionName,
    'degree': degree,
    'field_of_study': fieldOfStudy,
    'start_date': startDate,
    'end_date': endDate,
    'is_current': isCurrent,
    'grade': grade,
  };
}

class SuggestedLanguage {
  final String name;
  final String proficiency;

  SuggestedLanguage({required this.name, required this.proficiency});

  factory SuggestedLanguage.fromJson(Map<String, dynamic> json) =>
      SuggestedLanguage(
        name: json['name'] as String? ?? '',
        proficiency: json['proficiency'] as String? ?? 'conversational',
      );

  Map<String, dynamic> toJson() => {'name': name, 'proficiency': proficiency};
}

class CvSuggestedProfile {
  final String? suggestedBio;
  final List<String> skills;
  final List<SuggestedWorkExperience> workExperience;
  final List<SuggestedEducation> education;
  final List<SuggestedLanguage> languages;

  CvSuggestedProfile({
    this.suggestedBio,
    this.skills = const [],
    this.workExperience = const [],
    this.education = const [],
    this.languages = const [],
  });

  factory CvSuggestedProfile.fromJson(
    Map<String, dynamic> json,
  ) => CvSuggestedProfile(
    suggestedBio: json['suggested_bio'] as String?,
    skills:
        (json['skills'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        [],
    workExperience:
        (json['work_experience'] as List<dynamic>?)
            ?.map(
              (e) =>
                  SuggestedWorkExperience.fromJson(e as Map<String, dynamic>),
            )
            .toList() ??
        [],
    education:
        (json['education'] as List<dynamic>?)
            ?.map((e) => SuggestedEducation.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    languages:
        (json['languages'] as List<dynamic>?)
            ?.map((e) => SuggestedLanguage.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
  );
}
