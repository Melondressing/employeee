import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth_session.dart';
import '../models/work_entry.dart';
import 'cloud_sync_service.dart';
import 'providers.dart';

class EmployeeeeCloudSyncCoordinator {
  EmployeeeeCloudSyncCoordinator._();

  static final Set<String> _inFlight = <String>{};

  static Future<void> sync(WidgetRef ref, AuthSession session) async {
    if (!session.hasCloudToken) return;

    final key = _syncKey(session);
    if (_inFlight.contains(key)) return;

    _inFlight.add(key);
    try {
      final cloudApi = ref.read(employeeCloudApiProvider);
      final localRule = ref.read(payRuleProvider);
      final localEntries = ref.read(workEntriesProvider);
      final cloud = await cloudApi.fetchBootstrap(session);

      final nextRule = cloud.payRule ?? localRule;
      final nextEntries = mergeWorkEntries(
        localEntries: localEntries,
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

      await cloudApi.sync(
        session: session,
        payRule: nextRule,
        workEntries: nextEntries,
      );
    } finally {
      _inFlight.remove(key);
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
}
