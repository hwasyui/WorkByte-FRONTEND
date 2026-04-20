import 'package:flutter/material.dart';
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

  static const Color primaryColor = Color(0xFF00AAA8);

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
          postedJobs = jobsList
              .map((job) => JobPostModel.fromJson(job))
              .toList();
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
    if (auth.token != null && identifier != null) {
      final refreshSuccess = await profile.fetchProfile(
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
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newBio = bioController.text;
              final bioValue = newBio.trim().isEmpty ? null : newBio;
              setState(() => bioText = newBio);
              Navigator.pop(context);

              final auth = Provider.of<AuthProvider>(context, listen: false);
              final profile = Provider.of<ProfileProvider>(context, listen: false);
              final identifier = profile.clientProfile?.clientId ?? auth.currentUser!.userId;
              final updateFields = {"bio": bioValue};
              final success = await profile.updateProfile(
                token: auth.token!,
                identifier: identifier,
                fields: updateFields,
              );
              if (success) {
                await _refreshProfile();
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
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
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUrl = websiteController.text;
              final urlValue = newUrl.trim().isEmpty ? null : newUrl;
              setState(() => websiteUrl = newUrl);
              Navigator.pop(context);

              final auth = Provider.of<AuthProvider>(context, listen: false);
              final profile = Provider.of<ProfileProvider>(context, listen: false);
              final identifier = profile.clientProfile?.clientId ?? auth.currentUser!.userId;
              final updateFields = {"website_url": urlValue};
              final success = await profile.updateProfile(
                token: auth.token!,
                identifier: identifier,
                fields: updateFields,
              );
              if (success) {
                await _refreshProfile();
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
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
          final fields = {
            "full_name": data['name'],
          };

          final identifier = profile.clientProfile?.clientId ?? auth.currentUser!.userId;
          final selectedImage = data['image'] as String?;

          if (data['imageDeleted'] == true) {
            // Delete profile picture from both Supabase and database
            final deleteSuccess = await ApiService.deleteProfilePicture(
              token: auth.token!,
              userType: 'client',
              identifier: identifier,
            );
            
            if (!deleteSuccess) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to delete profile photo. Please try again.'),
                  ),
                );
              }
              return;
            }
            
            fields['profile_picture_url'] = '';
          } else if (selectedImage != null && selectedImage.isNotEmpty &&
              selectedImage != profile.profilePictureUrl) {
            if (!selectedImage.startsWith('http') && File(selectedImage).existsSync()) {
              final uploadedUrl = await ApiService.uploadProfilePicture(
                token: auth.token!,
                userType: 'client',
                identifier: identifier,
                filePath: selectedImage,
              );

              if (uploadedUrl == null) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to upload profile photo. Please try again.'),
                    ),
                  );
                }
                return;
              }

              fields['profile_picture_url'] = uploadedUrl;
            } else if (selectedImage.startsWith('http')) {
              fields['profile_picture_url'] = selectedImage;
            }
          }

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

  @override
  void dispose() {
    bioController.dispose();
    websiteController.dispose();
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Consumer<ProfileProvider>(
        builder: (context, profile, child) {
          if (!profile.isClient || profile.clientProfile == null) {
            return const Center(
              child: Text('Client profile not available'),
            );
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
                          child: profileImage == null ||
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
            child: _buildStarRating(
              rating: Provider.of<ProfileProvider>(context, listen: false)
                      .clientProfile
                      ?.averageRatingGiven ??
                  0.0,
              size: 18,
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
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile.jobTitle,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

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
            hasEdit: true,
            onEdit: _editAbout,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                bioText.isEmpty ? 'No information added yet' : bioText,
                style: TextStyle(
                    color: bioText.isEmpty ? Colors.grey : Colors.black87,
                    fontSize: 14,
                    height: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Website',
            hasEdit: true,
            onEdit: _editWebsite,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                websiteUrl.isEmpty ? 'No website added' : websiteUrl,
                style: TextStyle(
                  color: websiteUrl.isEmpty ? Colors.grey : primaryColor,
                  fontSize: 14,
                  decoration: websiteUrl.isNotEmpty
                      ? TextDecoration.underline
                      : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Statistics',
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '${profile.clientProfile?.totalJobsPosted ?? 0}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Jobs Posted',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '${profile.clientProfile?.totalProjectsCompleted ?? 0}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Completed',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  if (profile.clientProfile?.averageRatingGiven != null)
                    Column(
                      children: [
                        Text(
                          '${profile.clientProfile?.averageRatingGiven?.toStringAsFixed(1) ?? '-'}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Rating',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
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
            Icon(
              Icons.work_outline,
              size: 64,
              color: Colors.grey[300],
            ),
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
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
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
                  typeTag: job.projectType == 'team'
                      ? 'Team'
                      : 'Individual',
                  bidderAvatars: const [],
                  biddingsLabel:
                      '${job.proposalCount} proposal${job.proposalCount != 1 ? 's' : ''}',
                  onTap: () {
                  },
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
                    if (hasEdit) ...[const SizedBox(width: 8),
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
}
