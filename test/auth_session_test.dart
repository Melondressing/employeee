import 'package:flutter_test/flutter_test.dart';

import 'package:employeeee/models/auth_session.dart';
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
    });

    expect(bootstrap.payRule?.baseWage, 31);
    expect(bootstrap.workEntries, hasLength(1));
    expect(bootstrap.workEntries.first.id, 'we_cloud');
    expect(bootstrap.workEntries.first.paidHours, 7.5);
  });
}
