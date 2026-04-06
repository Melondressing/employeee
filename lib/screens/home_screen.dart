import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../services/providers.dart';
import '../theme/colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/nav_card.dart';
import 'calculator_screen.dart';
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
        titleSpacing: 0,
        title: const Row(
          children: [
            Text('employeeee'),
            SizedBox(width: 6),
            Icon(Icons.payments_outlined, size: 20),
          ],
        ),
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
                  color: Colors.white70,
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
        bg: const Color(0xFFBE9151),
      ),
      NavCard(
        title: 'Add Work Entry',
        subtitle: 'Log date, hours, break and work type',
        icon: '🕐',
        onTap: () => Navigator.pushNamed(context, WorkEntryFormScreen.route),
        bg: const Color(0xFFD28B4A),
      ),
      NavCard(
        title: 'Work Log',
        subtitle: 'All entries · CSV export',
        icon: '📋',
        onTap: () => Navigator.pushNamed(context, WorkLogScreen.route),
        bg: const Color(0xFFC38A67),
      ),
      NavCard(
        title: 'Pay Calculator',
        subtitle: 'Gross · Net · per-type breakdown',
        icon: '🧮',
        onTap: () => Navigator.pushNamed(context, CalculatorScreen.route),
        bg: const Color(0xFFD39D57),
      ),
      NavCard(
        title: 'Reverse Calculator',
        subtitle: 'Net target → required rate',
        icon: '🔄',
        onTap: () =>
            Navigator.pushNamed(context, ReverseCalculatorScreen.route),
        bg: const Color(0xFFB87A46),
      ),
      NavCard(
        title: 'Payslip Checker',
        subtitle: 'Compare payslip vs my calc',
        icon: '✅',
        onTap: () => Navigator.pushNamed(context, PaycheckCheckerScreen.route),
        bg: const Color(0xFFA87346),
      ),
    ];
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
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF20110B), Color(0xFF30170D), Color(0xFF3A1C10)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 12)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    Text(
                      net,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _Pill(label: '지급일 ${_d(payDate)}'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${_d(cycleStart)} ~ ${_d(cycleEnd)}',
            style: const TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              Row(
                children: [
                  Expanded(child: _MetricTile(label: '세전', value: gross)),
                  const SizedBox(width: 8),
                  Expanded(child: _MetricTile(label: '총 시간', value: hours)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      label: '급여 주기',
                      value: '${_d(cycleStart)} ~ ${_d(cycleEnd)}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _MetricTile(label: '남은 연차', value: leave)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
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
