import '../core/api_client.dart';
import '../core/config.dart';
import '../models/job.dart';
import '../models/job_status.dart';

class JobService {
  final ApiClient _apiClient;

  JobService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<Job>> getJobs() async {
    final response = await _apiClient.get(AppConfig.jobsUrl);
    if (response is List) {
      return response
          .map((item) => Job.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw const ApiException('Invalid job list response format.');
  }

  Future<Job> getJobDetails(int id) async {
    final response = await _apiClient.get(AppConfig.jobDetailUrl(id));
    if (response is Map<String, dynamic>) {
      return Job.fromJson(response);
    }
    throw const ApiException('Invalid job detail response format.');
  }

  Future<Job> updateJobStatus(int id, JobStatus newStatus) async {
    final response = await _apiClient.patch(
      AppConfig.jobStatusUrl(id),
      body: {'status': newStatus.value},
    );
    if (response is Map<String, dynamic>) {
      return Job.fromJson(response);
    }
    throw const ApiException('Invalid update status response format.');
  }
}
