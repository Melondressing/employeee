import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/pay_rule.dart';
import '../models/work_entry.dart';
import '../services/providers.dart';
import '../theme/colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/glass_card.dart';

class WorkEntryFormScreen extends ConsumerStatefulWidget {
  const WorkEntryFormScreen({super.key});
  static const route = '/work-entry';

  @override
  ConsumerState<WorkEntryFormScreen> createState() =>
      _WorkEntryFormScreenState();
}

class _WorkEntryFormScreenState extends ConsumerState<WorkEntryFormScreen> {
  DateTime _date = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 18, minute: 0);
  int _breakMinutes = 30;
  WorkType _type = WorkType.weekday;
  bool _isNight = false;
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('yyyy-MM-dd');
    final entries = ref.watch(workEntriesProvider);
    final rule = ref.watch(payRuleProvider);
    final calc = ref.watch(payCalculatorProvider);
    final tempEntry = _buildTempEntry();
    final tempPay = tempEntry == null
        ? null
        : calc.calculate(entries: [tempEntry], rule: rule);

    return AppScaffold(
      appBar: AppBar(title: const Text('근무 기록 입력')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        label: const Text('추가'),
        icon: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${formatter.format(_date)} (${_weekdayLabel(_date.weekday)})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepInk,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today,
                          color: AppColors.deepInk),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 365)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() {
                            _date =
                                DateTime(picked.year, picked.month, picked.day);
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _presetChip('오전 9-6', () {
                      setState(() {
                        _start = const TimeOfDay(hour: 9, minute: 0);
                        _end = const TimeOfDay(hour: 18, minute: 0);
                        _breakMinutes = 60;
                      });
                    }),
                    _presetChip('오후 2-10', () {
                      setState(() {
                        _start = const TimeOfDay(hour: 14, minute: 0);
                        _end = const TimeOfDay(hour: 22, minute: 0);
                        _breakMinutes = 30;
                      });
                    }),
                    _presetChip('야간 10-6', () {
                      setState(() {
                        _start = const TimeOfDay(hour: 22, minute: 0);
                        _end = const TimeOfDay(hour: 6, minute: 0);
                        _breakMinutes = 30;
                        _isNight = true;
                      });
                    }),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _timeButton('시작', _start,
                          (t) => setState(() => _start = _roundTo15(t))),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _timeButton('종료', _end,
                          (t) => setState(() => _end = _roundTo15(t))),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _breakSlider(),
                const SizedBox(height: 8),
                DropdownButtonFormField<WorkType>(
                  initialValue: _type,
                  dropdownColor: AppColors.cardSurfaceStrong,
                  style: const TextStyle(color: AppColors.deepInk),
                  decoration: const InputDecoration(labelText: '근무 유형'),
                  items: const [
                    DropdownMenuItem(
                        value: WorkType.weekday, child: Text('평일')),
                    DropdownMenuItem(
                        value: WorkType.saturday, child: Text('토요일')),
                    DropdownMenuItem(
                        value: WorkType.sunday, child: Text('일요일')),
                    DropdownMenuItem(
                        value: WorkType.holiday, child: Text('공휴일')),
                  ],
                  onChanged: (v) =>
                      setState(() => _type = v ?? WorkType.weekday),
                ),
                SwitchListTile(
                  value: _isNight,
                  activeThumbColor: AppColors.vividOrange,
                  title: const Text('야간 근무 (배율 적용)',
                      style: TextStyle(color: AppColors.deepInk)),
                  onChanged: (v) => setState(() => _isNight = v),
                ),
                TextField(
                  controller: _noteCtrl,
                  decoration: const InputDecoration(labelText: '메모'),
                  style: const TextStyle(color: AppColors.deepInk),
                ),
                const SizedBox(height: 12),
                if (tempPay != null)
                  Text(
                    '예상 일급(세전) ${tempPay.gross.toStringAsFixed(2)} / 세후 ${tempPay.net.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepInk,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _section(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '최근 기록',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: AppColors.deepInk),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    await ref
                        .read(workEntriesProvider.notifier)
                        .copyLastWeekForward();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('지난주를 다음주로 복사했습니다. 필요하면 수정하세요.')));
                  },
                  icon: const Icon(Icons.content_copy),
                  label: const Text('지난주 복사 → 이번주'),
                ),
                ...entries.reversed.take(5).map(
                      (e) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${formatter.format(e.date)} ${e.type.name}',
                          style: const TextStyle(color: AppColors.deepInk),
                        ),
                        subtitle: Text(
                          '시간 ${e.paidHours.toStringAsFixed(2)}h / 메모 ${e.note.isEmpty ? '-' : e.note}',
                          style: const TextStyle(color: AppColors.softBlack),
                        ),
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  Widget _timeButton(
      String label, TimeOfDay time, ValueChanged<TimeOfDay> onPick) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        side: const BorderSide(color: AppColors.glassStroke),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.cardSurfaceAlt,
      ),
      onPressed: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
          builder: (context, child) {
            return MediaQuery(
              data:
                  MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
        if (picked != null) onPick(picked);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.deepInk)),
          Text(
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.deepInk),
          ),
        ],
      ),
    );
  }

  Widget _breakSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('휴게시간: $_breakMinutes 분',
            style: const TextStyle(color: AppColors.deepInk)),
        Slider(
          value: _breakMinutes.toDouble(),
          min: 0,
          max: 180,
          divisions: 12,
          label: '$_breakMinutes 분',
          onChanged: (v) => setState(() => _breakMinutes = v.round()),
        ),
      ],
    );
  }

  Widget _presetChip(String label, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: false,
      backgroundColor: AppColors.cardSurfaceAlt,
      side: const BorderSide(color: AppColors.glassStroke),
      labelStyle: const TextStyle(color: AppColors.deepInk),
      onSelected: (_) => onTap(),
    );
  }

  Widget _section({required Widget child}) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: child,
    );
  }

  TimeOfDay _roundTo15(TimeOfDay t) {
    final totalMinutes = t.hour * 60 + t.minute;
    final rounded = (totalMinutes / 15).round() * 15;
    final h = (rounded ~/ 60) % 24;
    final m = rounded % 60;
    return TimeOfDay(hour: h, minute: m);
  }

  WorkEntry? _buildTempEntry() {
    var startDate = DateTime(
        _date.year, _date.month, _date.day, _start.hour, _start.minute);
    var endDate =
        DateTime(_date.year, _date.month, _date.day, _end.hour, _end.minute);
    if (endDate.isBefore(startDate)) {
      endDate = endDate.add(const Duration(days: 1));
    }

    final entry = WorkEntry(
      date: _date,
      start: startDate,
      end: endDate,
      breakMinutes: _breakMinutes,
      type: _type,
      note: _noteCtrl.text,
      isNight: _isNight,
      leaveHoursUsed: 0,
    );

    if (entry.paidHours <= 0) return null;
    return entry;
  }

  void _save() {
    final startDate = DateTime(
        _date.year, _date.month, _date.day, _start.hour, _start.minute);
    final endDate =
        DateTime(_date.year, _date.month, _date.day, _end.hour, _end.minute);

    ref.read(workEntriesProvider.notifier).add(
          WorkEntry(
            date: _date,
            start: startDate,
            end: endDate,
            breakMinutes: _breakMinutes,
            type: _type,
            note: _noteCtrl.text,
            isNight: _isNight,
            leaveHoursUsed: 0,
          ),
        );

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('추가되었습니다.')));
    }
  }

  String _weekdayLabel(int weekday) {
    const names = ['월', '화', '수', '목', '금', '토', '일'];
    return names[(weekday - 1) % 7];
  }
}
