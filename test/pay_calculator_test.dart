import 'package:flutter_test/flutter_test.dart';

import 'package:employeeee/models/pay_rule.dart';
import 'package:employeeee/models/work_entry.dart';
import 'package:employeeee/services/pay_calculator.dart';

void main() {
  test('includes both start and end dates in cycle range', () {
    final calc = PayCalculator();
    final rule = PayRule(
      baseWage: 20,
      taxRate: 0,
      localTaxRate: 0,
      insuranceRate: 0,
    );

    final entries = [
      WorkEntry(
        date: DateTime(2026, 4, 30, 14, 20),
        start: DateTime(2026, 4, 30, 9, 0),
        end: DateTime(2026, 4, 30, 17, 0),
        breakMinutes: 0,
      ),
      WorkEntry(
        date: DateTime(2026, 5, 5, 18, 45),
        start: DateTime(2026, 5, 5, 10, 0),
        end: DateTime(2026, 5, 5, 18, 0),
        breakMinutes: 0,
      ),
    ];

    final result = calc.calculate(
      entries: entries,
      rule: rule,
      from: DateTime(2026, 4, 30),
      to: DateTime(2026, 5, 5),
    );

    expect(result.totalHours, 16);
    expect(result.gross, 320);
  });
}
