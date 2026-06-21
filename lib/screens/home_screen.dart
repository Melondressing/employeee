import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/pay_rule.dart';
import '../models/work_entry.dart';
import '../services/language_service.dart';
import '../services/providers.dart';
import '../theme/colors.dart';
import '../widgets/app_page.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/glass_card.dart';
import '../widgets/language_toggle.dart';
import '../widgets/nav_card.dart';
import 'calculator_screen.dart';
import 'login_screen.dart';
import 'pay_history_screen.dart';
import 'paycheck_checker_screen.dart';
import 'reverse_calculator_screen.dart';
import 'rules_screen.dart';
import 'work_entry_form_screen.dart';
import 'work_log_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rule = ref.watch(payRuleProvider);
    final language = ref.watch(appLanguageProvider);
    final entries = ref.watch(workEntriesProvider);
    final calc = ref.watch(payCalculatorProvider);
    final cycle = calc.currentCycle(rule);
    final cycleResult = calc.calculate(
      entries: entries,
      rule: rule,
      from: cycle.$1,
      to: cycle.$2,
    );

    final payDate = calc.paydayForPeriod(cycle.$2, rule.paydayWeekday);
    final cycleLength =
        rule.payCycleLengthDays <= 0 ? 1 : rule.payCycleLengthDays;
    final previousStart = cycle.$1.subtract(Duration(days: cycleLength));
    final previousEnd = previousStart.add(Duration(days: cycleLength - 1));
    final previousResult = calc.calculate(
      entries: entries,
      rule: rule,
      from: previousStart,
      to: previousEnd,
    );
    final previousPayDate =
        calc.paydayForPeriod(previousEnd, rule.paydayWeekday);
    final formatter = NumberFormat.currency(symbol: '${rule.currency} ');
    final leaveLeft = (rule.annualLeaveTotalHours - rule.annualLeaveUsedHours)
        .toStringAsFixed(1);

    return AppScaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: const _HomeAppBarTitle(),
        toolbarHeight: 58,
        actions: [
          const LanguageToggle(compact: true),
          IconButton(
            tooltip: language.text('계정', 'Account'),
            onPressed: () => Navigator.pushNamed(context, LoginScreen.route),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: AppPage(
        fillHeight: true,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: ListView(
          primary: true,
          padding: EdgeInsets.zero,
          children: [
            _TopSummary(
              language: language,
              net: formatter.format(cycleResult.net),
              cycleStart: cycle.$1,
              cycleEnd: cycle.$2,
              payDate: payDate,
              gross: formatter.format(cycleResult.gross),
              hours: '${cycleResult.totalHours.toStringAsFixed(2)} h',
              leave: '$leaveLeft h',
            ),
            const SizedBox(height: 10),
            _PreviousPaySummary(
              language: language,
              net: formatter.format(previousResult.net),
              gross: formatter.format(previousResult.gross),
              hours: '${previousResult.totalHours.toStringAsFixed(2)} h',
              cycleStart: previousStart,
              cycleEnd: previousEnd,
              payDate: previousPayDate,
              onTap: () => Navigator.pushNamed(
                context,
                PayHistoryScreen.route,
              ),
            ),
            const SizedBox(height: 14),
            _HomeMonthCalendar(
              entries: entries,
              rule: rule,
              language: language,
              onDateTap: (date) => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => WorkEntryFormScreen(initialDate: date),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              language.text('도구', 'Tools'),
              style: const TextStyle(
                color: AppColors.deepInk,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            ..._navCards(context, language).map(
              (card) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: card,
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  List<Widget> _navCards(BuildContext context, AppLanguage language) {
    return [
      NavCard(
        title: language.text('설정 & 규칙', 'Settings & Rules'),
        subtitle: language.text(
          '통화, 시급, 세율, 급여주기, 연차',
          'Currency, wage, tax rates, pay cycle, leave',
        ),
        icon: '⚙️',
        onTap: () => Navigator.pushNamed(context, RulesScreen.route),
        bg: AppColors.lavender,
      ),
      NavCard(
        title: language.text('근무 기록 입력', 'Add Work Entry'),
        subtitle: language.text(
          '날짜, 시간, 휴게, 근무유형 기록',
          'Log date, hours, break and work type',
        ),
        icon: '🕐',
        onTap: () => Navigator.pushNamed(context, WorkEntryFormScreen.route),
        bg: AppColors.serenityBlue,
      ),
      NavCard(
        title: language.text('근무 기록지', 'Work Log'),
        subtitle: language.text('전체 기록 · CSV 내보내기', 'All entries · CSV export'),
        icon: '📋',
        onTap: () => Navigator.pushNamed(context, WorkLogScreen.route),
        bg: AppColors.softRose,
      ),
      NavCard(
        title: language.text('급여 기록', 'Pay History'),
        subtitle: language.text(
          '지난 급여 · 월별 보기 · Budget 초안',
          'Past pay · monthly view · Budget draft',
        ),
        icon: '📆',
        onTap: () => Navigator.pushNamed(context, PayHistoryScreen.route),
        bg: AppColors.lavender,
      ),
      NavCard(
        title: language.text('급여 계산기', 'Pay Calculator'),
        subtitle: language.text(
          '세전 · 세후 · 유형별 합계',
          'Gross · Net · per-type breakdown',
        ),
        icon: '🧮',
        onTap: () => Navigator.pushNamed(context, CalculatorScreen.route),
        bg: AppColors.mint,
      ),
      NavCard(
        title: language.text('급여 역산기', 'Reverse Calculator'),
        subtitle: language.text('실수령 목표 → 필요 시급', 'Net target → required rate'),
        icon: '🔄',
        onTap: () =>
            Navigator.pushNamed(context, ReverseCalculatorScreen.route),
        bg: AppColors.warmYellow,
      ),
      NavCard(
        title: language.text('급여 검증기', 'Payslip Checker'),
        subtitle: language.text(
          '명세서와 내 계산 비교',
          'Compare payslip vs my calc',
        ),
        icon: '✅',
        onTap: () => Navigator.pushNamed(context, PaycheckCheckerScreen.route),
        bg: AppColors.taupe,
      ),
    ];
  }
}

class _HomeMonthCalendar extends StatelessWidget {
  const _HomeMonthCalendar({
    required this.entries,
    required this.rule,
    required this.language,
    required this.onDateTap,
  });

  final List<WorkEntry> entries;
  final PayRule rule;
  final AppLanguage language;
  final ValueChanged<DateTime> onDateTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final month = DateTime(now.year, now.month);
    final monthStart = DateTime(month.year, month.month);
    final monthEnd = DateTime(month.year, month.month + 1, 0);
    final startsSunday =
        rule.country == 'South Korea' || rule.currency == 'KRW';
    final gridStart = _calendarWeekStart(monthStart, startsSunday);
    final gridEnd = _calendarWeekEnd(monthEnd, startsSunday);
    final dayCount = gridEnd.difference(gridStart).inDays + 1;
    final days = List.generate(
      dayCount,
      (index) => gridStart.add(Duration(days: index)),
    );
    final weeks = [
      for (var index = 0; index < days.length; index += 7)
        days.sublist(index, index + 7),
    ];
    final entriesByDay = _entriesByDay(entries);
    final monthEntries = entries.where((entry) {
      final day = _dateOnly(entry.date);
      return !day.isBefore(monthStart) && !day.isAfter(monthEnd);
    }).toList();
    final totalHours =
        monthEntries.fold<double>(0, (sum, entry) => sum + entry.paidHours);
    final workedDays = monthEntries
        .where((entry) => entry.type != WorkType.dayOff && entry.paidHours > 0)
        .map((entry) => _dayKey(entry.date))
        .toSet();

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            language.text('${month.month}월 근무 달력',
                '${DateFormat.MMMM('en_GB').format(month)} work calendar'),
            style: const TextStyle(
              color: AppColors.deepInk,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            language.text(
              '월 ${totalHours.toStringAsFixed(1)}h · 근무 ${workedDays.length}일',
              'Month ${totalHours.toStringAsFixed(1)}h · ${workedDays.length} worked days',
            ),
            style: const TextStyle(
              color: AppColors.softBlack,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Align(
            alignment: Alignment.centerLeft,
            child: _MiniLegend(language: language),
          ),
          const SizedBox(height: 10),
          _CalendarHeader(startsSunday: startsSunday, language: language),
          const SizedBox(height: 5),
          for (final week in weeks) ...[
            _CalendarWeekRow(
              week: week,
              month: month,
              entriesByDay: entriesByDay,
              onDateTap: onDateTap,
            ),
            if (week != weeks.last) const SizedBox(height: 5),
          ],
        ],
      ),
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.startsSunday,
    required this.language,
  });

  final bool startsSunday;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final labels = startsSunday
        ? [
            weekdayLabel(DateTime(2026, 5, 10), language),
            weekdayLabel(DateTime(2026, 5, 11), language),
            weekdayLabel(DateTime(2026, 5, 12), language),
            weekdayLabel(DateTime(2026, 5, 13), language),
            weekdayLabel(DateTime(2026, 5, 14), language),
            weekdayLabel(DateTime(2026, 5, 15), language),
            weekdayLabel(DateTime(2026, 5, 16), language),
          ]
        : [
            weekdayLabel(DateTime(2026, 5, 11), language),
            weekdayLabel(DateTime(2026, 5, 12), language),
            weekdayLabel(DateTime(2026, 5, 13), language),
            weekdayLabel(DateTime(2026, 5, 14), language),
            weekdayLabel(DateTime(2026, 5, 15), language),
            weekdayLabel(DateTime(2026, 5, 16), language),
            weekdayLabel(DateTime(2026, 5, 17), language),
          ];

    return Row(
      children: [
        for (final label in labels)
          Expanded(
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.softBlack,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        const SizedBox(width: 5),
        SizedBox(
          width: 42,
          child: Text(
            language.text('주간', 'Week'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.softBlack,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _CalendarWeekRow extends StatelessWidget {
  const _CalendarWeekRow({
    required this.week,
    required this.month,
    required this.entriesByDay,
    required this.onDateTap,
  });

  final List<DateTime> week;
  final DateTime month;
  final Map<int, List<WorkEntry>> entriesByDay;
  final ValueChanged<DateTime> onDateTap;

  @override
  Widget build(BuildContext context) {
    final visibleWeekEntries = [
      for (final day in week)
        if (_sameMonth(day, month)) ...entriesByDay[_dayKey(day)] ?? const [],
    ];
    final weekHours = visibleWeekEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.paidHours,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (final day in week) ...[
          Expanded(
            child: _CalendarDayCell(
              date: day,
              isInMonth: _sameMonth(day, month),
              entries: entriesByDay[_dayKey(day)] ?? const [],
              onTap: () {
                if (_sameMonth(day, month)) onDateTap(day);
              },
            ),
          ),
          if (day != week.last) const SizedBox(width: 3),
        ],
        const SizedBox(width: 5),
        _WeekHours(hours: weekHours),
      ],
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
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
    final today = _sameDate(date, DateTime.now());
    final dotColors = _dotColors(
      entries,
      date: date,
      isInMonth: isInMonth,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: isInMonth ? onTap : null,
      child: Container(
        height: 35,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: today
              ? AppColors.warmYellow.withValues(alpha: 0.20)
              : Colors.white.withValues(alpha: isInMonth ? 0.20 : 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: today
                ? AppColors.golden
                : AppColors.glassStroke
                    .withValues(alpha: isInMonth ? 0.42 : 0.16),
          ),
        ),
        child: isInMonth
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${date.day}',
                    style: const TextStyle(
                      color: AppColors.deepInk,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final color in dotColors.take(3)) ...[
                        _Dot(color: color),
                        if (color != dotColors.take(3).last)
                          const SizedBox(width: 2),
                      ],
                    ],
                  ),
                ],
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _WeekHours extends StatelessWidget {
  const _WeekHours({required this.hours});

  final double hours;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 35,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.cardSurfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.glassStroke),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '${hours.toStringAsFixed(1)}h',
          style: const TextStyle(
            color: AppColors.deepInk,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _MiniLegend extends StatelessWidget {
  const _MiniLegend({required this.language});

  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      alignment: WrapAlignment.end,
      children: [
        _LegendDot(
            label: language.text('근무', 'Work'), color: _CalendarColors.work),
        _LegendDot(
            label: language.text('휴무', 'Off'), color: _CalendarColors.dayOff),
        _LegendDot(
            label: language.text('공휴', 'Holiday'),
            color: _CalendarColors.holiday),
        _LegendDot(
            label: language.text('야간', 'Night'), color: _CalendarColors.night),
        _LegendDot(
            label: language.text('미입력', 'Empty'),
            color: _CalendarColors.unrecorded),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Dot(color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.softBlack,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _CalendarColors {
  static const work = Color(0xFFE85D75);
  static const dayOff = Color(0xFF5A9DEE);
  static const holiday = Color(0xFFE6A0B4);
  static const night = Color(0xFF9C7FE8);
  static const unrecorded = Color(0xFF9AA6B2);
  static const future = Color(0xFFD5DBE3);
}

class _HomeAppBarTitle extends StatelessWidget {
  const _HomeAppBarTitle();

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 390;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Text(
              'eymployeee',
              style: TextStyle(
                fontSize: isCompact ? 18 : 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.payments_outlined, size: isCompact ? 18 : 20),
          ],
        ),
      ),
    );
  }
}

class _TopSummary extends StatelessWidget {
  const _TopSummary({
    required this.language,
    required this.net,
    required this.cycleStart,
    required this.cycleEnd,
    required this.payDate,
    required this.gross,
    required this.hours,
    required this.leave,
  });

  final AppLanguage language;
  final String net;
  final DateTime cycleStart;
  final DateTime cycleEnd;
  final DateTime payDate;
  final String gross;
  final String hours;
  final String leave;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 390;
        final horizontalPadding = isCompact ? 32.0 : 36.0;
        final contentWidth = constraints.maxWidth - horizontalPadding;
        final metricWidth = isCompact ? contentWidth : (contentWidth - 8) / 2;
        final topContent = isCompact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language.text('이번 급여 예상', 'Estimated pay'),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      net,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: AppColors.accentGlow,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _Pill(
                      label: language.text(
                        '지급일 ${_d(payDate)}',
                        'Payday ${_d(payDate)}',
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          language.text('이번 급여 예상', 'Estimated pay'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            net,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: AppColors.accentGlow,
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _Pill(
                        label: language.text(
                          '지급일 ${_d(payDate)}',
                          'Payday ${_d(payDate)}',
                        ),
                      ),
                    ),
                  ),
                ],
              );

        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFB4A7D6),
                Color(0xFF9CADCE),
                Color(0xFFC9ADA7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x335D6B8C),
                blurRadius: 22,
                offset: Offset(0, 12),
              ),
            ],
          ),
          padding: EdgeInsets.all(isCompact ? 16 : 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              topContent,
              const SizedBox(height: 10),
              Text(
                '${_d(cycleStart)} ~ ${_d(cycleEnd)}',
                style: const TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetricTile(
                    label: language.text('세전', 'Gross'),
                    value: gross,
                    width: metricWidth,
                  ),
                  _MetricTile(
                    label: language.text('총 시간', 'Hours'),
                    value: hours,
                    width: metricWidth,
                  ),
                  _MetricTile(
                    label: language.text('급여 주기', 'Pay period'),
                    value: '${_d(cycleStart)} ~ ${_d(cycleEnd)}',
                    width: metricWidth,
                  ),
                  _MetricTile(
                    label: language.text('남은 연차', 'Leave left'),
                    value: leave,
                    width: metricWidth,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PreviousPaySummary extends StatelessWidget {
  const _PreviousPaySummary({
    required this.language,
    required this.net,
    required this.gross,
    required this.hours,
    required this.cycleStart,
    required this.cycleEnd,
    required this.payDate,
    required this.onTap,
  });

  final AppLanguage language;
  final String net;
  final String gross;
  final String hours;
  final DateTime cycleStart;
  final DateTime cycleEnd;
  final DateTime payDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.mint.withValues(alpha: 0.38),
                  AppColors.serenityBlue.withValues(alpha: 0.22),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: AppColors.serenityBlue.withValues(alpha: 0.55),
              ),
            ),
            child: const Icon(Icons.history_rounded, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        language.text('지난 급여 확인', 'Previous pay'),
                        style: const TextStyle(
                          color: AppColors.deepInk,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Text(
                      language.text(
                        '지급일 ${_d(payDate)}',
                        'Payday ${_d(payDate)}',
                      ),
                      style: const TextStyle(
                        color: AppColors.softBlack,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      net,
                      style: const TextStyle(
                        color: AppColors.deepInk,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      language.text('세전 $gross', 'Gross $gross'),
                      style: const TextStyle(
                        color: AppColors.softBlack,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      hours,
                      style: const TextStyle(
                        color: AppColors.softBlack,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${_d(cycleStart)} ~ ${_d(cycleEnd)}',
                  style: const TextStyle(
                    color: AppColors.softBlack,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppColors.softBlack, size: 20),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.width,
  });

  final String label;
  final String value;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                shadows: [
                  Shadow(color: Color(0x44000000), blurRadius: 3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }
}

Map<int, List<WorkEntry>> _entriesByDay(List<WorkEntry> entries) {
  final grouped = <int, List<WorkEntry>>{};
  for (final entry in entries) {
    grouped.putIfAbsent(_dayKey(entry.date), () => []).add(entry);
  }
  for (final dayEntries in grouped.values) {
    dayEntries.sort((a, b) => a.start.compareTo(b.start));
  }
  return grouped;
}

List<Color> _dotColors(
  List<WorkEntry> entries, {
  required DateTime date,
  required bool isInMonth,
}) {
  if (!isInMonth) return const [];
  if (entries.isEmpty) {
    final today = _dateOnly(DateTime.now());
    final day = _dateOnly(date);
    return [
      day.isAfter(today) ? _CalendarColors.future : _CalendarColors.unrecorded,
    ];
  }

  final colors = <Color>[];
  for (final entry in entries) {
    if (entry.type == WorkType.dayOff) {
      if (!colors.contains(_CalendarColors.dayOff)) {
        colors.add(_CalendarColors.dayOff);
      }
      continue;
    }
    final typeColor = entry.type == WorkType.holiday
        ? _CalendarColors.holiday
        : _CalendarColors.work;
    if (!colors.contains(typeColor)) colors.add(typeColor);
    if (entry.isNight && !colors.contains(_CalendarColors.night)) {
      colors.add(_CalendarColors.night);
    }
  }
  return colors.isEmpty ? const [_CalendarColors.work] : colors;
}

DateTime _calendarWeekStart(DateTime date, bool startsSunday) {
  final day = _dateOnly(date);
  final offset = startsSunday ? day.weekday % 7 : day.weekday - 1;
  return day.subtract(Duration(days: offset));
}

DateTime _calendarWeekEnd(DateTime date, bool startsSunday) {
  return _calendarWeekStart(date, startsSunday).add(const Duration(days: 6));
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

int _dayKey(DateTime date) {
  final day = _dateOnly(date);
  return day.year * 10000 + day.month * 100 + day.day;
}

bool _sameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool _sameMonth(DateTime date, DateTime month) {
  return date.year == month.year && date.month == month.month;
}

String _d(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
