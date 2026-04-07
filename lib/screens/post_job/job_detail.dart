import 'package:flutter/material.dart';
import '../dashboard/dashboard.dart';
import 'team_roles.dart';
import 'team_roles_details.dart';
import '../../models/job_data_model.dart';

class PostNewJobJobDetail extends StatefulWidget {
  const PostNewJobJobDetail({super.key});
  @override
  PostNewJobJobDetailState createState() => PostNewJobJobDetailState();
}

class PostNewJobJobDetailState extends State<PostNewJobJobDetail> {
  String textField1 = '';
  String textField2 = '';
  DateTime selectedDate = DateTime.now();
  String deadlineText = "23/02/2023";
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _daysController = TextEditingController(
    text: "7",
  );

  bool _isTeamSelected = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        deadlineText =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _budgetController.dispose();
    _daysController.dispose();
    super.dispose();
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
                      padding: const EdgeInsets.only(bottom: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IntrinsicHeight(
                            child: Container(
                              padding: const EdgeInsets.only(bottom: 29),
                              margin: const EdgeInsets.only(bottom: 2),
                              width: double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  IntrinsicHeight(
                                    child: Container(
                                      color: Color(0xFF00AAA8),
                                      padding: const EdgeInsets.only(top: 23),
                                      width: double.infinity,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const HomeScreen(),
                                                ),
                                              );
                                            },
                                            child: Padding(
												padding: const EdgeInsets.only(
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
                                            margin: const EdgeInsets.only(
                                              bottom: 9,
                                              left: 29,
                                            ),
                                            child: Text(
                                              "Post new job",
                                              style: TextStyle(
                                                color: Color(0xFFFFFFFF),
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 57,
                                              left: 29,
                                            ),
                                            child: Text(
                                              "Job Detail",
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
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              margin: const EdgeInsets.only(
                                bottom: 12,
                                left: 28,
                                right: 28,
                              ),
                              width: double.infinity,
                              child: Row(
                                children: [
                                  // Individual
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _isTeamSelected = false;
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          color: !_isTeamSelected
                                              ? Color(0xFF00AAA8)
                                              : Colors.transparent,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          "Individual",
                                          style: TextStyle(
                                            color: !_isTeamSelected
                                                ? Colors.white
                                                : Color(0xFF333333),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Team
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _isTeamSelected = true;
                                        });
                                        final jobData = JobData(
                                          title: _titleController.text,
                                          description: _descController.text,
                                          budget: _budgetController.text,
                                          workingDays: _daysController.text,
                                          deadline: deadlineText,
                                          isTeam: true,
                                          isFullPayment: false,
                                          paymentOption: '',
                                        );
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                PostNewJobTeamRoles(
                                                  jobData: jobData,
                                                ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          color: _isTeamSelected
                                              ? Color(0xFF00AAA8)
                                              : Colors.transparent,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          "Team",
                                          style: TextStyle(
                                            color: _isTeamSelected
                                                ? Colors.white
                                                : Color(0xFF333333),
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
                          Container(
                            margin: const EdgeInsets.only(bottom: 27, left: 29),
                            width: 307,
                            child: Text(
                              "Individual, if your scope project can be done with 1 freelancer \nTeam, if your scope project can be done with 2 or more freelancer (for big and complex project)",
                              style: TextStyle(
                                color: Color(0xFFB5B4B4),
                                fontSize: 10,
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(bottom: 10, left: 32),
                            child: Text(
                              "Title",
                              style: TextStyle(
                                color: Color(0xFF7D7D7D),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IntrinsicHeight(
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Color(0xFFF0F0F1),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                color: Color(0xFFFFFFFF),
                              ),
                              margin: const EdgeInsets.only(
                                bottom: 17,
                                left: 29,
                                right: 29,
                              ),
                              width: double.infinity,
                              child: TextField(
                                controller: _titleController,
                                style: TextStyle(
                                  color: _titleController.text.isNotEmpty
                                      ? Color(0xFF333333)
                                      : Color(0xFFB5B4B4),
                                  fontSize: 12,
                                ),
                                onChanged: (value) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: "Create a logo for my company",
                                  hintStyle: TextStyle(
                                    color: Color(0xFFB5B4B4),
                                  ),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.all(19),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(bottom: 10, left: 32),
                            child: Text(
                              "Description",
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
                              margin: const EdgeInsets.only(
                                bottom: 17,
                                left: 29,
                                right: 29,
                              ),
                              width: double.infinity,
                              child: TextField(
                                controller: _descController,
                                maxLines: 5,
                                style: TextStyle(
                                  color: _descController.text.isNotEmpty
                                      ? Color(0xFF333333)
                                      : Color(0xFFB5B4B4),
                                  fontSize: 12,
                                ),
                                onChanged: (value) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText:
                                      "I need a freelancer who experiences with logo design...",
                                  hintStyle: TextStyle(
                                    color: Color(0xFFB5B4B4),
                                  ),
                                  contentPadding: const EdgeInsets.all(19),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(bottom: 7, left: 32),
                            child: Text(
                              "Budget / Total Budget",
                              style: TextStyle(
                                color: Color(0xFF7D7D7D),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IntrinsicHeight(
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Color(0xFFF0F0F1),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                color: Color(0xFFFFFFFF),
                              ),
                              margin: const EdgeInsets.only(
                                bottom: 11,
                                left: 29,
                                right: 29,
                              ),
                              width: double.infinity,
                              child: TextField(
                                controller: _budgetController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                  color: _budgetController.text.isNotEmpty
                                      ? const Color(0xFF333333)
                                      : const Color(0xFFB5B4B4),
                                  fontSize: 12,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    textField2 = value;
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: "Rp.    1.000.000",
                                  hintStyle: const TextStyle(
                                    color: Color(0xFFB5B4B4),
                                  ),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.only(
                                    top: 21,
                                    bottom: 21,
                                    left: 19,
                                    right: 19,
                                  ),
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(
                              bottom: 24,
                              left: 29,
                              right: 29,
                            ),
                            width: double.infinity,
                            child: Text(
                              "To get many proposal from freelancers, we recommended to set budget to Rp. 1.000.000",
                              style: TextStyle(
                                color: Color(0xFFB5B4B4),
                                fontSize: 10,
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(bottom: 7, left: 32),
                            child: Text(
                              "Working days",
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
                                horizontal: 19,
                                vertical: 5,
                              ),
                              margin: const EdgeInsets.only(
                                bottom: 11,
                                left: 29,
                                right: 29,
                              ),
                              width: double.infinity,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _daysController,
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(
                                        color: _daysController.text.isNotEmpty
                                            ? Color(0xFF333333)
                                            : Color(0xFFB5B4B4),
                                        fontSize: 12,
                                      ),
                                      onChanged: (value) {
                                        setState(() {});
                                      },
                                      decoration: InputDecoration(
                                        isDense: true,
                                        border: InputBorder.none,
                                        hintText: "0",
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "days",
                                    style: TextStyle(
                                      color: Color(0xFF333333),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(
                              bottom: 22,
                              left: 32,
                              right: 46,
                            ),
                            width: double.infinity,
                            child: Text(
                              "Working days will be start when you done to choose freelancer",
                              style: TextStyle(
                                color: Color(0xFFB5B4B4),
                                fontSize: 10,
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(bottom: 10, left: 32),
                            child: Text(
                              "Deadline",
                              style: TextStyle(
                                color: Color(0xFF7D7D7D),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IntrinsicHeight(
                            child: InkWell(
                              onTap: () => _selectDate(context),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFFF0F0F1),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  color: const Color(0xFFFFFFFF),
                                ),
                                padding: const EdgeInsets.only(
                                  top: 17,
                                  bottom: 17,
                                  left: 19,
                                  right: 19,
                                ),
                                margin: const EdgeInsets.only(
                                  bottom: 11,
                                  left: 29,
                                  right: 29,
                                ),
                                width: double.infinity,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      deadlineText,
                                      style: TextStyle(
                                        color: deadlineText == "23/02/2023"
                                            ? const Color(0xFFB5B4B4)
                                            : const Color(0xFF333333),
                                        fontSize: 12,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Image.network(
                                        "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/dPj38vYMjM/vkcsd2w0_expires_30_days.png",
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(bottom: 18, left: 32),
                            child: Text(
                              "When freelancers can send the proposal to this job",
                              style: TextStyle(
                                color: Color(0xFFB5B4B4),
                                fontSize: 10,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              final jobData = JobData(
                                title: _titleController.text,
                                description: _descController.text,
                                budget: _budgetController.text,
                                workingDays: _daysController.text,
                                deadline: deadlineText,
                                isTeam: _isTeamSelected,
                                isFullPayment: false, 
                                paymentOption: '', 
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PostNewJobTeamRolesDetails(
                                    jobData: jobData,
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
