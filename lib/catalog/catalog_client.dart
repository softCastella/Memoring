import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// 로컬 테스트 카탈로그 HTTP 클라이언트.
class CatalogClient {
  CatalogClient({
    String? baseUrl,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 60),
    List<String>? fallbacks,
  }) : baseUrl = (baseUrl ?? AppConfig.catalogUrl).replaceAll(RegExp(r'/$'), ''),
       _fallbacks = [
         for (final raw in fallbacks ?? AppConfig.catalogFallbacks.split(','))
           raw.trim(),
       ],
       _http = httpClient ?? http.Client();

  final String baseUrl;
  final Duration timeout;
  final http.Client _http;
  final List<String> _fallbacks;

  String? lastError;
  String? activeBaseUrl;

  Iterable<String> get _baseUrls sync* {
    final seen = <String>{};
    for (final raw in [
      'http://127.0.0.1:8090',
      baseUrl,
      'http://localhost:8090',
      'http://10.0.2.2:8090',
      ..._fallbacks,
    ]) {
      final url = raw.replaceAll(RegExp(r'/$'), '');
      if (url.isEmpty || !seen.add(url)) {
        continue;
      }
      yield url;
    }
  }

  Future<Map<String, dynamic>?> pull() async {
    lastError = null;
    for (final url in _baseUrls) {
      try {
        final response = await _http
            .get(Uri.parse('$url/catalog'))
            .timeout(timeout);
        if (response.statusCode != 200) {
          lastError = '카탈로그 서버가 $url 에서 응답하지 않았어요.';
          continue;
        }
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          activeBaseUrl = url;
          lastError = null;
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        lastError = '카탈로그 서버($url)에 연결하지 못했어요.';
      }
    }
    return null;
  }

  Future<bool> push(Map<String, dynamic> body) async {
    final encoded = jsonEncode(body);
    for (final url in _baseUrls) {
      try {
        final response = await _http
            .put(
              Uri.parse('$url/catalog'),
              headers: const {'Content-Type': 'application/json'},
              body: encoded,
            )
            .timeout(timeout);
        if (response.statusCode == 200) {
          activeBaseUrl = url;
          return true;
        }
      } catch (_) {}
    }
    return false;
  }
}
