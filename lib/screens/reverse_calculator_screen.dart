import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../services/providers.dart';
import '../theme/colors.dart';
import '../widgets/app_page.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/glass_card.dart';
import '../widgets/tax_note.dart';

class ReverseCalculatorScreen extends ConsumerStatefulWidget {
  const ReverseCalculatorScreen({super.key});
  static const route = '/reverse';

  @override
  ConsumerState<ReverseCalculatorScreen> createState() =>
      _ReverseCalculatorScreenState();
}

class _ReverseCalculatorScreenState
    extends ConsumerState<ReverseCalculatorScreen> {
  double _targetNet = 0;
  double _weekdayHours = 0;
  double _satHours = 0;
  double _sunHours = 0;
  double _holidayHours = 0;

  @override
  Widget build(BuildContext context) {
    final rule = ref.watch(payRuleProvider);
    final calc = ref.watch(payCalculatorProvider);
    final formatter = NumberFormat.currency(symbol: '${rule.currency} ');
    final screenWidth = MediaQuery.sizeOf(context).width;
    final statCardWidth = screenWidth < 420 ? (screenWidth - 56) / 2 : 136.0;
    final requiredBase = calc.reverseBaseWageFromHours(
      targetNet: _targetNet,
      rule: rule,
      weekdayHours: _weekdayHours,
      saturdayHours: _satHours,
      sundayHours: _sunHours,
      holidayHours: _holidayHours,
    );

    final totalWeighted = _weekdayHours * 1 +
        _satHours * rule.saturdayMultiplier +
        _sunHours * rule.sundayMultiplier +
        _holidayHours * rule.holidayMultiplier;
    final totalHours = _weekdayHours + _satHours + _sunHours + _holidayHours;
    final combinedRate = rule.taxRate + rule.localTaxRate + rule.insuranceRate;
    final requiredGross =
        _targetNet == 0 || totalWeighted == 0 || combinedRate >= 1
            ? 0
            : _targetNet / (1 - combinedRate);
    final taxAmount = requiredGross * combinedRate;
    final diffHourly = requiredBase == 0 ? 0 : requiredBase - rule.baseWage;

    return AppScaffold(
      appBar: AppBar(title: const Text('급여 역산기')),
      body: AppPage(
        child: SingleChildScrollView(
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '목표 실수령액과 각 요일별 총 시간을 넣으면\n'
                  '필요한 시급·세전 총액·세금까지 자동 계산합니다.\n'
                  '세율은 현재 규칙의 세율을 그대로 사용해요.',
                  style: TextStyle(color: AppColors.softBlack),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: '목표 실수령액',
                    prefixText: "\$",
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: false,
                  ),
                  onChanged: (v) => setState(
                      () => _targetNet = double.tryParse(v) ?? _targetNet),
                ),
                const SizedBox(height: 12),
                _hoursField('평일(월-금) 총 시간', (v) => _weekdayHours = v),
                _hoursField('토요일 총 시간', (v) => _satHours = v),
                _hoursField('일요일 총 시간', (v) => _sunHours = v),
                _hoursField('공휴일 총 시간', (v) => _holidayHours = v),
                const SizedBox(height: 18),
                TaxNote(rule.taxNote),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _statCard(
                      '필요 시급',
                      requiredBase == 0
                          ? '-'
                          : '${formatter.format(requiredBase)}/h',
                      width: statCardWidth,
                    ),
                    _statCard(
                      '필요 세전',
                      requiredGross == 0
                          ? '-'
                          : formatter.format(requiredGross),
                      width: statCardWidth,
                    ),
                    _statCard(
                      '세금',
                      requiredGross == 0 ? '-' : formatter.format(taxAmount),
                      width: statCardWidth,
                    ),
                    _statCard(
                      '총 시간',
                      '${totalHours.toStringAsFixed(3)} h',
                      width: statCardWidth,
                    ),
                    _statCard(
                      '가중 시간',
                      '${totalWeighted.toStringAsFixed(3)} h',
                      width: statCardWidth,
                    ),
                    _statCard(
                      '현재 시급 대비',
                      diffHourly == 0
                          ? '-'
                          : '${diffHourly > 0 ? '+' : ''}${diffHourly.toStringAsFixed(2)}/h',
                      width: statCardWidth,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (requiredBase > 0) ...[
                  const Text('상세',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Target Net: ${formatter.format(_targetNet)}'),
                  Text('Required Gross: ${formatter.format(requiredGross)}'),
                  Text(
                    '세율 ${(rule.taxRate * 100).toStringAsFixed(1)}% '
                    '→ 세금 ${formatter.format(taxAmount)}',
                  ),
                  Text('배율 적용 시간합(가중): ${totalWeighted.toStringAsFixed(3)}h'),
                  Text('입력 시간합(실제): ${totalHours.toStringAsFixed(3)}h'),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hoursField(String label, void Function(double) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        decoration: InputDecoration(labelText: label, suffixText: '시간'),
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true, signed: false),
        onChanged: (v) => setState(() => onChanged(double.tryParse(v) ?? 0)),
      ),
    );
  }

  Widget _statCard(String title, String value, {required double width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF4EA), Color(0xFFE6DDF5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassStroke),
        boxShadow: [
          BoxShadow(
            color: AppColors.lavender.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.softBlack,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 19,
              color: AppColors.deepInk,
              shadows: [
                Shadow(color: Color(0x55FFFFFF), blurRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
