import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:workbyte_app/models/cv_suggested_profile.dart';
import 'package:http/http.dart' as http;
import 'package:workbyte_app/screens/freelancer_profile/cv_review.dart';
import 'package:workbyte_app/services/cv_analysis_service.dart';
import 'package:workbyte_app/widgets/appeal_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/colors.dart';
import '../../core/utils/helpers.dart';
import '../../models/education_model.dart';
import '../../models/experience_model.dart';
import '../../models/freelancer_skill_model.dart';
import '../../models/portfolio_model.dart';
import '../../models/review_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/review_provider.dart';
import '../../providers/saved_items_provider.dart';
import '../../screens/auth/login.dart';
import '../../widgets/add_skill.dart';
import '../../widgets/edit_profile_form.dart';
import '../../widgets/education_profile.dart';
import '../../widgets/experience_profile.dart';
import '../../widgets/portfolio_profile.dart';
import 'upload_cv.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  String aboutText = '';
  String? uploadedCVPath;
  bool _cvRemoved = false;
  bool _isUploadingCV = false;
  String? cvDisplayName;

  final TextEditingController aboutController = TextEditingController();
  final TextEditingController hourlyController = TextEditingController();
  String _selectedRateTime = 'hourly';
  String _selectedCurrency = 'USD';
  late TabController _tabController;

  // Cached currency list loaded once from REST Countries API
  static List<Map<String, String>>? _currencyCache;

  static const List<Map<String, String>> _fallbackCurrencies = [
    {'code': 'USD', 'name': 'United States Dollar'},
    {'code': 'EUR', 'name': 'Euro'},
    {'code': 'GBP', 'name': 'British Pound Sterling'},
    {'code': 'IDR', 'name': 'Indonesian Rupiah'},
    {'code': 'JPY', 'name': 'Japanese Yen'},
    {'code': 'SGD', 'name': 'Singapore Dollar'},
    {'code': 'AUD', 'name': 'Australian Dollar'},
    {'code': 'CAD', 'name': 'Canadian Dollar'},
    {'code': 'CHF', 'name': 'Swiss Franc'},
    {'code': 'CNY', 'name': 'Chinese Yuan'},
    {'code': 'INR', 'name': 'Indian Rupee'},
    {'code': 'MYR', 'name': 'Malaysian Ringgit'},
    {'code': 'PHP', 'name': 'Philippine Peso'},
    {'code': 'THB', 'name': 'Thai Baht'},
    {'code': 'HKD', 'name': 'Hong Kong Dollar'},
    {'code': 'KRW', 'name': 'South Korean Won'},
    {'code': 'NZD', 'name': 'New Zealand Dollar'},
    {'code': 'BRL', 'name': 'Brazilian Real'},
    {'code': 'AED', 'name': 'UAE Dirham'},
    {'code': 'SAR', 'name': 'Saudi Riyal'},
  ];

  Future<List<Map<String, String>>> _loadCurrencies() async {
    if (_currencyCache != null) return _currencyCache!;
    final res = await http.get(
      Uri.parse('https://restcountries.com/v3.1/all?fields=currencies'),
    );
    if (res.statusCode != 200) throw Exception('Failed to load currencies');
    final countries = jsonDecode(res.body) as List<dynamic>;
    final seen = <String>{};
    final result = <Map<String, String>>[];
    for (final c in countries) {
      final map = c['currencies'] as Map<String, dynamic>?;
      if (map == null) continue;
      for (final e in map.entries) {
        if (seen.contains(e.key)) continue;
        seen.add(e.key);
        final name =
            (e.value as Map<String, dynamic>)['name'] as String? ?? e.key;
        result.add({'code': e.key, 'name': name});
      }
    }
    result.sort((a, b) => a['code']!.compareTo(b['code']!));
    _currencyCache = result;
    return result;
  }

  static const Color primaryColor = AppColors.primary;

  final List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    aboutController.addListener(() {
      setState(() => aboutText = aboutController.text);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final auth = Provider.of<AuthProvider>(context, listen: false);
      final profile = Provider.of<ProfileProvider>(context, listen: false);

      setState(() {
        aboutText = profile.bio ?? '';
        uploadedCVPath = profile.freelancerProfile?.cvFileUrl;
        _cvRemoved = false;
        final rate = profile.freelancerProfile?.estimatedRate;
        hourlyController.text = rate != null
            ? ThousandsSeparatorFormatter.format(rate)
            : '';
        _selectedRateTime = profile.freelancerProfile?.rateTime ?? 'hourly';
        _selectedCurrency = profile.freelancerProfile?.rateCurrency ?? 'USD';
      });

      if (auth.token != null && profile.isFreelancer) {
        await profile.refreshFreelancerDetails(auth.token!);
      }

      await _loadReviews();
    });
  }

  Future<void> _refreshProfile() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final profile = Provider.of<ProfileProvider>(context, listen: false);
    final userType = profile.userType ?? 'freelancer';

    final identifier =
        profile.freelancerProfile?.freelancerId ?? auth.currentUser!.userId;

    if (auth.token != null) {
      final refreshSuccess = await profile.fetchProfile(
        token: auth.token!,
        userId: identifier,
        userType: userType,
      );

      debugPrint(
        'Profile fetch refresh success: $refreshSuccess, bio: ${profile.bio}, cv: ${profile.freelancerProfile?.cvFileUrl}, pic: ${profile.profilePictureUrl}',
      );

      setState(() {
        aboutText = profile.bio ?? '';
        uploadedCVPath = profile.freelancerProfile?.cvFileUrl;
        _cvRemoved = false;
        final rate = profile.freelancerProfile?.estimatedRate;
        hourlyController.text = rate != null
            ? ThousandsSeparatorFormatter.format(rate)
            : '';
        _selectedRateTime = profile.freelancerProfile?.rateTime ?? 'hourly';
        _selectedCurrency = profile.freelancerProfile?.rateCurrency ?? 'USD';
      });
    }
  }

  Future<void> _loadReviews() async {
    if (!mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final profile = Provider.of<ProfileProvider>(context, listen: false);
    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);

    final freelancerId = profile.freelancerProfile?.freelancerId;
    if (auth.token != null && freelancerId != null) {
      await Future.wait([
        reviewProvider.loadFreelancerReviews(
          token: auth.token!,
          freelancerId: freelancerId,
        ),
        reviewProvider.loadTrustScore(
          token: auth.token!,
          freelancerId: freelancerId,
        ),
      ]);
    }
  }

  Future<void> _deleteEducation(String educationId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final profile = Provider.of<ProfileProvider>(context, listen: false);

    final success = await profile.removeEducation(
      token: auth.token!,
      educationId: educationId,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Education deleted successfully'
              : 'Failed to delete education',
        ),
      ),
    );
  }

  Future<void> _deleteExperience(String workExperienceId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final profile = Provider.of<ProfileProvider>(context, listen: false);

    final success = await profile.removeWorkExperience(
      token: auth.token!,
      workExperienceId: workExperienceId,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Experience deleted successfully'
              : 'Failed to delete experience',
        ),
      ),
    );
  }

  Future<void> _deleteSkill(String freelancerSkillId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final profile = Provider.of<ProfileProvider>(context, listen: false);

    final success = await profile.removeFreelancerSkill(
      token: auth.token!,
      freelancerSkillId: freelancerSkillId,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Skill deleted successfully' : 'Failed to delete skill',
        ),
      ),
    );
  }

  Future<void> _deletePortfolio(String portfolioId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final profile = Provider.of<ProfileProvider>(context, listen: false);

    final success = await profile.removePortfolio(
      token: auth.token!,
      portfolioId: portfolioId,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Portfolio deleted successfully'
                : 'Failed to delete portfolio',
          ),
        ),
      );
    }
  }

  void _showPortfolioForm() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final profile = Provider.of<ProfileProvider>(context, listen: false);
    final freelancerId = profile.freelancerProfile?.freelancerId;
    if (freelancerId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PortfolioProfile(
        onSave: (data) async {
          final completionDate = data['completionDate'] as DateTime?;
          await profile.addPortfolio(
            token: auth.token!,
            data: {
              'freelancer_id': freelancerId,
              'project_title': data['projectTitle'] as String,
              'project_description': data['projectDescription'] as String?,
              'project_url': data['projectUrl'] as String?,
              'completion_date': completionDate?.toIso8601String(),
            },
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Portfolio added successfully')),
            );
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    aboutController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFFF3F1FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 120,
                width: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDDD8FA),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.primary,
                        size: 36,
                      ),
                    ),
                    const Positioned(
                      top: 6,
                      left: 10,
                      child: Text(
                        '✦',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Positioned(
                      top: 6,
                      right: 10,
                      child: Text(
                        '✦',
                        style: TextStyle(
                          color: Color(0xFFB8B0F0),
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const Positioned(
                      bottom: 8,
                      right: 8,
                      child: Text(
                        '✦',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Positioned(
                      top: 30,
                      left: 2,
                      child: CircleAvatar(
                        radius: 3,
                        backgroundColor: Color(0xFFB8B0F0),
                      ),
                    ),
                    const Positioned(
                      bottom: 26,
                      right: 0,
                      child: CircleAvatar(
                        radius: 2.5,
                        backgroundColor: Color(0xFFB8B0F0),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Logout',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to logout?',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final auth = context.read<AuthProvider>();
                        final profile = context.read<ProfileProvider>();

                        await auth.logout(profileProvider: profile);

                        if (!mounted) return;

                        Navigator.pop(context);
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final auth = Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        );
                        final profile = Provider.of<ProfileProvider>(
                          context,
                          listen: false,
                        );
                        auth.logout(profileProvider: profile);
                        if (mounted) {
                          Navigator.pop(context);
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: Text(
                        'Logout',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfile() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final profile = Provider.of<ProfileProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => EditProfileForm(
        initialData: {
          "name": profile.displayName,
          "username": auth.currentUser?.email ?? '',
          "job": profile.jobTitle,
          "image": profile.profilePictureUrl,
        },
        onSave: (data) async {
          profile.updateJobTitle(data['job']);

          final identifier =
              profile.freelancerProfile?.freelancerId ??
              auth.currentUser!.userId;

          // Case 1: New local image selected → upload via multipart endpoint
          if (data['image'] != null &&
              data['image'].toString().isNotEmpty &&
              data['image'] != profile.profilePictureUrl &&
              !data['image'].toString().startsWith('http')) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Uploading profile picture...')),
              );
            }

            final picSuccess = await profile.uploadProfilePicture(
              token: auth.token!,
              identifier: identifier,
              imageFile: File(data['image']),
            );

            if (!picSuccess) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      profile.error ?? 'Failed to upload profile picture',
                    ),
                  ),
                );
              }
              return;
            }
          }
          // Case 2: Image deleted
          else if (data['imageDeleted'] == true) {
            await profile.deleteProfilePicture(
              token: auth.token!,
              identifier: identifier,
            );
          }

          // Update name/job title fields
          final fields = <String, dynamic>{
            "full_name": data['name'],
            if ((data['job'] as String?)?.isNotEmpty == true &&
                data['job'] != '-')
              "title": data['job'],
          };

          final success = await profile.updateProfile(
            token: auth.token!,
            identifier: identifier,
            fields: fields,
          );

          if (success) {
            await _refreshProfile();
            profile.forceRefreshProfilePicture();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated successfully')),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(profile.error ?? 'Failed to update profile'),
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showEducationForm() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final profile = Provider.of<ProfileProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => EducationProfile(
        onSave: (data) async {
          final success = await profile.addEducation(
            token: auth.token!,
            data: {
              "freelancer_id": profile.freelancerProfile?.freelancerId,
              "institution_name": data["school"],
              "degree": data["degree"],
              "field_of_study": data["field"],
              "start_date": data["startDate"]?.toIso8601String().split('T')[0],
              "end_date": data["endDate"]?.toIso8601String().split('T')[0],
              "is_current": data["isCurrent"],
              "grade": data["grade"],
              "description": data["description"],
            },
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Education added successfully'
                    : 'Failed to add education',
              ),
            ),
          );
        },
      ),
    );
  }

  void _showExperienceForm() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final profile = Provider.of<ProfileProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ExperienceProfile(
        onSave: (data) async {
          final success = await profile.addWorkExperience(
            token: auth.token!,
            data: {
              "freelancer_id": profile.freelancerProfile?.freelancerId,
              "job_title": data["title"],
              "company_name": data["company"],
              "location": data["location"],
              "start_date": data["startDate"] != null
                  ? data["startDate"].toIso8601String().split('T')[0]
                  : null,
              "end_date": data["endDate"] != null
                  ? data["endDate"].toIso8601String().split('T')[0]
                  : null,
              "is_current": data["isPresent"],
              "description": data["description"],
            },
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Experience added successfully'
                    : 'Failed to add experience',
              ),
            ),
          );
        },
      ),
    );
  }

  void _editAbout() {
    aboutController.text = aboutText;

    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0E7FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: Color(0xFF4F46E5),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Edit About',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(dialogContext),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE0E7FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Color(0xFF4F46E5),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Tell us about yourself',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: aboutController,
                maxLines: 7,
                style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
                decoration: InputDecoration(
                  hintText: 'Tell us about yourself...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFEEF0FF),
                  contentPadding: const EdgeInsets.all(16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF4F46E5),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF4F46E5),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(height: 1, color: const Color(0xFFE5E7EB)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFF4F46E5),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final newBio = aboutController.text.trim();
                        final bioValue = newBio.isEmpty ? null : newBio;

                        final auth = Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        );
                        final profile = Provider.of<ProfileProvider>(
                          context,
                          listen: false,
                        );
                        final messenger = ScaffoldMessenger.of(context);
                        final identifier =
                            profile.freelancerProfile?.freelancerId ??
                            auth.currentUser!.userId;

                        Navigator.pop(dialogContext);

                        final success = await profile.updateProfile(
                          token: auth.token!,
                          identifier: identifier,
                          fields: {'bio': bioValue},
                        );

                        if (success) {
                          setState(() => aboutText = newBio);
                          await _refreshProfile();
                        }
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'About saved successfully'
                                    : profile.error ?? 'Failed to save About',
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editHourly() {
    const rateTimes = [
      ('hourly', 'Hourly'),
      ('weekly', 'Weekly'),
      ('monthly', 'Monthly'),
      ('annually', 'Annually'),
    ];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        String localRateTime = _selectedRateTime;
        String localCurrency = _selectedCurrency;
        List<Map<String, String>>? currencies;
        bool loadingCurrencies = false;
        String? currencyError;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            // Kick off currency load once
            if (currencies == null &&
                !loadingCurrencies &&
                currencyError == null) {
              loadingCurrencies = true;
              _loadCurrencies()
                  .then((list) {
                    setDialogState(() {
                      currencies = list;
                      loadingCurrencies = false;
                    });
                  })
                  .catchError((e) {
                    setDialogState(() {
                      currencies = _fallbackCurrencies;
                      currencyError = e.toString();
                      loadingCurrencies = false;
                    });
                  });
            }

            Future<void> pickCurrency() async {
              if (currencies == null) return;
              final picked = await showModalBottomSheet<String>(
                context: ctx,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _CurrencyPickerSheet(currencies: currencies!),
              );
              if (picked != null) {
                setDialogState(() => localCurrency = picked);
              }
            }

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 40,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEEECFB),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.payments_outlined,
                              color: AppColors.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Edit Rate',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Set your desired rate and period.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(dialogContext),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFF9CA3AF),
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Rate type selector
                      Text(
                        'Rate Period',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: rateTimes.map((rt) {
                          final isSelected = localRateTime == rt.$1;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setDialogState(() => localRateTime = rt.$1),
                              child: Container(
                                margin: rt != rateTimes.last
                                    ? const EdgeInsets.only(right: 6)
                                    : null,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    rt.$2,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Amount + currency row
                      Text(
                        'Amount & Currency',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEECFB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: hourlyController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  ThousandsSeparatorFormatter(),
                                ],
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF111827),
                                ),
                                decoration: InputDecoration(
                                  hintText: '0',
                                  hintStyle: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                            // Currency picker button
                            GestureDetector(
                              onTap: loadingCurrencies ? null : pickCurrency,
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDDD8FA),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (loadingCurrencies)
                                      const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          color: AppColors.primary,
                                        ),
                                      )
                                    else
                                      Text(
                                        localCurrency,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.arrow_drop_down,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (currencyError != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Could not load currencies. Using cached list.',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      const Divider(color: Color(0xFFF0F0F1)),
                      const SizedBox(height: 16),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final val = ThousandsSeparatorFormatter.parse(
                                  hourlyController.text.trim(),
                                );
                                final auth = Provider.of<AuthProvider>(
                                  context,
                                  listen: false,
                                );
                                final profile = Provider.of<ProfileProvider>(
                                  context,
                                  listen: false,
                                );
                                final messenger = ScaffoldMessenger.of(context);
                                final identifier =
                                    profile.freelancerProfile?.freelancerId ??
                                    auth.currentUser!.userId;

                                Navigator.pop(dialogContext);

                                final fields = <String, dynamic>{
                                  'estimated_rate': val != null
                                      ? val.toString()
                                      : '',
                                  'rate_time': localRateTime,
                                  'rate_currency': localCurrency,
                                };

                                final success = await profile.updateProfile(
                                  token: auth.token!,
                                  identifier: identifier,
                                  fields: fields,
                                );

                                if (success) {
                                  setState(() {
                                    _selectedRateTime = localRateTime;
                                    _selectedCurrency = localCurrency;
                                  });
                                  await _refreshProfile();
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Rate saved successfully'),
                                    ),
                                  );
                                } else {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        profile.error ?? 'Failed to save rate',
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Save',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSkillForm() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final profile = Provider.of<ProfileProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddSkillWidget(
        onSave: (skillData) async {
          final skillId = skillData["skill_id"];
          final proficiency = skillData["proficiency_level"] as String;

          if (skillId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select a skill')),
            );
            return;
          }

          final success = await profile.addFreelancerSkill(
            token: auth.token!,
            data: {
              "freelancer_id": profile.freelancerProfile?.freelancerId,
              "skill_id": skillId,
              "proficiency_level": proficiency,
            },
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success ? 'Skill added successfully' : 'Failed to add skill',
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _uploadCV() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    final fileName = result.files.single.name;

    setState(() => _isUploadingCV = true);

    try {
      final data = await CvAnalysisService().uploadCV(auth.token!, file);

      final fileUrl = data['file_url'] as String?;
      if (fileUrl != null) {
        setState(() {
          uploadedCVPath = fileUrl;
          cvDisplayName = fileName;
          _cvRemoved = false;
        });
      }

      await _refreshProfile();
      if (!mounted) return;

      if (fileUrl != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'CV uploaded successfully',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: const Color(0xFF4F46E5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'CV upload failed. Please try again.',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: const Color(0xFFC62828),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: const Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploadingCV = false);
    }
  }

  Future<void> _removeCV() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final profile = Provider.of<ProfileProvider>(context, listen: false);

    final identifier =
        profile.freelancerProfile?.freelancerId ?? auth.currentUser!.userId;
    final updateFields = {'cv_file_url': ''};

    final success = await profile.updateProfile(
      token: auth.token!,
      identifier: identifier,
      fields: updateFields,
    );

    if (success) {
      await _refreshProfile();
      setState(() {
        uploadedCVPath = null;
        _cvRemoved = true;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('CV removed successfully')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(profile.error ?? 'Failed to remove CV')),
      );
    }
  }

  Future<void> _previewCV(String? cvUrl) async {
    if (cvUrl == null || cvUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No CV available to preview')),
      );
      return;
    }

    await openDocumentFromUrl(context, cvUrl);
  }

  String _getCvDisplayName(String? path) {
    if (path == null || path.isEmpty) return '';
    final parts = path.split(RegExp(r'[\\/]+'));
    return parts.isNotEmpty ? parts.last : path;
  }

  double _getAverageRating() {
    if (_reviews.isEmpty) return 0.0;
    final totalRating = _reviews.fold<int>(0, (sum, review) {
      return sum + (review['rating'] as int? ?? 0);
    });
    return totalRating / _reviews.length;
  }

  String _formatPeriod({
    required String? startDate,
    required String? endDate,
    required bool isCurrent,
  }) {
    String extractYear(String? value) {
      if (value == null || value.isEmpty) return '';
      try {
        return DateTime.parse(value).year.toString();
      } catch (_) {
        if (value.length >= 4) return value.substring(0, 4);
        return value;
      }
    }

    final startYear = extractYear(startDate);
    final endYear = isCurrent ? 'Present' : extractYear(endDate);

    if (startYear.isEmpty && endYear.isEmpty) return '';
    if (startYear.isEmpty) return endYear;
    if (endYear.isEmpty) return startYear;

    return '$startYear - $endYear';
  }

  Widget _buildStarRating({
    required double rating,
    required double size,
    Color? color,
    bool showValue = true,
  }) {
    final safeRating = rating.clamp(0.0, 5.0);
    final fullStars = safeRating.floor();
    final hasHalfStar = (safeRating - fullStars) >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...List.generate(5, (index) {
          if (index < fullStars) {
            return Icon(
              Icons.star,
              color: color ?? Colors.grey[400],
              size: size,
            );
          } else if (index == fullStars && hasHalfStar) {
            return Icon(
              Icons.star_half,
              color: color ?? Colors.grey[400],
              size: size,
            );
          } else {
            return Icon(
              Icons.star_outline,
              color: color ?? Colors.grey[400],
              size: size,
            );
          }
        }),
        if (showValue) ...[
          const SizedBox(width: 6),
          Text(
            safeRating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.75,
              fontWeight: FontWeight.w600,
              color: color ?? Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(child: _buildStickyHeader()),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [_buildAboutTab(), _buildReviewsTab(), _buildSavedTab()],
          ),
        ),
      ),
    );
  }

  Widget _buildDotGrid() {
    return Column(
      children: List.generate(
        4,
        (row) => Row(
          children: List.generate(
            5,
            (col) => Padding(
              padding: const EdgeInsets.all(3),
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.35),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStickyHeader() {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipPath(
                clipper: _ProfileBannerClipper(),
                child: Container(
                  height: 185,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    image: DecorationImage(
                      image: AssetImage('assets/profile.png'),
                      fit: BoxFit.cover,
                      opacity: 0.18,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        bottom: 10,
                        left: -45,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 40,
                        left: 30,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(top: 16, right: 56, child: _buildDotGrid()),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.maybePop(context),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(
                    Icons.bookmarks_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () => _tabController.animateTo(2),
                ),
              ),
              Positioned(
                bottom: -48,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: AppColors.secondary,
                    ),
                    child: Consumer<ProfileProvider>(
                      builder: (context, profile, child) {
                        final profileImage = profile.profilePictureUrl;
                        return CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.secondary,
                          backgroundImage: profileImage != null
                              ? (profileImage.startsWith('http')
                                    ? NetworkImage(profileImage)
                                    : (File(profileImage).existsSync()
                                          ? FileImage(File(profileImage))
                                          : null))
                              : null,
                          child:
                              profileImage == null ||
                                  (!profileImage.startsWith('http') &&
                                      !File(profileImage).existsSync())
                              ? const Icon(
                                  Icons.person,
                                  size: 44,
                                  color: AppColors.primary,
                                )
                              : null,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 58),

          Consumer<ReviewProvider>(
            builder: (context, reviewProvider, child) {
              final trustScore = reviewProvider.trustScore;
              return Center(
                child: _buildStarRating(
                  rating: trustScore?.weightedReviewAvg ?? 0.0,
                  size: 18,
                  color: Colors.amber,
                ),
              );
            },
          ),
          const SizedBox(height: 6),

          Consumer2<AuthProvider, ProfileProvider>(
            builder: (context, auth, profile, child) {
              return Column(
                children: [
                  Text(
                    profile.displayName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    auth.currentUser?.email ?? '',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  if (profile.jobTitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      profile.jobTitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showEditProfile,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UploadCVScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.analytics_outlined, size: 18),
                    label: const Text('Analyze CV'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Ban notice banner
          Consumer<AuthProvider>(
            builder: (context, auth, child) {
              if (!auth.isReportBanned) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFEF9A9A).withValues(alpha: 0.7),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFCDD2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.gavel_rounded,
                          color: Color(0xFFC62828),
                          size: 15,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account restricted',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFB71C1C),
                              ),
                            ),
                            if (auth.banMessage != null &&
                                auth.banMessage!.isNotEmpty)
                              Text(
                                auth.banMessage!,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: const Color(0xFF7D7D7D),
                                  height: 1.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => AppealDialog.show(
                          context,
                          targetType: 'user',
                          targetId: auth.userId!,
                          targetLabel: 'Account Restriction',
                          closureNote: auth.banMessage,
                        ).then((_) => auth.refreshUser()),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC62828),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Appeal',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // ── Tab bar ──────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: primaryColor,
              indicatorWeight: 2.5,
              labelColor: primaryColor,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(fontSize: 14),
              tabs: const [
                Tab(text: 'About'),
                Tab(text: 'Reviews'),
                Tab(text: 'Saved'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTab() {
    return Consumer<ProfileProvider>(
      builder: (context, profile, child) {
        final bioText = aboutText;
        final cvPath = !_cvRemoved
            ? (uploadedCVPath ?? profile.freelancerProfile?.cvFileUrl)
            : null;
        final cvDisplayName = _getCvDisplayName(cvPath);

        final skills = profile.skills;
        final List<ExperienceModel> experiences = profile.experiences;
        final List<EducationModel> educations = profile.educations;
        final List<PortfolioModel> portfolios = profile.portfolios;

        return SingleChildScrollView(
          padding: const EdgeInsets.only(top: 16, bottom: 32),
          child: Column(
            children: [
              if (!profile.isProfileComplete && profile.isFreelancer) ...[
                _buildProfileCompletionBanner(profile.missingProfileFields),
                const SizedBox(height: 16),
              ],
              _buildSection(
                title: 'Rate',
                icon: Icons.payments_outlined,
                hasEdit: true,
                onEdit: _editHourly,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    hourlyController.text.isEmpty
                        ? 'No rate set'
                        : '$_selectedCurrency ${hourlyController.text} / $_selectedRateTime',
                    style: TextStyle(
                      color: hourlyController.text.isEmpty
                          ? Colors.grey
                          : Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: 'About',
                icon: Icons.person_outline,
                hasEdit: true,
                onEdit: _editAbout,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    bioText.isEmpty ? 'No information added yet' : bioText,
                    style: TextStyle(
                      color: bioText.isEmpty ? Colors.grey : Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Upload CV',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (cvPath != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              cvDisplayName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (cvPath != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton(
                            onPressed: () => _previewCV(cvPath),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryColor,
                              side: const BorderSide(color: primaryColor),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Preview',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _removeCV,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      OutlinedButton(
                        onPressed: _isUploadingCV ? null : _uploadCV,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: const BorderSide(color: primaryColor),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isUploadingCV
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: primaryColor,
                                ),
                              )
                            : const Text(
                                'Upload',
                                style: TextStyle(fontSize: 12),
                              ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: 'Skills',
                icon: Icons.star_outline,
                actionButton: _buildAddButton('Add Skill', _showSkillForm),
                child: skills.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          'No skills added yet',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: skills.map((s) {
                            return _SkillChip(
                              label: s.skillName ?? 'Unknown Skill',
                              proficiency: s.proficiencyLevel,
                              category: s.skillCategory,
                              onDelete: () => _deleteSkill(s.freelancerSkillId),
                            );
                          }).toList(),
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: 'Experiences',
                icon: Icons.work_outline,
                actionButton: _buildAddButton(
                  'Add Experiences',
                  _showExperienceForm,
                ),
                child: experiences.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          'No experiences added yet',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      )
                    : Column(
                        children: experiences.map<Widget>((e) {
                          return _ExperienceItem(
                            logo: Icons.work,
                            title: e.jobTitle,
                            company: e.companyName,
                            period: _formatPeriod(
                              startDate: e.startDate,
                              endDate: e.endDate,
                              isCurrent: e.isCurrent,
                            ),
                            logoColor: primaryColor,
                            onDelete: () =>
                                _deleteExperience(e.workExperienceId),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: 'Education',
                icon: Icons.school_outlined,
                actionButton: _buildAddButton(
                  'Add Education',
                  _showEducationForm,
                ),
                child: educations.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          'No education added yet',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      )
                    : Column(
                        children: educations.map((e) {
                          return _EducationItem(
                            degree: e.degree,
                            school: e.institutionName,
                            period: _formatPeriod(
                              startDate: e.startDate,
                              endDate: e.endDate,
                              isCurrent: e.isCurrent,
                            ),
                            color: primaryColor,
                            onDelete: () => _deleteEducation(e.educationId),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: 'Portfolio',
                icon: Icons.work_history_outlined,
                actionButton: _buildAddButton(
                  'Add Portfolio',
                  _showPortfolioForm,
                ),
                child: portfolios.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          'No portfolio items yet',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      )
                    : Column(
                        children: portfolios.map<Widget>((p) {
                          return _PortfolioItem(
                            item: p,
                            onDelete: p.isAutoGenerated
                                ? null
                                : () => _deletePortfolio(p.portfolioId),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileCompletionBanner(List<String> missing) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFCC02).withOpacity(0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECB3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFF57F17),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile incomplete',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF5D4037),
                      ),
                    ),
                    Text(
                      'Fill in the missing info to unlock all features.',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: const Color(0xFF795548),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: missing
                .map(
                  (field) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFFCC02).withOpacity(0.7),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.circle,
                          size: 6,
                          color: Color(0xFFF57F17),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          field,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF5D4037),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, _) {
        final isLoading =
            reviewProvider.reviewsState == ReviewLoadState.loading ||
            reviewProvider.trustState == ReviewLoadState.loading;

        if (isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: primaryColor),
          );
        }

        final reviews = reviewProvider.reviews;
        final trustScore = reviewProvider.trustScore;

        final double averageRating =
            trustScore?.displayStarAvg ?? trustScore?.weightedReviewAvg ?? 0.0;

        final int totalReviews = trustScore?.totalReviews ?? reviews.length;
        final categoryAverages = _buildCategoryAverages(reviews);

        return SingleChildScrollView(
          padding: const EdgeInsets.only(top: 16, bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (totalReviews > 0) ...[
                _RatingSummaryCard(
                  averageRating: averageRating,
                  totalReviews: totalReviews,
                ),
                const SizedBox(height: 16),
                _CategoryRatingsCard(categoryAverages: categoryAverages),
                const SizedBox(height: 16),
              ],
              if (trustScore != null) ...[
                _TrustScoreCard(trustScore: trustScore),
                const SizedBox(height: 16),
              ],
              if (reviews.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.rate_review,
                          color: Colors.grey[400],
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No reviews yet',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Reviews',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$totalReviews total',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ...reviews.map((r) => _buildReviewCard(r)).toList(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSavedTab() {
    return Consumer<SavedItemsProvider>(
      builder: (context, saved, _) {
        final jobs = saved.savedJobs;
        final clients = saved.savedClients;

        if (jobs.isEmpty && clients.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bookmarks_outlined,
                    size: 52,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'No saved items yet',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Save jobs or clients to see them here.',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.only(top: 16, bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (jobs.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Saved Jobs',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${jobs.length}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                ...jobs.map(
                  (job) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.work_outline,
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
                                  job.jobTitle,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  job.clientName ?? 'Client',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => saved.toggleSaveJob(job),
                            child: const Icon(
                              Icons.bookmark_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              if (clients.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Saved Clients',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${clients.length}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                ...clients.map(
                  (c) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.secondary,
                            backgroundImage:
                                c.profilePictureUrl != null &&
                                    c.profilePictureUrl!.startsWith('http')
                                ? NetworkImage(c.profilePictureUrl!)
                                : null,
                            child:
                                c.profilePictureUrl == null ||
                                    !c.profilePictureUrl!.startsWith('http')
                                ? const Icon(
                                    Icons.business,
                                    color: AppColors.primary,
                                    size: 22,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.displayName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                const Text(
                                  'Client',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => saved.toggleSaveClient(c),
                            child: const Icon(
                              Icons.bookmark_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewCard(Review review) {
    final avg = review.ratings.isEmpty
        ? 0.0
        : review.ratings.map((r) => r.score).reduce((a, b) => a + b) /
              review.ratings.length;
    final comment = review.writtenContent?.overallComment ?? '';
    final tags = review.skillTags.take(3).map((t) => t.skillTag).toList();
    final publishedAt = review.publishedAt;

    String timeAgo = '';
    if (publishedAt != null) {
      final diff = DateTime.now().difference(publishedAt);
      if (diff.inDays >= 365) {
        timeAgo = '${(diff.inDays / 365).floor()}y ago';
      } else if (diff.inDays >= 30) {
        timeAgo = '${(diff.inDays / 30).floor()}mo ago';
      } else if (diff.inDays > 0) {
        timeAgo = '${diff.inDays}d ago';
      } else {
        timeAgo = 'Today';
      }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: primaryColor.withOpacity(0.1),
                child: Text(
                  review.isAnonymous ? '?' : 'C',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.isAnonymous ? 'Anonymous Client' : 'Client',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 3),
                  Text(
                    avg.toStringAsFixed(1),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (review.ratings.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ReviewRatingsWrap(ratings: review.ratings),
          ],
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            _ExpandableReviewText(text: comment, primaryColor: primaryColor),
          ],
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(fontSize: 10, color: Colors.black54),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _capitalizeCategory(String cat) {
    return cat
        .split('_')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  Widget _buildEmptyBio(VoidCallback onAdd) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.secondary.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.25),
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.edit_note_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add your bio',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Tell clients about yourself, your skills, and experience.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
    IconData? icon,
    bool hasEdit = false,
    VoidCallback? onEdit,
    Widget? actionButton,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (icon != null) ...[
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (hasEdit) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onEdit,
                        child: const Icon(
                          Icons.edit,
                          size: 18,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
                if (actionButton != null) actionButton,
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildAddButton(String label, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}

class _ExperienceItem extends StatelessWidget {
  final IconData logo;
  final String title;
  final String company;
  final String period;
  final Color logoColor;
  final VoidCallback? onDelete;

  const _ExperienceItem({
    required this.logo,
    required this.title,
    required this.company,
    required this.period,
    required this.logoColor,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(logo, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  company,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            period,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }
}

class _EducationItem extends StatelessWidget {
  final String degree;
  final String school;
  final String period;
  final Color color;
  final VoidCallback? onDelete;

  const _EducationItem({
    required this.degree,
    required this.school,
    required this.period,
    required this.color,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.school_outlined,
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
                  degree,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  school,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            period,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }
}

class _PortfolioItem extends StatelessWidget {
  final PortfolioModel item;
  final VoidCallback? onDelete;

  const _PortfolioItem({required this.item, this.onDelete});

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8FC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEAEAF0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.projectTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ),
                if (item.isAutoGenerated)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'From Contract',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (onDelete != null) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onDelete,
                    child: const Icon(
                      Icons.delete,
                      color: Colors.red,
                      size: 18,
                    ),
                  ),
                ],
              ],
            ),
            if (item.projectDescription != null &&
                item.projectDescription!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                item.projectDescription!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (item.completionDate != null || item.projectUrl != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (item.completionDate != null) ...[
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(item.completionDate!),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                  if (item.projectUrl != null &&
                      item.projectUrl!.isNotEmpty) ...[
                    if (item.completionDate != null) const SizedBox(width: 12),
                    const Icon(Icons.link, size: 12, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.projectUrl!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;
  final String proficiency;
  final String? category;
  final VoidCallback? onDelete;

  const _SkillChip({
    required this.label,
    required this.proficiency,
    this.category,
    this.onDelete,
  });

  static String _formatCategory(String? cat) {
    return switch (cat) {
      'hard_skill' => 'Hard Skill',
      'soft_skill' => 'Soft Skill',
      'tool' => 'Tool',
      _ => cat?.replaceAll('_', ' ') ?? '',
    };
  }

  String _toTitleCase(String text) {
    if (text.trim().isEmpty) return text;
    return text
        .trim()
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final catLabel = _formatCategory(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                catLabel.isNotEmpty
                    ? '$catLabel · ${_toTitleCase(proficiency)}'
                    : _toTitleCase(proficiency),
                style: const TextStyle(color: AppColors.primary, fontSize: 10),
              ),
            ],
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onDelete,
              child: const Icon(
                Icons.close,
                size: 14,
                color: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrustScoreCard extends StatelessWidget {
  final TrustScore trustScore;
  static const Color primaryColor = AppColors.primary;

  const _TrustScoreCard({required this.trustScore});

  @override
  Widget build(BuildContext context) {
    final score = trustScore.overallScore;
    final rankPct = trustScore.categoryRankPct;
    final category = trustScore.category?.replaceAll('_', ' ') ?? '';

    Color scoreColor;
    String scoreLabel;
    if (score >= 80) {
      scoreColor = AppColors.primary;
      scoreLabel = 'Excellent';
    } else if (score >= 60) {
      scoreColor = Colors.amber.shade700;
      scoreLabel = 'Good';
    } else if (score >= 40) {
      scoreColor = Colors.orange;
      scoreLabel = 'Fair';
    } else {
      scoreColor = Colors.red.shade400;
      scoreLabel = 'Needs Work';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Spacer(),
              if (rankPct != null && category.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Top ${(100 - rankPct).toStringAsFixed(0)}% in $category',
                    style: TextStyle(
                      fontSize: 10,
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 7,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(scoreColor),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            score.toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: scoreColor,
                            ),
                          ),
                          Text(
                            '/100',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scoreLabel,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Based on ${trustScore.totalReviews} review${trustScore.totalReviews == 1 ? '' : 's'}, delivery record & communication',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ScoreBar(
            label: 'Revision Efficiency',
            icon: Icons.schedule_outlined,
            value: trustScore.revisionRateScore,
          ),
          _ScoreBar(
            label: 'Responsiveness',
            icon: Icons.chat_bubble_outline,
            value: trustScore.responsivenessScore,
          ),
          _ScoreBar(
            label: 'Communication',
            icon: Icons.sentiment_satisfied_outlined,
            value: trustScore.communicationSentiment,
          ),
        ],
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final IconData icon;
  final double? value;

  const _ScoreBar({
    required this.label,
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final v = (value ?? 0.0).clamp(0.0, 1.0);
    final pct = (v * 100).toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 13, color: Colors.grey[500]),
          const SizedBox(width: 6),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: v,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$pct%',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingSummaryCard extends StatelessWidget {
  final double averageRating;
  final int totalReviews;

  const _RatingSummaryCard({
    required this.averageRating,
    required this.totalReviews,
  });

  @override
  Widget build(BuildContext context) {
    final rating = averageRating.clamp(0.0, 5.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Average Rating',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                _StarRow(rating: rating),
                const SizedBox(height: 6),
                Text(
                  'Based on $totalReviews review${totalReviews == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRatingsCard extends StatelessWidget {
  final Map<String, double> categoryAverages;

  const _CategoryRatingsCard({required this.categoryAverages});

  @override
  Widget build(BuildContext context) {
    if (categoryAverages.isEmpty) return const SizedBox.shrink();

    final orderedKeys = [
      'communication',
      'quality',
      'professionalism',
      'value_for_money',
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rating Breakdown',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          ...orderedKeys.where(categoryAverages.containsKey).map((key) {
            final value = categoryAverages[key]!.clamp(0.0, 5.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(_ratingIcon(key), size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 110,
                    child: Text(
                      _ratingLabel(key),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: value / 5.0,
                        minHeight: 7,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    value.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ReviewRatingsWrap extends StatelessWidget {
  final List<ReviewRating> ratings;

  const _ReviewRatingsWrap({required this.ratings});

  @override
  Widget build(BuildContext context) {
    if (ratings.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ratings.map((rating) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _ratingIcon(rating.category),
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                _ratingLabel(rating.category),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.star_rounded, size: 14, color: Colors.amber),
              const SizedBox(width: 2),
              Text(
                rating.score.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _StarRow extends StatelessWidget {
  final double rating;

  const _StarRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        final starValue = index + 1;
        IconData icon;

        if (rating >= starValue) {
          icon = Icons.star_rounded;
        } else if (rating >= starValue - 0.5) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_border_rounded;
        }

        return Icon(icon, size: 18, color: Colors.amber.shade700);
      }),
    );
  }
}

String _ratingLabel(String category) {
  switch (category) {
    case 'communication':
      return 'Communication';
    case 'quality':
      return 'Quality';
    case 'professionalism':
      return 'Professionalism';
    case 'value_for_money':
      return 'Value for money';
    default:
      return category.replaceAll('_', ' ');
  }
}

IconData _ratingIcon(String category) {
  switch (category) {
    case 'communication':
      return Icons.chat_bubble_outline;
    case 'quality':
      return Icons.workspace_premium_outlined;
    case 'professionalism':
      return Icons.badge_outlined;
    case 'value_for_money':
      return Icons.payments_outlined;
    default:
      return Icons.star_outline;
  }
}

Map<String, double> _buildCategoryAverages(List<Review> reviews) {
  final totals = <String, double>{};
  final counts = <String, int>{};

  for (final review in reviews) {
    for (final rating in review.ratings) {
      totals[rating.category] = (totals[rating.category] ?? 0) + rating.score;
      counts[rating.category] = (counts[rating.category] ?? 0) + 1;
    }
  }

  return totals.map((key, total) {
    final count = counts[key] ?? 1;
    return MapEntry(key, total / count);
  });
}

class _ProfileBannerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, 0);
    path.lineTo(0, size.height - 30);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 20,
      size.width,
      size.height - 30,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_ProfileBannerClipper oldClipper) => false;
}

class _ExpandableReviewText extends StatefulWidget {
  final String text;
  final Color primaryColor;

  const _ExpandableReviewText({required this.text, required this.primaryColor});

  @override
  State<_ExpandableReviewText> createState() => _ExpandableReviewTextState();
}

class _ExpandableReviewTextState extends State<_ExpandableReviewText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isLong = widget.text.trim().length > 140;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 13,
            height: 1.45,
          ),
          maxLines: _expanded ? null : 4,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        if (isLong) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded ? 'Read less' : 'Read more',
              style: TextStyle(
                color: widget.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Thousands separator formatter ─────────────────────────────────────────────
// International format: comma = thousands separator, period = decimal separator.
// e.g. 14000 → "14,000" | 20.25 → "20.25" | 1500000.5 → "1,500,000.5"
class ThousandsSeparatorFormatter extends TextInputFormatter {
  static final _intFmt = NumberFormat('#,##0', 'en');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow only digits and one period (decimal point)
    String raw = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');

    // Keep only the first period
    final dotIndex = raw.indexOf('.');
    if (dotIndex != -1) {
      final afterDot = raw.substring(dotIndex + 1).replaceAll('.', '');
      // Limit decimal places to 2
      final dec = afterDot.length > 2 ? afterDot.substring(0, 2) : afterDot;
      raw = '${raw.substring(0, dotIndex)}.$dec';
    }

    if (raw.isEmpty) return newValue.copyWith(text: '');

    // Format integer part with comma separators
    final parts = raw.split('.');
    final intDigits = parts[0].replaceAll(',', '');
    final intFormatted = intDigits.isEmpty
        ? '0'
        : _intFmt.format(int.parse(intDigits));

    final formatted = parts.length > 1
        ? '$intFormatted.${parts[1]}' // preserve decimal as typed
        : intFormatted;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// Strip commas and parse as double (returns null for empty/invalid).
  static double? parse(String text) {
    final clean = text.replaceAll(',', '');
    if (clean.isEmpty) return null;
    return double.tryParse(clean);
  }

  /// Format a double for display in the field.
  static String format(double value) {
    if (value == value.truncateToDouble()) {
      return _intFmt.format(value.toInt());
    }
    // Show up to 2 decimal places, strip trailing zeros
    final dec = value
        .toStringAsFixed(2)
        .split('.')[1]
        .replaceAll(RegExp(r'0+$'), '');
    return '${_intFmt.format(value.truncate())}.$dec';
  }
}

// ── Currency picker bottom sheet ───────────────────────────────────────────────
class _CurrencyPickerSheet extends StatefulWidget {
  final List<Map<String, String>> currencies;

  const _CurrencyPickerSheet({required this.currencies});

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  final _searchCtrl = TextEditingController();
  List<Map<String, String>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.currencies;
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.currencies
          : widget.currencies
                .where(
                  (c) =>
                      c['code']!.toLowerCase().contains(q) ||
                      c['name']!.toLowerCase().contains(q),
                )
                .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Select Currency',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search currency code or name...',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF9CA3AF),
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: Color(0xFF9CA3AF),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // List
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final c = _filtered[i];
                return ListTile(
                  dense: true,
                  leading: Container(
                    width: 44,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      c['code']!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  title: Text(
                    c['name']!,
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                  onTap: () => Navigator.pop(context, c['code']),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
