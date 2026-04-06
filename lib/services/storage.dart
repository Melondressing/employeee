import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/pay_rule.dart';
import '../models/work_entry.dart';

class Storage {
  static const _ruleKey = 'pay_rule';
  static const _entriesKey = 'work_entries';

  static Future<void> saveRule(PayRule rule) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ruleKey, jsonEncode(rule.toJson()));
  }

  static Future<PayRule?> loadRule() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_ruleKey);
    if (raw == null) return null;
    return PayRule.fromJson(jsonDecode(raw));
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
    final list = (jsonDecode(raw) as List<dynamic>)
        .map((e) => WorkEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }
}
