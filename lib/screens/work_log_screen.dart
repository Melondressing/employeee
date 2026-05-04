import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/pay_rule.dart';
import '../models/work_entry.dart';
import '../services/providers.dart';
import '../theme/colors.dart';
import '../widgets/app_date_picker.dart';
import '../widgets/app_page.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/glass_card.dart';
import '../widgets/period_range_controls.dart';
import 'work_entry_form_screen.dart';

class WorkLogScreen extends ConsumerWidget {
  const WorkLogScreen({super.key});
  static const route = '/work-log';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompact = MediaQuery.sizeOf(context).width < 390;
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
      final cycle = calc.currentCycle(rule);
      final start =
          cycle.$1.add(Duration(days: offset * rule.payCycleLengthDays));
      from = start;
      to = start.add(Duration(days: rule.payCycleLengthDays - 1));
    }

    final filtered = entries.where((e) {
      final entryDate = DateTime(e.date.year, e.date.month, e.date.day);
      return !entryDate.isBefore(from) && !entryDate.isAfter(to);
    }).toList();
    final fmt = DateFormat('yyyy-MM-dd');
    final summary = calc.calculate(entries: filtered, rule: rule);
    final payday = calc.paydayForPeriod(to, rule.paydayWeekday);

    return AppScaffold(
      appBar: AppBar(
        title: const Text('근무 기록지'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: filtered.isEmpty
                ? null
                : () async {
                    final csv = _toCsv(filtered);
                    await Share.share(csv, subject: '근무 기록 CSV');
                  },
          )
        ],
      ),
      body: AppPage(
        fillHeight: true,
        child: filtered.isEmpty
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox_outlined,
                      size: 48, color: AppColors.softBlack),
                  const SizedBox(height: 8),
                  const Text('No entries',
                      style: TextStyle(color: AppColors.softBlack)),
                  const Text('Add work entries to see them here',
                      style: TextStyle(color: AppColors.softBlack)),
                  const SizedBox(height: 16),
                  PeriodRangeControls(
                    from: from,
                    to: to,
                    payday: payday,
                    paydaySuffix: '',
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
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        initialDateRange: DateTimeRange(start: from, end: to),
                      );
                      if (picked != null) {
                        ref.read(customRangeProvider.notifier).state = picked;
                      }
                    },
                    onMonth: () {
                      final now = DateTime.now();
                      final monthStart = DateTime(now.year, now.month, 1);
                      final nextMonth = DateTime(now.year, now.month + 1, 1);
                      final monthEnd =
                          nextMonth.subtract(const Duration(days: 1));
                      ref.read(customRangeProvider.notifier).state =
                          DateTimeRange(start: monthStart, end: monthEnd);
                      ref.read(cycleOffsetProvider.notifier).state = 0;
                    },
                    monthLabel: '이번 달',
                    onReset: () {
                      ref.read(customRangeProvider.notifier).state = null;
                      ref.read(cycleOffsetProvider.notifier).state = 0;
                    },
                  ),
                ],
              )
            : Column(
                children: [
                  PeriodRangeControls(
                    from: from,
                    to: to,
                    payday: payday,
                    paydaySuffix: '',
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
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        initialDateRange: DateTimeRange(start: from, end: to),
                      );
                      if (picked != null) {
                        ref.read(customRangeProvider.notifier).state = picked;
                      }
                    },
                    onMonth: () {
                      final now = DateTime.now();
                      final monthStart = DateTime(now.year, now.month, 1);
                      final nextMonth = DateTime(now.year, now.month + 1, 1);
                      final monthEnd =
                          nextMonth.subtract(const Duration(days: 1));
                      ref.read(customRangeProvider.notifier).state =
                          DateTimeRange(start: monthStart, end: monthEnd);
                      ref.read(cycleOffsetProvider.notifier).state = 0;
                    },
                    monthLabel: '이번 달',
                    onReset: () {
                      ref.read(customRangeProvider.notifier).state = null;
                      ref.read(cycleOffsetProvider.notifier).state = 0;
                    },
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            _stat('Entries', '${filtered.length}',
                                compact: isCompact),
                            _stat(
                              'Total Hours',
                              '${summary.totalHours.toStringAsFixed(2)} h',
                              compact: isCompact,
                            ),
                            _stat(
                              'Gross',
                              NumberFormat.currency(symbol: '${rule.currency} ')
                                  .format(summary.gross),
                              compact: isCompact,
                            ),
                            _stat(
                              'Net',
                              NumberFormat.currency(symbol: '${rule.currency} ')
                                  .format(summary.net),
                              compact: isCompact,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '기간: ${fmt.format(from)} ~ ${fmt.format(to)} · 지급일 ${fmt.format(payday)}',
                          style: const TextStyle(
                              color: AppColors.softBlack, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.all(12),
                      child: ListView.separated(
                        primary: true,
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.12)),
                        itemBuilder: (_, i) {
                          final e = filtered[filtered.length - 1 - i];
                          final isDayOff = e.type == WorkType.dayOff;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              '${fmt.format(e.date)} / ${_typeLabel(e.type)}',
                              style: const TextStyle(
                                  color: AppColors.deepInk,
                                  fontWeight: FontWeight.w700),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isDayOff
                                      ? '휴무 · 급여 계산 제외'
                                      : '시간 ${e.paidHours.toStringAsFixed(2)}h | ${_h(e.start)} ~ ${_h(e.end)} | 휴게 ${e.breakMinutes}분',
                                  style: const TextStyle(
                                      color: AppColors.softBlack),
                                ),
                                if (e.note.isNotEmpty)
                                  Text(
                                    '메모: ${e.note}',
                                    style: const TextStyle(
                                        color: AppColors.deepInk),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: '수정',
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            WorkEntryFormScreen(entry: e),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  tooltip: '삭제',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (dialogContext) => AlertDialog(
                                        title: const Text('기록 삭제'),
                                        content: const Text('이 근무 기록을 삭제할까요?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(
                                                dialogContext, false),
                                            child: const Text('취소'),
                                          ),
                                          FilledButton(
                                            onPressed: () => Navigator.pop(
                                                dialogContext, true),
                                            child: const Text('삭제'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed != true) return;
                                    await ref
                                        .read(workEntriesProvider.notifier)
                                        .remove(e);
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('근무 기록을 삭제했어요.')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _h(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _typeLabel(WorkType t) {
    switch (t) {
      case WorkType.weekday:
        return '평일';
      case WorkType.saturday:
        return '토';
      case WorkType.sunday:
        return '일';
      case WorkType.holiday:
        return '공휴';
      case WorkType.dayOff:
        return '휴무';
    }
  }

  String _toCsv(List<WorkEntry> entries) {
    const header =
        'date,start,end,breakMinutes,type,hours,note,night,leaveHoursUsed';
    final fmt = DateFormat('yyyy-MM-dd');
    final lines = entries.map((e) {
      return [
        fmt.format(e.date),
        _h(e.start),
        _h(e.end),
        e.breakMinutes,
        e.type.name,
        e.paidHours.toStringAsFixed(2),
        e.note.replaceAll(',', ' '),
        e.isNight,
        e.leaveHoursUsed,
      ].join(',');
    }).toList();
    return ([header, ...lines]).join('\n');
  }

  Widget _stat(String title, String value, {required bool compact}) {
    return SizedBox(
      width: compact ? 130 : 148,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(color: AppColors.softBlack, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.deepInk,
              shadows: [Shadow(color: Color(0x44000000), blurRadius: 3)],
            ),
          ),
        ],
      ),
    );
  }
}
