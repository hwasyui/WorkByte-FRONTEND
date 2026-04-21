import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../widgets/education_profile.dart';
import '../../widgets/experience_profile.dart';
import '../../widgets/edit_profile_form.dart';
import '../../widgets/add_skill.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/review_provider.dart';
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

  static const Color primaryColor = Color(0xFF00AAA8);

  final List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> educations = [];
  List<Map<String, dynamic>> experiences = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final profile = Provider.of<ProfileProvider>(
                context,
                listen: false,
              );

              // Clear auth and profile state
              auth.logout(profileProvider: profile);

              if (mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
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
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            _buildStickyHeader(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildAboutTab(), _buildReviewsTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyHeader() {
    return Container(
      color: Colors.grey[100],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00AAA8), Color(0xFF008C8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.maybePop(context),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.white),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: () {
                        _showLogoutDialog(context);
                      },
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: -44,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Consumer<ProfileProvider>(
                      builder: (context, profile, child) {
                        final profileImage = profile.profilePictureUrl;
                        return CircleAvatar(
                          radius: 44,
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
                              ? const Icon(Icons.person, size: 44)
                              : null,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 52),

          Center(
            child: _buildStarRating(rating: _getAverageRating(), size: 18),
          ),
          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Consumer2<AuthProvider, ProfileProvider>(
                builder: (context, auth, profile, child) {
                  return Column(
                    children: [
                      Text(
                        profile.displayName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        auth.currentUser?.email ?? '',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      SizedBox(height: 2),
                      Text(
                        profile.jobTitle,
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 12),

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
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      side: const BorderSide(color: primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
                hasEdit: true,
                onEdit: _editAbout,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    bioText.isEmpty ? 'No information added yet' : bioText,
                    style: TextStyle(
                      color: bioText.isEmpty ? Colors.grey : Colors.black87,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Upload CV
              _buildSection(
                title: 'Upload CV',
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (cvPath == null)
                        OutlinedButton.icon(
                          onPressed: _uploadCV,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Upload CV'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: const BorderSide(color: primaryColor),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        )
                      else
                        Row(
                          children: [
                            const Icon(Icons.description, color: primaryColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                cvDisplayName,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.grey),
                              onPressed: _removeCV,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              _buildSection(
                title: 'Skills',
                actionButton: _buildAddButton('Add Skill', _showSkillForm),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: skills
                        .map(
                          (s) => _SkillChip(
                            label: s['skill_name'],
                            proficiency: s['proficiency_level'],
                            onDelete: () =>
                                _deleteSkill(s['freelancer_skill_id']),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildSection(
                title: 'Experiences',
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

        // Compute average rating inline
        final allScores = reviews
            .expand((r) => r.ratings)
            .map((r) => r.score)
            .toList();
        final avgRating = allScores.isEmpty
            ? 0.0
            : allScores.reduce((a, b) => a + b) / allScores.length;

        // Compute distribution inline
        final counts = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
        for (final r in reviews) {
          if (r.ratings.isEmpty) continue;
          final reviewAvg =
              r.ratings.map((rt) => rt.score).reduce((a, b) => a + b) /
              r.ratings.length;
          final star = reviewAvg.round().clamp(1, 5);
          counts[star] = (counts[star] ?? 0) + 1;
        }
        final distribution = counts.map(
          (star, count) =>
              MapEntry(star, reviews.isEmpty ? 0.0 : count / reviews.length),
        );

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

              // ── Rating summary card ───────────────────────────────────
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: avgRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const TextSpan(
                                text: ' /5',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: List.generate(5, (i) {
                            final filled = i < avgRating.round();
                            return Icon(
                              filled ? Icons.star : Icons.star_outline,
                              color: filled ? Colors.amber : Colors.grey[300],
                              size: 16,
                            );
                          }),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${reviews.length} review${reviews.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        children: [5, 4, 3, 2, 1].map((star) {
                          final fraction = distribution[star] ?? 0.0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 13),
                                const SizedBox(width: 4),
                                Text(
                                  '$star',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: fraction,
                                      minHeight: 7,
                                      backgroundColor: Colors.grey[200],
                                      valueColor: const AlwaysStoppedAnimation(
                                        Colors.amber,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

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

  Widget _buildSection({
    required String title,
    required Widget child,
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
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
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
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: logoColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(logo, color: logoColor, size: 24),
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
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                degree.contains('Bachelor') ? '2008' : '2005',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
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
    return Chip(
      label: Text('$label ($proficiency)'),
      deleteIcon: onDelete != null ? const Icon(Icons.delete, size: 18) : null,
      onDeleted: onDelete,
      backgroundColor: const Color(0xFF00AAA8).withOpacity(0.1),
      labelStyle: const TextStyle(color: Color(0xFF00AAA8)),
    );
  }
}

// ── Trust Score Card ──────────────────────────────────────────────────────────
class _TrustScoreCard extends StatelessWidget {
  final TrustScore trustScore;
  static const Color primaryColor = Color(0xFF00AAA8);

  const _TrustScoreCard({required this.trustScore});

  @override
  Widget build(BuildContext context) {
    final score = trustScore.overallScore;
    final rankPct = trustScore.categoryRankPct;
    final category = trustScore.category?.replaceAll('_', ' ') ?? '';

    Color scoreColor;
    String scoreLabel;
    if (score >= 80) {
      scoreColor = const Color(0xFF00AAA8);
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
              Icon(Icons.verified, color: scoreColor, size: 18),
              const SizedBox(width: 6),
              const Text(
                'AI Trust Score',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
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
                valueColor: const AlwaysStoppedAnimation(Color(0xFF00AAA8)),
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
