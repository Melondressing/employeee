import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/pay_rule.dart';
import '../models/work_entry.dart';
import '../services/providers.dart';
import '../theme/colors.dart';
import '../widgets/app_page.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/glass_card.dart';
import 'work_entry_form_screen.dart';

class WorkCalendarScreen extends ConsumerStatefulWidget {
  const WorkCalendarScreen({super.key});

  static const route = '/work-calendar';

  @override
  ConsumerState<WorkCalendarScreen> createState() => _WorkCalendarScreenState();
}

class _WorkCalendarScreenState extends ConsumerState<WorkCalendarScreen> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(workEntriesProvider);
    final rule = ref.watch(payRuleProvider);
    final monthStart = DateTime(_visibleMonth.year, _visibleMonth.month);
    final monthEnd = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0);
    final weekStartsSunday =
        rule.country == 'South Korea' || rule.currency == 'KRW';
    final gridStart = _startOfWeek(monthStart, startsSunday: weekStartsSunday);
    final gridEnd = _endOfWeek(monthEnd, startsSunday: weekStartsSunday);
    final dayCount = gridEnd.difference(gridStart).inDays + 1;
    final days = List.generate(
      dayCount,
      (index) => gridStart.add(Duration(days: index)),
    );
    final weeks = <List<DateTime>>[
      for (var index = 0; index < days.length; index += 7)
        days.sublist(index, index + 7),
    ];
    final entriesByDay = _groupEntriesByDay(entries);
    final monthEntries = entries.where((entry) {
      final day = _dateOnly(entry.date);
      return !day.isBefore(monthStart) && !day.isAfter(monthEnd);
    }).toList();
    final monthHours =
        monthEntries.fold<double>(0, (sum, entry) => sum + entry.paidHours);
    final workedDays = monthEntries.map((entry) => _dayKey(entry.date)).toSet();
    final daysInMonth = monthEnd.day;
    final dayOffs = daysInMonth - workedDays.length;

    return AppScaffold(
      appBar: AppBar(
        title: const Text('근무 달력'),
        actions: [
          IconButton(
            tooltip: '오늘',
            onPressed: _goToday,
            icon: const Icon(Icons.today_outlined),
          ),
        ],
      ),
      body: AppPage(
        fillHeight: true,
        maxWidth: 620,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
        child: ListView(
          primary: true,
          padding: EdgeInsets.zero,
          children: [
            _MonthHeader(
              month: _visibleMonth,
              monthHours: monthHours,
              workedDays: workedDays.length,
              dayOffs: dayOffs,
              onPrevious: () => _moveMonth(-1),
              onNext: () => _moveMonth(1),
            ),
            const SizedBox(height: 10),
            const _Legend(),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  _WeekHeader(startsSunday: weekStartsSunday),
                  const SizedBox(height: 6),
                  for (final week in weeks) ...[
                    _WeekRow(
                      week: week,
                      visibleMonth: _visibleMonth,
                      entriesByDay: entriesByDay,
                      onDayTap: (date, dayEntries) =>
                          _showDaySheet(date, dayEntries),
                    ),
                    if (week != weeks.last) const SizedBox(height: 6),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<int, List<WorkEntry>> _groupEntriesByDay(List<WorkEntry> entries) {
    final grouped = <int, List<WorkEntry>>{};

    for (final entry in entries) {
      grouped.putIfAbsent(_dayKey(entry.date), () => []).add(entry);
    }

    for (final list in grouped.values) {
      list.sort((a, b) => a.start.compareTo(b.start));
    }

    return grouped;
  }

  void _moveMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  void _goToday() {
    final now = DateTime.now();
    setState(() => _visibleMonth = DateTime(now.year, now.month));
  }

  Future<void> _showDaySheet(DateTime date, List<WorkEntry> entries) async {
    final formatter = DateFormat('yyyy-MM-dd');
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.cardSurfaceStrong,
      builder: (sheetContext) {
        final totalHours =
            entries.fold<double>(0, (sum, entry) => sum + entry.paidHours);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${formatter.format(date)} (${_weekdayLabel(date)})',
                        style: const TextStyle(
                          color: AppColors.deepInk,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _StatusPill(
                      label: entries.isEmpty
                          ? 'Day off'
                          : '${totalHours.toStringAsFixed(2)} h',
                      color: entries.isEmpty
                          ? AppColors.serenityBlue
                          : AppColors.vividOrange,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (entries.isEmpty)
                  const Text(
                    '이 날짜에는 저장된 근무 기록이 없습니다.',
                    style: TextStyle(color: AppColors.softBlack),
                  )
                else
                  ...entries.map(
                    (entry) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 17,
                        backgroundColor: _entryColor(entry)
                            .withValues(alpha: entry.isNight ? 0.35 : 0.24),
                        child: Icon(
                          entry.isNight
                              ? Icons.nights_stay_outlined
                              : Icons.work_outline,
                          size: 17,
                          color: AppColors.deepInk,
                        ),
                      ),
                      title: Text(
                        '${_h(entry.start)}-${_h(entry.end)} · ${entry.paidHours.toStringAsFixed(2)} h',
                        style: const TextStyle(
                          color: AppColors.deepInk,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        '${_typeLabel(entry.type)} · 휴게 ${entry.breakMinutes}분${entry.note.isEmpty ? '' : ' · ${entry.note}'}',
                        style: const TextStyle(color: AppColors.softBlack),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _openEntryForm(entry: entry);
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _openEntryForm(initialDate: date);
                    },
                    icon: const Icon(Icons.add),
                    label: Text(entries.isEmpty ? '이 날짜에 근무 추가' : '추가 근무 입력'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openEntryForm({WorkEntry? entry, DateTime? initialDate}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkEntryFormScreen(
          entry: entry,
          initialDate: initialDate,
        ),
      ),
    );
  }

  DateTime _startOfWeek(DateTime date, {required bool startsSunday}) {
    final day = _dateOnly(date);
    final offset = startsSunday ? day.weekday % 7 : day.weekday - 1;
    return day.subtract(Duration(days: offset));
  }

  DateTime _endOfWeek(DateTime date, {required bool startsSunday}) {
    return _startOfWeek(date, startsSunday: startsSunday)
        .add(const Duration(days: 6));
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.monthHours,
    required this.workedDays,
    required this.dayOffs,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final double monthHours;
  final int workedDays;
  final int dayOffs;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('yyyy년 M월').format(month);
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: '이전 달',
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      monthLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.deepInk,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '월간 근무 패턴',
                      style: TextStyle(
                        color: AppColors.softBlack,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '다음 달',
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryChip(
                label: '월 총 시간',
                value: '${monthHours.toStringAsFixed(2)} h',
                color: AppColors.vividOrange,
              ),
              _SummaryChip(
                label: '근무일',
                value: '$workedDays일',
                color: AppColors.softRose,
              ),
              _SummaryChip(
                label: 'Day off',
                value: '$dayOffs일',
                color: AppColors.serenityBlue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return const GlassCard(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _LegendItem(label: '근무', color: AppColors.vividOrange),
          _LegendItem(label: 'Day off', color: AppColors.serenityBlue),
          _LegendItem(label: '공휴일', color: AppColors.softRose),
          _LegendItem(label: '야간', color: AppColors.lavender),
        ],
      ),
    );
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({required this.startsSunday});

  final bool startsSunday;

  @override
  Widget build(BuildContext context) {
    final labels = startsSunday
        ? const ['일', '월', '화', '수', '목', '금', '토']
        : const ['월', '화', '수', '목', '금', '토', '일'];

    return Row(
      children: [
        for (final label in labels)
          Expanded(
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.softBlack,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        const SizedBox(width: 6),
        const SizedBox(
          width: 54,
          child: Text(
            '주간',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.softBlack,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _WeekRow extends StatelessWidget {
  const _WeekRow({
    required this.week,
    required this.visibleMonth,
    required this.entriesByDay,
    required this.onDayTap,
  });

  final List<DateTime> week;
  final DateTime visibleMonth;
  final Map<int, List<WorkEntry>> entriesByDay;
  final void Function(DateTime date, List<WorkEntry> entries) onDayTap;

  @override
  Widget build(BuildContext context) {
    final weekEntries = [
      for (final date in week) ...entriesByDay[_dayKey(date)] ?? const [],
    ];
    final totalHours =
        weekEntries.fold<double>(0, (sum, entry) => sum + entry.paidHours);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final date in week) ...[
          Expanded(
            child: _DayCell(
              date: date,
              isInMonth: date.month == visibleMonth.month &&
                  date.year == visibleMonth.year,
              entries: entriesByDay[_dayKey(date)] ?? const [],
              onTap: () => onDayTap(
                date,
                entriesByDay[_dayKey(date)] ?? const [],
              ),
            ),
          ),
          if (date != week.last) const SizedBox(width: 4),
        ],
        const SizedBox(width: 6),
        _WeekTotal(hours: totalHours),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.isInMonth,
    required this.entries,
    required this.onTap,
  });

  final DateTime date;
  final bool isInMonth;
  final List<WorkEntry> entries;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasWork = entries.isNotEmpty;
    final totalHours =
        entries.fold<double>(0, (sum, entry) => sum + entry.paidHours);
    final color = _cellColor(entries);
    final today = _sameDate(date, DateTime.now());
    final foreground = isInMonth
        ? AppColors.deepInk
        : AppColors.softBlack.withValues(alpha: 0.55);
    final label = hasWork ? _shortTypeLabel(entries) : 'OFF';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isInMonth ? 0.22 : 0.08),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: today
                ? AppColors.deepInk
                : color.withValues(alpha: isInMonth ? 0.78 : 0.22),
            width: today ? 1.4 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: foreground,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                hasWork ? '${totalHours.toStringAsFixed(1)}h' : '',
                maxLines: 1,
                style: TextStyle(
                  color: foreground,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekTotal extends StatelessWidget {
  const _WeekTotal({required this.hours});

  final double hours;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardSurfaceAlt,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.glassStroke),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Total',
            style: TextStyle(
              color: AppColors.softBlack,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${hours.toStringAsFixed(1)}h',
              maxLines: 1,
              style: const TextStyle(
                color: AppColors.deepInk,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.deepInk,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.17),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.46)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.softBlack,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.deepInk,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.deepInk,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

Color _cellColor(List<WorkEntry> entries) {
  if (entries.isEmpty) return AppColors.serenityBlue;
  if (entries.any((entry) => entry.isNight)) return AppColors.lavender;
  if (entries.any((entry) => entry.type == WorkType.holiday)) {
    return AppColors.softRose;
  }
  return AppColors.vividOrange;
}

Color _entryColor(WorkEntry entry) {
  if (entry.isNight) return AppColors.lavender;
  if (entry.type == WorkType.holiday) return AppColors.softRose;
  return AppColors.vividOrange;
}

String _shortTypeLabel(List<WorkEntry> entries) {
  if (entries.length > 1) return 'WORK+${entries.length - 1}';
  final entry = entries.first;
  if (entry.isNight) return 'NIGHT';

  switch (entry.type) {
    case WorkType.weekday:
      return 'WORK';
    case WorkType.saturday:
      return 'SAT';
    case WorkType.sunday:
      return 'SUN';
    case WorkType.holiday:
      return 'HOL';
  }
}

String _typeLabel(WorkType type) {
  switch (type) {
    case WorkType.weekday:
      return '평일';
    case WorkType.saturday:
      return '토요일';
    case WorkType.sunday:
      return '일요일';
    case WorkType.holiday:
      return '공휴일';
  }
}

String _weekdayLabel(DateTime date) {
  const names = ['월', '화', '수', '목', '금', '토', '일'];
  return names[(date.weekday - 1) % 7];
}

String _h(DateTime date) {
  return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

int _dayKey(DateTime date) {
  final day = _dateOnly(date);
  return day.year * 10000 + day.month * 100 + day.day;
}

bool _sameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
