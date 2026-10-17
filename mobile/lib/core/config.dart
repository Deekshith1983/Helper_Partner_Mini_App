/// Application runtime configuration.
/// Defaults to Android emulator gateway (http://10.0.2.2:8000).
/// Can be overridden at build/run time via:
/// `--dart-define=API_BASE_URL=http://<YOUR_LAN_IP>:8000`
class AppConfig {
  static const String _defaultEmulatorUrl = 'http://10.0.2.2:8000';

  static String get baseUrl {
    const definedUrl = String.fromEnvironment('API_BASE_URL');
    if (definedUrl.isNotEmpty) {
      // Strip trailing slash if present for consistency
      return definedUrl.endsWith('/')
          ? definedUrl.substring(0, definedUrl.length - 1)
          : definedUrl;
    }
    return _defaultEmulatorUrl;
  }

  static String get loginUrl => '$baseUrl/api/auth/login/';
  static String get jobsUrl => '$baseUrl/api/jobs/';
  static String jobDetailUrl(int id) => '$baseUrl/api/jobs/$id/';
  static String jobStatusUrl(int id) => '$baseUrl/api/jobs/$id/status/';
}
