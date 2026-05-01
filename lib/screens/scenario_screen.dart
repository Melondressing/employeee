import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../services/providers.dart';
import '../theme/colors.dart';
import '../widgets/app_page.dart';
import '../widgets/app_scaffold.dart';

class ScenarioScreen extends ConsumerStatefulWidget {
  const ScenarioScreen({super.key});
  static const route = '/scenario';

  @override
  ConsumerState<ScenarioScreen> createState() => _ScenarioScreenState();
}

class _ScenarioScreenState extends ConsumerState<ScenarioScreen> {
  double _tax = 15;
  double _weekend = 1.5;

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(workEntriesProvider);
    final baseRule = ref.watch(payRuleProvider);
    final calc = ref.watch(payCalculatorProvider);
    final formatter = NumberFormat.currency(symbol: '${baseRule.currency} ');

    final scenarios = [
      baseRule,
      baseRule.copyWith(
        saturdayMultiplier: _weekend,
        sundayMultiplier: _weekend + 0.25,
        taxRate: _tax / 100,
      ),
    ];

    final results = scenarios
        .map((r) => calc.calculate(entries: entries, rule: r))
        .toList();

    return AppScaffold(
      appBar: AppBar(title: const Text('시나리오 비교')),
      body: AppPage(
        fillHeight: true,
        child: entries.isEmpty
            ? const Center(
                child: Text('근무 기록을 먼저 입력하세요.',
                    style: TextStyle(color: AppColors.softBlack)),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '세율과 주말·공휴 배율을 바꿔서\n“내가 규칙을 이렇게 정하면 실수령이 얼마나 달라질까?”를 보는 화면입니다.',
                    style: TextStyle(color: AppColors.softBlack),
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: _tax,
                    min: 0,
                    max: 40,
                    divisions: 40,
                    label: '세율 ${_tax.toStringAsFixed(0)}%',
                    onChanged: (v) => setState(() => _tax = v),
                  ),
                  Slider(
                    value: _weekend,
                    min: 1.0,
                    max: 2.5,
                    divisions: 15,
                    label: '토/일 배율 ${_weekend.toStringAsFixed(2)}',
                    onChanged: (v) => setState(() => _weekend = v),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: scenarios.length,
                      itemBuilder: (_, i) {
                        final r = scenarios[i];
                        final res = results[i];
                        return Card(
                          child: ListTile(
                            title: Text(i == 0 ? '현재 규칙' : '가정 시나리오'),
                            subtitle: Text(
                                '세율 ${(r.taxRate * 100).toStringAsFixed(1)}% · 토 ${r.saturdayMultiplier} · 일 ${r.sundayMultiplier}'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('실수령 ${formatter.format(res.net)}'),
                                Text('세전 ${formatter.format(res.gross)}'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
