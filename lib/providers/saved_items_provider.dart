import 'package:flutter/material.dart';
import '../models/job_post_model.dart';
import '../models/freelancer_model.dart';
import '../models/client_model.dart';

class SavedItemsProvider extends ChangeNotifier {
  final List<JobPostModel> _savedJobs = [];
  final List<FreelancerModel> _savedFreelancers = [];
  final List<ClientModel> _savedClients = [];

  List<JobPostModel> get savedJobs => List.unmodifiable(_savedJobs);
  List<FreelancerModel> get savedFreelancers =>
      List.unmodifiable(_savedFreelancers);
  List<ClientModel> get savedClients => List.unmodifiable(_savedClients);

  bool isJobSaved(String jobPostId) =>
      _savedJobs.any((j) => j.jobPostId == jobPostId);

  bool isFreelancerSaved(String freelancerId) =>
      _savedFreelancers.any((f) => f.freelancerId == freelancerId);

  bool isClientSaved(String clientId) =>
      _savedClients.any((c) => c.clientId == clientId);

  void toggleSaveJob(JobPostModel job) {
    if (isJobSaved(job.jobPostId)) {
      _savedJobs.removeWhere((j) => j.jobPostId == job.jobPostId);
    } else {
      _savedJobs.add(job);
    }
    notifyListeners();
  }

  void toggleSaveFreelancer(FreelancerModel freelancer) {
    if (isFreelancerSaved(freelancer.freelancerId)) {
      _savedFreelancers
          .removeWhere((f) => f.freelancerId == freelancer.freelancerId);
    } else {
      _savedFreelancers.add(freelancer);
    }
    notifyListeners();
  }

  void toggleSaveClient(ClientModel client) {
    if (isClientSaved(client.clientId)) {
      _savedClients.removeWhere((c) => c.clientId == client.clientId);
    } else {
      _savedClients.add(client);
    }
    notifyListeners();
  }
}
