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
    if (_shouldPersistLocal) {
      await Storage.saveRule(rule);
    }
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

  bool get _shouldPersistLocal {
    final session = _ref.read(authSessionProvider);
    return session == null || session.isLocalOnly;
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
    if (_shouldPersistLocal) {
      await Storage.saveEntries(state);
    }
    _syncCloudEntry(entry);
  }

  Future<void> update(WorkEntry updated) async {
    state = [
      for (final entry in state)
        if (entry.id == updated.id) updated else entry,
    ];
    if (_shouldPersistLocal) {
      await Storage.saveEntries(state);
    }
    _syncCloudEntry(updated);
  }

  Future<void> remove(WorkEntry entry) async {
    state = state.where((e) => e.id != entry.id).toList();
    if (_shouldPersistLocal) {
      await Storage.saveEntries(state);
    }
    _deleteCloudEntry(entry);
  }

  Future<void> replaceAll(
    List<WorkEntry> entries, {
    bool syncCloud = true,
  }) async {
    state = entries;
    if (_shouldPersistLocal) {
      await Storage.saveEntries(state);
    }
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
    if (_shouldPersistLocal) {
      await Storage.saveEntries(state);
    }
    _syncCloudEntries(copied);
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

  void _syncCloudEntries(List<WorkEntry> entries) {
    for (final entry in entries) {
      _syncCloudEntry(entry);
    }
  }

  void _syncCloudEntry(WorkEntry entry) {
    final session = _ref.read(authSessionProvider);
    if (session == null || !session.hasCloudToken) return;

    unawaited(
      _ref
          .read(employeeCloudApiProvider)
          .saveWorkEntry(session: session, workEntry: entry)
          .catchError((_) {}),
    );
  }

  void _deleteCloudEntry(WorkEntry entry) {
    final session = _ref.read(authSessionProvider);
    if (session == null || !session.hasCloudToken) return;

    unawaited(
      _ref
          .read(employeeCloudApiProvider)
          .deleteWorkEntry(session: session, workEntry: entry)
          .catchError((_) {}),
    );
  }

  bool get _shouldPersistLocal {
    final session = _ref.read(authSessionProvider);
    return session == null || session.isLocalOnly;
  }
}

final payCalculatorProvider = Provider((ref) => PayCalculator());
