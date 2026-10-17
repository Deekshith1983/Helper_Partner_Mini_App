import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../models/job.dart';
import '../models/job_status.dart';
import '../services/analytics_service.dart';
import '../services/job_service.dart';

class JobsProvider extends ChangeNotifier {
  final JobService _jobService;
  final AnalyticsService _analyticsService;

  List<Job> _jobs = [];
  bool _isLoading = false;
  String? _errorMessage;

  JobsProvider({
    JobService? jobService,
    AnalyticsService? analyticsService,
  })  : _jobService = jobService ?? JobService(),
        _analyticsService = analyticsService ?? AnalyticsService();

  List<Job> get jobs => _jobs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get assignedCount => _jobs.where((j) => j.status == JobStatus.assigned).length;
  int get inProgressCount => _jobs.where((j) => j.status == JobStatus.inProgress).length;
  int get completedCount => _jobs.where((j) => j.status == JobStatus.completed).length;

  String get summaryText {
    return '$assignedCount assigned · $inProgressCount in progress · $completedCount completed';
  }

  Future<void> fetchJobs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetched = await _jobService.getJobs();
      _jobs = fetched;
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _errorMessage = "Couldn't load your jobs. Tap Retry.";
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Job?> fetchJobDetails(int id) async {
    try {
      final fresh = await _jobService.getJobDetails(id);
      // Update item in local list if already present
      final index = _jobs.indexWhere((j) => j.id == id);
      if (index != -1) {
        _jobs[index] = fresh;
        notifyListeners();
      }
      // Log job viewed analytics event
      await _analyticsService.logJobViewed(
        jobId: fresh.id,
        status: fresh.status.value,
      );
      return fresh;
    } catch (_) {
      rethrow;
    }
  }

  Future<Job> updateJobStatus(int id, JobStatus newStatus) async {
    final oldJob = _jobs.firstWhere((j) => j.id == id);
    final oldStatusStr = oldJob.status.value;

    try {
      final updatedJob = await _jobService.updateJobStatus(id, newStatus);

      final index = _jobs.indexWhere((j) => j.id == id);
      if (index != -1) {
        _jobs[index] = updatedJob;
        notifyListeners();
      }

      // Log status transition analytics event
      await _analyticsService.logJobStatusUpdated(
        jobId: updatedJob.id,
        oldStatus: oldStatusStr,
        newStatus: updatedJob.status.value,
      );

      return updatedJob;
    } catch (_) {
      rethrow;
    }
  }
}
