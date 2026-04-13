import 'package:flutter/material.dart';
import 'summary.dart';
import '../../models/job_data_model.dart';

class PostNewJobMilestone extends StatefulWidget {
  final String selectedOption;
  final JobData jobData;

  const PostNewJobMilestone({
    super.key,
    required this.selectedOption,
    required this.jobData,
  });

  @override
  PostNewJobMilestoneState createState() => PostNewJobMilestoneState();
}

class PostNewJobMilestoneState extends State<PostNewJobMilestone> {
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
                      padding: const EdgeInsets.only(bottom: 284),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IntrinsicHeight(
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 27),
                              width: double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  IntrinsicHeight(
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 25),
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
                                                          bottom: 6,
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
                                                          bottom: 60,
                                                          left: 29,
                                                        ),
                                                    child: Text(
                                                      "Milestone",
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
                                  for (
                                    var index = 0;
                                    index < milestoneCount;
                                    index++
                                  ) ...[
                                    Container(
                                      margin: const EdgeInsets.only(
                                        bottom: 11,
                                        left: 28,
                                      ),
                                      child: Text(
                                        "Milestone ${index + 1}",
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
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          color: Color(0xFFFFFFFF),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 26,
                                        ),
                                        width: double.infinity,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            IntrinsicHeight(
                                              child: Container(
                                                margin: const EdgeInsets.only(
                                                  bottom: 6,
                                                  left: 20,
                                                  right: 33,
                                                ),
                                                width: double.infinity,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      "Work progress",
                                                      style: TextStyle(
                                                        color: Color(
                                                          0xFF7D7D7D,
                                                        ),
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                      "Payment Percentage",
                                                      style: TextStyle(
                                                        color: Color(
                                                          0xFF7D7D7D,
                                                        ),
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            IntrinsicHeight(
                                              child: Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                    ),
                                                width: double.infinity,
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: IntrinsicHeight(
                                                        child: Container(
                                                          alignment:
                                                              Alignment.center,
                                                          decoration: BoxDecoration(
                                                            border: Border.all(
                                                              color: Color(
                                                                0xFFF0F0F1,
                                                              ),
                                                              width: 1,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  10,
                                                                ),
                                                            color: Color(
                                                              0xFFFFFFFF,
                                                            ),
                                                          ),
                                                          margin:
                                                              const EdgeInsets.only(
                                                                right: 19,
                                                              ),
                                                          width:
                                                              double.infinity,
                                                          child: TextField(
                                                            style: TextStyle(
                                                              color: Color(
                                                                0xFFB5B4B4,
                                                              ),
                                                              fontSize: 12,
                                                            ),
                                                            onChanged: (value) {
                                                              setState(() {
                                                                workProgress[index] =
                                                                    value;
                                                              });
                                                            },
                                                            decoration:
                                                                InputDecoration(
                                                                  hintText:
                                                                      "Ex: 25%",
                                                                  isDense: true,
                                                                  contentPadding:
                                                                      const EdgeInsets.only(
                                                                        top: 22,
                                                                        bottom:
                                                                            22,
                                                                        left:
                                                                            17,
                                                                        right:
                                                                            17,
                                                                      ),
                                                                  border:
                                                                      InputBorder
                                                                          .none,
                                                                  focusedBorder:
                                                                      InputBorder
                                                                          .none,
                                                                  filled: false,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: IntrinsicHeight(
                                                        child: Container(
                                                          alignment:
                                                              Alignment.center,
                                                          decoration: BoxDecoration(
                                                            border: Border.all(
                                                              color: Color(
                                                                0xFFF0F0F1,
                                                              ),
                                                              width: 1,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  10,
                                                                ),
                                                            color: Color(
                                                              0xFFFFFFFF,
                                                            ),
                                                          ),
                                                          width:
                                                              double.infinity,
                                                          child: TextField(
                                                            style: TextStyle(
                                                              color: Color(
                                                                0xFFB5B4B4,
                                                              ),
                                                              fontSize: 12,
                                                            ),
                                                            onChanged: (value) {
                                                              setState(() {
                                                                paymentPercentage[index] =
                                                                    value;
                                                              });
                                                            },
                                                            decoration:
                                                                InputDecoration(
                                                                  hintText:
                                                                      "Ex: 25%",
                                                                  isDense: true,
                                                                  contentPadding:
                                                                      const EdgeInsets.only(
                                                                        top: 22,
                                                                        bottom:
                                                                            22,
                                                                        left:
                                                                            19,
                                                                        right:
                                                                            19,
                                                                      ),
                                                                  border:
                                                                      InputBorder
                                                                          .none,
                                                                  focusedBorder:
                                                                      InputBorder
                                                                          .none,
                                                                  filled: false,
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
                                  ],
                                ],
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PostNewJobSummary(
                                    jobData: widget.jobData,
                                  ),
                                ),
                              );
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
                                  horizontal: 27,
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
