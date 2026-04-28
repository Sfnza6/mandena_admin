import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../controllers/AuthController.dart';
import '../../controllers/admin_branch_scope_controller.dart';
import '../config/env.dart';

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  Duration timeout = const Duration(seconds: 25);

  String _absUrl(String url) => Env.url(url);

  int? _currentBranchId() {
    try {
      if (Get.isRegistered<AdminBranchScopeController>()) {
        final id = Get.find<AdminBranchScopeController>().effectiveBranchId;
        if (id != null && id > 0) return id;
      }
    } catch (_) {}

    try {
      if (Get.isRegistered<AuthController>()) {
        final id = Get.find<AuthController>().currentBranchId;
        if (id != null && id > 0) return id;
      }
    } catch (_) {}

    return null;
  }

  String? _currentToken() {
    try {
      if (Get.isRegistered<AuthController>()) {
        final t = Get.find<AuthController>().token;
        if (t != null && t.isNotEmpty) return t;
      }
    } catch (_) {}
    return null;
  }

  Map<String, String> _appendBranchToQuery(Map<String, String>? query) {
    final branchId = _currentBranchId();
    final token = _currentToken();
    final merged = <String, String>{...?query};

    if (branchId != null && branchId > 0 && !merged.containsKey('branch_id')) {
      merged['branch_id'] = '$branchId';
    }
    if (token != null && token.isNotEmpty && !merged.containsKey('token')) {
      merged['token'] = token;
    }
    return merged;
  }

  Map<String, String> _appendBranchToBody(Map<String, String>? body) {
    final branchId = _currentBranchId();
    final token = _currentToken();
    final merged = <String, String>{...?body};

    if (branchId != null && branchId > 0 && !merged.containsKey('branch_id')) {
      merged['branch_id'] = '$branchId';
    }
    if (token != null && token.isNotEmpty && !merged.containsKey('token')) {
      merged['token'] = token;
    }
    return merged;
  }

  Map<String, dynamic> _appendBranchToJson(Map<String, dynamic>? body) {
    final branchId = _currentBranchId();
    final token = _currentToken();
    final merged = <String, dynamic>{...?body};

    if (branchId != null && branchId > 0 && !merged.containsKey('branch_id')) {
      merged['branch_id'] = branchId;
    }
    if (token != null && token.isNotEmpty && !merged.containsKey('token')) {
      merged['token'] = token;
    }
    return merged;
  }

  Future<dynamic> get(
    String url, {
    Map<String, String>? query,
    bool includeToken = false,
    String? token,
    Map<String, String>? headers,
  }) async {
    final abs = _absUrl(url);
    final uri = Uri.parse(abs).replace(
      queryParameters: _appendBranchToQuery({
        if (query != null) ...query,
        if (includeToken && token != null && token.isNotEmpty) 'token': token,
      }),
    );
    debugPrint('[GET] $uri');

    final r = await _client
        .get(uri, headers: _mergedHeaders(headers))
        .timeout(timeout);
    return _decode(r, uri, unwrap: true);
  }

  Future<dynamic> postForm(
    String url,
    Map<String, String> body, {
    bool includeToken = false,
    String? token,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse(_absUrl(url));
    final b = _appendBranchToBody({
      ...body,
      if (includeToken && token != null && token.isNotEmpty) 'token': token,
    });

    debugPrint('[POST:FORM] $uri body=$b');

    final r = await _client
        .post(
          uri,
          headers: _mergedHeaders({
            'Content-Type': 'application/x-www-form-urlencoded',
            ...?headers,
          }),
          body: b,
        )
        .timeout(timeout);

    return _decode(r, uri, unwrap: false);
  }

  Future<dynamic> postJson(
    String url,
    Map<String, dynamic> body, {
    bool includeToken = false,
    String? token,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse(_absUrl(url));
    final payload = _appendBranchToJson({
      ...body,
      if (includeToken && token != null && token.isNotEmpty) 'token': token,
    });

    debugPrint('[POST:JSON] $uri body=$payload');

    final r = await _client
        .post(
          uri,
          headers: _mergedHeaders({
            'Content-Type': 'application/json',
            ...?headers,
          }),
          body: jsonEncode(payload),
        )
        .timeout(timeout);

    return _decode(r, uri, unwrap: false);
  }

  Future<dynamic> post(
    String url, {
    Map<String, String>? body,
    bool json = false,
    bool includeToken = false,
    String? token,
    Map<String, String>? headers,
  }) async {
    if (json) {
      return await postJson(
        url,
        Map<String, dynamic>.from(body ?? {}),
        includeToken: includeToken,
        token: token,
        headers: headers,
      );
    }

    return await postForm(
      url,
      body ?? {},
      includeToken: includeToken,
      token: token,
      headers: headers,
    );
  }

  Future<dynamic> uploadFile(
    String url, {
    required String filePath,
    String fieldName = 'image',
    Map<String, String>? extraFields,
  }) async {
    final uri = Uri.parse(_absUrl(url));

    final req = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath(fieldName, filePath));

    req.headers.addAll(_mergedHeaders(null));
    req.fields.addAll(_appendBranchToBody(extraFields));

    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();

    try {
      return json.decode(body);
    } catch (_) {
      return body;
    }
  }

  Future<dynamic> postMultipart(
    String url, {
    required Map<String, String> fields,
    required String filePath,
    String fieldName = 'image',
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse(_absUrl(url));

    final req = http.MultipartRequest('POST', uri);
    req.headers.addAll(_mergedHeaders(headers));
    req.fields.addAll(_appendBranchToBody(fields));
    req.files.add(await http.MultipartFile.fromPath(fieldName, filePath));

    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();

    final resp = http.Response(
      body,
      streamed.statusCode,
      request: http.Request('POST', uri),
    );
    return _decode(resp, uri, unwrap: false);
  }

  Map<String, String> _mergedHeaders(Map<String, String>? extra) {
    final branchId = _currentBranchId();
    final token = _currentToken();

    return {
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      if (branchId != null && branchId > 0) 'X-Branch-Id': '$branchId',
      ...?extra,
    };
  }

  bool _isHtml(String text) {
    if (text.isEmpty) return false;
    final t = text.trimLeft();
    return t.startsWith('<!DOCTYPE') ||
        t.startsWith('<html') ||
        (t.startsWith('<') && !t.startsWith('{') && !t.startsWith('['));
  }

  dynamic _tryTopLevelDoubleDecode(String text) {
    final t = text.trim();
    final looksQuotedJson =
        (t.startsWith('"{') && t.endsWith('}"')) ||
        (t.startsWith('"[') && t.endsWith(']"')) ||
        (t.startsWith('"') && (t.contains(r'\"{') || t.contains(r'\"[')));

    if (!looksQuotedJson) return null;

    try {
      final once = jsonDecode(t);
      if (once is String) {
        return jsonDecode(once);
      }
    } catch (_) {}
    return null;
  }

  dynamic _decode(http.Response r, Uri uri, {required bool unwrap}) {
    final raw0 = r.body;
    final text0 = raw0.isNotEmpty && raw0.codeUnitAt(0) == 0xFEFF
        ? raw0.substring(1)
        : raw0;
    final text = text0.trim();

    debugPrint('[HTTP ${r.statusCode}] ${uri.toString()} BODY: ${_peek(text)}');

    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw 'HTTP ${r.statusCode} for $uri\n${_peek(text)}';
    }

    if (_isHtml(text)) {
      throw 'Non-JSON response from $uri\n${_peek(text)}';
    }

    final topLevel = _tryTopLevelDoubleDecode(text);
    if (topLevel != null) {
      final j = topLevel;
      if (unwrap &&
          j is Map &&
          j.containsKey('status') &&
          j.containsKey('data')) {
        return j['data'];
      }
      return j;
    }

    try {
      var j = jsonDecode(text);

      if (j is Map && j['data'] is String) {
        final inner = (j['data'] as String).trim();
        if (inner.isNotEmpty &&
            ((inner.startsWith('{') && inner.endsWith('}')) ||
                (inner.startsWith('[') && inner.endsWith(']')))) {
          try {
            j['data'] = jsonDecode(inner);
          } catch (_) {}
        }
      }

      if (unwrap &&
          j is Map &&
          j.containsKey('status') &&
          j.containsKey('data')) {
        return j['data'];
      }

      return j;
    } catch (_) {
      throw 'JSON parse error from $uri\n${_peek(text)}';
    }
  }

  String _peek(String s) => s.length <= 300 ? s : ('${s.substring(0, 300)} …');
}
