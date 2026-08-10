import 'package:flutter/material.dart';
import '../models/job_post_model.dart';

class SavedItemsProvider extends ChangeNotifier {
  final List<JobPostModel> _savedJobs = [];

  List<JobPostModel> get savedJobs => List.unmodifiable(_savedJobs);

  bool isJobSaved(String jobPostId) =>
      _savedJobs.any((j) => j.jobPostId == jobPostId);

  void toggleSaveJob(JobPostModel job) {
    if (isJobSaved(job.jobPostId)) {
      _savedJobs.removeWhere((j) => j.jobPostId == job.jobPostId);
    } else {
      _savedJobs.add(job);
    }
    notifyListeners();
  }
}
