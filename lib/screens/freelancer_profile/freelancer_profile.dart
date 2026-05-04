import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../widgets/education_profile.dart';
import '../../widgets/experience_profile.dart';
import '../../widgets/edit_profile_form.dart';
import '../../widgets/add_skill.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/review_provider.dart';
import '../../providers/saved_items_provider.dart';
import '../../models/review_model.dart';
import '../../services/api_service.dart';
import '../../screens/auth/login.dart';
import 'upload_cv.dart';
import 'dart:io';

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
  List<Map<String, dynamic>> skills = [];
  final TextEditingController aboutController = TextEditingController();
  late TabController _tabController;

  static const Color primaryColor = AppColors.primary;

  final List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> educations = [];
  List<Map<String, dynamic>> experiences = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEducations();
    _loadSkills();
    _loadExperiences();
    aboutController.addListener(() {
      setState(() => aboutText = aboutController.text);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final profile = Provider.of<ProfileProvider>(context, listen: false);
      setState(() {
        aboutText = profile.bio ?? '';
        uploadedCVPath = profile.freelancerProfile?.cvFileUrl;
      });

      _loadReviews();
    });
  }

  Future<void> _deleteEducation(String educationId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final success = await ApiService.deleteEducation(auth.token!, educationId);

    if (success) {
      setState(() {
        educations.removeWhere((edu) => edu["education_id"] == educationId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Education deleted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete education')),
      );
    }
  }

  Future<void> _refreshProfile() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final profile = Provider.of<ProfileProvider>(context, listen: false);
    final userType = profile.userType ?? 'freelancer';

    final identifier =
        profile.freelancerProfile?.freelancerId ?? auth.currentUser!.userId;
    if (auth.token != null) {
      print('Fetching profile for refresh using identifier: $identifier');
      final refreshSuccess = await profile.fetchProfile(
        token: auth.token!,
        userId: identifier,
        userType: userType,
      );
      print(
        'Profile fetch refresh success: $refreshSuccess, bio: ${profile.bio}, cv: ${profile.freelancerProfile?.cvFileUrl}, pic: ${profile.profilePictureUrl}',
      );
      setState(() {
        aboutText = profile.bio ?? '';
        uploadedCVPath = profile.freelancerProfile?.cvFileUrl;
        _cvRemoved = profile.freelancerProfile?.cvFileUrl == null;
      });
      print(
        'UI updated: aboutText: $aboutText, uploadedCVPath: $uploadedCVPath, _cvRemoved: $_cvRemoved',
      );
    }
  }

  Future<void> _loadSkills() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final profile = Provider.of<ProfileProvider>(context, listen: false);

    if (auth.token != null && profile.freelancerProfile?.freelancerId != null) {
      final skillsData = await ApiService.getFreelancerSkills(
        auth.token!,
        profile.freelancerProfile!.freelancerId,
      );
      setState(() {
        skills = skillsData
            .map(
              (skill) => {
                'freelancer_skill_id': skill['freelancer_skill_id'],
                'skill_name':
                    skill['skill_name'] ??
                    'Unknown Skill', // ✅ always populated now
                'proficiency_level': skill['proficiency_level'] ?? 'beginner',
              },
            )
            .toList();
      });
    }
  }

  Future<void> _loadExperiences() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final profile = Provider.of<ProfileProvider>(context, listen: false);

    if (auth.token != null && profile.freelancerProfile?.freelancerId != null) {
      final experiencesData = await ApiService.getWorkExperiences(
        auth.token!,
        profile.freelancerProfile!.freelancerId,
      );

      setState(() {
        experiences = experiencesData
            .map(
              (exp) => {
                "work_experience_id": exp["work_experience_id"],
                "title": exp["job_title"],
                "company": exp["company_name"],
                "location": exp["location"],
                "description": exp["description"],
                "startDate": exp["start_date"] != null
                    ? DateTime.parse(exp["start_date"])
                    : null,
                "endDate": exp["end_date"] != null
                    ? DateTime.parse(exp["end_date"])
                    : null,
                "isPresent": exp["is_current"] ?? false,
              },
            )
            .toList();
      });
    }
  }

  Future<void> _loadEducations() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final profile = Provider.of<ProfileProvider>(context, listen: false);

    if (auth.token != null && profile.freelancerProfile?.freelancerId != null) {
      final educationsData = await ApiService.getEducations(
        auth.token!,
        profile.freelancerProfile!.freelancerId,
      );

      setState(() {
        educations = educationsData
            .map(
              (edu) => {
                "education_id": edu["education_id"],
                "school": edu["institution_name"],
                "degree": edu["degree"],
                "field": edu["field_of_study"],
                "grade": edu["grade"],
                "description": edu["description"],
                "startDate": edu["start_date"] != null
                    ? DateTime.parse(edu["start_date"])
                    : null,
                "endDate": edu["end_date"] != null
                    ? DateTime.parse(edu["end_date"])
                    : null,
                "isCurrent": edu["is_current"] ?? false,
              },
            )
            .toList();
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

  Future<void> _deleteSkill(String freelancerSkillId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final success = await ApiService.deleteFreelancerSkill(
      auth.token!,
      freelancerSkillId,
    );

    if (success) {
      setState(() {
        skills.removeWhere(
          (skill) => skill["freelancer_skill_id"] == freelancerSkillId,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Skill deleted successfully')),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to delete skill')));
    }
  }

  Future<void> _deleteExperience(String workExperienceId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final success = await ApiService.deleteWorkExperience(
      auth.token!,
      workExperienceId,
    );

    if (success) {
      setState(() {
        experiences.removeWhere(
          (exp) => exp["work_experience_id"] == workExperienceId,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Experience deleted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete experience')),
      );
    }
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
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
                      child: Text('✦',
                          style: TextStyle(
                              color: AppColors.primary, fontSize: 14)),
                    ),
                    const Positioned(
                      top: 6,
                      right: 10,
                      child: Text('✦',
                          style: TextStyle(
                              color: Color(0xFFB8B0F0), fontSize: 10)),
                    ),
                    const Positioned(
                      bottom: 8,
                      right: 8,
                      child: Text('✦',
                          style: TextStyle(
                              color: AppColors.primary, fontSize: 12)),
                    ),
                    const Positioned(
                      top: 30,
                      left: 2,
                      child: CircleAvatar(
                          radius: 3,
                          backgroundColor: Color(0xFFB8B0F0)),
                    ),
                    const Positioned(
                      bottom: 26,
                      right: 0,
                      child: CircleAvatar(
                          radius: 2.5,
                          backgroundColor: Color(0xFFB8B0F0)),
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
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
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
                      onPressed: () {
                        final auth = Provider.of<AuthProvider>(
                            context,
                            listen: false);
                        final profile = Provider.of<ProfileProvider>(
                            context,
                            listen: false);
                        auth.logout(profileProvider: profile);
                        if (mounted) {
                          Navigator.pop(context);
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
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

          final fields = <String, dynamic>{"full_name": data['name']};

          if (data['imageDeleted'] == true) {
            // User explicitly deleted their profile picture
            fields['profile_picture_url'] = null;
          } else if (data['image'] != null &&
              data['image'].toString().isNotEmpty &&
              data['image'] != profile.profilePictureUrl) {
            final imageVal = data['image'].toString();

            if (imageVal.startsWith('http')) {
              // Already a remote URL — save directly
              fields['profile_picture_url'] = imageVal;
            } else {
              // TODO: Replace this block with Supabase upload when ready:
              // final uploadedUrl = await SupabaseService.uploadProfilePicture(
              //   token: auth.token!,
              //   filePath: imageVal,
              // );
              // if (uploadedUrl != null) {
              //   fields['profile_picture_url'] = uploadedUrl;
              // } else {
              //   ScaffoldMessenger.of(context).showSnackBar(
              //     const SnackBar(content: Text('Failed to upload profile picture')),
              //   );
              //   return;
              // }

              // ⚠️ Temporary: save local path until Supabase upload is ready
              // Note: this path only works on this device
              fields['profile_picture_url'] = imageVal;
            }
          }

          final identifier =
              profile.freelancerProfile?.freelancerId ??
              auth.currentUser!.userId;

          final success = await profile.updateProfile(
            token: auth.token!,
            identifier: identifier,
            fields: fields,
          );

          print(
            'Update Profile success: $success, fields: $fields, error: ${profile.error}',
          );

          if (success) {
            if (data['imageDeleted'] == true) {
              profile.clearProfilePicture();
            } else if (fields.containsKey('profile_picture_url') &&
                fields['profile_picture_url'] != null) {
              // Update local state with whatever URL/path was saved
              profile.updateProfilePictureUrl(fields['profile_picture_url']);
            }

            print('Refreshing profile after Profile update');
            await _refreshProfile();
            profile.forceRefreshProfilePicture();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(profile.error ?? 'Failed to update profile'),
              ),
            );
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
          final success = await ApiService.createEducation(auth.token!, {
            "freelancer_id": profile.freelancerProfile?.freelancerId,
            "institution_name": data["school"],
            "degree": data["degree"],
            "field_of_study": data["field"],
            "start_date": data["startDate"]?.toIso8601String().split('T')[0],
            "end_date": data["endDate"]?.toIso8601String().split('T')[0],
            "is_current": data["isCurrent"],
            "grade": data["grade"],
            "description": data["description"],
          });

          if (success) {
            await _loadEducations();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Education added successfully')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to add education')),
            );
          }
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
          final success = await ApiService.createWorkExperience(auth.token!, {
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
          });

          if (success) {
            await _loadExperiences();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Experience added successfully')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to add experience')),
            );
          }
        },
      ),
    );
  }

  void _editAbout() {
    aboutController.text = aboutText;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        // ← renamed, stops shadowing
        title: const Text('Edit About'),
        content: TextField(
          controller: aboutController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Tell us about yourself...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newBio = aboutController.text.trim();
              final bioValue = newBio.isEmpty ? null : newBio;

              // ✅ These now use the SCREEN's context, not the dialog's
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final profile = Provider.of<ProfileProvider>(
                context,
                listen: false,
              );
              final messenger = ScaffoldMessenger.of(context);
              final identifier =
                  profile.freelancerProfile?.freelancerId ??
                  auth.currentUser!.userId;

              Navigator.pop(dialogContext); // ← pop using dialog's context

              final success = await profile.updateProfile(
                token: auth.token!,
                identifier: identifier,
                fields: {'bio': bioValue},
              );

              if (success) {
                setState(() => aboutText = newBio);
                await _refreshProfile(); // ✅ uses screen's context internally
                messenger.showSnackBar(
                  const SnackBar(content: Text('About saved successfully')),
                );
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(profile.error ?? 'Failed to save About'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Save'),
          ),
        ],
      ),
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

          final success = await ApiService.createFreelancerSkill(auth.token!, {
            "freelancer_id": profile.freelancerProfile?.freelancerId,
            "skill_id": skillId,
            "proficiency_level": proficiency,
          });

          if (success) {
            await _loadSkills();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Skill added successfully')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to add skill')),
            );
          }
        },
      ),
    );
  }

  Future<void> _uploadCV() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final profile = Provider.of<ProfileProvider>(context, listen: false);

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (result != null) {
      final fileName = result.files.single.name;
      final identifier =
          profile.freelancerProfile?.freelancerId ?? auth.currentUser!.userId;
      final updateFields = {"cv_file_url": fileName};
      print(
        'Sending CV upload update: identifier=$identifier, fields=$updateFields',
      );
      final success = await profile.updateProfile(
        token: auth.token!,
        identifier: identifier,
        fields: updateFields,
      );
      if (success) {
        setState(() {
          uploadedCVPath = fileName;
          _cvRemoved = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CV uploaded and saved: $fileName')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(profile.error ?? 'Failed to save CV')),
        );
      }
    }
  }

  Future<void> _removeCV() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final profile = Provider.of<ProfileProvider>(context, listen: false);

    final identifier =
        profile.freelancerProfile?.freelancerId ?? auth.currentUser!.userId;
    final updateFields = {"cv_file_url": null};
    print(
      'Sending CV remove update: identifier=$identifier, fields=$updateFields',
    );
    final success = await profile.updateProfile(
      token: auth.token!,
      identifier: identifier,
      fields: updateFields,
    );

    print('Remove CV success: $success, error: ${profile.error}');

    if (success) {
      print('Refreshing profile after CV remove');
      await _refreshProfile();
      setState(() {
        uploadedCVPath = null;
        _cvRemoved = true;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('CV removed successfully')));
    } else {
      print('Failed to remove CV');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(profile.error ?? 'Failed to remove CV')),
      );
    }
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

  Widget _buildStarRating({required double rating, required double size}) {
    final fullStars = rating.floor();
    final hasHalfStar = rating % 1 != 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return Icon(Icons.star, color: Colors.grey[400], size: size);
        } else if (index == fullStars && hasHalfStar) {
          return Icon(Icons.star_half, color: Colors.grey[400], size: size);
        } else {
          return Icon(Icons.star_outline, color: Colors.grey[400], size: size);
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildStickyHeader(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAboutTab(),
                  _buildReviewsTab(),
                  _buildSavedTab(),
                ],
              ),
            ),
          ],
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
              // ── Banner ────────────────────────────────────────────────
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
                      // Decorative circles bottom-left
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
                      // Dot pattern top-right
                      Positioned(
                        top: 16,
                        right: 56,
                        child: _buildDotGrid(),
                      ),
                    ],
                  ),
                ),
              ),
              // ── Nav buttons ───────────────────────────────────────────
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
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                          Icons.bookmarks_outlined, color: Colors.white),
                      onPressed: () => _tabController.animateTo(2),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: () => _showLogoutDialog(context),
                    ),
                  ],
                ),
              ),
              // ── Profile avatar ────────────────────────────────────────
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
                          child: profileImage == null ||
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

          Center(
            child: _buildStarRating(rating: _getAverageRating(), size: 18),
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
          const SizedBox(height: 12),

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

        return SingleChildScrollView(
          padding: const EdgeInsets.only(top: 16, bottom: 32),
          child: Column(
            children: [
              // About
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

              // Upload CV — custom card layout
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
                      )
                    else
                      OutlinedButton(
                        onPressed: _uploadCV,
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: skills.map((s) {
                            return _SkillChip(
                              label: s['skill_name'],
                              proficiency: s['proficiency_level'],
                              onDelete: () =>
                                  _deleteSkill(s['freelancer_skill_id']),
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
                child: Column(
                  children: experiences.map<Widget>((e) {
                    return _ExperienceItem(
                      logo: Icons.work,
                      title: e['title'],
                      company: e['company'],
                      period: e['isPresent'] == true
                          ? "${e['startDate']?.year ?? ''} - Present"
                          : "${e['startDate']?.year ?? ''} - ${e['endDate']?.year ?? ''}",
                      logoColor: primaryColor,
                      onDelete: () =>
                          _deleteExperience(e['work_experience_id']),
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
                child: Column(
                  children: educations.map((e) {
                    String endYear = e['isCurrent'] == true
                        ? 'Present'
                        : (e['endDate']?.year.toString() ?? '');
                    return _EducationItem(
                      degree: e['degree'],
                      school: e['school'],
                      period: "${e['startDate']?.year ?? ''} - $endYear",
                      color: primaryColor,
                      onDelete: () => _deleteEducation(e['education_id']),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // _buildSection(
              //   title: 'Portfolio',
              //   actionButton: _buildAddButton('Add Portfolio', () {}),
              //   child: const SizedBox(height: 16),
              // ),
            ],
          ),
        );
      },
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


        return SingleChildScrollView(
          padding: const EdgeInsets.only(top: 16, bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Trust Score Card ──────────────────────────────────────
              if (trustScore != null) ...[
                _TrustScoreCard(trustScore: trustScore),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 20),

              // ── Reviews list ──────────────────────────────────────────
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
                        '${reviews.length} total',
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
                  Icon(Icons.bookmarks_outlined,
                      size: 52, color: Colors.grey[300]),
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
                            color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                ...jobs.map((job) => Padding(
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
                              child: const Icon(Icons.work_outline,
                                  color: AppColors.primary, size: 22),
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
                                        color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => saved.toggleSaveJob(job),
                              child: const Icon(Icons.bookmark_rounded,
                                  color: AppColors.primary, size: 22),
                            ),
                          ],
                        ),
                      ),
                    )),
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
                            color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                ...clients.map((c) => Padding(
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
                              backgroundImage: c.profilePictureUrl != null &&
                                      c.profilePictureUrl!.startsWith('http')
                                  ? NetworkImage(c.profilePictureUrl!)
                                  : null,
                              child: c.profilePictureUrl == null ||
                                      !c.profilePictureUrl!.startsWith('http')
                                  ? const Icon(Icons.business,
                                      color: AppColors.primary, size: 22)
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
                                        color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => saved.toggleSaveClient(c),
                              child: const Icon(Icons.bookmark_rounded,
                                  color: AppColors.primary, size: 22),
                            ),
                          ],
                        ),
                      ),
                    )),
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
      if (diff.inDays >= 365)
        timeAgo = '${(diff.inDays / 365).floor()}y ago';
      else if (diff.inDays >= 30)
        timeAgo = '${(diff.inDays / 30).floor()}mo ago';
      else if (diff.inDays > 0)
        timeAgo = '${diff.inDays}d ago';
      else
        timeAgo = 'Today';
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
          // ── Header row ────────────────────────────────────────────────
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
              // Star + score
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

          // ── Category ratings row ──────────────────────────────────────
          if (review.ratings.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: review.ratings.map((r) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_capitalizeCategory(r.category)} ${r.score.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // ── Comment ───────────────────────────────────────────────────
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              comment,
              style: const TextStyle(color: Colors.black87, fontSize: 13),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // ── Skill tags ────────────────────────────────────────────────
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

class _SkillChip extends StatelessWidget {
  final String label;
  final String proficiency;
  final VoidCallback? onDelete;

  const _SkillChip({
    required this.label,
    required this.proficiency,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ($proficiency)',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
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

// ── Trust Score Card ──────────────────────────────────────────────────────────
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
          // ── Title row ─────────────────────────────────────────────────
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

          // ── Score circle + label ──────────────────────────────────────
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

          // ── Component bars ────────────────────────────────────────────
          _ScoreBar(
            label: 'Work Quality',
            icon: Icons.workspace_premium_outlined,
            value: trustScore.workQualityScore,
          ),
          _ScoreBar(
            label: 'On-Time Delivery',
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
  final double? value; // 0.0 – 1.0

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
