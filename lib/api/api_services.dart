import 'dart:convert';

import 'package:http/http.dart' as http;

/// A small JSON client for the DummyJSON REST API.
class ApiServices {
  ApiServices({http.Client? client}) : _client = client ?? http.Client();

  static const String baseUrl = 'https://dummyjson.com';

  final http.Client _client;

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
    final request = http.Request(method, _buildUri(endpoint, queryParameters))
      ..headers.addAll({
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        ...?headers,
      });

    if (body != null) {
      request.body = jsonEncode(body);
    }

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    return _decodeResponse(response);
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
