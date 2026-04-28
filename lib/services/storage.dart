import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/pay_rule.dart';
import '../models/work_entry.dart';

class Storage {
  static const _ruleKey = 'pay_rule';
  static const _entriesKey = 'work_entries';
  static const _backupVersion = 1;
  static Future<SharedPreferences>? _prefsFuture;

  static Future<void> init() async {
    await _prefs;
  }

  static void resetCache() {
    _prefsFuture = null;
  }

  static Future<StorageBootstrapData> loadBootstrap() async {
    final prefs = await _prefs;
    return StorageBootstrapData(
      rule: _decodeRule(prefs.getString(_ruleKey)),
      entries: _decodeEntries(prefs.getString(_entriesKey)),
    );
  }

  static Future<void> saveRule(PayRule rule) async {
    final prefs = await _prefs;
    await prefs.setString(_ruleKey, jsonEncode(rule.toJson()));
  }

  static Future<PayRule?> loadRule() async {
    final prefs = await _prefs;
    return _decodeRule(prefs.getString(_ruleKey));
  }

  static Future<void> saveEntries(List<WorkEntry> entries) async {
    final prefs = await _prefs;
    final list = entries.map((e) => e.toJson()).toList();
    await prefs.setString(_entriesKey, jsonEncode(list));
  }

  static Future<List<WorkEntry>> loadEntries() async {
    final prefs = await _prefs;
    return _decodeEntries(prefs.getString(_entriesKey));
  }

  static Future<String> exportBackup() async {
    final prefs = await _prefs;
    final payload = <String, dynamic>{
      'version': _backupVersion,
      'pay_rule': _decodeJson(prefs.getString(_ruleKey)),
      'work_entries': _decodeJson(prefs.getString(_entriesKey)) ?? [],
    };
    return jsonEncode(payload);
  }

  static Future<bool> importBackup(String raw) async {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return false;

      final prefs = await _prefs;
      final rule = decoded['pay_rule'];
      final entries = decoded['work_entries'];

      if (rule is Map) {
        await prefs.setString(_ruleKey, jsonEncode(rule));
      }
      if (entries is List) {
        await prefs.setString(_entriesKey, jsonEncode(entries));
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static dynamic _decodeJson(String? raw) {
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  static PayRule? _decodeRule(String? raw) {
    final decoded = _decodeJson(raw);
    if (decoded is Map<String, dynamic>) {
      return PayRule.fromJson(decoded);
    }
    return null;
  }

  static List<WorkEntry> _decodeEntries(String? raw) {
    final decoded = _decodeJson(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(WorkEntry.fromJson)
        .toList();
  }

  static Future<SharedPreferences> get _prefs {
    return _prefsFuture ??= SharedPreferences.getInstance();
  }
}

class StorageBootstrapData {
  const StorageBootstrapData({
    required this.rule,
    required this.entries,
  });

  final PayRule? rule;
  final List<WorkEntry> entries;
}
