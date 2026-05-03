import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../models/auth_session.dart';
import '../models/pay_rule.dart';
import '../models/work_entry.dart';
import 'auth_service.dart';

final employeeCloudApiProvider = Provider((_) => const EmployeeCloudApi());

class EmployeeCloudApi {
  const EmployeeCloudApi();

  Future<EmployeeCloudBootstrap> fetchBootstrap(AuthSession session) async {
    final response = await http
        .get(
          _uri(session, '/api/employeeee/bootstrap'),
          headers: _headers(session),
        )
        .timeout(const Duration(seconds: 12));

    final body = _decodeResponse(response);
    final data = _jsonMap(body['data']);
    return EmployeeCloudBootstrap.fromJson(data);
  }

  Future<EmployeeCloudBootstrap> sync({
    required AuthSession session,
    required PayRule payRule,
    required List<WorkEntry> workEntries,
  }) async {
    final response = await http
        .put(
          _uri(session, '/api/employeeee/sync'),
          headers: _headers(session),
          body: jsonEncode({
            'pay_rule': payRule.toJson(),
            'work_entries': workEntries.map((entry) => entry.toJson()).toList(),
          }),
        )
        .timeout(const Duration(seconds: 12));

    final body = _decodeResponse(response);
    final data = _jsonMap(body['data']);
    return EmployeeCloudBootstrap.fromJson(data);
  }

  Future<void> savePayRule({
    required AuthSession session,
    required PayRule payRule,
  }) async {
    final response = await http
        .put(
          _uri(session, '/api/employeeee/pay-rule'),
          headers: _headers(session),
          body: jsonEncode({'pay_rule': payRule.toJson()}),
        )
        .timeout(const Duration(seconds: 12));
    _decodeResponse(response);
  }

  Future<void> saveWorkEntries({
    required AuthSession session,
    required List<WorkEntry> workEntries,
  }) async {
    final response = await http
        .put(
          _uri(session, '/api/employeeee/work-entries'),
          headers: _headers(session),
          body: jsonEncode({
            'work_entries': workEntries.map((entry) => entry.toJson()).toList(),
          }),
        )
        .timeout(const Duration(seconds: 12));
    _decodeResponse(response);
  }

  Uri _uri(AuthSession session, String path) {
    final baseUrl = (session.apiBaseUrl?.isNotEmpty == true)
        ? session.apiBaseUrl!
        : AuthApiClient.defaultBaseUrl;
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$base$path');
  }

  Map<String, String> _headers(AuthSession session) {
    final token = session.accessToken;
    if (token == null || token.isEmpty) {
      throw const AuthException('클라우드 저장에는 공통 계정 로그인이 필요해요.');
    }

    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AuthException('employeeee 클라우드 응답을 이해하지 못했어요.');
    }

    final success = decoded['success'] == true;
    if (response.statusCode < 200 || response.statusCode >= 300 || !success) {
      throw AuthException(
        decoded['error']?.toString() ??
            decoded['message']?.toString() ??
            'employeeee 클라우드 저장에 실패했어요.',
      );
    }
    return decoded;
  }

  Map<String, dynamic> _jsonMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }
}

class EmployeeCloudBootstrap {
  const EmployeeCloudBootstrap({
    required this.payRule,
    required this.workEntries,
  });

  final PayRule? payRule;
  final List<WorkEntry> workEntries;

  bool get isEmpty => payRule == null && workEntries.isEmpty;

  factory EmployeeCloudBootstrap.fromJson(Map<String, dynamic> json) {
    final rawRule = json['pay_rule'];
    final rawEntries = json['work_entries'];

    return EmployeeCloudBootstrap(
      payRule: rawRule is Map
          ? PayRule.fromJson(
              rawRule.map((key, value) => MapEntry(key.toString(), value)),
            )
          : null,
      workEntries: rawEntries is List
          ? rawEntries
              .whereType<Map>()
              .map(
                (entry) => WorkEntry.fromJson(
                  entry.map((key, value) => MapEntry(key.toString(), value)),
                ),
              )
              .toList()
          : const [],
    );
  }
}
