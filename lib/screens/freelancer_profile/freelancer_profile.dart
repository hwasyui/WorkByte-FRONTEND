import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../widgets/education_profile.dart';
import '../../widgets/experience_profile.dart';
import '../../widgets/edit_profile_form.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  String name = "Dennis Wang";
  String username = "@denniswang";
  String job = "UI/UX Designer";
  String aboutText= '';
  String? profileImage;
  String? uploadedCVPath;
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
  }

  @override
  void dispose() {
    aboutController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  void _showEditProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => EditProfileForm(
        initialData: {
          "name": name,
          "username": username,
          "job": job,
          "image": profileImage,
        },
        onSave: (data) {
          setState(() {
            name = data['name'];
            username = data['username'];
            job = data['job'];
            profileImage = data['image'];
          });
        },
      ),
    );
  }

  void _showEducationForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => EducationProfile(
        onSave: (data) {
          setState(() {
            educations.add(data);
          });
        },
      ),
    );
  }

  void _showExperienceForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ExperienceProfile(
        onSave: (data) {
          setState(() {
            experiences.add(data);
          });
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
            onPressed: () {
              setState(() => aboutText = aboutController.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadCV() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (result != null) {
      setState(() => uploadedCVPath = result.files.single.name);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CV uploaded: ${result.files.single.name}')),
      );
    }
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
                    child: CircleAvatar(
                      radius: 44,
                      backgroundImage: profileImage != null
                        ? (profileImage!.startsWith('http')
                            ? NetworkImage(profileImage!)
                            : FileImage(File(profileImage!)) as ImageProvider)
                        : const NetworkImage('https://via.placeholder.com/150'),
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
              Text(name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(width: 4),
              Icon(Icons.verified, color: primaryColor, size: 18),
            ],
          ),
          SizedBox(height: 2),
          Text(username, style: TextStyle(color: Colors.grey, fontSize: 13)),
          SizedBox(height: 2),
          Text(job, style: TextStyle(color: Colors.grey, fontSize: 13)),
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
                    onPressed: () {},
                    icon: const Icon(Icons.share, size: 16),
                    label: const Text('Share Profile'),
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
                aboutText.isEmpty ? 'No information added yet' : aboutText,
                style: TextStyle(
                    color: aboutText.isEmpty ? Colors.grey : Colors.black87),
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
                  if (uploadedCVPath == null)
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
                          child: Text(uploadedCVPath!,
                              style: const TextStyle(fontSize: 14)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () =>
                              setState(() => uploadedCVPath = null),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.analytics_outlined, size: 18),
                      label: const Text('Analyze CV'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          _buildSection(
            title: 'Skills',
            actionButton: _buildAddButton('Add Skill', () {}),
            child: const SizedBox(height: 16),
          ),
          const SizedBox(height: 16),

          _buildSection(
            title: 'Experiences',
            actionButton: _buildAddButton('Add Experiences', _showExperienceForm),
            child: Column(
              children: experiences.map((e) {
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
                return _EducationItem(
                  degree: e['degree'],
                  school: e['school'],
                  period:
                      "${e['startDate']?.year ?? ''} - ${e['endDate']?.year ?? ''}",
                  color: primaryColor,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          _buildSection(
            title: 'Portfolio',
            actionButton: _buildAddButton('Add Portfolio', () {}),
            child: const SizedBox(height: 16),
          ),
        ],
      ),
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

class _SkillChip extends StatelessWidget {
  final String label;
  const _SkillChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: const Color(0xFF00AAA8),
      labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  const _EducationItem({
    required this.degree,
    required this.school,
    required this.period,
    required this.color,
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
        ],
      ),
    );
  }
}