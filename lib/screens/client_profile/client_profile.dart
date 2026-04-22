import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/api_service.dart';
import '../../screens/auth/login.dart';
import '../../widgets/job_list_card.dart';
import '../../widgets/edit_profile_form.dart';
import '../../models/job_post_model.dart';
import 'dart:io';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({Key? key}) : super(key: key);

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen>
    with SingleTickerProviderStateMixin {
  String bioText = '';
  String websiteUrl = '';
  List<JobPostModel> postedJobs = [];
  bool _isLoading = false;
  late TabController _tabController;

  static const Color primaryColor = AppColors.primary;

  final TextEditingController bioController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    bioController.addListener(() {
      setState(() => bioText = bioController.text);
    });
    websiteController.addListener(() {
      setState(() => websiteUrl = websiteController.text);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = Provider.of<ProfileProvider>(context, listen: false);
      setState(() {
        bioText = profile.clientProfile?.bio ?? '';
        websiteUrl = profile.clientProfile?.websiteUrl ?? '';
        bioController.text = bioText;
        websiteController.text = websiteUrl;
      });
      _loadPostedJobs();
    });
  }

  Future<void> _loadPostedJobs() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final profile = Provider.of<ProfileProvider>(context, listen: false);

    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final jobsList = await ApiService.getClientPostedJobs(
        auth.token!,
        profile.clientProfile!.clientId,
      );

      if (mounted) {
        setState(() {
          postedJobs = jobsList.map((job) => JobPostModel.fromJson(job)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load jobs: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _refreshProfile() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final profile = Provider.of<ProfileProvider>(context, listen: false);
    final userType = profile.userType ?? 'client';

    final identifier = profile.clientProfile?.clientId ?? auth.currentUser!.userId;
    if (auth.token != null) {
      await profile.fetchProfile(
        token: auth.token!,
        userId: identifier,
        userType: userType,
      );
      if (mounted) {
        setState(() {
          bioText = profile.clientProfile?.bio ?? '';
          websiteUrl = profile.clientProfile?.websiteUrl ?? '';
          bioController.text = bioText;
          websiteController.text = websiteUrl;
        });
      }
    }
  }

  void _editAbout() {
    bioController.text = bioText;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit About'),
        content: TextField(
          controller: bioController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Tell us about your company...',
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
              final newBio = bioController.text;
              final bioValue = newBio.trim().isEmpty ? null : newBio;
              setState(() => bioText = newBio);

              final auth = Provider.of<AuthProvider>(context, listen: false);
              final profile = Provider.of<ProfileProvider>(context, listen: false);
              final messenger = ScaffoldMessenger.of(context);
              final identifier = profile.clientProfile?.clientId ?? auth.currentUser!.userId;

              Navigator.pop(dialogContext);

              final success = await profile.updateProfile(
                token: auth.token!,
                identifier: identifier,
                fields: {'bio': bioValue},
              );
              if (success) await _refreshProfile();
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'About saved successfully'
                        : profile.error ?? 'Failed to save About'),
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

  void _editWebsite() {
    websiteController.text = websiteUrl;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Website'),
        content: TextField(
          controller: websiteController,
          decoration: const InputDecoration(
            hintText: 'https://example.com',
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
              final newUrl = websiteController.text;
              final urlValue = newUrl.trim().isEmpty ? null : newUrl;
              setState(() => websiteUrl = newUrl);

              final auth = Provider.of<AuthProvider>(context, listen: false);
              final profile = Provider.of<ProfileProvider>(context, listen: false);
              final messenger = ScaffoldMessenger.of(context);
              final identifier = profile.clientProfile?.clientId ?? auth.currentUser!.userId;

              Navigator.pop(dialogContext);

              final success = await profile.updateProfile(
                token: auth.token!,
                identifier: identifier,
                fields: {'website_url': urlValue},
              );
              if (success) await _refreshProfile();
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Website saved successfully'
                        : profile.error ?? 'Failed to save Website'),
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

  void _showEditProfile() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final profile = Provider.of<ProfileProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => EditProfileForm(
        initialData: {
          "name": profile.clientProfile?.fullName,
          "username": auth.currentUser?.email ?? '',
          "image": profile.profilePictureUrl,
        },
        onSave: (data) async {
          final fields = <String, dynamic>{"full_name": data['name']};

          if (data['imageDeleted'] == true) {
            fields['profile_picture_url'] = null;
          } else if (data['image'] != null &&
              data['image'].toString().isNotEmpty &&
              data['image'] != profile.profilePictureUrl) {
            if (!data['image'].toString().startsWith('http')) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Uploading profile picture...')),
                );
              }

              final identifier = profile.clientProfile?.clientId ?? auth.currentUser!.userId;
              final uploadResult = await ApiService.uploadClientProfilePicture(
                auth.token!,
                identifier,
                data['image'],
              );

              if (uploadResult != null) {
                final uploadedUrl = uploadResult['profile_picture_url'] as String?;
                if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
                  await _refreshProfile();
                  profile.forceRefreshProfilePicture();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile picture updated successfully')),
                    );
                    Navigator.pop(context);
                  }
                  return;
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to upload profile picture')),
                  );
                }
                return;
              }
            } else {
              fields['profile_picture_url'] = data['image'];
            }
          }

          final identifier = profile.clientProfile?.clientId ?? auth.currentUser!.userId;
          final success = await profile.updateProfile(
            token: auth.token!,
            identifier: identifier,
            fields: fields,
          );

          if (success) {
            if (data['imageDeleted'] == true) {
              profile.clearProfilePicture();
            } else {
              final updatedUrl = profile.profilePictureUrl;
              if (updatedUrl != null && updatedUrl.isNotEmpty) {
                profile.updateProfilePictureUrl(updatedUrl);
              }
            }

            await _refreshProfile();
            profile.forceRefreshProfilePicture();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated successfully')),
              );
              Navigator.pop(context);
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(profile.error ?? 'Failed to update profile')),
              );
            }
          }
        },
      ),
    );
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
              final profile = Provider.of<ProfileProvider>(context, listen: false);

              auth.logout(profileProvider: profile);

              if (mounted) {
                Navigator.pop(context);
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

  @override
  void dispose() {
    bioController.dispose();
    websiteController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<ProfileProvider>(
        builder: (context, profile, child) {
          if (!profile.isClient || profile.clientProfile == null) {
            return const Center(child: Text('Client profile not available'));
          }

          return SafeArea(
            child: Column(
              children: [
                _buildStickyHeader(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAboutTab(profile),
                      _buildPostedJobsTab(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
              // ── Banner ─────────────────────────────────────────────────
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
                      Positioned(
                        top: 16,
                        right: 56,
                        child: _buildDotGrid(),
                      ),
                    ],
                  ),
                ),
              ),
              // ── Nav buttons ────────────────────────────────────────────
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
                      icon: const Icon(Icons.share, color: Colors.white),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: () => _showLogoutDialog(context),
                    ),
                  ],
                ),
              ),
              // ── Profile avatar ─────────────────────────────────────────
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
            child: _buildStarRating(
              rating: Provider.of<ProfileProvider>(context, listen: false)
                      .clientProfile
                      ?.averageRatingGiven ??
                  0.0,
              size: 18,
            ),
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
                Tab(text: 'Posted Jobs'),
              ],
            ),
          ),
        ],
      ),
    );
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
        }
        return Icon(Icons.star_outline, color: Colors.grey[400], size: size);
      }),
    );
  }

  Widget _buildAboutTab(ProfileProvider profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16, bottom: 32),
      child: Column(
        children: [
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
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          _buildSection(
            title: 'Website',
            icon: Icons.language_outlined,
            hasEdit: true,
            onEdit: _editWebsite,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                websiteUrl.isEmpty ? 'No website added' : websiteUrl,
                style: TextStyle(
                  color: websiteUrl.isEmpty ? Colors.grey : primaryColor,
                  fontSize: 14,
                  decoration: websiteUrl.isNotEmpty ? TextDecoration.underline : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 16),

          _buildSection(
            title: 'Statistics',
            icon: Icons.bar_chart_outlined,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    label: 'Jobs Posted',
                    value: '${profile.clientProfile?.totalJobsPosted ?? 0}',
                  ),
                  _buildStatItem(
                    label: 'Completed',
                    value: '${profile.clientProfile?.totalProjectsCompleted ?? 0}',
                  ),
                  if (profile.clientProfile?.averageRatingGiven != null)
                    _buildStatItem(
                      label: 'Rating',
                      value: profile.clientProfile!.averageRatingGiven!.toStringAsFixed(1),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({required String label, required String value}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildPostedJobsTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
        ),
      );
    }

    if (postedJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No jobs posted yet',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start posting jobs to find freelancers',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          ...postedJobs.asMap().entries.map((entry) {
            final job = entry.value;
            return Column(
              children: [
                JobListCard(
                  posterLogo: Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.business,
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                  posterName: 'Your Job',
                  title: job.jobTitle,
                  category: job.projectType.toUpperCase(),
                  teamSize: 1,
                  salaryTag: job.projectScope.toUpperCase(),
                  typeTag: job.projectType == 'team' ? 'Team' : 'Individual',
                  bidderAvatars: const [],
                  biddingsLabel:
                      '${job.proposalCount} proposal${job.proposalCount != 1 ? 's' : ''}',
                  onTap: () {},
                  bookmarked: false,
                ),
                const SizedBox(height: 12),
              ],
            );
          }).toList(),
        ],
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
