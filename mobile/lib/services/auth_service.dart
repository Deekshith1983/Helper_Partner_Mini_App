import '../core/api_client.dart';
import '../core/config.dart';
import '../models/user.dart';

class LoginResult {
  final String token;
  final User user;

  const LoginResult({
    required this.token,
    required this.user,
  });
}

class AuthService {
  final ApiClient _apiClient;

  AuthService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<LoginResult> login({
    required String username,
    required String password,
  }) async {
    final response = await _apiClient.post(
      AppConfig.loginUrl,
      body: {
        'username': username,
        'password': password,
      },
      includeAuth: false,
    );

    if (response is Map<String, dynamic>) {
      final token = response['token'] as String;
      final userMap = response['user'] as Map<String, dynamic>;
      final user = User.fromJson(userMap);
      return LoginResult(token: token, user: user);
    }

    throw const ApiException('Unexpected response format from server.');
  }
}
