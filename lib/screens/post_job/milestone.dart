import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/job_post_provider.dart';
import '../../models/job_payment_model.dart';
import 'summary.dart';

class PostNewJobMilestone extends StatefulWidget {
  final String selectedOption;

  const PostNewJobMilestone({super.key, required this.selectedOption});

  @override
  PostNewJobMilestoneState createState() => PostNewJobMilestoneState();
}

class PostNewJobMilestoneState extends State<PostNewJobMilestone> {
  static const Color _primary = Color(0xFF00AAA8);

  late int milestoneCount;
  late List<String> workProgress;
  late List<String> paymentPercentage;

  @override
  void initState() {
    super.initState();
    milestoneCount = int.tryParse(widget.selectedOption.split(' ').first) ?? 1;
    workProgress = List<String>.filled(milestoneCount, '');
    paymentPercentage = List<String>.filled(milestoneCount, '');
  }

  // ─── Validation ───────────────────────────────────────────────────────────
  String? _validate() {
    for (int i = 0; i < milestoneCount; i++) {
      if (workProgress[i].trim().isEmpty) {
        return 'Milestone ${i + 1}: work progress is required';
      }
      if (paymentPercentage[i].trim().isEmpty) {
        return 'Milestone ${i + 1}: payment percentage is required';
      }
    }
    return null;
  }

  void _onNext() {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final milestones = List.generate(
      milestoneCount,
      (i) => JobMilestoneModel(
        workProgress: workProgress[i].trim(),
        paymentPercentage: paymentPercentage[i].trim(),
        milestoneOrder: i + 1,
      ),
    );

    // Update the draft payment with milestone details
    final provider = context.read<JobPostProvider>();
    final existing = provider.draftPayment;
    provider.setDraftPayment(
      JobPaymentDraft(
        isFullPayment: existing?.isFullPayment ?? false,
        paymentOption: existing?.paymentOption ?? widget.selectedOption,
        milestones: milestones,
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PostNewJobSummary()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          constraints: const BoxConstraints.expand(),
          color: const Color(0xFFFFFFFF),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: IntrinsicHeight(
                  child: Container(
                    color: const Color(0xFFF9F9F9),
                    width: double.infinity,
                    height: double.infinity,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 284),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Header ────────────────────────────────────────
                          Container(
                            color: _primary,
                            padding: const EdgeInsets.only(top: 23),
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InkWell(
                                  onTap: () => Navigator.pop(context),
                                  child: const Padding(
                                    padding: EdgeInsets.only(
                                      bottom: 15,
                                      left: 18,
                                    ),
                                    child: Icon(
                                      Icons.chevron_left,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(
                                    bottom: 6,
                                    left: 29,
                                  ),
                                  child: const Text(
                                    'Post new job',
                                    style: TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(
                                    bottom: 60,
                                    left: 29,
                                  ),
                                  child: const Text(
                                    'Milestone',
                                    style: TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 25),
                          // ── Milestone rows ────────────────────────────────
                          for (
                            int index = 0;
                            index < milestoneCount;
                            index++
                          ) ...[
                            Container(
                              margin: const EdgeInsets.only(
                                bottom: 11,
                                left: 28,
                              ),
                              child: Text(
                                'Milestone ${index + 1}',
                                style: const TextStyle(
                                  color: Color(0xFF7D7D7D),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFF0F0F1),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                color: const Color(0xFFFFFFFF),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 26,
                              ),
                              width: double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 6,
                                      left: 20,
                                      right: 33,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: const [
                                        Text(
                                          'Work progress',
                                          style: TextStyle(
                                            color: Color(0xFF7D7D7D),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Payment Percentage',
                                          style: TextStyle(
                                            color: Color(0xFF7D7D7D),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: const Color(0xFFF0F0F1),
                                                width: 1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: const Color(0xFFFFFFFF),
                                            ),
                                            margin: const EdgeInsets.only(
                                              right: 19,
                                            ),
                                            child: TextField(
                                              style: const TextStyle(
                                                color: Color(0xFF333333),
                                                fontSize: 12,
                                              ),
                                              onChanged: (value) => setState(
                                                () =>
                                                    workProgress[index] = value,
                                              ),
                                              decoration: const InputDecoration(
                                                hintText: 'Ex: 25%',
                                                hintStyle: TextStyle(
                                                  color: Color(0xFFB5B4B4),
                                                  fontSize: 12,
                                                ),
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 17,
                                                      vertical: 22,
                                                    ),
                                                border: InputBorder.none,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: const Color(0xFFF0F0F1),
                                                width: 1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: const Color(0xFFFFFFFF),
                                            ),
                                            child: TextField(
                                              style: const TextStyle(
                                                color: Color(0xFF333333),
                                                fontSize: 12,
                                              ),
                                              onChanged: (value) => setState(
                                                () => paymentPercentage[index] =
                                                    value,
                                              ),
                                              decoration: const InputDecoration(
                                                hintText: 'Ex: 25%',
                                                hintStyle: TextStyle(
                                                  color: Color(0xFFB5B4B4),
                                                  fontSize: 12,
                                                ),
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 19,
                                                      vertical: 22,
                                                    ),
                                                border: InputBorder.none,
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
                            const SizedBox(height: 8),
                          ],
                          // ── Next button ───────────────────────────────────
                          InkWell(
                            onTap: _onNext,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: _primary,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 27,
                              ),
                              width: double.infinity,
                              child: const Center(
                                child: Text(
                                  'Next',
                                  style: TextStyle(
                                    color: Color(0xFFFFFFFF),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
