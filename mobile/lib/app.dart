import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/api_client.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/jobs_provider.dart';
import 'screens/jobs_list_screen.dart';
import 'screens/login_screen.dart';
import 'services/analytics_service.dart';
import 'services/auth_service.dart';
import 'services/job_service.dart';
import 'services/token_storage.dart';

class HelperPartnerApp extends StatefulWidget {
  const HelperPartnerApp({super.key});

  @override
  State<HelperPartnerApp> createState() => _HelperPartnerAppState();
}

class _HelperPartnerAppState extends State<HelperPartnerApp> {
  late final TokenStorage _tokenStorage;
  late final ApiClient _apiClient;
  late final AuthService _authService;
  late final JobService _jobService;
  late final AnalyticsService _analyticsService;

  @override
  void initState() {
    super.initState();
    _tokenStorage = TokenStorage();
    _apiClient = ApiClient(tokenStorage: _tokenStorage);
    _authService = AuthService(apiClient: _apiClient);
    _jobService = JobService(apiClient: _apiClient);
    _analyticsService = AnalyticsService();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (ctx) {
            final authProvider = AuthProvider(
              authService: _authService,
              tokenStorage: _tokenStorage,
              jobService: _jobService,
              analyticsService: _analyticsService,
            );
            // Wire 401 session expiry callback
            _apiClient.onUnauthorized = () {
              authProvider.logout();
            };
            // Trigger auto-login verification on app start
            authProvider.tryAutoLogin();
            return authProvider;
          },
        ),
        ChangeNotifierProvider<JobsProvider>(
          create: (_) => JobsProvider(
            jobService: _jobService,
            analyticsService: _analyticsService,
          ),
        ),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.initial:
      case AuthStatus.authenticating:
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                SizedBox(height: 20),
                Text(
                  AppStrings.appName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      case AuthStatus.authenticated:
        return const JobsListScreen();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}
