import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../services/providers.dart';
import '../theme/colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/nav_card.dart';
import 'calculator_screen.dart';
import 'login_screen.dart';
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
    final formatter = NumberFormat.currency(symbol: '${rule.currency} ');
    final leaveLeft = (rule.annualLeaveTotalHours - rule.annualLeaveUsedHours)
        .toStringAsFixed(1);

    return AppScaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: const _HomeAppBarTitle(),
        toolbarHeight: 58,
        actions: [
          IconButton(
            tooltip: 'Account',
            onPressed: () => Navigator.pushNamed(context, LoginScreen.route),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            children: [
              _TopSummary(
                net: formatter.format(cycleResult.net),
                cycleStart: cycle.$1,
                cycleEnd: cycle.$2,
                payDate: payDate,
                gross: formatter.format(cycleResult.gross),
                hours: '${cycleResult.totalHours.toStringAsFixed(2)} h',
                leave: '$leaveLeft h',
              ),
              const SizedBox(height: 14),
              const Text(
                'Tools',
                style: TextStyle(
                  color: AppColors.deepInk,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              ..._navCards(context).map(
                (card) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: card,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _navCards(BuildContext context) {
    return [
      NavCard(
        title: 'Settings & Rules',
        subtitle: 'Currency, wage, tax rates, pay cycle, leave',
        icon: '⚙️',
        onTap: () => Navigator.pushNamed(context, RulesScreen.route),
        bg: AppColors.lavender,
      ),
      NavCard(
        title: 'Add Work Entry',
        subtitle: 'Log date, hours, break and work type',
        icon: '🕐',
        onTap: () => Navigator.pushNamed(context, WorkEntryFormScreen.route),
        bg: AppColors.serenityBlue,
      ),
      NavCard(
        title: 'Work Log',
        subtitle: 'All entries · CSV export',
        icon: '📋',
        onTap: () => Navigator.pushNamed(context, WorkLogScreen.route),
        bg: AppColors.softRose,
      ),
      NavCard(
        title: 'Pay Calculator',
        subtitle: 'Gross · Net · per-type breakdown',
        icon: '🧮',
        onTap: () => Navigator.pushNamed(context, CalculatorScreen.route),
        bg: AppColors.mint,
      ),
      NavCard(
        title: 'Reverse Calculator',
        subtitle: 'Net target → required rate',
        icon: '🔄',
        onTap: () =>
            Navigator.pushNamed(context, ReverseCalculatorScreen.route),
        bg: AppColors.warmYellow,
      ),
      NavCard(
        title: 'Payslip Checker',
        subtitle: 'Compare payslip vs my calc',
        icon: '✅',
        onTap: () => Navigator.pushNamed(context, PaycheckCheckerScreen.route),
        bg: AppColors.taupe,
      ),
    ];
  }
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
              'employeeee',
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
    required this.net,
    required this.cycleStart,
    required this.cycleEnd,
    required this.payDate,
    required this.gross,
    required this.hours,
    required this.leave,
  });

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
                  const Text(
                    '이번 급여 예상',
                    style: TextStyle(
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
                    child: _Pill(label: '지급일 ${_d(payDate)}'),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '이번 급여 예상',
                          style: TextStyle(
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
                      child: _Pill(label: '지급일 ${_d(payDate)}'),
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
                    label: '세전',
                    value: gross,
                    width: metricWidth,
                  ),
                  _MetricTile(
                    label: '총 시간',
                    value: hours,
                    width: metricWidth,
                  ),
                  _MetricTile(
                    label: '급여 주기',
                    value: '${_d(cycleStart)} ~ ${_d(cycleEnd)}',
                    width: metricWidth,
                  ),
                  _MetricTile(
                    label: '남은 연차',
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

String _d(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
