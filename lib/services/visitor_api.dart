import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/visitor.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class VisitorApi {
  VisitorApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Uri _uri([String? id]) {
    final base = '${ApiConfig.baseUrl}/${ApiConfig.resource}';
    return Uri.parse(id == null ? base : '$base/${Uri.encodeComponent(id)}');
  }

  Future<dynamic> _send(Future<http.Response> Function() call) async {
    if (!ApiConfig.isConfigured) {
      throw const ApiException(
          'MockAPI URL is not set. Edit ApiConfig.baseUrl in api_config.dart.');
    }
    try {
      final res = await call().timeout(ApiConfig.timeout);
      final code = res.statusCode;
      if (code >= 200 && code < 300) {
        if (res.body.trim().isEmpty) return null;
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
      if (code == 404) {
        throw const ApiException('Not found on server (404).', statusCode: 404);
      }
      if (code == 429) {
        throw const ApiException('Too many requests. Wait a moment and retry.',
            statusCode: 429);
      }
      throw ApiException('Server error ($code). Please try again.',
          statusCode: code);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('Request timed out. Check your connection.');
    } on SocketException {
      throw const ApiException('No internet connection.');
    } on http.ClientException {
      throw const ApiException('Could not reach the server.');
    } on FormatException {
      throw const ApiException('Unexpected response from the server.');
    }
  }

  Visitor _parseOne(dynamic body) {
    if (body is! Map) {
      throw const ApiException('Unexpected response from the server.');
    }
    return Visitor.fromJson(Map<String, dynamic>.from(body));
  }

  // GET /visitors
  Future<List<Visitor>> getAll() async {
    try {
      final body = await _send(() => _client.get(_uri(), headers: _headers));
      if (body == null) return [];
      if (body is! List) {
        throw const ApiException('Unexpected response from the server.');
      }
      return body
          .whereType<Map>()
          .map((e) => Visitor.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw const ApiException(
            'Endpoint not found. Check baseUrl and that the resource is named "visitors".',
            statusCode: 404);
      }
      rethrow;
    }
  }

  Future<Visitor> getById(String id) async {
    try {
      final body =
          await _send(() => _client.get(_uri(id), headers: _headers));
      return _parseOne(body);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw const ApiException('Visitor not found', statusCode: 404);
      }
      rethrow;
    }
  }

  Future<Visitor> create(Visitor v) async {
    final body = await _send(() =>
        _client.post(_uri(), headers: _headers, body: jsonEncode(v.toJson())));
    final created = _parseOne(body);
    if (created.id.isEmpty) {
      throw const ApiException('Server did not return a visitor ID.');
    }
    return created;
  }

  // PUT /visitors/:id
  Future<Visitor> update(Visitor v) async {
    final body = await _send(() => _client.put(_uri(v.id),
        headers: _headers, body: jsonEncode(v.toJson())));
    return _parseOne(body);
  }

  Future<void> delete(String id) async {
    await _send(() => _client.delete(_uri(id), headers: _headers));
  }
}