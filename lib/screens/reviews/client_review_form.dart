import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/client_review_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/client_review_provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../widgets/review_rating_helpers.dart';
import '../../widgets/app_toast.dart';
import 'client_review_submitted.dart';

/// Freelancer-reviews-client form - mirrors review_form.dart's structure for
/// the symmetric counterpart. Shown to a freelancer after contract completion.
class ClientReviewFormScreen extends StatefulWidget {
  final String contractId;
  final String clientName;
  final String projectTitle;

  const ClientReviewFormScreen({
    super.key,
    required this.contractId,
    required this.clientName,
    required this.projectTitle,
  });

  @override
  State<ClientReviewFormScreen> createState() =>
      _ClientReviewFormScreenState();
}

class _ClientReviewFormScreenState extends State<ClientReviewFormScreen> {
  final Map<String, double> _ratings = {
    'communication': 5.0,
    'clarity_of_requirements': 5.0,
    'responsiveness': 5.0,
    'professionalism': 5.0,
  };

  static const Map<String, String> _ratingLabels = {
    'communication': 'Communication',
    'clarity_of_requirements': 'Clarity of Requirements',
    'responsiveness': 'Responsiveness',
    'professionalism': 'Professionalism',
  };

  static const Map<String, IconData> _ratingIcons = {
    'communication': Icons.chat_bubble_outline,
    'clarity_of_requirements': Icons.fact_check_outlined,
    'responsiveness': Icons.bolt_outlined,
    'professionalism': Icons.badge_outlined,
  };

  final TextEditingController _answerController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadForm());
  }

  Future<void> _loadForm() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    await context.read<ClientReviewProvider>().loadReviewForm(
      token: token,
      contractId: widget.contractId,
    );
  }

  Future<void> _submit() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      _showSnack('Please write an overall comment before submitting.');
      return;
    }

    final provider = context.read<ClientReviewProvider>();
    final reviewId = provider.pendingReview?.id;
    if (reviewId == null) {
      _showSnack('Review not ready yet. Please wait a moment.');
      return;
    }

    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final success = await provider.submitReview(
      token: token,
      clientReviewId: reviewId,
      ratingsMap: Map.of(_ratings),
      freelancerAnswer: _answerController.text.trim(),
      overallComment: comment,
    );

    if (!mounted) return;
    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ClientReviewSubmittedScreen(clientName: widget.clientName),
        ),
      );
    } else if (provider.flaggedLabels != null) {
      showReviewFlaggedDialog(context, rawLabels: provider.flaggedLabels!);
    } else {
      _showSnack(provider.error ?? 'Failed to submit. Please try again.');
    }
  }

  void _showSnack(String msg) {
    AppToast.error(msg);
  }

  @override
  void dispose() {
    _answerController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Rate This Client',
          style: AppText.h3.copyWith(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Consumer<ClientReviewProvider>(
        builder: (context, rp, _) {
          switch (rp.formState) {
            case ClientReviewLoadState.loading:
              return _buildWaitingState();
            case ClientReviewLoadState.error:
              return _buildErrorState(rp.error);
            case ClientReviewLoadState.loaded:
            case ClientReviewLoadState.idle:
              final review = rp.pendingReview;
              if (review == null) return _buildWaitingState();
              if (review.status != 'pending') {
                return _buildAlreadySubmittedState();
              }
              return _buildForm(review, rp);
          }
        },
      ),
    );
  }

  Widget _buildForm(ClientReview review, ClientReviewProvider rp) {
    final aiQuestion =
        review.writtenContent?.aiQuestion ??
        'How clear were the project requirements when you started?';

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProjectHeader(),
              const SizedBox(height: 20),
              _buildCard(
                title: 'Rate Your Experience',
                child: Column(
                  children: _ratings.keys.map(_buildRatingRow).toList(),
                ),
              ),
              const SizedBox(height: 16),
              _buildCard(
                title: 'Quick Question',
                subtitle: 'AI-generated based on your project',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              aiQuestion,
                              style: AppText.body.copyWith(
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _answerController,
                      hint: 'Share your thoughts...',
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildCard(
                title: 'Overall Review',
                child: _buildTextField(
                  controller: _commentController,
                  hint:
                      'Describe your experience working with ${widget.clientName}...',
                  maxLines: 5,
                ),
              ),
              const SizedBox(height: 16),
              _buildAiNotice(),
            ],
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            color: AppColors.background,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: rp.submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: rp.submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Submit Review',
                        style: AppText.bodySemiBold.copyWith(
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProjectHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.task_alt, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.projectTitle,
                  style: AppText.bodySemiBold.copyWith(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Review for ${widget.clientName}',
                  style: AppText.caption.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Completed',
              style: AppText.caption.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingRow(String category) {
    final value = _ratings[category] ?? 5.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _ratingIcons[category],
              size: 16,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_ratingLabels[category]!, style: AppText.captionSemiBold),
                Row(
                  children: List.generate(5, (i) {
                    return GestureDetector(
                      onTap: () => setState(
                        () => _ratings[category] = (i + 1).toDouble(),
                      ),
                      child: Icon(
                        i < value.round() ? Icons.star : Icons.star_outline,
                        color: i < value.round()
                            ? Colors.amber
                            : Colors.grey.shade300,
                        size: 24,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
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
          Text(title, style: AppText.h3),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppText.caption.copyWith(color: Colors.grey[600]),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: AppText.body,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppText.body.copyWith(color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildAiNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, size: 16, color: Colors.blue.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Your review is AI-verified for fairness and authenticity before publishing.',
              style: AppText.caption.copyWith(color: Colors.blue.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlreadySubmittedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48,
              color: Colors.green[400],
            ),
            const SizedBox(height: 12),
            Text(
              'Already Reviewed',
              style: AppText.h3.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ve already submitted a review for this client.',
              style: AppText.body.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String? error) {
    final isProcessing = error?.contains('still be processing') ?? false;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_empty_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'Review Not Ready Yet',
              style: AppText.h3.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              isProcessing
                  ? 'The AI is setting up your review form. Please try again in a moment.'
                  : (error ?? 'Something went wrong.'),
              style: AppText.body.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadForm,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'Preparing your review form...',
            style: AppText.body.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
