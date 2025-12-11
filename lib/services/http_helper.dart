import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// HttpHelper provides methods for making authenticated HTTP requests
/// with automatic token refresh on 401 responses
class HttpHelper {
  static final HttpHelper _instance = HttpHelper._internal();

  final AuthService _authService = AuthService();

  HttpHelper._internal();

  factory HttpHelper() {
    return _instance;
  }

  /// Make a GET request with automatic token refresh
  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    final finalHeaders = await addBearerToken(headers);
    return _requestWithTokenRefresh(
      () => http.get(url, headers: finalHeaders),
    );
  }

  /// Make a POST request with automatic token refresh
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    final finalHeaders = await addBearerToken(headers);
    return _requestWithTokenRefresh(
      () => http.post(
        url,
        headers: finalHeaders,
        body: body,
      ),
    );
  }

  /// Make a PATCH request with automatic token refresh
  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    final finalHeaders = await addBearerToken(headers);
    return _requestWithTokenRefresh(
      () => http.patch(
        url,
        headers: finalHeaders,
        body: body,
      ),
    );
  }

  /// Make a PUT request with automatic token refresh
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    final finalHeaders = await addBearerToken(headers);
    return _requestWithTokenRefresh(
      () => http.put(
        url,
        headers: finalHeaders,
        body: body,
      ),
    );
  }

  /// Make a DELETE request with automatic token refresh
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    final finalHeaders = await addBearerToken(headers);
    return _requestWithTokenRefresh(
      () => http.delete(url, headers: finalHeaders),
    );
  }

  /// Internal method that handles token refresh on 401 responses
  Future<http.Response> _requestWithTokenRefresh(
    Future<http.Response> Function() requestFn,
  ) async {
    try {
      var response = await requestFn();

      // If unauthorized, try to refresh token and retry
      if (response.statusCode == 401) {
        print('Got 401 Unauthorized, attempting token refresh...');
        final refreshed = await _authService.refreshAccessToken();

        if (refreshed) {
          print('Token refreshed, retrying request...');
          response = await requestFn();
        } else {
          print('Token refresh failed, logging out user');
          await _authService.logout();
        }
      }

      return response;
    } catch (e) {
      print('Error in HTTP request: $e');
      rethrow;
    }
  }

  /// Set the authorization bearer token in headers
  Future<Map<String, String>> addBearerToken(
    Map<String, String>? headers,
  ) async {
    final token = await _authService.getAccessToken();
    final finalHeaders = {
      'Content-Type': 'application/json',
      ...?headers,
    };

    if (token != null) {
      finalHeaders['Authorization'] = 'Bearer $token';
    }

    return finalHeaders;
  }
}
