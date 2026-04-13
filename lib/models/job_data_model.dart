class JobData {
  final String title;
  final String description;
  final String budget;
  final String workingDays;
  final String deadline;
  final bool isTeam;
  final bool isFullPayment;
  final String paymentOption; 

  JobData({
    required this.title,
    required this.description,
    required this.budget,
    required this.workingDays,
    required this.deadline,
    required this.isTeam,
    required this.isFullPayment,
    required this.paymentOption,
  });
}
