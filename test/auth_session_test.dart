import 'package:flutter_test/flutter_test.dart';

import 'package:employeeee/models/auth_session.dart';
import 'package:employeeee/models/work_entry.dart';
import 'package:employeeee/services/cloud_sync_coordinator.dart';
import 'package:employeeee/services/cloud_sync_service.dart';

void main() {
  test('cloud auth session round trips shared account fields', () {
    final session = AuthSession(
      userId: 42,
      username: 'mino',
      email: 'mino@example.com',
      displayName: 'Mino',
      provider: 'budget-lee',
      isLocalOnly: false,
      createdAt: DateTime(2026, 5, 3),
      accessToken: 'token',
      apiBaseUrl: 'https://budget-lee.pages.dev',
    );

    final restored = AuthSession.fromJson(session.toJson());

    expect(restored.userId, 42);
    expect(restored.username, 'mino');
    expect(restored.email, 'mino@example.com');
    expect(restored.displayName, 'Mino');
    expect(restored.provider, 'budget-lee');
    expect(restored.isLocalOnly, isFalse);
    expect(restored.hasCloudToken, isTrue);
    expect(restored.accessToken, 'token');
    expect(restored.apiBaseUrl, 'https://budget-lee.pages.dev');
  });

  test('employeeee cloud bootstrap parses rule and entries', () {
    final bootstrap = EmployeeCloudBootstrap.fromJson({
      'pay_rule': {
        'baseWage': 31,
        'currency': 'AUD',
      },
      'work_entries': [
        {
          'id': 'we_cloud',
          'date': '2026-05-03T00:00:00.000',
          'start': '2026-05-03T09:00:00.000',
          'end': '2026-05-03T17:00:00.000',
          'breakMinutes': 30,
          'type': 0,
          'note': 'cloud',
        }
      ],
      'deleted_entries': [
        {
          'entry_id': 'we_deleted',
          'deleted_at': '2026-05-03 10:00:00',
        }
      ],
    });

    expect(bootstrap.payRule?.baseWage, 31);
    expect(bootstrap.workEntries, hasLength(1));
    expect(bootstrap.workEntries.first.id, 'we_cloud');
    expect(bootstrap.workEntries.first.paidHours, 7.5);
    expect(bootstrap.deletedEntries, hasLength(1));
    expect(bootstrap.deletedEntries.first.entryId, 'we_deleted');
  });

  test('budget export result parses transaction ids', () {
    final result = BudgetExportResult.fromJson({
      'already_exported': true,
      'pay_run_id': '7',
      'transaction_id': 42,
    });

    expect(result.alreadyExported, isTrue);
    expect(result.payRunId, 7);
    expect(result.transactionId, 42);
  });

  test('cloud sync merge keeps newest local and cloud work entries', () {
    final oldCloud = WorkEntry(
      id: 'same',
      date: DateTime(2026, 5, 1),
      start: DateTime(2026, 5, 1, 9),
      end: DateTime(2026, 5, 1, 15),
      note: 'cloud old',
      updatedAt: DateTime(2026, 5, 1, 10),
    );
    final newerLocal = oldCloud.copyWith(
      end: DateTime(2026, 5, 1, 17),
      note: 'local newer',
      updatedAt: DateTime(2026, 5, 1, 11),
    );
    final cloudOnly = WorkEntry(
      id: 'cloud',
      date: DateTime(2026, 5, 2),
      start: DateTime(2026, 5, 2, 9),
      end: DateTime(2026, 5, 2, 17),
      updatedAt: DateTime(2026, 5, 2, 10),
    );

    final merged = EmployeeeeCloudSyncCoordinator.mergeWorkEntries(
      localEntries: [newerLocal],
      cloudEntries: [oldCloud, cloudOnly],
    );

    expect(merged, hasLength(2));
    expect(merged.first.id, 'same');
    expect(merged.first.note, 'local newer');
    expect(merged.last.id, 'cloud');
  });

  test('cloud sync merge respects delete tombstones from another device', () {
    final staleLocal = WorkEntry(
      id: 'deleted',
      date: DateTime(2026, 5, 1),
      start: DateTime(2026, 5, 1, 9),
      end: DateTime(2026, 5, 1, 17),
      updatedAt: DateTime(2026, 5, 1, 9),
    );

    final merged = EmployeeeeCloudSyncCoordinator.mergeWorkEntries(
      localEntries: [staleLocal],
      cloudEntries: const [],
      deletedEntries: [
        DeletedWorkEntry(
          entryId: 'deleted',
          deletedAt: DateTime(2026, 5, 1, 10),
        ),
      ],
    );

    expect(merged, isEmpty);
  });
}
