import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// A small JSON client for the DummyJSON REST API.
class ApiServices {
  ApiServices({
    http.Client? client,
    String? Function()? accessTokenReader,
    Future<String?> Function()? accessTokenRefresher,
    Future<void> Function()? onRefreshFailure,
  })  : _client = client ?? http.Client(),
        _accessTokenReader = accessTokenReader,
        _accessTokenRefresher = accessTokenRefresher,
        _onRefreshFailure = onRefreshFailure;

  static const String baseUrl = 'https://dummyjson.com';

  final http.Client _client;
  final String? Function()? _accessTokenReader;
  final Future<String?> Function()? _accessTokenRefresher;
  final Future<void> Function()? _onRefreshFailure;
  Future<String?>? _refreshInFlight;

  Future<dynamic> get(
    String endpoint, {
    Map<String, Object?>? queryParameters,
    Map<String, String>? headers,
  }) {
    return _send(
      'GET',
      endpoint,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  Future<dynamic> post(
    String endpoint, {
    Object? body,
    Map<String, Object?>? queryParameters,
    Map<String, String>? headers,
  }) {
    return _send(
      'POST',
      endpoint,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  Future<dynamic> put(
    String endpoint, {
    Object? body,
    Map<String, Object?>? queryParameters,
    Map<String, String>? headers,
  }) {
    return _send(
      'PUT',
      endpoint,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  Future<dynamic> patch(
    String endpoint, {
    Object? body,
    Map<String, Object?>? queryParameters,
    Map<String, String>? headers,
  }) {
    return _send(
      'PATCH',
      endpoint,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  Future<dynamic> delete(
    String endpoint, {
    Object? body,
    Map<String, Object?>? queryParameters,
    Map<String, String>? headers,
  }) {
    return _send(
      'DELETE',
      endpoint,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  Future<dynamic> _send(
    String method,
    String endpoint, {
    Object? body,
    Map<String, Object?>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(endpoint, queryParameters);
    final stopwatch = Stopwatch()..start();
    _logApi('--> $method $uri');

    try {
      final hasExplicitToken = headers?.keys
              .any((key) => key.toLowerCase() == 'authorization') ??
          false;
      final explicitToken = _bearerToken(headers);
      var token = explicitToken ?? _accessTokenReader?.call();
      var response = await _sendOnce(
        method,
        uri,
        body: body,
        headers: headers,
        accessToken: token,
      );
      _logResponse(method, uri, response, stopwatch);

      if (response.statusCode == 401 &&
          token != null &&
          !_isAuthEndpoint(endpoint) &&
          _accessTokenRefresher != null) {
        _logApi('Access token expired; refreshing it before retry.');
        String? refreshedToken;
        var sessionEnded = false;
        try {
          refreshedToken = await _refreshAccessToken();
        } on ApiException catch (error) {
          if (error.statusCode != 401 && error.statusCode != 403) rethrow;
          _logApi('Refresh token expired; signing out.');
          await _onRefreshFailure?.call();
          sessionEnded = true;
        }
        if (refreshedToken == null) {
          if (!sessionEnded) await _onRefreshFailure?.call();
        } else {
          token = refreshedToken;
          _logApi('Retrying: $method $uri');
          response = await _sendOnce(
            method,
            uri,
            body: body,
            headers: hasExplicitToken ? headers : null,
            accessToken: token,
          );
          _logResponse(method, uri, response, stopwatch);
          if (response.statusCode == 401) {
            _logApi('Retried request was unauthorized; signing out.');
            await _onRefreshFailure?.call();
          }
        }
      }

      stopwatch.stop();
      return _decodeResponse(response);
    } catch (error) {
      if (stopwatch.isRunning) stopwatch.stop();
      if (error is ApiException) {
        _logApi('API error: ${error.message}');
      } else {
        _logApi(
          'Request failed: $method $uri '
          '(${stopwatch.elapsedMilliseconds} ms): $error',
        );
      }
      rethrow;
    }
  }

  Future<http.Response> _sendOnce(
    String method,
    Uri uri, {
    required Object? body,
    required Map<String, String>? headers,
    required String? accessToken,
  }) async {
    final requestHeaders = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      ...?headers,
    };
    if (accessToken != null && !_isAuthEndpoint(uri.path)) {
      requestHeaders['Authorization'] = 'Bearer $accessToken';
    }

    final request = http.Request(method, uri)..headers.addAll(requestHeaders);
    if (body != null) request.body = jsonEncode(body);

    final streamedResponse = await _client.send(request);
    return http.Response.fromStream(streamedResponse);
  }

  Future<String?> _refreshAccessToken() {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;
    final refresher = _accessTokenRefresher;
    if (refresher == null) return Future<String?>.value(null);
    final refresh = refresher();
    _refreshInFlight = refresh;
    return refresh.whenComplete(() => _refreshInFlight = null);
  }

  void _logResponse(
    String method,
    Uri uri,
    http.Response response,
    Stopwatch stopwatch,
  ) {
    final succeeded = response.statusCode >= 200 && response.statusCode < 300;
    _logApi(
      '${succeeded ? '<--' : '<!!'} ${response.statusCode} $method $uri '
      '(${stopwatch.elapsedMilliseconds} ms)',
    );
  }

  bool _isAuthEndpoint(String endpoint) {
    final path = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return path == 'auth/login' || path == 'auth/refresh';
  }

  String? _bearerToken(Map<String, String>? headers) {
    if (headers == null) return null;
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == 'authorization' &&
          entry.value.toLowerCase().startsWith('bearer ')) {
        return entry.value.substring(7).trim();
      }
    }
    return null;
  }

  void _logApi(String message) {
    if (kDebugMode) debugPrint('[API] $message');
  }

  Uri _buildUri(String endpoint, Map<String, Object?>? queryParameters) {
    final path = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    final uri = Uri.parse('$baseUrl/$path');
    if (queryParameters == null || queryParameters.isEmpty) return uri;

    final parameters = Map<String, String>.from(uri.queryParameters);
    for (final entry in queryParameters.entries) {
      final value = entry.value;
      if (value == null) {
        parameters.remove(entry.key);
      } else {
        parameters[entry.key] = value.toString();
      }
    }
    return uri.replace(queryParameters: parameters);
  }

  dynamic _decodeResponse(http.Response response) {
    final responseText = response.body.trim();
    dynamic data;

    if (responseText.isNotEmpty) {
      try {
        data = jsonDecode(responseText);
      } on FormatException {
        data = responseText;
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data is Map<String, dynamic>
          ? (data['message'] ?? data['error'] ?? response.reasonPhrase)
          : (data ?? response.reasonPhrase);
      throw ApiException(
        statusCode: response.statusCode,
        message: message?.toString() ?? 'Request failed',
      );
    }

    return data;
  }

  /// Close the underlying HTTP client when this service is no longer needed.
  void close() => _client.close();
}

class ApiException implements Exception {
  const ApiException({required this.statusCode, required this.message});

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException ($statusCode): $message';
}
