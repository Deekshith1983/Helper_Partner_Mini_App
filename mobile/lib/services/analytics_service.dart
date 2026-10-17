import 'dart:developer' as developer;

/// Analytics service stub for Stage 3.
/// Will be integrated with firebase_analytics in Stage 4.
class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._internal();

  AnalyticsService._internal();

  factory AnalyticsService() => instance;

  /// Logs successful helper authentication.
  Future<void> logLoginSuccess({
    required String username,
    required int userId,
  }) async {
    developer.log(
      'Analytics Event: login_success (username=$username, userId=$userId)',
      name: 'AnalyticsService',
    );
  }

  /// Logs when helper opens a job details screen.
  Future<void> logJobViewed({
    required int jobId,
    required String status,
  }) async {
    developer.log(
      'Analytics Event: job_viewed (jobId=$jobId, status=$status)',
      name: 'AnalyticsService',
    );
  }

  /// Logs when helper successfully transitions a job to a new status.
  Future<void> logJobStatusUpdated({
    required int jobId,
    required String oldStatus,
    required String newStatus,
  }) async {
    developer.log(
      'Analytics Event: job_status_updated (jobId=$jobId, from=$oldStatus, to=$newStatus)',
      name: 'AnalyticsService',
    );
  }
}
