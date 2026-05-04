import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/pay_rule.dart';
import '../models/work_entry.dart';
import '../services/language_service.dart';
import '../services/providers.dart';
import '../theme/colors.dart';
import '../widgets/app_date_picker.dart';
import '../widgets/app_page.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/glass_card.dart';

class WorkEntryFormScreen extends ConsumerStatefulWidget {
  const WorkEntryFormScreen({super.key, this.entry, this.initialDate});
  static const route = '/work-entry';

  final WorkEntry? entry;
  final DateTime? initialDate;

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
  bool _typeTouched = false;
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    if (entry == null) {
      final initialDate = widget.initialDate;
      if (initialDate != null) {
        _date = DateTime(initialDate.year, initialDate.month, initialDate.day);
      }
      _type = _defaultTypeForDate(_date);
      return;
    }

    _date = DateTime(entry.date.year, entry.date.month, entry.date.day);
    _start = TimeOfDay(hour: entry.start.hour, minute: entry.start.minute);
    _end = TimeOfDay(hour: entry.end.hour, minute: entry.end.minute);
    _breakMinutes = entry.breakMinutes;
    _type = entry.type;
    _typeTouched = true;
    _isNight = entry.isNight;
    _noteCtrl.text = entry.note;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(appLanguageProvider);
    final formatter = DateFormat('yyyy-MM-dd');
    final entries = ref.watch(workEntriesProvider);
    final rule = ref.watch(payRuleProvider);
    final calc = ref.watch(payCalculatorProvider);
    final tempEntry = _buildTempEntry();
    final tempPay = tempEntry == null
        ? null
        : calc.calculate(entries: [tempEntry], rule: rule);
    final isEditing = widget.entry != null;
    final selectedDateEntries = entries
        .where((entry) => _sameDate(entry.date, _date))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    final weekStart = _weekStart(_date);
    final weekEnd = weekStart.add(const Duration(days: 6));
    final weekEntries = entries.where((entry) {
      final day = _dateOnly(entry.date);
      return !day.isBefore(weekStart) && !day.isAfter(weekEnd);
    }).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    final isDayOff = _type == WorkType.dayOff;

    return AppScaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? language.text('근무 기록 수정', 'Edit work entry')
              : language.text('근무 기록 입력', 'Add work entry'),
        ),
      ),
      body: AppPage(
        fillHeight: true,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
        child: ListView(
          primary: true,
          padding: EdgeInsets.zero,
          children: [
            _section(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dateControls(formatter),
                  const SizedBox(height: 12),
                  _typeSelector(),
                  const SizedBox(height: 12),
                  if (isDayOff)
                    _dayOffNotice()
                  else ...[
                    _presetSection(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _timeControl(
                            label: language.text('시작', 'Start'),
                            time: _start,
                            onPick: (picked) =>
                                setState(() => _start = _roundTo15(picked)),
                            onAdjust: (minutes) => setState(
                              () => _start = _adjustTime(_start, minutes),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _timeControl(
                            label: language.text('종료', 'End'),
                            time: _end,
                            onPick: (picked) =>
                                setState(() => _end = _roundTo15(picked)),
                            onAdjust: (minutes) => setState(
                              () => _end = _adjustTime(_end, minutes),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _breakSelector(),
                    SwitchListTile(
                      value: _isNight,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppColors.vividOrange,
                      title: Text(
                        language.text('야간 근무 배율 적용', 'Apply night rate'),
                        style: const TextStyle(color: AppColors.deepInk),
                      ),
                      onChanged: (value) => setState(() => _isNight = value),
                    ),
                  ],
                  TextField(
                    controller: _noteCtrl,
                    decoration: InputDecoration(
                      labelText: language.text('메모', 'Note'),
                    ),
                    style: const TextStyle(color: AppColors.deepInk),
                  ),
                  const SizedBox(height: 12),
                  _payPreview(tempPay),
                  const SizedBox(height: 12),
                  _saveButtons(isEditing),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _dayEntriesSection(selectedDateEntries, formatter),
            const SizedBox(height: 12),
            _weekToolsSection(weekEntries, formatter, weekStart, weekEnd),
          ],
        ),
      ),
    );
  }

  Widget _dateControls(DateFormat formatter) {
    final language = ref.watch(appLanguageProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: language.text('전날', 'Previous day'),
              onPressed: () =>
                  _setDate(_date.subtract(const Duration(days: 1))),
              icon: const Icon(Icons.chevron_left, color: AppColors.deepInk),
            ),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  side: const BorderSide(color: AppColors.glassStroke),
                  foregroundColor: AppColors.deepInk,
                  backgroundColor: AppColors.cardSurfaceAlt,
                ),
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text(
                  _dateWithWeekday(_date, formatter, language),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            IconButton(
              tooltip: language.text('다음날', 'Next day'),
              onPressed: () => _setDate(_date.add(const Duration(days: 1))),
              icon: const Icon(Icons.chevron_right, color: AppColors.deepInk),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          children: [
            TextButton(
              onPressed: () => _setDate(DateTime.now()),
              child: Text(language.text('오늘', 'Today')),
            ),
            TextButton(
              onPressed: () =>
                  _setDate(DateTime.now().subtract(const Duration(days: 1))),
              child: Text(language.text('어제', 'Yesterday')),
            ),
            TextButton(
              onPressed: () =>
                  _setDate(DateTime.now().add(const Duration(days: 1))),
              child: Text(language.text('내일', 'Tomorrow')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _presetSection() {
    final language = ref.watch(appLanguageProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          language.text('자주 쓰는 시간', 'Quick presets'),
          style: const TextStyle(
            color: AppColors.deepInk,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _presetChip('9-6', const TimeOfDay(hour: 9, minute: 0),
                const TimeOfDay(hour: 18, minute: 0), 60, false),
            _presetChip('2-10', const TimeOfDay(hour: 14, minute: 0),
                const TimeOfDay(hour: 22, minute: 0), 30, false),
            _presetChip('10-6 야간', const TimeOfDay(hour: 22, minute: 0),
                const TimeOfDay(hour: 6, minute: 0), 30, true),
            _presetChip(
                language.text('휴게 없음', 'No break'), _start, _end, 0, _isNight),
          ],
        ),
      ],
    );
  }

  Widget _timeControl({
    required String label,
    required TimeOfDay time,
    required ValueChanged<TimeOfDay> onPick,
    required ValueChanged<int> onAdjust,
  }) {
    final language = ref.watch(appLanguageProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.softBlack)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardSurfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.glassStroke),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: language.text('$label 15분 전', '$label -15 min'),
                onPressed: () => onAdjust(-15),
                icon: const Icon(Icons.remove, size: 18),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () => _pickTime(time, onPick),
                  child: Text(
                    _formatTime(time),
                    style: const TextStyle(
                      color: AppColors.deepInk,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: language.text('$label 15분 후', '$label +15 min'),
                onPressed: () => onAdjust(15),
                icon: const Icon(Icons.add, size: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _breakSelector() {
    final language = ref.watch(appLanguageProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          language.text('휴게시간: $_breakMinutes 분', 'Break: $_breakMinutes min'),
          style: const TextStyle(
            color: AppColors.deepInk,
            fontWeight: FontWeight.w700,
          ),
        ),
        Slider(
          value: _breakMinutes.toDouble(),
          min: 0,
          max: 180,
          divisions: 12,
          label: '$_breakMinutes 분',
          onChanged: (value) => setState(() => _breakMinutes = value.round()),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [0, 15, 30, 45, 60].map((minutes) {
            return ChoiceChip(
              label: Text(language.text('$minutes분', '${minutes}m')),
              selected: _breakMinutes == minutes,
              backgroundColor: AppColors.cardSurfaceAlt,
              selectedColor: AppColors.vividOrange.withValues(alpha: 0.3),
              side: const BorderSide(color: AppColors.glassStroke),
              labelStyle: const TextStyle(color: AppColors.deepInk),
              onSelected: (_) => setState(() => _breakMinutes = minutes),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _typeSelector() {
    final language = ref.watch(appLanguageProvider);
    final items = [
      (WorkType.weekday, language.text('평일', 'Weekday')),
      (WorkType.saturday, language.text('토', 'Sat')),
      (WorkType.sunday, language.text('일', 'Sun')),
      (WorkType.holiday, language.text('공휴', 'Holiday')),
      (WorkType.dayOff, language.text('휴무', 'Day off')),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          language.text('근무 유형', 'Work type'),
          style: const TextStyle(
            color: AppColors.deepInk,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            return ChoiceChip(
              label: Text(item.$2),
              selected: _type == item.$1,
              backgroundColor: AppColors.cardSurfaceAlt,
              selectedColor: AppColors.vividOrange.withValues(alpha: 0.3),
              side: const BorderSide(color: AppColors.glassStroke),
              labelStyle: const TextStyle(color: AppColors.deepInk),
              onSelected: (_) {
                setState(() {
                  _type = item.$1;
                  _typeTouched = true;
                  if (_type == WorkType.dayOff) {
                    _breakMinutes = 0;
                    _isNight = false;
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _dayOffNotice() {
    final language = ref.watch(appLanguageProvider);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.serenityBlue.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.serenityBlue.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.beach_access_outlined, color: AppColors.deepInk),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              language.text(
                '휴무로 저장됩니다. 급여, 총 근무시간, 연차 적립 계산에는 포함되지 않아요.',
                'Saved as a day off. It will not count toward pay, total hours, or leave accrual.',
              ),
              style: const TextStyle(
                color: AppColors.deepInk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _payPreview(dynamic tempPay) {
    final language = ref.watch(appLanguageProvider);
    if (_type == WorkType.dayOff) {
      return Text(
        language.text(
          '휴무는 달력 표시용으로 저장되고 급여 계산에는 들어가지 않습니다.',
          'Day off is saved for calendar visibility and excluded from pay calculations.',
        ),
        style: const TextStyle(color: AppColors.softBlack),
      );
    }
    if (tempPay == null) {
      return Text(
        language.text(
          '종료 시간이 시작 시간보다 빠르면 다음날 퇴근으로 계산합니다.',
          'If the end time is earlier than the start time, it is treated as next-day finish.',
        ),
        style: const TextStyle(color: AppColors.softBlack),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardSurfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassStroke),
      ),
      child: Text(
        language.text(
          '예상 일급 세전 ${tempPay.gross.toStringAsFixed(2)} · 세후 ${tempPay.net.toStringAsFixed(2)} · ${tempPay.totalHours.toStringAsFixed(2)}h',
          'Estimated day pay gross ${tempPay.gross.toStringAsFixed(2)} · net ${tempPay.net.toStringAsFixed(2)} · ${tempPay.totalHours.toStringAsFixed(2)}h',
        ),
        style: const TextStyle(
          color: AppColors.deepInk,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _saveButtons(bool isEditing) {
    final language = ref.watch(appLanguageProvider);
    if (isEditing) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () => _save(),
          icon: const Icon(Icons.save_outlined),
          label: Text(language.text('수정 저장', 'Save changes')),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () => _save(advanceDay: true),
          icon: const Icon(Icons.playlist_add_check),
          label: Text(language.text('저장 후 다음날 입력', 'Save and enter next day')),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _save(),
          icon: const Icon(Icons.add),
          label: Text(language.text('이 날짜에 저장만 하기', 'Save this date only')),
        ),
      ],
    );
  }

  Widget _dayEntriesSection(List<WorkEntry> entries, DateFormat formatter) {
    final language = ref.watch(appLanguageProvider);
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_dateWithWeekday(_date, formatter, language)} ${language.text('기록', 'entries')}',
            style: const TextStyle(
              color: AppColors.deepInk,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            Text(
              language.text(
                '이 날짜에는 아직 기록이 없습니다.',
                'No entries for this date yet.',
              ),
              style: const TextStyle(color: AppColors.softBlack),
            )
          else
            ...entries.map((entry) => _entryTile(entry, formatter)),
        ],
      ),
    );
  }

  Widget _weekToolsSection(
    List<WorkEntry> entries,
    DateFormat formatter,
    DateTime weekStart,
    DateTime weekEnd,
  ) {
    final language = ref.watch(appLanguageProvider);
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  language.text(
                    '이번 주 기록 ${entries.length}개',
                    'This week: ${entries.length} entries',
                  ),
                  style: const TextStyle(
                    color: AppColors.deepInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: language.text(
                  '지난주를 다음주로 복사',
                  'Copy last week to next week',
                ),
                onPressed: _copyLastWeekForward,
                icon: const Icon(Icons.content_copy),
              ),
            ],
          ),
          Text(
            '${_dateWithWeekday(weekStart, formatter, language)} ~ ${_dateWithWeekday(weekEnd, formatter, language)}',
            style: const TextStyle(color: AppColors.softBlack, fontSize: 12),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _copyLastWeekForward,
            icon: const Icon(Icons.copy_all_outlined),
            label: Text(
              language.text(
                '지난주 패턴을 다음주로 복사',
                'Copy last week pattern to next week',
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            Text(
              language.text(
                '주간 기록이 없습니다. 위에서 빠르게 추가해보세요.',
                'No weekly entries yet. Add one above.',
              ),
              style: const TextStyle(color: AppColors.softBlack),
            )
          else
            ...entries.take(10).map((entry) => _entryTile(entry, formatter)),
        ],
      ),
    );
  }

  Widget _entryTile(WorkEntry entry, DateFormat formatter) {
    final language = ref.watch(appLanguageProvider);
    final isDayOff = entry.type == WorkType.dayOff;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        isDayOff
            ? '${_dateWithWeekday(entry.date, formatter, language)} ${language.text('휴무', 'Day off')}'
            : '${_dateWithWeekday(entry.date, formatter, language)} ${_formatTimeOfDate(entry.start)}-${_formatTimeOfDate(entry.end)}',
        style: const TextStyle(
          color: AppColors.deepInk,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        isDayOff
            ? '${_typeLabel(entry.type, language)} · ${language.text('급여 계산 제외', 'Excluded from pay')}${entry.note.isEmpty ? '' : ' · ${entry.note}'}'
            : '${_typeLabel(entry.type, language)} · ${entry.paidHours.toStringAsFixed(2)}h · ${language.text('휴게 ${entry.breakMinutes}분', 'break ${entry.breakMinutes}m')}${entry.note.isEmpty ? '' : ' · ${entry.note}'}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.softBlack),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: language.text('수정', 'Edit'),
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _openEditor(entry),
          ),
          IconButton(
            tooltip: language.text('삭제', 'Delete'),
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteEntry(entry),
          ),
        ],
      ),
      onTap: () => _openEditor(entry),
    );
  }

  Widget _presetChip(
    String label,
    TimeOfDay start,
    TimeOfDay end,
    int breakMinutes,
    bool night,
  ) {
    return ActionChip(
      label: Text(label),
      backgroundColor: AppColors.cardSurfaceAlt,
      side: const BorderSide(color: AppColors.glassStroke),
      labelStyle: const TextStyle(color: AppColors.deepInk),
      onPressed: () {
        setState(() {
          _start = start;
          _end = end;
          _breakMinutes = breakMinutes;
          _isNight = night;
        });
      },
    );
  }

  Widget _section({required Widget child}) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: child,
    );
  }

  Future<void> _pickDate() async {
    final picked = await showAppDatePicker(
      context: context,
      rule: ref.read(payRuleProvider),
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) _setDate(picked);
  }

  Future<void> _pickTime(
    TimeOfDay time,
    ValueChanged<TimeOfDay> onPick,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: time,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null) onPick(picked);
  }

  void _setDate(DateTime date) {
    setState(() {
      _date = _dateOnly(date);
      if (!_typeTouched || widget.entry == null) {
        _type = _defaultTypeForDate(_date);
        _typeTouched = false;
      }
    });
  }

  Future<void> _copyLastWeekForward() async {
    final copied =
        await ref.read(workEntriesProvider.notifier).copyLastWeekForward();
    if (!mounted) return;
    if (copied.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(_t('복사할 지난주 기록이 없습니다.', 'No last-week entries to copy.')),
        ),
      );
      return;
    }

    setState(() {
      _date = _dateOnly(copied.first.date);
      _type = _defaultTypeForDate(_date);
      _typeTouched = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _t(
            '${copied.length}개 기록을 다음주로 복사했습니다.',
            'Copied ${copied.length} entries to next week.',
          ),
        ),
      ),
    );
  }

  Future<void> _deleteEntry(WorkEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_t('기록 삭제', 'Delete entry')),
        content: Text(_t('이 근무 기록을 삭제할까요?', 'Delete this work entry?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_t('취소', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(_t('삭제', 'Delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(workEntriesProvider.notifier).remove(entry);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_t('근무 기록을 삭제했어요.', 'Work entry deleted.'))),
    );
  }

  void _openEditor(WorkEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WorkEntryFormScreen(entry: entry)),
    );
  }

  TimeOfDay _roundTo15(TimeOfDay time) {
    final totalMinutes = time.hour * 60 + time.minute;
    final rounded = (totalMinutes / 15).round() * 15;
    final hour = (rounded ~/ 60) % 24;
    final minute = rounded % 60;
    return TimeOfDay(hour: hour, minute: minute);
  }

  TimeOfDay _adjustTime(TimeOfDay time, int deltaMinutes) {
    final total = (time.hour * 60 + time.minute + deltaMinutes) % 1440;
    final normalized = total < 0 ? total + 1440 : total;
    return TimeOfDay(hour: normalized ~/ 60, minute: normalized % 60);
  }

  WorkEntry? _buildTempEntry() {
    if (_type == WorkType.dayOff) {
      final day = _dateOnly(_date);
      return _buildEntry(date: day, start: day, end: day);
    }

    final startDate = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _start.hour,
      _start.minute,
    );
    var endDate = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _end.hour,
      _end.minute,
    );
    if (endDate.isBefore(startDate) || endDate.isAtSameMomentAs(startDate)) {
      endDate = endDate.add(const Duration(days: 1));
    }

    final entry = _buildEntry(
      date: _date,
      start: startDate,
      end: endDate,
    );

    if (entry.paidHours <= 0) return null;
    return entry;
  }

  Future<void> _save({bool advanceDay = false}) async {
    final entry = _buildTempEntry();
    if (entry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('근무 시간이 올바르지 않습니다.', 'Work time is invalid.')),
        ),
      );
      return;
    }

    final notifier = ref.read(workEntriesProvider.notifier);
    final isEditing = widget.entry != null;

    if (isEditing) {
      await notifier.update(
        widget.entry!.copyWith(
          date: entry.date,
          start: entry.start,
          end: entry.end,
          breakMinutes: entry.breakMinutes,
          type: entry.type,
          note: entry.note,
          isNight: entry.isNight,
          leaveHoursUsed: widget.entry!.leaveHoursUsed,
          updatedAt: DateTime.now(),
        ),
      );
    } else {
      await notifier.add(
        entry.copyWith(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEditing ? _t('수정되었습니다.', 'Updated.') : _t('추가되었습니다.', 'Added.'),
        ),
      ),
    );
    if (isEditing) {
      Navigator.of(context).pop();
      return;
    }
    if (advanceDay) {
      _noteCtrl.clear();
      _setDate(_date.add(const Duration(days: 1)));
    }
  }

  WorkEntry _buildEntry({
    required DateTime date,
    required DateTime start,
    required DateTime end,
  }) {
    final existing = widget.entry;
    final isDayOff = _type == WorkType.dayOff;
    final normalizedDate = _dateOnly(date);
    final normalizedStart = isDayOff ? normalizedDate : start;
    final normalizedEnd = isDayOff ? normalizedDate : end;
    final normalizedBreak = isDayOff ? 0 : _breakMinutes;
    final normalizedNight = isDayOff ? false : _isNight;

    if (existing != null) {
      return existing.copyWith(
        date: normalizedDate,
        start: normalizedStart,
        end: normalizedEnd,
        breakMinutes: normalizedBreak,
        type: _type,
        note: _noteCtrl.text,
        isNight: normalizedNight,
        leaveHoursUsed: existing.leaveHoursUsed,
      );
    }

    return WorkEntry(
      date: normalizedDate,
      start: normalizedStart,
      end: normalizedEnd,
      breakMinutes: normalizedBreak,
      type: _type,
      note: _noteCtrl.text,
      isNight: normalizedNight,
      leaveHoursUsed: 0,
    );
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime _weekStart(DateTime date) {
    final onlyDate = _dateOnly(date);
    return onlyDate.subtract(Duration(days: onlyDate.weekday - 1));
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  WorkType _defaultTypeForDate(DateTime date) {
    if (date.weekday == DateTime.saturday) return WorkType.saturday;
    if (date.weekday == DateTime.sunday) return WorkType.sunday;
    return WorkType.weekday;
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeOfDate(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _dateWithWeekday(
    DateTime date,
    DateFormat formatter,
    AppLanguage language,
  ) {
    return '${formatter.format(date)} (${weekdayLabel(date, language)})';
  }

  String _typeLabel(WorkType type, AppLanguage language) {
    switch (type) {
      case WorkType.weekday:
        return language.text('평일', 'Weekday');
      case WorkType.saturday:
        return language.text('토요일', 'Saturday');
      case WorkType.sunday:
        return language.text('일요일', 'Sunday');
      case WorkType.holiday:
        return language.text('공휴일', 'Public holiday');
      case WorkType.dayOff:
        return language.text('휴무', 'Day off');
    }
  }

  String _t(String ko, String en) => ref.read(appLanguageProvider).text(ko, en);
}
