import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/pay_rule.dart';
import '../models/work_entry.dart';
import '../services/language_service.dart';
import '../services/providers.dart';
import '../theme/colors.dart';
import '../widgets/app_date_picker.dart';
import '../widgets/app_page.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/glass_card.dart';
import '../widgets/language_toggle.dart';
import '../widgets/period_range_controls.dart';
import 'work_entry_form_screen.dart';

class WorkLogScreen extends ConsumerWidget {
  const WorkLogScreen({super.key});
  static const route = '/work-log';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompact = MediaQuery.sizeOf(context).width < 390;
    final language = ref.watch(appLanguageProvider);
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
        title: Text(language.text('근무 기록지', 'Work log')),
        actions: [
          const LanguageToggle(compact: true),
          IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: filtered.isEmpty
                ? null
                : () async {
                    final csv = _toCsv(filtered);
                    await Share.share(
                      csv,
                      subject: language.text('근무 기록 CSV', 'Work log CSV'),
                    );
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
                  Text(language.text('기록이 없습니다', 'No entries'),
                      style: const TextStyle(color: AppColors.softBlack)),
                  Text(
                      language.text(
                        '근무 기록을 입력하면 여기에 표시됩니다',
                        'Add work entries to see them here',
                      ),
                      style: const TextStyle(color: AppColors.softBlack)),
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
                    monthLabel: language.text('이번 달', 'This month'),
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
                    monthLabel: language.text('이번 달', 'This month'),
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
                            _stat(language.text('기록', 'Entries'),
                                '${filtered.length}',
                                compact: isCompact),
                            _stat(
                              language.text('총 시간', 'Total hours'),
                              '${summary.totalHours.toStringAsFixed(2)} h',
                              compact: isCompact,
                            ),
                            _stat(
                              language.text('세전', 'Gross'),
                              NumberFormat.currency(symbol: '${rule.currency} ')
                                  .format(summary.gross),
                              compact: isCompact,
                            ),
                            _stat(
                              language.text('세후', 'Net'),
                              NumberFormat.currency(symbol: '${rule.currency} ')
                                  .format(summary.net),
                              compact: isCompact,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          language.text(
                            '기간: ${_dateWithWeekday(from, fmt, language)} ~ ${_dateWithWeekday(to, fmt, language)} · 지급일 ${_dateWithWeekday(payday, fmt, language)}',
                            'Period: ${_dateWithWeekday(from, fmt, language)} ~ ${_dateWithWeekday(to, fmt, language)} · payday ${_dateWithWeekday(payday, fmt, language)}',
                          ),
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
                              '${_dateWithWeekday(e.date, fmt, language)} / ${_typeLabel(e.type, language)}',
                              style: const TextStyle(
                                  color: AppColors.deepInk,
                                  fontWeight: FontWeight.w700),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isDayOff
                                      ? language.text(
                                          '휴무 · 급여 계산 제외',
                                          'Day off · excluded from pay',
                                        )
                                      : language.text(
                                          '시간 ${e.paidHours.toStringAsFixed(2)}h | ${_h(e.start)} ~ ${_h(e.end)} | 휴게 ${e.breakMinutes}분',
                                          '${e.paidHours.toStringAsFixed(2)}h | ${_h(e.start)} ~ ${_h(e.end)} | break ${e.breakMinutes}m',
                                        ),
                                  style: const TextStyle(
                                      color: AppColors.softBlack),
                                ),
                                if (e.note.isNotEmpty)
                                  Text(
                                    language.text(
                                        '메모: ${e.note}', 'Note: ${e.note}'),
                                    style: const TextStyle(
                                        color: AppColors.deepInk),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: language.text('수정', 'Edit'),
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
                                  tooltip: language.text('삭제', 'Delete'),
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (dialogContext) => AlertDialog(
                                        title: Text(language.text(
                                            '기록 삭제', 'Delete entry')),
                                        content: Text(language.text(
                                          '이 근무 기록을 삭제할까요?',
                                          'Delete this work entry?',
                                        )),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(
                                                dialogContext, false),
                                            child: Text(
                                                language.text('취소', 'Cancel')),
                                          ),
                                          FilledButton(
                                            onPressed: () => Navigator.pop(
                                                dialogContext, true),
                                            child: Text(
                                                language.text('삭제', 'Delete')),
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
                                      SnackBar(
                                        content: Text(
                                          language.text(
                                            '근무 기록을 삭제했어요.',
                                            'Work entry deleted.',
                                          ),
                                        ),
                                      ),
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

  String _typeLabel(WorkType t, AppLanguage language) {
    switch (t) {
      case WorkType.weekday:
        return language.text('평일', 'Weekday');
      case WorkType.saturday:
        return language.text('토', 'Sat');
      case WorkType.sunday:
        return language.text('일', 'Sun');
      case WorkType.holiday:
        return language.text('공휴', 'Holiday');
      case WorkType.dayOff:
        return language.text('휴무', 'Day off');
    }
  }

  String _toCsv(List<WorkEntry> entries) {
    const header =
        'date,weekday,start,end,breakMinutes,type,hours,note,night,leaveHoursUsed';
    final fmt = DateFormat('yyyy-MM-dd');
    final lines = entries.map((e) {
      return [
        fmt.format(e.date),
        weekdayLabel(e.date, AppLanguage.en),
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

  String _dateWithWeekday(
    DateTime date,
    DateFormat formatter,
    AppLanguage language,
  ) {
    return '${formatter.format(date)} (${weekdayLabel(date, language)})';
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
