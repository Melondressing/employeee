import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/pay_rule.dart';
import '../models/work_entry.dart';
import '../services/providers.dart';
import '../theme/colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/glass_card.dart';

class WorkLogScreen extends ConsumerWidget {
  const WorkLogScreen({super.key});
  static const route = '/work-log';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(workEntriesProvider);
    final rule = ref.watch(payRuleProvider);
    final calc = ref.watch(payCalculatorProvider);
    final cycle = calc.currentCycle(rule);
    final showCurrentOnly = ref.watch(_currentOnlyProvider);
    final filtered = showCurrentOnly
        ? entries.where((e) {
            final entryDate = DateTime(e.date.year, e.date.month, e.date.day);
            return !entryDate.isBefore(cycle.$1) &&
                !entryDate.isAfter(cycle.$2);
          }).toList()
        : entries;
    final fmt = DateFormat('yyyy-MM-dd');
    final summary = calc.calculate(entries: filtered, rule: rule);

    return AppScaffold(
      appBar: AppBar(
        title: const Text('근무 기록지'),
        actions: [
          IconButton(
            icon: Icon(
                showCurrentOnly ? Icons.filter_alt : Icons.filter_alt_outlined),
            tooltip: '이번 주기만 보기',
            onPressed: () => ref.read(_currentOnlyProvider.notifier).state =
                !showCurrentOnly,
          ),
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: filtered.isEmpty
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: Colors.white70),
                  SizedBox(height: 8),
                  Text('No entries', style: TextStyle(color: Colors.white70)),
                  Text('Add work entries to see them here',
                      style: TextStyle(color: Colors.white70)),
                ],
              )
            : Column(
                children: [
                  GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _stat('Entries', '${filtered.length}'),
                            _stat('Total Hours',
                                '${summary.totalHours.toStringAsFixed(2)} h'),
                            _stat(
                                'Gross',
                                NumberFormat.currency(
                                        symbol: '${rule.currency} ')
                                    .format(summary.gross)),
                            _stat(
                                'Net',
                                NumberFormat.currency(
                                        symbol: '${rule.currency} ')
                                    .format(summary.net)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          showCurrentOnly ? '필터: 현재 주기만' : '필터: 모든 기록',
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
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.12)),
                        itemBuilder: (_, i) {
                          final e = filtered[filtered.length - 1 - i];
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
                                  '시간 ${e.paidHours.toStringAsFixed(2)}h | ${_h(e.start)} ~ ${_h(e.end)} | 휴게 ${e.breakMinutes}분',
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
                            trailing: IconButton(
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
                                        onPressed: () =>
                                            Navigator.pop(dialogContext, false),
                                        child: const Text('취소'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext, true),
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

  Widget _stat(String title, String value) {
    return Column(
      children: [
        Text(title,
            style: const TextStyle(color: AppColors.softBlack, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.deepInk,
            shadows: [Shadow(color: Color(0x44000000), blurRadius: 3)],
          ),
        ),
      ],
    );
  }
}

final _currentOnlyProvider = StateProvider<bool>((_) => false);
