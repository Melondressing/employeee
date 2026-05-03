import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth_session.dart';
import '../models/pay_rule.dart';
import '../models/work_entry.dart';
import 'cloud_sync_service.dart';
import 'providers.dart';
import 'storage.dart';

class EmployeeeeCloudSyncCoordinator {
  EmployeeeeCloudSyncCoordinator._();

  static final Map<String, Future<void>> _inFlight = <String, Future<void>>{};

  static Future<void> sync(
    WidgetRef ref,
    AuthSession session, {
    bool includeDeviceData = false,
    bool clearDeviceDataAfterUpload = false,
  }) async {
    if (!session.hasCloudToken) return;

    final key = _syncKey(session);
    final running = _inFlight[key];
    if (running != null) {
      await running;
      if (!includeDeviceData) return;
    }

    final future = _syncNow(
      ref,
      session,
      includeDeviceData: includeDeviceData,
      clearDeviceDataAfterUpload: clearDeviceDataAfterUpload,
    );
    _inFlight[key] = future;
    try {
      await future;
    } finally {
      if (identical(_inFlight[key], future)) {
        _inFlight.remove(key);
      }
    }
  }

  static Future<void> _syncNow(
    WidgetRef ref,
    AuthSession session, {
    required bool includeDeviceData,
    required bool clearDeviceDataAfterUpload,
  }) async {
    final cloudApi = ref.read(employeeCloudApiProvider);
    final deviceData = includeDeviceData ? await Storage.loadBootstrap() : null;
    final cloud = await cloudApi.fetchBootstrap(session);

    final nextRule = _selectRule(
      includeDeviceData: includeDeviceData,
      deviceRule: deviceData?.rule,
      cloudRule: cloud.payRule,
    );
    final nextEntries = mergeWorkEntries(
      localEntries:
          includeDeviceData ? deviceData?.entries ?? const [] : const [],
      cloudEntries: cloud.workEntries,
      deletedEntries: cloud.deletedEntries,
    );

    await ref.read(payRuleProvider.notifier).update(
          nextRule,
          syncCloud: false,
        );
    await ref.read(workEntriesProvider.notifier).replaceAll(
          nextEntries,
          syncCloud: false,
        );

    if (includeDeviceData) {
      await cloudApi.sync(
        session: session,
        payRule: nextRule,
        workEntries: nextEntries,
      );
      if (clearDeviceDataAfterUpload) {
        await Storage.clearWorkData();
      }
    }
  }

  static List<WorkEntry> mergeWorkEntries({
    required List<WorkEntry> localEntries,
    required List<WorkEntry> cloudEntries,
    List<DeletedWorkEntry> deletedEntries = const [],
  }) {
    final byId = <String, WorkEntry>{};
    final deletedById = {
      for (final deletion in deletedEntries) deletion.entryId: deletion,
    };

    for (final entry in [...cloudEntries, ...localEntries]) {
      final deletion = deletedById[entry.id];
      if (deletion != null && !entry.updatedAt.isAfter(deletion.deletedAt)) {
        continue;
      }

      final existing = byId[entry.id];
      if (existing == null || entry.updatedAt.isAfter(existing.updatedAt)) {
        byId[entry.id] = entry;
      }
    }

    return byId.values.toList()
      ..sort((a, b) {
        final dateCompare = a.date.compareTo(b.date);
        if (dateCompare != 0) return dateCompare;
        final startCompare = a.start.compareTo(b.start);
        if (startCompare != 0) return startCompare;
        return a.id.compareTo(b.id);
      });
  }

  static String _syncKey(AuthSession session) {
    return session.accessToken ?? '${session.provider}:${session.userId}';
  }

  static PayRule _selectRule({
    required bool includeDeviceData,
    required PayRule? deviceRule,
    required PayRule? cloudRule,
  }) {
    if (includeDeviceData && deviceRule != null) return deviceRule;
    return cloudRule ?? PayRule(baseWage: 25);
  }
}
