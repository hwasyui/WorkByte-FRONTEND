import 'package:flutter/material.dart';
import 'milestone.dart';
import 'summary.dart';
import '../../models/job_data_model.dart';

class PostNewJobTeamRolesDetails extends StatefulWidget {
  final JobData jobData;

  const PostNewJobTeamRolesDetails({super.key, required this.jobData});
  @override
  PostNewJobTeamRolesDetailsState createState() =>
      PostNewJobTeamRolesDetailsState();
}

class PostNewJobTeamRolesDetailsState
    extends State<PostNewJobTeamRolesDetails> {
  bool _isFullSelected = false;
  String _selectedOption = '2 (50%, 100%)';

  final List<String> _milestoneOptions = [
    '2 (50%, 100%)',
    '3 (25%, 75%, 100%)',
    '4 (25%, 50%, 75%, 100%)',
    '5 (15%, 30%, 50%, 75%, 100%)',
  ];

  final List<String> _fullOptions = ['1 (100%)'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          constraints: const BoxConstraints.expand(),
          color: Color(0xFFFFFFFF),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: IntrinsicHeight(
                  child: Container(
                    color: Color(0xFFF9F9F9),
                    width: double.infinity,
                    height: double.infinity,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 210),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IntrinsicHeight(
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 19),
                              width: double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  IntrinsicHeight(
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 27),
                                      width: double.infinity,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          IntrinsicHeight(
                                            child: Container(
                                              color: Color(0xFF00AAA8),
                                              padding: const EdgeInsets.only(
                                                top: 23,
                                              ),
                                              width: double.infinity,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  InkWell(
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                    },
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            bottom: 15,
                                                            left: 18,
                                                          ),

                                                      child: const Icon(
                                                        Icons.chevron_left,
                                                        color: Colors.white,
                                                        size: 24,
                                                      ),
                                                    ),
                                                  ),

                                                  Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                          bottom: 9,
                                                          left: 29,
                                                        ),
                                                    child: Text(
                                                      "Post new job",
                                                      style: TextStyle(
                                                        color: Color(
                                                          0xFFFFFFFF,
                                                        ),
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                          bottom: 54,
                                                          left: 29,
                                                        ),
                                                    child: Text(
                                                      "Payment Detail",
                                                      style: TextStyle(
                                                        color: Color(
                                                          0xFFFFFFFF,
                                                        ),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  IntrinsicHeight(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color: Color(0xFFFFFFFF),
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
                                          Expanded(
                                            child: InkWell(
                                              onTap: () {
                                                setState(() {
                                                  _isFullSelected = true;
                                                  _selectedOption =
                                                      _fullOptions[0];
                                                });
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  color: _isFullSelected
                                                      ? Color(0xFF00AAA8)
                                                      : Colors.transparent,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 10,
                                                    ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  "Full",
                                                  style: TextStyle(
                                                    color: _isFullSelected
                                                        ? Colors.white
                                                        : Color(0xFF7D7D7D),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: InkWell(
                                              onTap: () {
                                                setState(() {
                                                  _isFullSelected = false;
                                                  _selectedOption =
                                                      _milestoneOptions[0];
                                                });
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  color: !_isFullSelected
                                                      ? Color(0xFF00AAA8)
                                                      : Colors.transparent,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 10,
                                                    ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  "Milestone",
                                                  style: TextStyle(
                                                    color: !_isFullSelected
                                                        ? Colors.white
                                                        : Color(0xFF7D7D7D),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(bottom: 31, left: 29),
                            width: 309,
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  color: Color(0xFFB5B4B4),
                                  fontSize: 10,
                                ),
                                children: [
                                  const TextSpan(
                                    text: "Full payment",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const TextSpan(
                                    text:
                                        ", pay at the end of project finish\n",
                                  ),
                                  const TextSpan(
                                    text: "Milestone payment",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const TextSpan(
                                    text:
                                        ", pay as their work progress, ex: 25%, 50%, 100%. (Usually for big and long term project)\n\nBetween ",
                                  ),
                                  const TextSpan(
                                    text: "full payment and milestone payment",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const TextSpan(
                                    text:
                                        ", you need to deposit your payment first before freelancer start to work your project.",
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(bottom: 10, left: 32),
                            child: Text(
                              _isFullSelected ? "Full" : "Milestone",
                              style: TextStyle(
                                color: Color(0xFF7D7D7D),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IntrinsicHeight(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Color(0xFFF0F0F1),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                color: Color(0xFFFFFFFF),
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
                                      setState(() {
                                        _selectedOption = value;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              final updatedJobData = JobData(
                                title: widget.jobData.title,
                                description: widget.jobData.description,
                                budget: widget.jobData.budget,
                                workingDays: widget.jobData.workingDays,
                                deadline: widget.jobData.deadline,
                                isTeam: widget.jobData.isTeam,
                                isFullPayment: _isFullSelected,
                                paymentOption: _selectedOption,
                              );
                              if (_isFullSelected) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PostNewJobSummary(
                                      jobData: updatedJobData,
                                    ),
                                  ),
                                );
                              } else {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PostNewJobMilestone(
                                      selectedOption: _selectedOption,
                                      jobData: updatedJobData,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: IntrinsicHeight(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Color(0xFF00AAA8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 29,
                                ),
                                width: double.infinity,
                                child: Column(
                                  children: [
                                    Text(
                                      "Next",
                                      style: TextStyle(
                                        color: Color(0xFFFFFFFF),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          IntrinsicHeight(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Color(0xFFFAF9FE),
                              ),
                              padding: const EdgeInsets.only(top: 41, left: 30),
                              width: double.infinity,
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
