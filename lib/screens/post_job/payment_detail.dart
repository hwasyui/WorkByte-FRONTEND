import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/job_post_provider.dart';
import '../../models/job_payment_model.dart';
import 'milestone.dart';
import 'summary.dart';

class PostPaymentDetail extends StatefulWidget {
  const PostPaymentDetail({super.key});

  @override
  PostPaymentDetailState createState() => PostPaymentDetailState();
}

class PostPaymentDetailState extends State<PostPaymentDetail> {
  static const Color _primary = Color(0xFF00AAA8);

  bool _isFullSelected = true;
  String _selectedOption = '1 (100%)';

  final List<String> _milestoneOptions = [
    '2 (50%, 100%)',
    '3 (25%, 75%, 100%)',
    '4 (25%, 50%, 75%, 100%)',
    '5 (15%, 30%, 50%, 75%, 100%)',
  ];

  final List<String> _fullOptions = ['1 (100%)'];

  void _onNext() {
    if (_isFullSelected) {
      context.read<JobPostProvider>().setDraftPayment(
        JobPaymentDraft(isFullPayment: true, paymentOption: _selectedOption),
      );
      Navigator.push(
        // ← push, not pushReplacement
        context,
        MaterialPageRoute(builder: (_) => const PostNewJobSummary()),
      );
    } else {
      context.read<JobPostProvider>().setDraftPayment(
        JobPaymentDraft(isFullPayment: false, paymentOption: _selectedOption),
      );
      Navigator.push(
        // ← push, not pushReplacement
        context,
        MaterialPageRoute(
          builder: (_) => PostNewJobMilestone(selectedOption: _selectedOption),
        ),
      );
    }
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
                      padding: const EdgeInsets.only(bottom: 210),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Header ────────────────────────────────────────
                          Container(
                            margin: const EdgeInsets.only(bottom: 19),
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(bottom: 27),
                                  width: double.infinity,
                                  child: Container(
                                    color: _primary,
                                    padding: const EdgeInsets.only(top: 23),
                                    width: double.infinity,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                        const Padding(
                                          padding: EdgeInsets.only(
                                            bottom: 9,
                                            left: 29,
                                          ),
                                          child: Text(
                                            'Post new job',
                                            style: TextStyle(
                                              color: Color(0xFFFFFFFF),
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.only(
                                            bottom: 54,
                                            left: 29,
                                          ),
                                          child: Text(
                                            'Payment Detail',
                                            style: TextStyle(
                                              color: Color(0xFFFFFFFF),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // ── Full / Milestone toggle ─────────────────
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: const Color(0xFFFFFFFF),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 3,
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 29,
                                  ),
                                  width: double.infinity,
                                  child: Row(
                                    children: [
                                      _toggleOption(
                                        label: 'Full',
                                        selected: _isFullSelected,
                                        onTap: () => setState(() {
                                          _isFullSelected = true;
                                          _selectedOption = _fullOptions[0];
                                        }),
                                      ),
                                      _toggleOption(
                                        label: 'Milestone',
                                        selected: !_isFullSelected,
                                        onTap: () => setState(() {
                                          _isFullSelected = false;
                                          _selectedOption =
                                              _milestoneOptions[0];
                                        }),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // ── Explanation text ──────────────────────────────
                          Container(
                            margin: const EdgeInsets.only(bottom: 31, left: 29),
                            width: 309,
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  color: Color(0xFFB5B4B4),
                                  fontSize: 10,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Full payment',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        ', pay at the end of project finish\n',
                                  ),
                                  TextSpan(
                                    text: 'Milestone payment',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        ', pay as their work progress, ex: 25%, 50%, 100%. (Usually for big and long term project)\n\nBetween ',
                                  ),
                                  TextSpan(
                                    text: 'full payment and milestone payment',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        ', you need to deposit your payment first before freelancer start to work your project.',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // ── Dropdown label ────────────────────────────────
                          Container(
                            margin: const EdgeInsets.only(bottom: 10, left: 32),
                            child: Text(
                              _isFullSelected ? 'Full' : 'Milestone',
                              style: const TextStyle(
                                color: Color(0xFF7D7D7D),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // ── Dropdown ──────────────────────────────────────
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFF0F0F1),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              color: const Color(0xFFFFFFFF),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            margin: const EdgeInsets.only(
                              bottom: 25,
                              left: 29,
                              right: 29,
                            ),
                            width: double.infinity,
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedOption,
                                isExpanded: true,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Color(0xFF333333),
                                ),
                                items:
                                    (_isFullSelected
                                            ? _fullOptions
                                            : _milestoneOptions)
                                        .map(
                                          (option) => DropdownMenuItem(
                                            value: option,
                                            child: Text(
                                              option,
                                              style: const TextStyle(
                                                color: Color(0xFF333333),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _selectedOption = value);
                                  }
                                },
                              ),
                            ),
                          ),
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
                                horizontal: 29,
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

  Widget _toggleOption({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: selected ? _primary : Colors.transparent,
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF7D7D7D),
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
