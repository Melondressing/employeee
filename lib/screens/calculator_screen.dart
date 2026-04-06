import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../services/providers.dart';
import '../theme/colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/glass_card.dart';
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
                      _RangeControls(
                          from: from, to: to, payday: payday, ref: ref),
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

class _RangeControls extends ConsumerWidget {
  const _RangeControls(
      {required this.from,
      required this.to,
      required this.payday,
      required this.ref});

  final DateTime from;
  final DateTime to;
  final DateTime payday;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef _) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () {
                ref.read(customRangeProvider.notifier).state = null;
                ref.read(cycleOffsetProvider.notifier).state--;
              },
              icon: const Icon(Icons.chevron_left, color: AppColors.deepInk),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${_d(from)} ~ ${_d(to)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.deepInk),
                  ),
                  Text(
                    '지급일 ${_d(payday)} (${_weekday(payday)}) · 기간 내 합계',
                    style: const TextStyle(
                        color: AppColors.softBlack, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                ref.read(customRangeProvider.notifier).state = null;
                ref.read(cycleOffsetProvider.notifier).state++;
              },
              icon: const Icon(Icons.chevron_right, color: AppColors.deepInk),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          children: [
            TextButton(
              onPressed: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  initialDateRange: DateTimeRange(start: from, end: to),
                );
                if (picked != null) {
                  ref.read(customRangeProvider.notifier).state = picked;
                }
              },
              child: const Text('사용자 지정'),
            ),
            TextButton(
              onPressed: () {
                ref.read(customRangeProvider.notifier).state = null;
                ref.read(cycleOffsetProvider.notifier).state = 0;
              },
              child: const Text('현재 주기'),
            ),
          ],
        ),
      ],
    );
  }

  String _d(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  static String _weekday(DateTime d) {
    const names = ['월', '화', '수', '목', '금', '토', '일'];
    return names[(d.weekday - 1) % 7];
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
