import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../services/token_storage.dart';
import 'constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  final TokenStorage _tokenStorage;
  final http.Client _httpClient;
  VoidCallback? onUnauthorized;

  ApiClient({
    TokenStorage? tokenStorage,
    http.Client? httpClient,
    this.onUnauthorized,
  })  : _tokenStorage = tokenStorage ?? TokenStorage(),
        _httpClient = httpClient ?? http.Client();

  static const Duration timeoutDuration = Duration(seconds: 12);

  Future<Map<String, String>> _buildHeaders({bool includeAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      final token = await _tokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Token $token';
      }
    }

    return headers;
  }

  Future<dynamic> get(String url, {bool includeAuth = true}) async {
    try {
      final headers = await _buildHeaders(includeAuth: includeAuth);
      final response = await _httpClient
          .get(Uri.parse(url), headers: headers)
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } on SocketException {
      throw const ApiException(AppStrings.networkError);
    } on TimeoutException {
      throw const ApiException(AppStrings.networkError);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Unexpected error: ${e.toString()}');
    }
  }

  Future<dynamic> post(
    String url, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
  }) async {
    try {
      final headers = await _buildHeaders(includeAuth: includeAuth);
      final response = await _httpClient
          .post(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } on SocketException {
      throw const ApiException(AppStrings.networkError);
    } on TimeoutException {
      throw const ApiException(AppStrings.networkError);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Unexpected error: ${e.toString()}');
    }
  }

  Future<dynamic> patch(
    String url, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
  }) async {
    try {
      final headers = await _buildHeaders(includeAuth: includeAuth);
      final response = await _httpClient
          .patch(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } on SocketException {
      throw const ApiException(AppStrings.networkError);
    } on TimeoutException {
      throw const ApiException(AppStrings.networkError);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Unexpected error: ${e.toString()}');
    }
  }

  dynamic _handleResponse(http.Response response) {
    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = null;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    // 401 Unauthorized: clear token and notify session expired
    if (response.statusCode == 401) {
      onUnauthorized?.call();
      throw const ApiException(
        AppStrings.sessionExpired,
        statusCode: 401,
      );
    }

    // 404 Not Found: ownership or missing entity
    if (response.statusCode == 404) {
      final detail = decoded is Map ? decoded['detail'] as String? : null;
      throw ApiException(
        detail ?? AppStrings.jobNotFound,
        statusCode: 404,
      );
    }

    // 400 Bad Request: extract server message detail
    if (response.statusCode == 400) {
      String message = 'Invalid request.';
      if (decoded is Map && decoded['detail'] != null) {
        message = decoded['detail'].toString();
      }
      throw ApiException(message, statusCode: 400);
    }

    // 500 or other errors
    String fallbackMessage = 'Server error (${response.statusCode}). Please try again later.';
    if (decoded is Map && decoded['detail'] != null) {
      fallbackMessage = decoded['detail'].toString();
    }
    throw ApiException(fallbackMessage, statusCode: response.statusCode);
  }
}

typedef VoidCallback = void Function();
