import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/pay_result.dart';
import '../models/pay_rule.dart';
import '../models/work_entry.dart';
import '../services/pay_calculator.dart';
import '../services/providers.dart';
import '../theme/colors.dart';
import '../widgets/app_page.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/glass_card.dart';

class PayHistoryScreen extends ConsumerStatefulWidget {
  const PayHistoryScreen({super.key});
  static const route = '/pay-history';

  @override
  ConsumerState<PayHistoryScreen> createState() => _PayHistoryScreenState();
}

class _PayHistoryScreenState extends ConsumerState<PayHistoryScreen> {
  _HistoryMode _mode = _HistoryMode.cycle;

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(workEntriesProvider);
    final rule = ref.watch(payRuleProvider);
    final calc = ref.watch(payCalculatorProvider);
    final formatter = NumberFormat.currency(symbol: '${rule.currency} ');
    final summaries = _mode == _HistoryMode.cycle
        ? _cycleSummaries(entries: entries, rule: rule, calc: calc)
        : _monthSummaries(entries: entries, rule: rule, calc: calc);
    final current = summaries.firstWhere(
      (summary) => summary.isCurrent,
      orElse: () => summaries.first,
    );

    return AppScaffold(
      appBar: AppBar(title: const Text('급여 기록')),
      body: AppPage(
        fillHeight: true,
        child: ListView(
          primary: true,
          padding: EdgeInsets.zero,
          children: [
            _HistoryHeader(
              summary: current,
              formatter: formatter,
              mode: _mode,
            ),
            const SizedBox(height: 12),
            SegmentedButton<_HistoryMode>(
              segments: const [
                ButtonSegment(
                  value: _HistoryMode.cycle,
                  label: Text('급여주기별'),
                  icon: Icon(Icons.payments_outlined),
                ),
                ButtonSegment(
                  value: _HistoryMode.month,
                  label: Text('월별'),
                  icon: Icon(Icons.calendar_month_outlined),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) {
                setState(() => _mode = selection.first);
              },
            ),
            const SizedBox(height: 10),
            const Text(
              '쌓인 급여',
              style: TextStyle(
                color: AppColors.deepInk,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              const _EmptyHint()
            else
              Text(
                _mode == _HistoryMode.cycle
                    ? '저장된 근무기록을 급여 주기별로 묶어서 보여줘요.'
                    : '저장된 근무기록을 월별로 합산해서 보여줘요.',
                style: const TextStyle(
                  color: AppColors.softBlack,
                  fontSize: 12,
                ),
              ),
            if (entries.isNotEmpty) const SizedBox(height: 8),
            ...summaries.map(
              (summary) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _HistoryCard(
                  summary: summary,
                  formatter: formatter,
                  mode: _mode,
                  onShareBudgetDraft: () => _shareBudgetDraft(
                    summary: summary,
                    rule: rule,
                    formatter: formatter,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const _BudgetNote(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  List<_PayHistorySummary> _cycleSummaries({
    required List<WorkEntry> entries,
    required PayRule rule,
    required PayCalculator calc,
  }) {
    final cycleLength = math.max(1, rule.payCycleLengthDays);
    final currentCycle = calc.currentCycle(rule);
    final previousStart = currentCycle.$1.subtract(Duration(days: cycleLength));
    final starts = <DateTime>{
      _dateOnly(currentCycle.$1),
      _dateOnly(previousStart),
      for (final entry in entries)
        _dateOnly(calc.currentCycle(rule, reference: entry.date).$1),
    }.toList()
      ..sort((a, b) => b.compareTo(a));

    return starts.map((start) {
      final end = start.add(Duration(days: cycleLength - 1));
      final periodEntries = _entriesInRange(entries, start, end);
      final result = calc.calculate(
        entries: periodEntries,
        rule: rule,
      );

      return _PayHistorySummary(
        periodStart: start,
        periodEnd: end,
        postedDate: calc.paydayForPeriod(end, rule.paydayWeekday),
        result: result,
        entryCount: periodEntries.length,
        isCurrent: _sameDay(start, currentCycle.$1),
        kind: _SummaryKind.cycle,
      );
    }).toList();
  }

  List<_PayHistorySummary> _monthSummaries({
    required List<WorkEntry> entries,
    required PayRule rule,
    required PayCalculator calc,
  }) {
    final now = DateTime.now();
    final starts = <DateTime>{
      DateTime(now.year, now.month),
      DateTime(now.year, now.month - 1),
      for (final entry in entries) DateTime(entry.date.year, entry.date.month),
    }.toList()
      ..sort((a, b) => b.compareTo(a));

    return starts.map((start) {
      final end = DateTime(start.year, start.month + 1, 0);
      final periodEntries = _entriesInRange(entries, start, end);
      final result = calc.calculate(
        entries: periodEntries,
        rule: rule,
      );

      return _PayHistorySummary(
        periodStart: start,
        periodEnd: end,
        postedDate: end,
        result: result,
        entryCount: periodEntries.length,
        isCurrent: start.year == now.year && start.month == now.month,
        kind: _SummaryKind.month,
      );
    }).toList();
  }

  List<WorkEntry> _entriesInRange(
    List<WorkEntry> entries,
    DateTime from,
    DateTime to,
  ) {
    return entries.where((entry) {
      final date = _dateOnly(entry.date);
      return !date.isBefore(from) && !date.isAfter(to);
    }).toList();
  }

  Future<void> _shareBudgetDraft({
    required _PayHistorySummary summary,
    required PayRule rule,
    required NumberFormat formatter,
  }) async {
    final payload = const JsonEncoder.withIndent('  ').convert({
      'source': 'employeeee',
      'type': 'pay_income_draft',
      'budgetAppTarget': 'budget-lee',
      'postedDate': _d(summary.postedDate),
      'periodStart': _d(summary.periodStart),
      'periodEnd': _d(summary.periodEnd),
      'summaryMode': summary.kind.name,
      'currency': rule.currency,
      'gross': summary.result.gross,
      'deductions': summary.result.tax,
      'net': summary.result.net,
      'hours': summary.result.totalHours,
      'entryCount': summary.entryCount,
      'employmentType': rule.employmentType.name,
      'employeeName': rule.employeeName,
      'employerName': rule.employerName,
      'payrollId': rule.payrollId,
    });

    await Share.share(
      payload,
      subject: 'employeeee 급여 기록 ${formatter.format(summary.result.net)}',
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({
    required this.summary,
    required this.formatter,
    required this.mode,
  });

  final _PayHistorySummary summary;
  final NumberFormat formatter;
  final _HistoryMode mode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFB4A7D6),
            Color(0xFFA8DADC),
            Color(0xFFF1C6A0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x225D6B8C),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mode == _HistoryMode.cycle ? '이번 급여 예상 포함' : '이번 달 급여 포함',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              shadows: [Shadow(color: Color(0x55000000), blurRadius: 5)],
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatter.format(summary.result.net),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                shadows: [Shadow(color: Color(0x44000000), blurRadius: 8)],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _LightPill(
                  '${_d(summary.periodStart)} ~ ${_d(summary.periodEnd)}'),
              _LightPill(
                mode == _HistoryMode.cycle
                    ? '지급일 ${_d(summary.postedDate)}'
                    : '월 마감 ${_d(summary.postedDate)}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.summary,
    required this.formatter,
    required this.mode,
    required this.onShareBudgetDraft,
  });

  final _PayHistorySummary summary;
  final NumberFormat formatter;
  final _HistoryMode mode;
  final VoidCallback onShareBudgetDraft;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.deepInk,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (summary.isCurrent) ...[
                          const SizedBox(width: 6),
                          const _StatusTag('현재'),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mode == _HistoryMode.cycle
                          ? '지급일 ${_d(summary.postedDate)}'
                          : '월별 합산 · ${summary.entryCount}개 기록',
                      style: const TextStyle(
                        color: AppColors.softBlack,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    '실수령',
                    style: TextStyle(
                      color: AppColors.softBlack,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    formatter.format(summary.result.net),
                    style: const TextStyle(
                      color: AppColors.deepInk,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoTile('세전', formatter.format(summary.result.gross)),
              _InfoTile('공제', formatter.format(summary.result.tax)),
              _InfoTile(
                  '총 시간', '${summary.result.totalHours.toStringAsFixed(2)} h'),
              _InfoTile('기록', '${summary.entryCount}개'),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onShareBudgetDraft,
              icon: const Icon(Icons.outbox_outlined, size: 18),
              label: const Text('Budget 보내기 초안'),
            ),
          ),
        ],
      ),
    );
  }

  String get _title {
    if (mode == _HistoryMode.month) {
      return DateFormat('yyyy년 M월').format(summary.periodStart);
    }
    return '${_d(summary.periodStart)} ~ ${_d(summary.periodEnd)}';
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.sizeOf(context).width < 390 ? 132 : 142,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.inputSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.softBlack,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.deepInk,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _LightPill extends StatelessWidget {
  const _LightPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          shadows: [Shadow(color: Color(0x33000000), blurRadius: 3)],
        ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.mint.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.mint),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.deepInk,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return const GlassCard(
      padding: EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.softBlack),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '근무기록을 입력하면 지난 급여와 월별 급여가 자동으로 쌓여 보여요.',
              style: TextStyle(color: AppColors.softBlack),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetNote extends StatelessWidget {
  const _BudgetNote();

  @override
  Widget build(BuildContext context) {
    return const GlassCard(
      padding: EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.sync_alt_outlined, color: AppColors.deepInk),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Budget 앱 연동 준비: 각 급여 카드는 지급일을 postedDate로 포함해 보내도록 구성했어요. 나중에 Budget 앱에서 이 값을 급여 입금일로 받아 저장하면 됩니다.',
              style: TextStyle(color: AppColors.softBlack, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

enum _HistoryMode { cycle, month }

enum _SummaryKind { cycle, month }

class _PayHistorySummary {
  const _PayHistorySummary({
    required this.periodStart,
    required this.periodEnd,
    required this.postedDate,
    required this.result,
    required this.entryCount,
    required this.isCurrent,
    required this.kind,
  });

  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime postedDate;
  final PayResult result;
  final int entryCount;
  final bool isCurrent;
  final _SummaryKind kind;
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _d(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
