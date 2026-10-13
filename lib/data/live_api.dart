import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'live_models.dart';

/// Build-time settings. CI passes them with --dart-define; without them the app
/// runs on the built-in demo catalog.
class LiveConfig {
  static const base = String.fromEnvironment('CC_API_BASE');
  static const appKey = String.fromEnvironment('CC_APP_KEY');
  static bool get enabled => base.isNotEmpty;
}

class LiveApiException implements Exception {
  final String message;
  const LiveApiException(this.message);
  @override
  String toString() => message;
}

/// Talks to the Cunning Cat API (server/worker.js). Keys for SerpApi and Claude
/// live on that server, never in the app.
class LiveApi {
  LiveApi({http.Client? client, String base = LiveConfig.base, String appKey = LiveConfig.appKey})
      : _client = client ?? http.Client(),
        _base = base.replaceAll(RegExp(r'/+$'), ''),
        _appKey = appKey;

  final http.Client _client;
  final String _base;
  final String _appKey;

  Map<String, String> get _headers => {'x-cc-key': _appKey, 'content-type': 'application/json'};

  Future<List<LiveProduct>> search(String query) async {
    final j = await _get('/search', {'q': query});
    final list = j['products'];
    if (list is! List) return const [];
    return [
      for (final p in list)
        if (p is Map) LiveProduct.fromJson(Map<String, dynamic>.from(p)),
    ];
  }

  Future<LiveDetail> product(String token) async => LiveDetail.fromJson(await _get('/product', {'token': token}));

  Future<AiInsight> insights(String token) async => AiInsight.fromJson(await _get('/insights', {'token': token}));

  Future<AskAnswer> ask(String message, List<({String role, String text})> history) async {
    final body = jsonEncode({
      'message': message,
      'history': [for (final h in history) {'role': h.role, 'text': h.text}],
    });
    final res = await _send(() => _client.post(Uri.parse('$_base/ask'), headers: _headers, body: body),
        timeout: const Duration(seconds: 45));
    return AskAnswer.fromJson(res);
  }

  Future<Map<String, dynamic>> _get(String path, Map<String, String> query) {
    final uri = Uri.parse('$_base$path').replace(queryParameters: query);
    return _send(() => _client.get(uri, headers: _headers));
  }

  Future<Map<String, dynamic>> _send(Future<http.Response> Function() call,
      {Duration timeout = const Duration(seconds: 30)}) async {
    if (_base.isEmpty) throw const LiveApiException('Live search is not set up in this build.');
    http.Response res;
    try {
      res = await call().timeout(timeout);
    } on TimeoutException {
      throw const LiveApiException('The stores are slow to answer. Please try again.');
    } catch (_) {
      throw const LiveApiException('No internet connection, or the Cunning Cat server is unreachable.');
    }
    Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      decoded = null;
    }
    final map = decoded is Map ? Map<String, dynamic>.from(decoded) : <String, dynamic>{};
    if (res.statusCode != 200) {
      throw LiveApiException('${map['error'] ?? 'Server error ${res.statusCode}'}');
    }
    return map;
  }
}
