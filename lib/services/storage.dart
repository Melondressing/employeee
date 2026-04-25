import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/pay_rule.dart';
import '../models/work_entry.dart';

class Storage {
  static const _ruleKey = 'pay_rule';
  static const _entriesKey = 'work_entries';
  static const _backupVersion = 1;

  static Future<void> saveRule(PayRule rule) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ruleKey, jsonEncode(rule.toJson()));
  }

  static Future<PayRule?> loadRule() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_ruleKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return PayRule.fromJson(decoded);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveEntries(List<WorkEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final list = entries.map((e) => e.toJson()).toList();
    await prefs.setString(_entriesKey, jsonEncode(list));
  }

  static Future<List<WorkEntry>> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_entriesKey);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(WorkEntry.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<String> exportBackup() async {
    final prefs = await SharedPreferences.getInstance();
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

      final prefs = await SharedPreferences.getInstance();
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
}
