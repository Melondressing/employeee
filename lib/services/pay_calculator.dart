import 'dart:math' as math;

import 'package:collection/collection.dart';

import '../models/pay_result.dart';
import '../models/pay_rule.dart';
import '../models/work_entry.dart';

class PayCalculator {
  PayResult calculate({
    required List<WorkEntry> entries,
    required PayRule rule,
    double leaveHoursToDeduct = 0,
    DateTime? from,
    DateTime? to,
  }) {
    final fromDate = from == null ? null : _dateOnly(from);
    final toDate = to == null ? null : _dateOnly(to);

    final filtered = entries.where((e) {
      final entryDate = _dateOnly(e.date);
      final after = fromDate == null || !entryDate.isBefore(fromDate);
      final before = toDate == null || !entryDate.isAfter(toDate);
      return after && before;
    }).toList();

    double gross = 0;
    double totalHours = 0;
    double leaveDeduction = leaveHoursToDeduct * rule.baseWage;
    double accruedLeaveHours = 0;
    final breakdown = <String, double>{
      'weekday': 0,
      'sat': 0,
      'sun': 0,
      'holiday': 0,
      'night': 0
    };

    for (final e in filtered) {
      final hours = e.paidHours;
      totalHours += hours;
      final multiplier = _multiplierFor(e, rule);
      final line = hours * rule.baseWage * multiplier;
      gross += line;

      switch (e.type) {
        case WorkType.weekday:
          breakdown['weekday'] = (breakdown['weekday'] ?? 0) + line;
          break;
        case WorkType.saturday:
          breakdown['sat'] = (breakdown['sat'] ?? 0) + line;
          break;
        case WorkType.sunday:
          breakdown['sun'] = (breakdown['sun'] ?? 0) + line;
          break;
        case WorkType.holiday:
          breakdown['holiday'] = (breakdown['holiday'] ?? 0) + line;
          break;
      }
      if (e.isNight) {
        final nightExtra = hours * rule.baseWage * (rule.nightMultiplier - 1);
        gross += nightExtra;
        breakdown['night'] = (breakdown['night'] ?? 0) + nightExtra;
      }
      accruedLeaveHours += hours * rule.leaveAccrualPerHour;
    }

    final tax = gross * rule.taxRate;
    final local = gross * rule.localTaxRate;
    final insurance = gross * rule.insuranceRate;
    final totalDeduction = tax + local + insurance + leaveDeduction;
    final net = gross - totalDeduction;

    return PayResult(
      gross: gross,
      tax: totalDeduction,
      net: net,
      totalHours: totalHours,
      leaveDeduction: leaveDeduction,
      breakdown: breakdown..removeWhere((_, v) => v == 0),
      accruedLeaveHours: accruedLeaveHours,
    );
  }

  double reverseBaseWage({
    required double targetNet,
    required List<WorkEntry> entries,
    required PayRule rule,
    double leaveHours = 0,
  }) {
    final totalWeightedHours = entries
        .map((e) =>
            e.paidHours * _multiplierFor(e, rule) +
            (e.isNight ? e.paidHours * (rule.nightMultiplier - 1) : 0))
        .sum;
    if (totalWeightedHours == 0) return 0;
    final grossNeeded = targetNet + leaveHours * rule.baseWage;
    final grossBeforeTax = grossNeeded / (1 - rule.taxRate);
    return grossBeforeTax / totalWeightedHours;
  }

  double _multiplierFor(WorkEntry e, PayRule rule) {
    switch (e.type) {
      case WorkType.weekday:
        return 1;
      case WorkType.saturday:
        return rule.saturdayMultiplier;
      case WorkType.sunday:
        return rule.sundayMultiplier;
      case WorkType.holiday:
        return rule.holidayMultiplier;
    }
  }

  /// Returns current pay-cycle (start, end) based on rule and reference date.
  (DateTime start, DateTime end) currentCycle(PayRule rule,
      {DateTime? reference}) {
    final ref = reference ?? DateTime.now();
    final refDate = DateTime(ref.year, ref.month, ref.day);
    final cycleLength = math.max(1, rule.payCycleLengthDays);

    final start = rule.cycleAnchorDate == null
        ? refDate.subtract(
            Duration(
              days:
                  (refDate.weekday - rule.payPeriodStartWeekday) % 7,
            ),
          )
        : _anchoredCycleStart(refDate, rule.cycleAnchorDate!, cycleLength);

    final end = start.add(Duration(days: cycleLength - 1));
    return (start, end);
  }

  /// Next payday after period end.
  DateTime paydayForPeriod(DateTime periodEnd, int paydayWeekday) {
    if (paydayWeekday == 0) return periodEnd; // same day 지급
    var d = periodEnd.add(const Duration(days: 1));
    for (int i = 0; i < 7; i++) {
      if (d.weekday == paydayWeekday) return d;
      d = d.add(const Duration(days: 1));
    }
    return d;
  }

  double reverseBaseWageFromHours({
    required double targetNet,
    required PayRule rule,
    double weekdayHours = 0,
    double saturdayHours = 0,
    double sundayHours = 0,
    double holidayHours = 0,
  }) {
    final totalWeighted = weekdayHours * 1 +
        saturdayHours * rule.saturdayMultiplier +
        sundayHours * rule.sundayMultiplier +
        holidayHours * rule.holidayMultiplier;
    if (totalWeighted == 0) return 0;
    final combinedRate = rule.taxRate + rule.localTaxRate + rule.insuranceRate;
    final grossNeeded = combinedRate >= 1 ? 0 : targetNet / (1 - combinedRate);
    return grossNeeded / totalWeighted;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _anchoredCycleStart(
    DateTime refDate,
    DateTime anchorDate,
    int cycleLength,
  ) {
    final anchor = DateTime(anchorDate.year, anchorDate.month, anchorDate.day);
    final diffDays = refDate.difference(anchor).inDays;
    final cycleIndex = (diffDays / cycleLength).floor();
    return anchor.add(Duration(days: cycleIndex * cycleLength));
  }
}
