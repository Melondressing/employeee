import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pay_rule.dart';
import '../models/work_entry.dart';
import 'auth_service.dart';
import 'cloud_sync_service.dart';
import 'pay_calculator.dart';
import 'storage.dart';

final bootstrapPayRuleProvider = Provider<PayRule?>((_) => null);
final bootstrapWorkEntriesProvider = Provider<List<WorkEntry>?>((_) => null);

final payRuleProvider = StateNotifierProvider<PayRuleNotifier, PayRule>((ref) {
  return PayRuleNotifier(
    initialRule: ref.watch(bootstrapPayRuleProvider),
    ref: ref,
  );
});

class PayRuleNotifier extends StateNotifier<PayRule> {
  PayRuleNotifier({
    PayRule? initialRule,
    required Ref ref,
  })  : _ref = ref,
        super(initialRule ?? PayRule(baseWage: 25)) {
    if (initialRule == null) {
      _load();
    }
  }

  final Ref _ref;

  Future<void> reload() => _load();

  Future<void> _load() async {
    final saved = await Storage.loadRule();
    if (saved != null) state = saved;
  }

  Future<void> update(PayRule rule, {bool syncCloud = true}) async {
    state = rule;
    await Storage.saveRule(rule);
    if (syncCloud) _syncCloud(rule);
  }

  void _syncCloud(PayRule rule) {
    final session = _ref.read(authSessionProvider);
    if (session == null || !session.hasCloudToken) return;

    unawaited(
      _ref
          .read(employeeCloudApiProvider)
          .savePayRule(session: session, payRule: rule)
          .catchError((_) {}),
    );
  }
}

final workEntriesProvider =
    StateNotifierProvider<WorkEntriesNotifier, List<WorkEntry>>((ref) {
  return WorkEntriesNotifier(
    initialEntries: ref.watch(bootstrapWorkEntriesProvider),
    ref: ref,
  );
});

/// Offset in pay cycles: 0 = current, -1 = previous, +1 = next.
final cycleOffsetProvider = StateProvider<int>((_) => 0);

/// Custom manual date range; when non-null it overrides cycleOffset.
final customRangeProvider = StateProvider<DateTimeRange?>((_) => null);

class WorkEntriesNotifier extends StateNotifier<List<WorkEntry>> {
  WorkEntriesNotifier({
    List<WorkEntry>? initialEntries,
    required Ref ref,
  })  : _ref = ref,
        super(initialEntries ?? const []) {
    if (initialEntries == null) {
      _load();
    }
  }

  final Ref _ref;

  Future<void> reload() => _load();

  Future<void> _load() async {
    state = await Storage.loadEntries();
  }

  Future<void> add(WorkEntry entry) async {
    state = [...state, entry];
    await Storage.saveEntries(state);
    _syncCloud(state);
  }

  Future<void> update(WorkEntry updated) async {
    state = [
      for (final entry in state)
        if (entry.id == updated.id) updated else entry,
    ];
    await Storage.saveEntries(state);
    _syncCloud(state);
  }

  Future<void> remove(WorkEntry entry) async {
    state = state.where((e) => e.id != entry.id).toList();
    await Storage.saveEntries(state);
    _syncCloud(state);
  }

  Future<void> replaceAll(
    List<WorkEntry> entries, {
    bool syncCloud = true,
  }) async {
    state = entries;
    await Storage.saveEntries(state);
    if (syncCloud) _syncCloud(state);
  }

  /// Copy last 7 days of entries to next week (date +7).
  Future<List<WorkEntry>> copyLastWeekForward() async {
    if (state.isEmpty) return const [];
    final latest =
        state.map((e) => e.date).reduce((a, b) => a.isAfter(b) ? a : b);
    final weekStart = latest.subtract(Duration(days: latest.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final source = state
        .where((e) => !e.date.isBefore(weekStart) && !e.date.isAfter(weekEnd))
        .toList();
    if (source.isEmpty) return const [];
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
    _syncCloud(state);
    return copied;
  }

  void _syncCloud(List<WorkEntry> entries) {
    final session = _ref.read(authSessionProvider);
    if (session == null || !session.hasCloudToken) return;

    unawaited(
      _ref
          .read(employeeCloudApiProvider)
          .saveWorkEntries(session: session, workEntries: entries)
          .catchError((_) {}),
    );
  }
}

final payCalculatorProvider = Provider((ref) => PayCalculator());
