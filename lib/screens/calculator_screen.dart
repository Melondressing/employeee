import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../services/providers.dart';
import '../theme/colors.dart';
import '../widgets/app_date_picker.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/glass_card.dart';
import '../widgets/period_range_controls.dart';
import '../widgets/tax_note.dart';

class CalculatorScreen extends ConsumerWidget {
  const CalculatorScreen({super.key});
  static const route = '/calculator';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(workEntriesProvider);
    final rule = ref.watch(payRuleProvider);
    final calc = ref.watch(payCalculatorProvider);
    final offset = ref.watch(cycleOffsetProvider);
    final custom = ref.watch(customRangeProvider);

    late final DateTime from;
    late final DateTime to;
    if (custom != null) {
      from = custom.start;
      to = custom.end;
    } else {
      final baseCycle = calc.currentCycle(rule);
      final start =
          baseCycle.$1.add(Duration(days: offset * rule.payCycleLengthDays));
      from = start;
      to = start.add(Duration(days: rule.payCycleLengthDays - 1));
    }

    final result =
        calc.calculate(entries: entries, rule: rule, from: from, to: to);
    final formatter = NumberFormat.currency(symbol: '${rule.currency} ');
    final payday = calc.paydayForPeriod(to, rule.paydayWeekday);

    return AppScaffold(
      appBar: AppBar(title: const Text('예상 급여 계산기')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: entries.isEmpty
            ? const Center(
                child: Text('근무 기록을 먼저 입력하세요.',
                    style: TextStyle(color: Colors.white70)),
              )
            : SingleChildScrollView(
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PeriodRangeControls(
                        from: from,
                        to: to,
                        payday: payday,
                        paydaySuffix: ' · 기간 내 합계',
                        onPrevious: () {
                          ref.read(customRangeProvider.notifier).state = null;
                          ref.read(cycleOffsetProvider.notifier).state--;
                        },
                        onNext: () {
                          ref.read(customRangeProvider.notifier).state = null;
                          ref.read(cycleOffsetProvider.notifier).state++;
                        },
                        onCustomRange: () async {
                          final picked = await showAppDateRangePicker(
                            context: context,
                            rule: rule,
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 365)),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                            initialDateRange:
                                DateTimeRange(start: from, end: to),
                          );
                          if (picked != null) {
                            ref.read(customRangeProvider.notifier).state =
                                picked;
                          }
                        },
                        onReset: () {
                          ref.read(customRangeProvider.notifier).state = null;
                          ref.read(cycleOffsetProvider.notifier).state = 0;
                        },
                      ),
                      const SizedBox(height: 12),
                      TaxNote(rule.taxNote),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _ChipCard('총 시간',
                              '${result.totalHours.toStringAsFixed(2)} h'),
                          _ChipCard('세전', formatter.format(result.gross)),
                          _ChipCard('세금', formatter.format(result.tax)),
                          _ChipCard(
                              '연차 공제', formatter.format(result.leaveDeduction)),
                          _ChipCard('연차 적립',
                              '${result.accruedLeaveHours.toStringAsFixed(2)} h'),
                          _ChipCard('실수령', formatter.format(result.net)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '항목별 합계',
                        style: TextStyle(
                          color: AppColors.deepInk,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...result.breakdown.entries.map(
                        (entry) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            entry.key,
                            style: const TextStyle(color: AppColors.deepInk),
                          ),
                          trailing: Text(
                            formatter.format(entry.value),
                            style: const TextStyle(
                              color: AppColors.deepInk,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '엔트리 수: ${entries.length}',
                        style: const TextStyle(color: AppColors.softBlack),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _ChipCard extends StatelessWidget {
  const _ChipCard(this.title, this.value);

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      label: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 12, color: AppColors.softBlack)),
          Text(
            value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.deepInk),
          ),
        ],
      ),
    );
  }
}
