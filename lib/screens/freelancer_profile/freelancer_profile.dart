import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../widgets/education_profile.dart';
import '../../widgets/experience_profile.dart';
import '../../widgets/edit_profile_form.dart';
import '../../widgets/add_skill.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/api_service.dart';
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

  final List<Map<String, dynamic>> _reviews = [
    {
      'name': 'Ais Vadelia',
      'username': '@aisvadelia',
      'rating': 5,
      'title': 'Design logo for brand new company',
      'body': 'Absolutely good work Dennis! Keep your great work for all clients',
      'time': '1 month ago',
    },
    {
      'name': 'Hansen Nugraha',
      'username': '@hansen',
      'rating': 5,
      'title': 'Design logo for brand new company',
      'body': 'Absolutely good work Dennis! Keep your great work for all clients',
      'time': '1 month ago',
    },
  ];
  List<Map<String, dynamic>> educations = [];
  List<Map<String, dynamic>> experiences = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEducations();
    _loadSkills();
    _loadExperiences();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = Provider.of<ProfileProvider>(context, listen: false);
      setState(() {
        aboutText = profile.bio ?? '';
        uploadedCVPath = profile.freelancerProfile?.cvFileUrl;
      });
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

  Future<void> _loadSkills() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final profile = Provider.of<ProfileProvider>(context, listen: false);

    if (auth.token != null && profile.freelancerProfile?.freelancerId != null) {
      final skillsData = await ApiService.getFreelancerSkills(
        auth.token!,
        profile.freelancerProfile!.freelancerId,
      );

      print('DEBUG _loadSkills response: $skillsData');

      setState(() {
        skills = skillsData.map((skill) => {
          "freelancer_skill_id": skill["freelancer_skill_id"],
          "skill_name": skill["skill_name"] ?? "Unknown Skill",
          "proficiency_level": skill["proficiency_level"] ?? "beginner",
        }).toList();
      });
      
      print('DEBUG skills mapped: $skills');
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
        experiences = experiencesData.map((exp) => {
          "work_experience_id": exp["work_experience_id"],
          "title": exp["job_title"],
          "company": exp["company_name"],
          "location": exp["location"],
          "description": exp["description"],
          "startDate": exp["start_date"] != null ? DateTime.parse(exp["start_date"]) : null,
          "endDate": exp["end_date"] != null ? DateTime.parse(exp["end_date"]) : null,
          "isPresent": exp["is_current"] ?? false,
        }).toList();
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
        educations = educationsData.map((edu) => {
          "education_id": edu["education_id"],
          "school": edu["institution_name"],
          "degree": edu["degree"],
          "field": edu["field_of_study"],
          "grade": edu["grade"],
          "description": edu["description"],
          "startDate": edu["start_date"] != null ? DateTime.parse(edu["start_date"]) : null,
          "endDate": edu["end_date"] != null ? DateTime.parse(edu["end_date"]) : null,
          "isCurrent": edu["is_current"] ?? false,
        }).toList();
      });
    }
  }

  Future<void> _deleteSkill(String freelancerSkillId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final success = await ApiService.deleteFreelancerSkill(auth.token!, freelancerSkillId);

    if (success) {
      setState(() {
        skills.removeWhere((skill) => skill["freelancer_skill_id"] == freelancerSkillId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Skill deleted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete skill')),
      );
    }
  }

  @override
  void dispose() {
    aboutController.dispose();
    _tabController.dispose();
    super.dispose();
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
        
          final fields = {
            "full_name": data['name'],
            "profile_picture_url": data['imageUrl'] ?? data['image'], 
          };
          final success = await profile.updateProfile(
            token: auth.token!,
            identifier: auth.currentUser!.userId,
            fields: fields,
          );
          if (success) {
            profile.updateProfilePictureUrl(data['image']);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(profile.error ?? 'Failed to update profile')),
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
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newBio = aboutController.text;
              setState(() => aboutText = newBio);
              Navigator.pop(context);

              final auth = Provider.of<AuthProvider>(context, listen: false);
              final profile = Provider.of<ProfileProvider>(context, listen: false);
              final success = await profile.updateProfile(
                token: auth.token!,
                identifier: auth.currentUser!.userId,
                fields: {"bio": newBio},
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success
                      ? 'About saved successfully'
                      : profile.error ?? 'Failed to save About'),
                ),
              );
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
      final success = await profile.updateProfile(
        token: auth.token!,
        identifier: auth.currentUser!.userId,
        fields: {"cv_file_url": fileName},
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

  String _getCvDisplayName(String? path) {
    if (path == null || path.isEmpty) return '';
    final parts = path.split(RegExp(r'[\\/]+'));
    return parts.isNotEmpty ? parts.last : path;
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
                children: [
                  _buildAboutTab(),
                  _buildReviewsTab(),
                ],
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
                      icon: const Icon(Icons.bookmark_border, color: Colors.white),
                      onPressed: () {},
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
                          child: profileImage == null || (!profileImage.startsWith('http') && !File(profileImage).existsSync())
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

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (_) => const Icon(Icons.star, color: Colors.amber, size: 18),
            ),
          ),
          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Consumer2<AuthProvider, ProfileProvider>(
                builder: (context, auth, profile, child) {
                  return Column(
                    children: [
                      Text(profile.displayName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text(auth.currentUser?.email ?? '', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      SizedBox(height: 2),
                      Text(profile.jobTitle, style: TextStyle(color: Colors.grey, fontSize: 13)),
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
                          borderRadius: BorderRadius.circular(8)),
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
                          borderRadius: BorderRadius.circular(8)),
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
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
        final bioText = aboutText.isNotEmpty ? aboutText : (profile.bio ?? '');
        final cvPath = !_cvRemoved ? (uploadedCVPath ?? profile.freelancerProfile?.cvFileUrl) : null;
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
                        color: bioText.isEmpty ? Colors.grey : Colors.black87),
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
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        )
                      else
                        Row(
                          children: [
                            const Icon(Icons.description, color: primaryColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(cvDisplayName,
                                  style: const TextStyle(fontSize: 14)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.grey),
                              onPressed: () => setState(() {
                                uploadedCVPath = null;
                                _cvRemoved = true;
                              }),
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
                children: skills.map((s) => _SkillChip(
                  label: s['skill_name'],
                  proficiency: s['proficiency_level'],
                  onDelete: () => _deleteSkill(s['freelancer_skill_id']),
                )).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),

          _buildSection(
            title: 'Experiences',
            actionButton: _buildAddButton('Add Experiences', _showExperienceForm),
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
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          _buildSection(
            title: 'Education',
            actionButton: _buildAddButton('Add Education', _showEducationForm),
            child: Column(
              children: educations.map((e) {
                String endYear = e['isCurrent'] == true ? 'Present' : (e['endDate']?.year.toString() ?? '');
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
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16, bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: '4.5',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          TextSpan(
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
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < 4 ? Icons.star : Icons.star_half,
                          color: Colors.amber,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('25 reviews',
                        style: TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),

                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: [5, 4, 3, 2, 1].map((star) {
                      const Map<int, double> fractions = {
                        5: 0.75,
                        4: 0.55,
                        3: 0.30,
                        2: 0.10,
                        1: 0.05,
                      };
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 13),
                            const SizedBox(width: 4),
                            Text('$star',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: fractions[star]!,
                                  minHeight: 7,
                                  backgroundColor: Colors.grey[200],
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Colors.amber),
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Reviews',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Row(
                  children: const [
                    Text('Latest',
                        style:
                            TextStyle(color: Colors.grey, fontSize: 13)),
                    SizedBox(width: 4),
                    Icon(Icons.filter_list, color: Colors.grey, size: 18),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          ..._reviews.map((r) => _buildReviewCard(r)).toList(),

          const SizedBox(height: 4),
          Center(
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: Colors.grey, size: 18),
              label: const Text('Load more',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> r) {
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
                backgroundColor: Colors.grey[200],
                child: Text(
                  (r['name'] as String)[0],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r['name'],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(r['username'],
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 3),
                  Text('${r['rating']}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(r['title'],
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),

          Text(r['body'],
              style:
                  const TextStyle(color: Colors.black87, fontSize: 13)),
          const SizedBox(height: 8),

          Text(r['time'],
              style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
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
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    if (hasEdit) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onEdit,
                        child: const Icon(Icons.edit,
                            size: 18, color: primaryColor),
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

  const _ExperienceItem({
    required this.logo,
    required this.title,
    required this.company,
    required this.period,
    required this.logoColor,
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
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(company,
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(period,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
                    fontSize: 10),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(degree,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(school,
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(period,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
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