import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:employeeee/app.dart';

void main() {
  testWidgets('home screen renders app title', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: EmployeeeeApp()));
    await tester.pumpAndSettle();

    expect(find.text('employeeee'), findsOneWidget);
  });
}
