import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pay_rule.dart';
import '../models/work_entry.dart';
import 'pay_calculator.dart';
import 'storage.dart';

final payRuleProvider = StateNotifierProvider<PayRuleNotifier, PayRule>((ref) {
  return PayRuleNotifier();
});

class PayRuleNotifier extends StateNotifier<PayRule> {
  PayRuleNotifier() : super(PayRule(baseWage: 25)) {
    _load();
  }

  Future<void> reload() => _load();

  Future<void> _load() async {
    final saved = await Storage.loadRule();
    if (saved != null) state = saved;
  }

  Future<void> update(PayRule rule) async {
    state = rule;
    await Storage.saveRule(rule);
  }
}

final workEntriesProvider =
    StateNotifierProvider<WorkEntriesNotifier, List<WorkEntry>>((ref) {
  return WorkEntriesNotifier();
});

/// Offset in pay cycles: 0 = current, -1 = previous, +1 = next.
final cycleOffsetProvider = StateProvider<int>((_) => 0);

/// Custom manual date range; when non-null it overrides cycleOffset.
final customRangeProvider = StateProvider<DateTimeRange?>((_) => null);

class WorkEntriesNotifier extends StateNotifier<List<WorkEntry>> {
  WorkEntriesNotifier() : super(const []) {
    _load();
  }

  Future<void> reload() => _load();

  Future<void> _load() async {
    state = await Storage.loadEntries();
  }

  Future<void> add(WorkEntry entry) async {
    state = [...state, entry];
    await Storage.saveEntries(state);
  }

  Future<void> update(WorkEntry updated) async {
    state = [
      for (final entry in state)
        if (entry.id == updated.id) updated else entry,
    ];
    await Storage.saveEntries(state);
  }

  Future<void> remove(WorkEntry entry) async {
    state = state.where((e) => e.id != entry.id).toList();
    await Storage.saveEntries(state);
  }

  /// Copy last 7 days of entries to next week (date +7).
  Future<void> copyLastWeekForward() async {
    if (state.isEmpty) return;
    final latest =
        state.map((e) => e.date).reduce((a, b) => a.isAfter(b) ? a : b);
    final weekStart = latest.subtract(Duration(days: latest.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final source = state
        .where((e) => !e.date.isBefore(weekStart) && !e.date.isAfter(weekEnd))
        .toList();
    if (source.isEmpty) return;
    final now = DateTime.now();
    final copied = source
        .map(
          (e) => e.copyWith(
            id: WorkEntry.generateId(),
            date: e.date.add(const Duration(days: 7)),
            start: e.start.add(const Duration(days: 7)),
            end: e.end.add(const Duration(days: 7)),
            createdAt: now,
            updatedAt: now,
          ),
        )
        .toList();
    state = [...state, ...copied];
    await Storage.saveEntries(state);
  }
}

final payCalculatorProvider = Provider((ref) => PayCalculator());
