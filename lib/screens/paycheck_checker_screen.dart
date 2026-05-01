import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../services/providers.dart';
import '../theme/colors.dart';
import '../widgets/app_date_picker.dart';
import '../widgets/app_page.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/glass_card.dart';
import '../widgets/period_range_controls.dart';
import '../widgets/tax_note.dart';

class PaycheckCheckerScreen extends ConsumerStatefulWidget {
  const PaycheckCheckerScreen({super.key});
  static const route = '/checker';

  @override
  ConsumerState<PaycheckCheckerScreen> createState() =>
      _PaycheckCheckerScreenState();
}

class _PaycheckCheckerScreenState extends ConsumerState<PaycheckCheckerScreen> {
  double _actualGross = 0;
  double _actualTax = 0;
  double _actualLocal = 0;
  double _actualInsurance = 0;

  @override
  Widget build(BuildContext context) {
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
      final base = calc.currentCycle(rule);
      final start =
          base.$1.add(Duration(days: offset * rule.payCycleLengthDays));
      from = start;
      to = start.add(Duration(days: rule.payCycleLengthDays - 1));
    }

    final result =
        calc.calculate(entries: entries, rule: rule, from: from, to: to);
    final formatter = NumberFormat.currency(symbol: '${rule.currency} ');

    final actualNet =
        _actualGross - (_actualTax + _actualLocal + _actualInsurance);
    final delta = actualNet - result.net;
    final payday = calc.paydayForPeriod(to, rule.paydayWeekday);

    return AppScaffold(
      appBar: AppBar(title: const Text('급여 검증기')),
      body: AppPage(
        fillHeight: entries.isEmpty,
        child: entries.isEmpty
            ? const Center(
                child: Text('근무 기록을 먼저 입력하세요.',
                    style: TextStyle(color: AppColors.softBlack)),
              )
            : SingleChildScrollView(
                primary: true,
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PeriodRangeControls(
                        from: from,
                        to: to,
                        payday: payday,
                        paydaySuffix: ' · 기간 내 금액만 비교',
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
                        onMonth: () {
                          final now = DateTime.now();
                          final monthStart = DateTime(now.year, now.month, 1);
                          final nextMonth =
                              DateTime(now.year, now.month + 1, 1);
                          final monthEnd =
                              nextMonth.subtract(const Duration(days: 1));
                          ref.read(customRangeProvider.notifier).state =
                              DateTimeRange(start: monthStart, end: monthEnd);
                        },
                        monthLabel: '이달 전체(월간) 보기',
                        onReset: () {
                          ref.read(customRangeProvider.notifier).state = null;
                          ref.read(cycleOffsetProvider.notifier).state = 0;
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Current period: ${DateFormat('yyyy-MM-dd').format(from)} '
                        '– ${DateFormat('yyyy-MM-dd').format(to)}',
                        style: const TextStyle(color: AppColors.softBlack),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton(
                            onPressed: () {
                              final now = DateTime.now();
                              final monthStart =
                                  DateTime(now.year, now.month, 1);
                              final nextMonth =
                                  DateTime(now.year, now.month + 1, 1);
                              final monthEnd =
                                  nextMonth.subtract(const Duration(days: 1));
                              ref.read(customRangeProvider.notifier).state =
                                  DateTimeRange(
                                      start: monthStart, end: monthEnd);
                            },
                            child: const Text('이달 전체(월간) 보기'),
                          ),
                          TextButton(
                            onPressed: () {
                              ref.read(customRangeProvider.notifier).state =
                                  null;
                              ref.read(cycleOffsetProvider.notifier).state = 0;
                            },
                            child: const Text('급여주기 보기'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        decoration:
                            const InputDecoration(labelText: '명세서 세전 (Gross)'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (v) => setState(
                            () => _actualGross = double.tryParse(v) ?? 0),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        decoration:
                            const InputDecoration(labelText: '명세서 세금/소득세'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (v) => setState(
                            () => _actualTax = double.tryParse(v) ?? 0),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        decoration:
                            const InputDecoration(labelText: '명세서 지방/주세'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (v) => setState(
                            () => _actualLocal = double.tryParse(v) ?? 0),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        decoration:
                            const InputDecoration(labelText: '명세서 연금/보험'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (v) => setState(
                            () => _actualInsurance = double.tryParse(v) ?? 0),
                      ),
                      const SizedBox(height: 16),
                      TaxNote(rule.taxNote),
                      const SizedBox(height: 10),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('내 계산 실수령',
                            style: TextStyle(color: AppColors.deepInk)),
                        trailing: Text(
                          formatter.format(result.net),
                          style: const TextStyle(
                              color: AppColors.deepInk,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('명세서 실수령',
                            style: TextStyle(color: AppColors.deepInk)),
                        trailing: Text(
                          formatter.format(actualNet),
                          style: const TextStyle(
                              color: AppColors.deepInk,
                              fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '공제합계 ${formatter.format(_actualTax + _actualLocal + _actualInsurance)}',
                          style: const TextStyle(color: AppColors.softBlack),
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('차이 (Payslip − My Calc)',
                            style: TextStyle(color: AppColors.deepInk)),
                        trailing: Text(
                          formatter.format(delta),
                          style: TextStyle(
                            color: delta >= 0
                                ? const Color(0xFF7CD88E)
                                : const Color(0xFFFFC080),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          delta >= 0
                              ? '명세서가 더 높습니다. 수당/보너스가 포함된 것일 수 있어요.'
                              : '명세서가 더 낮습니다. 세율/배율/시간을 다시 확인하세요.',
                          style: const TextStyle(color: AppColors.softBlack),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '차이가 크면 세율·배율·휴게시간 입력과 payslip 공제 항목을 다시 확인하세요.',
                        style: TextStyle(color: AppColors.softBlack),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
