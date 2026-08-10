import 'package:workbyte_app/widgets/appeal_dialog.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:workbyte_app/services/deep_link_service.dart';
import '../../core/constants/colors.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/client_review_provider.dart';
import '../../screens/auth/login.dart';
import '../../widgets/edit_profile_form.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/pinned_tab_bar_delegate.dart';
import '../../widgets/review_card.dart' show SentimentBadge;
import '../../widgets/trust_score_card.dart';
import '../../widgets/review_rating_helpers.dart';
import '../people_list/people_list_screen.dart' show PeopleProfileScreen;
import 'dart:io';

/// Height of the fixed back/share/saved row that sits above the scrolling body.
const double _kActionBarHeight = 48;

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({Key? key}) : super(key: key);

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen>
    with SingleTickerProviderStateMixin {
  String bioText = '';
  String websiteUrl = '';
  late TabController _tabController;

  static const Color primaryColor = AppColors.primary;

  final TextEditingController bioController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();
  final Map<String, String> _reviewerNameCache = {};
  final Map<String, String?> _reviewerAvatarCache = {};

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final profile = Provider.of<ProfileProvider>(context, listen: false);

      if (profile.clientProfile == null && auth.token != null) {
        final userId = auth.currentUser?.userId;
        if (userId != null) {
          await profile.fetchProfile(
            token: auth.token!,
            userId: userId,
            userType: 'client',
          );
        }
      }

      if (!mounted) return;
      setState(() {
        bioText = profile.clientProfile?.bio ?? '';
        websiteUrl = profile.clientProfile?.websiteUrl ?? '';
        bioController.text = bioText;
        websiteController.text = websiteUrl;
      });
      _loadReviews();
    });
  }

  Future<void> _loadReviews() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final profile = Provider.of<ProfileProvider>(context, listen: false);
    final clientReviewProvider = Provider.of<ClientReviewProvider>(
      context,
      listen: false,
    );

    final clientId = profile.clientProfile?.clientId;
    if (auth.token != null && clientId != null) {
      await Future.wait([
        clientReviewProvider.loadClientReviews(
          token: auth.token!,
          clientId: clientId,
        ),
        clientReviewProvider.loadTrustScore(
          token: auth.token!,
          clientId: clientId,
        ),
      ]);
      await _loadReviewerNames(auth.token!, clientReviewProvider.reviews);
    }
  }

  Future<void> _loadReviewerNames(String token, List reviews) async {
    final profile = Provider.of<ProfileProvider>(context, listen: false);
    final ids = reviews
        .map((r) => r.reviewerId as String)
        .toSet()
        .where((id) => id.isNotEmpty && !_reviewerNameCache.containsKey(id))
        .toList();
    if (ids.isEmpty) return;

    final results = await Future.wait(
      ids.map(
        (id) => profile.fetchFreelancerById(token: token, freelancerId: id),
      ),
    );
    for (int i = 0; i < ids.length; i++) {
      final f = results[i];
      if (f != null) {
        _reviewerNameCache[ids[i]] = f.displayName;
        _reviewerAvatarCache[ids[i]] = f.profilePictureUrl;
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _refreshProfile() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final profile = Provider.of<ProfileProvider>(context, listen: false);
    final userType = profile.userType ?? 'client';

    final identifier =
        profile.clientProfile?.clientId ?? auth.currentUser!.userId;
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
                  Expanded(
                    child: Text(
                      'Edit About',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A2E),
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
              Text(
                'Tell us about your company',
                style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF6B7280)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bioController,
                maxLines: 7,
                style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1A1A2E)),
                decoration: InputDecoration(
                  hintText: 'Tell us about your company...',
                  hintStyle: GoogleFonts.poppins(
                    color: const Color(0xFF9CA3AF),
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
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF4F46E5),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final newBio = bioController.text;
                        final bioValue = newBio.trim().isEmpty ? null : newBio;
                        setState(() => bioText = newBio);

                        final auth = Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        );
                        final profile = Provider.of<ProfileProvider>(
                          context,
                          listen: false,
                        );
                        final identifier =
                            profile.clientProfile?.clientId ??
                            auth.currentUser!.userId;

                        Navigator.pop(dialogContext);

                        final success = await profile.updateProfile(
                          token: auth.token!,
                          identifier: identifier,
                          fields: {'bio': bioValue},
                        );
                        if (success) await _refreshProfile();
                        if (mounted) {
                          if (success) {
                            AppToast.success('About saved successfully');
                          } else {
                            AppToast.error(
                              profile.error ?? 'Failed to save About',
                            );
                          }
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
                      child: Text(
                        'Save',
                        style: GoogleFonts.poppins(
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

  void _editWebsite() {
    websiteController.text = websiteUrl;
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
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0E7FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.language_rounded,
                      color: Color(0xFF4F46E5),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Website',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Update your portfolio or website link.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(dialogContext),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE0E7FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Color(0xFF4F46E5),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Website Address',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (context, setLocal) => TextField(
                  controller: websiteController,
                  keyboardType: TextInputType.url,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF1A1A2E),
                  ),
                  onChanged: (_) => setLocal(() {}),
                  decoration: InputDecoration(
                    hintText: 'https://yourwebsite.com',
                    hintStyle: GoogleFonts.poppins(
                      color: const Color(0xFF9CA3AF),
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.language_rounded,
                      color: Color(0xFF4F46E5),
                      size: 20,
                    ),
                    suffixIcon: websiteController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              websiteController.clear();
                              setLocal(() {});
                            },
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE0E7FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Color(0xFF4F46E5),
                                size: 14,
                              ),
                            ),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFEEF0FF),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
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
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Enter a valid website URL (e.g., https://yourwebsite.com)',
                      style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF9CA3AF)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(height: 1, color: const Color(0xFFE5E7EB)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFF4F46E5),
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF4F46E5),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final newUrl = websiteController.text;
                          final urlValue = newUrl.trim().isEmpty
                              ? null
                              : newUrl;
                          setState(() => websiteUrl = newUrl);

                          final auth = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          );
                          final profile = Provider.of<ProfileProvider>(
                            context,
                            listen: false,
                          );
                          final identifier =
                              profile.clientProfile?.clientId ??
                              auth.currentUser!.userId;

                          Navigator.pop(dialogContext);

                          final success = await profile.updateProfile(
                            token: auth.token!,
                            identifier: identifier,
                            fields: {'website_url': urlValue},
                          );
                          if (success) await _refreshProfile();
                          if (mounted) {
                            if (success) {
                              AppToast.success('Website saved successfully');
                            } else {
                              AppToast.error(
                                profile.error ?? 'Failed to save Website',
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: Text(
                          'Save',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
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

  void _showEditProfile() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final profile = Provider.of<ProfileProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => EditProfileForm(
        showJobTitle: false,
        initialData: {
          "name": profile.clientProfile?.fullName,
          "username": auth.currentUser?.email ?? '',
          "image": profile.profilePictureUrl,
        },
        onSave: (data) async {
          final identifier =
              profile.clientProfile?.clientId ?? auth.currentUser!.userId;

          if (data['image'] != null &&
              data['image'].toString().isNotEmpty &&
              data['image'] != profile.profilePictureUrl &&
              !data['image'].toString().startsWith('http')) {
            if (mounted) {
              AppToast.info('Uploading profile picture...');
            }

            final success = await profile.uploadProfilePicture(
              token: auth.token!,
              identifier: identifier,
              imageFile: File(data['image']),
            );

            if (!success) {
              if (mounted) {
                AppToast.error(
                  profile.error ?? 'Failed to upload profile picture',
                );
              }
              return;
            }
          }
          else if (data['imageDeleted'] == true) {
            final success = await profile.deleteProfilePicture(
              token: auth.token!,
              identifier: identifier,
            );

            if (!success && mounted) {
              AppToast.error(
                profile.error ?? 'Failed to delete profile picture',
              );
              return;
            }
          }

          final fields = <String, dynamic>{
            if (data['name'] != null) 'full_name': data['name'],
          };

          if (fields.isNotEmpty) {
            final success = await profile.updateProfile(
              token: auth.token!,
              identifier: identifier,
              fields: fields,
            );

            if (!success && mounted) {
              AppToast.error(profile.error ?? 'Failed to update profile');
              return;
            }
          }

          await _refreshProfile();
          profile.forceRefreshProfilePicture();

          if (mounted) {
            AppToast.success('Profile updated successfully');
          }
        },
      ),
    );
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
                    Positioned(
                      top: 6,
                      left: 10,
                      child: Text(
                        '✦',
                        style: GoogleFonts.poppins(
                          color: AppColors.primary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 10,
                      child: Text(
                        '✦',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFB8B0F0),
                          fontSize: 10,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Text(
                        '✦',
                        style: GoogleFonts.poppins(
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
          if (!profile.isClient) {
            return const Center(child: Text('Client profile not available'));
          }
          if (profile.clientProfile == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          return SafeArea(
            top: false,
            child: Column(
              children: [
                _buildFixedActionBar(),
                Expanded(
                  child: NestedScrollView(
                    headerSliverBuilder: (context, _) => [
                      SliverToBoxAdapter(child: _buildProfileHeader()),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: PinnedTabBarDelegate(_buildTabBar()),
                      ),
                    ],
                    body: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAboutTab(profile),
                        _buildReviewsTab(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// The only permanently fixed part of the screen: back and share.
  /// Everything below it scrolls away.
  Widget _buildFixedActionBar() {
    return Container(
      color: AppColors.secondary,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: _kActionBarHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  onPressed: () => Navigator.maybePop(context),
                ),
                Row(
                  children: [
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) => IconButton(
                        icon: const Icon(
                          Icons.share_outlined,
                          color: AppColors.primary,
                        ),
                        onPressed: auth.userId == null
                            ? null
                            : () => Share.share(profileShareUrl(auth.userId!)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final auth = context.read<AuthProvider>();

    // The action row is pinned above, so the banner only draws what is left of
    // its original 175px once that row and the status bar are accounted for.
    final bannerHeight =
        (175 - MediaQuery.of(context).padding.top - _kActionBarHeight)
            .clamp(60.0, 175.0);

    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: bannerHeight,
                width: double.infinity,
                color: AppColors.secondary,
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
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
                          onBackgroundImageError: profileImage != null
                              ? (_, _) {}
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

          const SizedBox(height: 56),

          Consumer2<AuthProvider, ProfileProvider>(
            builder: (context, auth, profile, child) {
              return Column(
                children: [
                  Text(
                    profile.displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Client',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    auth.currentUser?.email ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),

          Consumer<ClientReviewProvider>(
            builder: (context, reviewProvider, _) {
              final trustScore = reviewProvider.trustScore;
              final rawRating = trustScore?.displayStarAvg;
              final totalReviews = trustScore?.totalReviewsReceived ?? 0;

              if (rawRating == null || totalReviews == 0) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.withOpacity(0.22)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_border_rounded,
                          size: 15,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'No ratings received yet',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final safeRating = rawRating.clamp(0.0, 5.0);
              return Center(
                child: Tooltip(
                  triggerMode: TooltipTriggerMode.tap,
                  message:
                      'Average rating this client has received from freelancers, based on $totalReviews review${totalReviews == 1 ? '' : 's'}',
                  textStyle: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: Colors.white,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber.withOpacity(0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 15,
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          safeRating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.info_outline_rounded,
                          size: 13,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showEditProfile,
                    icon: const Icon(Icons.edit_rounded, size: 15),
                    label: Text(
                      'Edit Profile',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (auth.isReportBanned) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFEF9A9A).withValues(alpha: 0.7),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFCDD2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.gavel_rounded,
                        color: Color(0xFFC62828),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your account has been restricted',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFB71C1C),
                            ),
                          ),
                          if (auth.banMessage != null &&
                              auth.banMessage!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              auth.banMessage!,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF7D7D7D),
                                height: 1.4,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () =>
                                AppealDialog.show(
                                  context,
                                  targetType: 'user',
                                  targetId: auth.userId!,
                                  targetLabel: 'Account Restriction',
                                  closureNote: auth.banMessage,
                                ).then((_) {
                                  context.read<AuthProvider>().refreshUser();
                                }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC62828),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Submit an Appeal',
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
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  TabBar _buildTabBar() {
    return TabBar(
      controller: _tabController,
      indicatorColor: primaryColor,
      indicatorWeight: 2.5,
      labelColor: primaryColor,
      unselectedLabelColor: Colors.grey[400],
      labelStyle: GoogleFonts.poppins(
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
      unselectedLabelStyle: GoogleFonts.poppins(
        fontWeight: FontWeight.w500,
        fontSize: 13,
      ),
      tabs: const [
        Tab(text: 'About'),
        Tab(text: 'Reviews'),
      ],
    );
  }

  Widget _buildStarRating({required double rating, required double size}) {
    final fullStars = rating.floor();
    final hasHalfStar = rating % 1 != 0;
    final starColor = rating > 0 ? Colors.amber : Colors.grey[300]!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...List.generate(5, (index) {
          if (index < fullStars) {
            return Icon(Icons.star_rounded, color: starColor, size: size);
          } else if (index == fullStars && hasHalfStar) {
            return Icon(Icons.star_half_rounded, color: starColor, size: size);
          }
          return Icon(Icons.star_outline_rounded, color: starColor, size: size);
        }),
        if (rating > 0) ...[
          const SizedBox(width: 5),
          Text(
            rating.toStringAsFixed(1),
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.amber[700],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAboutTab(ProfileProvider profile) {
    return SingleChildScrollView(
      key: const PageStorageKey<String>('about'),
      padding: const EdgeInsets.only(top: 16, bottom: 32),
      child: Column(
        children: [
          _buildSection(
            title: 'About',
            icon: Icons.person_outline,
            hasEdit: bioText.isNotEmpty,
            onEdit: _editAbout,
            child: bioText.isEmpty
                ? _buildEmptyBio(_editAbout)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Text(
                      bioText,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF374151),
                        height: 1.6,
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Text(
                websiteUrl.isEmpty ? 'No website added' : websiteUrl,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: websiteUrl.isEmpty ? Colors.grey[400] : primaryColor,
                  fontWeight: websiteUrl.isNotEmpty
                      ? FontWeight.w500
                      : FontWeight.normal,
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
            icon: Icons.bar_chart_outlined,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    label: 'Jobs Posted',
                    value: '${profile.clientProfile?.totalJobsPosted ?? 0}',
                  ),
                  _buildStatItem(
                    label: 'Completed',
                    value:
                        '${profile.clientProfile?.totalProjectsCompleted ?? 0}',
                  ),
                  if (profile.clientProfile?.averageRatingGiven != null)
                    _buildStatItem(
                      label: 'Rating',
                      value: profile.clientProfile!.averageRatingGiven!
                          .toStringAsFixed(1),
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
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsTab() {
    return Consumer<ClientReviewProvider>(
      builder: (context, reviewProvider, _) {
        final isLoading =
            reviewProvider.reviewsState == ClientReviewLoadState.loading ||
            reviewProvider.trustState == ClientReviewLoadState.loading;

        if (isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          );
        }

        final reviews = reviewProvider.reviews;
        final trustScore = reviewProvider.trustScore;
        final totalReviews = trustScore?.totalReviewsReceived ?? reviews.length;

        if (totalReviews == 0 && reviews.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'No reviews yet',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Freelancers you work with can review you after a contract completes',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: primaryColor,
          onRefresh: _loadReviews,
          child: SingleChildScrollView(
            key: const PageStorageKey<String>('reviews'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (trustScore != null) ...[
                  RatingSummaryCard(
                    averageRating: trustScore.displayStarAvg ?? 0.0,
                    totalReviews: totalReviews,
                    confidence: trustScore.confidence,
                  ),
                  const SizedBox(height: 16),
                  ClientTrustScoreCard(trustScore: trustScore, isOwnProfile: true),
                  const SizedBox(height: 16),
                  SentimentDistributionCard(
                    distribution: trustScore.sentimentDistribution,
                    confidence: trustScore.confidence,
                  ),
                  if (trustScore.sentimentDistribution.total > 0)
                    const SizedBox(height: 16),
                  AiReviewSummaryCard(summary: trustScore.aiReviewSummary),
                  if ((trustScore.aiReviewSummary ?? '').trim().isNotEmpty)
                    const SizedBox(height: 16),
                ],
                if (reviews.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Reviews',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$totalReviews total',
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...reviews.map(_buildOwnReviewCard),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOwnReviewCard(dynamic review) {
    final displayName = review.isAnonymous == true
        ? 'Anonymous Freelancer'
        : (_reviewerNameCache[review.reviewerId as String] ?? 'Freelancer');
    final avatarUrl = review.isAnonymous == true
        ? null
        : _reviewerAvatarCache[review.reviewerId as String];
    final ratings = review.ratings as List;
    final avg = ratings.isEmpty
        ? 0.0
        : ratings.map((r) => r.score as double).reduce((a, b) => a + b) /
              ratings.length;
    final comment = review.writtenContent?.overallComment as String? ?? '';

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
                radius: 18,
                backgroundColor: primaryColor.withOpacity(0.1),
                backgroundImage:
                    (avatarUrl != null && avatarUrl.startsWith('http'))
                    ? NetworkImage(avatarUrl)
                    : null,
                onBackgroundImageError:
                    (avatarUrl != null && avatarUrl.startsWith('http'))
                    ? (_, _) {}
                    : null,
                child: (avatarUrl != null && avatarUrl.startsWith('http'))
                    ? null
                    : const Icon(
                        Icons.person_outline,
                        color: primaryColor,
                        size: 18,
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  displayName,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              StarRow(rating: avg),
            ],
          ),
          if (review.sentiment != null) ...[
            const SizedBox(height: 10),
            SentimentBadge(sentiment: review.sentiment as String?),
          ],
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              comment,
              style: GoogleFonts.poppins(
                color: Colors.black87,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
          if (ratings.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ratings.map<Widget>((rating) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        ratingIcon(rating.category as String),
                        size: 13,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${ratingLabel(rating.category as String)} ${(rating.score as double).toStringAsFixed(1)}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
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
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Tell freelancers about your company and what you are looking for.',
                    style: GoogleFonts.poppins(
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEECFB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (icon != null) ...[
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    if (hasEdit) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onEdit,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEECFB),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            size: 13,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (actionButton != null) actionButton,
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
          child,
        ],
      ),
    );
  }
}
