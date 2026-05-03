import 'package:flutter_test/flutter_test.dart';

import 'package:employeeee/models/auth_session.dart';

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
}
