import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:employeeee/models/pay_rule.dart';
import 'package:employeeee/models/work_entry.dart';
import 'package:employeeee/services/storage.dart';

void main() {
  test('backup export and import round trip', () async {
    SharedPreferences.setMockInitialValues({});

    final rule = PayRule(
      baseWage: 27,
      taxRate: 0.12,
      localTaxRate: 0.03,
      insuranceRate: 0.05,
      cycleAnchorDate: DateTime(2026, 4, 6),
    );
    final entries = [
      WorkEntry(
        id: 'we_a',
        date: DateTime(2026, 4, 30),
        start: DateTime(2026, 4, 30, 9, 0),
        end: DateTime(2026, 4, 30, 17, 0),
        breakMinutes: 30,
      ),
    ];

    await Storage.saveRule(rule);
    await Storage.saveEntries(entries);

    final backup = await Storage.exportBackup();

    SharedPreferences.setMockInitialValues({});
    final imported = await Storage.importBackup(backup);
    expect(imported, isTrue);

    final restoredRule = await Storage.loadRule();
    final restoredEntries = await Storage.loadEntries();

    expect(restoredRule?.baseWage, 27);
    expect(restoredRule?.cycleAnchorDate, DateTime(2026, 4, 6));
    expect(restoredEntries, hasLength(1));
    expect(restoredEntries.first.id, 'we_a');
    expect(restoredEntries.first.note, isEmpty);
  });
}
