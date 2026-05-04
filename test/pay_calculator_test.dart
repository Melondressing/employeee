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

  test('work entry json round trip preserves stable id', () {
    final original = WorkEntry(
      id: 'we_test_001',
      date: DateTime(2026, 4, 30),
      start: DateTime(2026, 4, 30, 9, 0),
      end: DateTime(2026, 4, 30, 17, 0),
      breakMinutes: 30,
      note: 'sample',
      createdAt: DateTime(2026, 4, 30, 8, 0),
      updatedAt: DateTime(2026, 4, 30, 8, 15),
    );

    final restored = WorkEntry.fromJson(original.toJson());

    expect(restored.id, original.id);
    expect(restored.createdAt, original.createdAt);
    expect(restored.updatedAt, original.updatedAt);
    expect(restored.paidHours, original.paidHours);
  });

  test('legacy work entry json without id still loads', () {
    final restored = WorkEntry.fromJson({
      'date': '2026-04-30T00:00:00.000',
      'start': '2026-04-30T09:00:00.000',
      'end': '2026-04-30T17:00:00.000',
      'breakMinutes': 30,
      'type': 0,
      'note': 'legacy',
      'isNight': false,
      'leaveHoursUsed': 0,
    });

    expect(restored.id, isNotEmpty);
    expect(restored.note, 'legacy');
    expect(restored.paidHours, 7.5);
  });

  test('anchored pay cycle handles multi-week periods', () {
    final calc = PayCalculator();
    final rule = PayRule(
      baseWage: 20,
      taxRate: 0,
      localTaxRate: 0,
      insuranceRate: 0,
      payCycleLengthDays: 14,
      payPeriodStartWeekday: DateTime.monday,
      cycleAnchorDate: DateTime(2026, 4, 6),
    );

    final cycle = calc.currentCycle(rule, reference: DateTime(2026, 4, 30));

    expect(cycle.$1, DateTime(2026, 4, 20));
    expect(cycle.$2, DateTime(2026, 5, 3));
  });

  test('casual employment does not accrue annual leave', () {
    final calc = PayCalculator();
    final rule = PayRule(
      baseWage: 30,
      employmentType: EmploymentType.casual,
      taxRate: 0,
      localTaxRate: 0,
      insuranceRate: 0,
      leaveAccrualPerHour: 0.0769,
    );

    final result = calc.calculate(
      entries: [
        WorkEntry(
          date: DateTime(2026, 5, 1),
          start: DateTime(2026, 5, 1, 9),
          end: DateTime(2026, 5, 1, 17),
          breakMinutes: 0,
        ),
      ],
      rule: rule,
    );

    expect(result.totalHours, 8);
    expect(result.accruedLeaveHours, 0);
  });

  test('day off entries are stored but excluded from pay and leave accrual',
      () {
    final calc = PayCalculator();
    final rule = PayRule(
      baseWage: 30,
      taxRate: 0,
      localTaxRate: 0,
      insuranceRate: 0,
      leaveAccrualPerHour: 0.0769,
    );
    final dayOff = WorkEntry(
      date: DateTime(2026, 5, 2),
      start: DateTime(2026, 5, 2),
      end: DateTime(2026, 5, 2),
      type: WorkType.dayOff,
    );

    final restored = WorkEntry.fromJson(dayOff.toJson());
    final result = calc.calculate(entries: [restored], rule: rule);

    expect(restored.type, WorkType.dayOff);
    expect(restored.paidHours, 0);
    expect(result.totalHours, 0);
    expect(result.gross, 0);
    expect(result.accruedLeaveHours, 0);
  });

  test('legacy Australia preset migrates public holiday to double pay', () {
    final rule = PayRule.fromJson({
      'baseWage': 20,
      'country': 'Australia',
      'holidayMultiplier': 2.25,
      'taxNote': '호주 예시: 세율 15%, 연금/보험 10.7%, 토 1.25·일 1.5·공휴 2.25',
    });

    expect(rule.holidayMultiplier, 2.0);
    expect(rule.taxNote, contains('공휴 2.0'));
  });
}
