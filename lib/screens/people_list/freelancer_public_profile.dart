import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/colors.dart';
import '../../models/education_model.dart';
import '../../models/experience_model.dart';
import '../../models/review_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/review_provider.dart';

class FreelancerPublicProfileScreen extends StatefulWidget {
  final String freelancerId;

  const FreelancerPublicProfileScreen({Key? key, required this.freelancerId})
    : super(key: key);

  @override
  State<FreelancerPublicProfileScreen> createState() =>
      _FreelancerPublicProfileScreenState();
}

class _FreelancerPublicProfileScreenState
    extends State<FreelancerPublicProfileScreen>
    with SingleTickerProviderStateMixin {
  static const Color primaryColor = AppColors.primary;

  late TabController _tabController;
  String aboutText = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadProfile();
      await _loadReviews();
    });
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final profile = Provider.of<ProfileProvider>(context, listen: false);

    if (auth.token == null) return;

    final success = await profile.fetchProfile(
      token: auth.token!,
      userId: widget.freelancerId,
      userType: 'freelancer',
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        aboutText = profile.bio ?? '';
      });
    }
  }

  Future<void> _loadReviews() async {
    if (!mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);

    if (auth.token != null) {
      await Future.wait([
        reviewProvider.loadFreelancerReviews(
          token: auth.token!,
          freelancerId: widget.freelancerId,
        ),
        reviewProvider.loadTrustScore(
          token: auth.token!,
          freelancerId: widget.freelancerId,
        ),
      ]);
    }
  }

  Future<void> _previewCV(String? cvUrl) async {
    if (cvUrl == null || cvUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No CV available to preview')),
      );
      return;
    }

    final uri = Uri.tryParse(cvUrl);
    if (uri == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid CV URL')));
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open CV preview')),
      );
    }
  }

  String _getCvDisplayName(String? path) {
    if (path == null || path.isEmpty) return '';
    final parts = path.split(RegExp(r'[\\/]+'));
    return parts.isNotEmpty ? parts.last : path;
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

  void _onMessageTap() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Open message flow here')));
  }

  void _onInviteToJobTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Open invite to job flow here')),
    );
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
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                  _buildPortfolioTab(),
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
                      Positioned(top: 16, right: 16, child: _buildDotGrid()),
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
                                    as ImageProvider?
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
                    onPressed: _onMessageTap,
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: const Text('Message'),
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
                    onPressed: _onInviteToJobTap,
                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                    label: const Text('Invite to Job'),
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
                Tab(text: 'Portfolio'),
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
        final cvPath = profile.freelancerProfile?.cvFileUrl;
        final cvDisplayName = _getCvDisplayName(cvPath);

        final skills = profile.skills;
        final List<ExperienceModel> experiences = profile.experiences;
        final List<EducationModel> educations = profile.educations;

        return SingleChildScrollView(
          padding: const EdgeInsets.only(top: 16, bottom: 32),
          child: Column(
            children: [
              _buildSection(
                title: 'About',
                icon: Icons.person_outline,
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
                            'CV',
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
                          ] else ...[
                            const SizedBox(height: 3),
                            const Text(
                              'No CV uploaded',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (cvPath != null)
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
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: 'Skills',
                icon: Icons.star_outline,
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
                            );
                          }).toList(),
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: 'Experiences',
                icon: Icons.work_outline,
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
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: 'Education',
                icon: Icons.school_outlined,
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

  Widget _buildPortfolioTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.work_outline, size: 52, color: Colors.grey[300]),
            const SizedBox(height: 14),
            Text(
              'No portfolio yet',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Portfolio items will appear here.',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      ),
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

  Widget _buildSection({
    required String title,
    required Widget child,
    IconData? icon,
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
              ],
            ),
          ),
          child,
        ],
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
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;
  final String proficiency;

  const _SkillChip({required this.label, required this.proficiency});

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label (${_toTitleCase(proficiency)})',
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
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
              const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
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
