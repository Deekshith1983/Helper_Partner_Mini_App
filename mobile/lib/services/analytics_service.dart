import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Firebase Analytics service adhering to the hiring assessment specifications.
/// - Event names match exactly: login_success, job_viewed, job_status_updated.
/// - Zero personal data logged (no usernames, no customer names, no personal IDs).
/// - Each event is logged to Firebase and printed to the debug console for easy monitoring.
class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._internal();

  AnalyticsService._internal();

  factory AnalyticsService() => instance;

  FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;

  /// Logs successful helper authentication.
  /// Event: login_success
  /// Parameters: {method: "password"}
  Future<void> logLoginSuccess() async {
    const eventName = 'login_success';
    final params = <String, Object>{'method': 'password'};

    debugPrint('📊 [Analytics] Event: $eventName | Parameters: $params');

    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: params,
      );
    } catch (e) {
      debugPrint('⚠️ [Analytics] Firebase logEvent failed: $e');
    }
  }

  /// Logs when a helper opens a job details screen.
  /// Event: job_viewed
  /// Parameters: {job_id: <int>, status: <string>}
  Future<void> logJobViewed({
    required int jobId,
    required String status,
  }) async {
    const eventName = 'job_viewed';
    final params = <String, Object>{
      'job_id': jobId,
      'status': status,
    };

    debugPrint('📊 [Analytics] Event: $eventName | Parameters: $params');

    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: params,
      );
    } catch (e) {
      debugPrint('⚠️ [Analytics] Firebase logEvent failed: $e');
    }
  }

  /// Logs when a helper successfully transitions a job to a new status.
  /// Event: job_status_updated
  /// Parameters: {job_id: <int>, from_status: <string>, to_status: <string>}
  /// Fired strictly after the backend API returns 200 OK.
  Future<void> logJobStatusUpdated({
    required int jobId,
    required String oldStatus,
    required String newStatus,
  }) async {
    const eventName = 'job_status_updated';
    final params = <String, Object>{
      'job_id': jobId,
      'from_status': oldStatus,
      'to_status': newStatus,
    };

    debugPrint('📊 [Analytics] Event: $eventName | Parameters: $params');

    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: params,
      );
    } catch (e) {
      debugPrint('⚠️ [Analytics] Firebase logEvent failed: $e');
    }
  }
}
