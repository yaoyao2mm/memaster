import 'dart:convert';

import 'package:http/http.dart' as http;

class LocalApiClient {
  LocalApiClient({
    http.Client? httpClient,
    String? baseUrl,
  })  : _httpClient = httpClient ?? http.Client(),
        _baseUrl = baseUrl ??
            const String.fromEnvironment(
              'LOCAL_API_BASE_URL',
              defaultValue: 'http://127.0.0.1:4318',
            );

  final http.Client _httpClient;
  final String _baseUrl;

  Future<Map<String, dynamic>> getJson(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await _httpClient.get(uri).timeout(
          const Duration(milliseconds: 800),
        );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Request failed: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await _httpClient
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 5));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Request failed: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
