import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../screens/dashboard/dashboard.dart';
import '../../screens/job_client_view/job_list.dart';
import 'job_detail.dart';

class Frame1 extends StatefulWidget {
  const Frame1({super.key});

  @override
  Frame1State createState() => Frame1State();
}

class Frame1State extends State<Frame1> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // ── Top indigo section ────────────────────────────────────────────
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  height: screenHeight * 0.42,
                  width: double.infinity,
                  color: AppColors.primary,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Decorative circle top-right
                      Positioned(
                        right: -50,
                        top: -30,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      // Decorative circle bottom-left
                      Positioned(
                        left: -30,
                        bottom: 40,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.07),
                          ),
                        ),
                      ),
                      // Dot grid top-right
                      Positioned(right: 28, top: 60, child: _buildDotGrid()),
                    ],
                  ),
                ),
                // Success icon circle — overlaps the boundary
                Positioned(
                  bottom: -52,
                  child: Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Bottom content section ────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 76, 28, 32),
                  child: Column(
                    children: [
                      const Text(
                        'Your job has been\nposted!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Your job is posted successfully. You can view your jobs or post another one.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.08),
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.primary,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Your job is already live and visible to freelancers. We also run automated safety checks in the background — you\'ll get a notification if it ever needs your attention.',
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // View Jobs button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const JobListScreen(),
                              ),
                              (route) => route.isFirst,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'View Jobs',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Post another job button (outlined)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PostNewJobJobDetail(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            backgroundColor: AppColors.secondary,
                          ),
                          child: const Text(
                            'Post Another Job',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
        (row) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: List.generate(
              3,
              (col) => Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
