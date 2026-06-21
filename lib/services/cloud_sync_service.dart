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

  Future<void> saveWorkEntry({
    required AuthSession session,
    required WorkEntry workEntry,
  }) async {
    final response = await http
        .put(
          _uri(
            session,
            '/api/employeeee/work-entries/${Uri.encodeComponent(workEntry.id)}',
          ),
          headers: _headers(session),
          body: jsonEncode({'work_entry': workEntry.toJson()}),
        )
        .timeout(const Duration(seconds: 12));
    _decodeResponse(response);
  }

  Future<void> deleteWorkEntry({
    required AuthSession session,
    required WorkEntry workEntry,
  }) async {
    final response = await http
        .delete(
          _uri(
            session,
            '/api/employeeee/work-entries/${Uri.encodeComponent(workEntry.id)}',
          ),
          headers: _headers(session),
        )
        .timeout(const Duration(seconds: 12));
    _decodeResponse(response);
  }

  Future<BudgetExportResult> exportPayRunToBudget({
    required AuthSession session,
    required Map<String, dynamic> payload,
  }) async {
    final response = await http
        .post(
          _uri(session, '/api/employeeee/pay-runs/export-budget'),
          headers: _headers(session),
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 12));

    final body = _decodeResponse(response);
    final data = _jsonMap(body['data']);
    return BudgetExportResult.fromJson(data);
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
      throw const AuthException('eymployeee 클라우드 응답을 이해하지 못했어요.');
    }

    final success = decoded['success'] == true;
    if (response.statusCode < 200 || response.statusCode >= 300 || !success) {
      throw AuthException(
        decoded['error']?.toString() ??
            decoded['message']?.toString() ??
            'eymployeee 클라우드 저장에 실패했어요.',
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

class BudgetExportResult {
  const BudgetExportResult({
    required this.alreadyExported,
    required this.payRunId,
    required this.transactionId,
  });

  final bool alreadyExported;
  final int? payRunId;
  final int? transactionId;

  factory BudgetExportResult.fromJson(Map<String, dynamic> json) {
    return BudgetExportResult(
      alreadyExported: json['already_exported'] == true,
      payRunId: _parseInt(json['pay_run_id']),
      transactionId: _parseInt(json['transaction_id']),
    );
  }

  static int? _parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class EmployeeCloudBootstrap {
  const EmployeeCloudBootstrap({
    required this.payRule,
    required this.workEntries,
    required this.deletedEntries,
  });

  final PayRule? payRule;
  final List<WorkEntry> workEntries;
  final List<DeletedWorkEntry> deletedEntries;

  bool get isEmpty =>
      payRule == null && workEntries.isEmpty && deletedEntries.isEmpty;

  factory EmployeeCloudBootstrap.fromJson(Map<String, dynamic> json) {
    final rawRule = json['pay_rule'];
    final rawEntries = json['work_entries'];
    final rawDeletedEntries = json['deleted_entries'];

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
      deletedEntries: rawDeletedEntries is List
          ? rawDeletedEntries
              .whereType<Map>()
              .map(
                (entry) => DeletedWorkEntry.fromJson(
                  entry.map((key, value) => MapEntry(key.toString(), value)),
                ),
              )
              .where((entry) => entry.entryId.isNotEmpty)
              .toList()
          : const [],
    );
  }
}

class DeletedWorkEntry {
  const DeletedWorkEntry({
    required this.entryId,
    required this.deletedAt,
  });

  final String entryId;
  final DateTime deletedAt;

  factory DeletedWorkEntry.fromJson(Map<String, dynamic> json) {
    return DeletedWorkEntry(
      entryId: (json['entry_id'] ?? json['entryId'] ?? '').toString(),
      deletedAt: _parseDeletedAt(json['deleted_at'] ?? json['deletedAt']),
    );
  }

  static DateTime _parseDeletedAt(Object? value) {
    final raw = value?.toString() ?? '';
    return DateTime.tryParse(raw) ??
        DateTime.tryParse(raw.replaceFirst(' ', 'T')) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }
}
