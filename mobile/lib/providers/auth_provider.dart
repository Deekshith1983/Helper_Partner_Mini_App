import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../models/user.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/job_service.dart';
import '../services/token_storage.dart';

enum AuthStatus {
  initial,
  authenticating,
  authenticated,
  unauthenticated,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final TokenStorage _tokenStorage;
  final JobService _jobService;
  final AnalyticsService _analyticsService;

  AuthStatus _status = AuthStatus.initial;
  User? _currentUser;
  String? _token;
  String? _errorMessage;
  bool _isLoading = false;

  AuthProvider({
    AuthService? authService,
    TokenStorage? tokenStorage,
    JobService? jobService,
    AnalyticsService? analyticsService,
  })  : _authService = authService ?? AuthService(),
        _tokenStorage = tokenStorage ?? TokenStorage(),
        _jobService = jobService ?? JobService(),
        _analyticsService = analyticsService ?? AnalyticsService();

  AuthStatus get status => _status;
  User? get currentUser => _currentUser;
  String? get token => _token;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Verifies existing saved token on startup by querying backend jobs API.
  Future<bool> tryAutoLogin() async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    final savedToken = await _tokenStorage.getToken();
    final savedUser = await _tokenStorage.getUser();

    if (savedToken == null || savedToken.isEmpty) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }

    try {
      // Verify token with real API endpoint
      await _jobService.getJobs();
      _token = savedToken;
      _currentUser = savedUser;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (_) {
      // On 401 or token failure, clear saved data
      await _tokenStorage.clear();
      _token = null;
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(
        username: username.trim(),
        password: password,
      );

      _token = result.token;
      _currentUser = result.user;

      await _tokenStorage.saveToken(result.token);
      await _tokenStorage.saveUser(result.user);

      _status = AuthStatus.authenticated;
      _isLoading = false;

      // Log login success analytics event (zero PII)
      await _analyticsService.logLoginSuccess();

      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
    _token = null;
    _currentUser = null;
    _errorMessage = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
