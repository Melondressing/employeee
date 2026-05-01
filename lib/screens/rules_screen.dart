import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/pay_rule.dart';
import '../services/providers.dart';
import '../services/storage.dart';
import '../theme/colors.dart';
import '../widgets/app_date_picker.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/glass_card.dart';

class RulesScreen extends ConsumerStatefulWidget {
  const RulesScreen({super.key});
  static const route = '/rules';

  @override
  ConsumerState<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends ConsumerState<RulesScreen> {
  late final TextEditingController _baseWage;
  late final TextEditingController _sat;
  late final TextEditingController _sun;
  late final TextEditingController _holiday;
  late final TextEditingController _night;
  late final TextEditingController _tax;
  late final TextEditingController _localTax;
  late final TextEditingController _insurance;
  late final TextEditingController _leaveTotal;
  late final TextEditingController _leaveUsed;
  late final TextEditingController _leaveAccrual;
  late final TextEditingController _payCycleLength;

  int _periodStartWeekday = DateTime.monday;
  int _paydayWeekday = DateTime.friday;
  late DateTime _cycleAnchorDate;
  String _country = 'Custom';
  String _taxNote = '';
  String _currency = 'AUD';

  @override
  void initState() {
    super.initState();
    final rule = ref.read(payRuleProvider);
    _baseWage = TextEditingController(text: rule.baseWage.toString());
    _sat = TextEditingController(text: rule.saturdayMultiplier.toString());
    _sun = TextEditingController(text: rule.sundayMultiplier.toString());
    _holiday = TextEditingController(text: rule.holidayMultiplier.toString());
    _night = TextEditingController(text: rule.nightMultiplier.toString());
    _tax = TextEditingController(text: (rule.taxRate * 100).toString());
    _localTax =
        TextEditingController(text: (rule.localTaxRate * 100).toString());
    _insurance =
        TextEditingController(text: (rule.insuranceRate * 100).toString());
    _leaveTotal =
        TextEditingController(text: rule.annualLeaveTotalHours.toString());
    _leaveUsed =
        TextEditingController(text: rule.annualLeaveUsedHours.toString());
    _leaveAccrual =
        TextEditingController(text: rule.leaveAccrualPerHour.toString());
    _payCycleLength =
        TextEditingController(text: rule.payCycleLengthDays.toString());
    _periodStartWeekday = rule.payPeriodStartWeekday;
    _paydayWeekday = rule.paydayWeekday;
    _cycleAnchorDate = rule.cycleAnchorDate ?? _defaultCycleAnchor(rule);
    _country = rule.country;
    _taxNote = rule.taxNote;
    _currency = rule.currency;
  }

  @override
  void dispose() {
    _baseWage.dispose();
    _sat.dispose();
    _sun.dispose();
    _holiday.dispose();
    _night.dispose();
    _tax.dispose();
    _localTax.dispose();
    _insurance.dispose();
    _leaveTotal.dispose();
    _leaveUsed.dispose();
    _leaveAccrual.dispose();
    _payCycleLength.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Settings & Rules')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            children: [
              _sectionCard(
                title: 'Currency & Country',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _currencyGrid(),
                    const SizedBox(height: 6),
                    Text(
                      '선택: $_currency · $_country',
                      style: const TextStyle(
                          color: AppColors.softBlack, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _sectionCard(
                title: 'Hourly Wage',
                child: Column(
                  children: [
                    _numField(_baseWage, 'Hourly wage', suffix: _currency),
                    const SizedBox(height: 6),
                    _previewBlock(),
                  ],
                ),
              ),
              _sectionCard(
                title: 'Penalty Rates / Multipliers',
                child: Column(
                  children: [
                    _numField(_sat, 'Saturday ×'),
                    _numField(_sun, 'Sunday ×'),
                    _numField(_holiday, 'Public holiday ×'),
                    _numField(_night, 'Night loading ×'),
                  ],
                ),
              ),
              _sectionCard(
                title: 'Tax & Deductions',
                child: Column(
                  children: [
                    _numField(_tax, 'Income tax (%)'),
                    _numField(_localTax, 'Local / State tax (%)'),
                    _numField(_insurance, 'Super / Insurance (%)'),
                    if (_taxNote.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _taxNote,
                          style: const TextStyle(
                              color: AppColors.softBlack, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              _sectionCard(
                title: 'Pay Cycle',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _numField(_payCycleLength, 'Cycle length (days)',
                        suffix: '일'),
                    Wrap(
                      spacing: 8,
                      children: [
                        _chipButton('7', () => _payCycleLength.text = '7'),
                        _chipButton('14', () => _payCycleLength.text = '14'),
                        _chipButton('28', () => _payCycleLength.text = '28'),
                        _chipButton('30', () => _payCycleLength.text = '30'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      initialValue: _periodStartWeekday,
                      dropdownColor: AppColors.cardSurfaceStrong,
                      style: const TextStyle(color: AppColors.deepInk),
                      decoration:
                          const InputDecoration(labelText: 'Cycle start day'),
                      items: _weekdayItems(),
                      onChanged: (v) => setState(
                          () => _periodStartWeekday = v ?? DateTime.monday),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      initialValue: _paydayWeekday,
                      dropdownColor: AppColors.cardSurfaceStrong,
                      style: const TextStyle(color: AppColors.deepInk),
                      decoration: const InputDecoration(
                          labelText: 'Payday (0 = same day)'),
                      items: _weekdayItems(includeSameDay: true),
                      onChanged: (v) =>
                          setState(() => _paydayWeekday = v ?? DateTime.friday),
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.deepInk,
                        side: const BorderSide(color: AppColors.glassStroke),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          locale: calendarLocaleForCountry(
                            country: _country,
                            currency: _currency,
                          ),
                          initialDate: _cycleAnchorDate,
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 3650)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 3650)),
                        );
                        if (picked != null) {
                          setState(() {
                            _cycleAnchorDate =
                                DateTime(picked.year, picked.month, picked.day);
                          });
                        }
                      },
                      icon: const Icon(Icons.event_outlined),
                      label: Text(
                        'Cycle anchor: ${DateFormat('yyyy-MM-dd').format(_cycleAnchorDate)}',
                      ),
                    ),
                  ],
                ),
              ),
              _sectionCard(
                title: 'Annual Leave',
                child: Column(
                  children: [
                    _numField(_leaveTotal, 'Total leave (hours)'),
                    _numField(_leaveUsed, 'Used leave (hours)'),
                    _numField(_leaveAccrual, 'Accrual per work hour',
                        suffix: 'h'),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.golden,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _save,
                child: const Text('Save settings',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              _sectionCard(
                title: 'Backup & Restore',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.vividOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _exportBackup,
                      icon: const Icon(Icons.upload_outlined),
                      label: const Text('Export backup'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.deepInk,
                        side: const BorderSide(color: AppColors.glassStroke),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _importBackup,
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Import backup'),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Backups contain the pay rule and every saved work entry in JSON format.',
                      style:
                          TextStyle(color: AppColors.softBlack, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GlassCard(
        padding: const EdgeInsets.all(9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.deepInk,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            child,
          ],
        ),
      ),
    );
  }

  Widget _currencyGrid() {
    final items = <_CountryItem>[
      const _CountryItem(flag: '🇦🇺', currency: 'AUD', country: 'Australia'),
      const _CountryItem(flag: '🇳🇿', currency: 'NZD', country: 'New Zealand'),
      const _CountryItem(
          flag: '🇬🇧', currency: 'GBP', country: 'United Kingdom'),
      const _CountryItem(
          flag: '🇺🇸', currency: 'USD', country: 'United States'),
      const _CountryItem(flag: '🇯🇵', currency: 'JPY', country: 'Japan'),
      const _CountryItem(flag: '🇰🇷', currency: 'KRW', country: 'South Korea'),
      const _CountryItem(flag: '🇫🇷', currency: 'EUR', country: 'France'),
      const _CountryItem(flag: '🇮🇹', currency: 'EUR', country: 'Italy'),
      const _CountryItem(flag: '⭐', currency: 'CUSTOM', country: 'Custom'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 420;
        final isWide = constraints.maxWidth >= 520;
        final columns = isWide ? 4 : 3;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: isCompact ? 2 : 3,
            crossAxisSpacing: isCompact ? 2 : 3,
            childAspectRatio: isCompact ? 1.34 : 1.62,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final selected = item.country == _country;

            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                setState(() {
                  if (item.country == 'Custom') {
                    _country = 'Custom';
                    _taxNote = '사용자 지정 모드';
                  } else {
                    _country = item.country;
                    _currency = item.currency;
                    _applyCountryPreset(item.country);
                  }
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 7 : 9,
                  vertical: isCompact ? 5 : 6,
                ),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(
                          colors: [Color(0xFF5A3624), Color(0xFF3F2519)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : const LinearGradient(
                          colors: [Color(0xFF342016), Color(0xFF2A1912)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? AppColors.vividOrange
                        : AppColors.glassStroke,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      item.flag,
                      style: TextStyle(fontSize: isCompact ? 15 : 17),
                    ),
                    SizedBox(width: isCompact ? 6 : 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.currency,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.deepInk,
                              fontSize: isCompact ? 11 : 12,
                            ),
                          ),
                          Text(
                            item.country,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isCompact ? 9 : 10,
                              color: AppColors.softBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _numField(TextEditingController c, String label, {String? suffix}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        style: const TextStyle(color: AppColors.deepInk),
        cursorColor: AppColors.warmYellow,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true, signed: false),
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _chipButton(String label, VoidCallback onTap) {
    final selected = _payCycleLength.text == label;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.vividOrange.withValues(alpha: 0.35),
      backgroundColor: AppColors.cardSurfaceAlt,
      labelStyle: const TextStyle(color: AppColors.deepInk),
      side: const BorderSide(color: AppColors.glassStroke),
      onSelected: (_) => setState(onTap),
    );
  }

  Widget _previewBlock() {
    final wage = double.tryParse(_baseWage.text) ?? 0;
    final tax = (double.tryParse(_tax.text) ?? 0) / 100;
    final local = (double.tryParse(_localTax.text) ?? 0) / 100;
    final ins = (double.tryParse(_insurance.text) ?? 0) / 100;
    final gross8 = wage * 8;
    final net8 = gross8 * (1 - tax - local - ins);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: AppColors.cardSurfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassStroke),
      ),
      child: Row(
        children: [
          Expanded(child: _miniPreview('시급', '$wage $_currency')),
          const SizedBox(width: 8),
          Expanded(
              child: _miniPreview(
                  '8h 세전', '${gross8.toStringAsFixed(2)} $_currency')),
          const SizedBox(width: 8),
          Expanded(
              child: _miniPreview(
                  '8h 세후', '${net8.toStringAsFixed(2)} $_currency')),
        ],
      ),
    );
  }

  Widget _miniPreview(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.glassStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.softBlack)),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.deepInk,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<int>> _weekdayItems({bool includeSameDay = false}) {
    const names = ['월', '화', '수', '목', '금', '토', '일'];
    final items = List.generate(
      7,
      (i) => DropdownMenuItem(
        value: i + 1,
        child: Text(names[i], style: const TextStyle(color: AppColors.deepInk)),
      ),
    );

    if (includeSameDay) {
      items.insert(
        0,
        const DropdownMenuItem(
          value: 0,
          child: Text('기간 종료일과 동일', style: TextStyle(color: AppColors.deepInk)),
        ),
      );
    }

    return items;
  }

  void _applyCountryPreset(String country) {
    const presets = {
      'Australia': _CountryPreset(
        baseWage: 20,
        currency: 'AUD',
        tax: 0.15,
        local: 0.00,
        insurance: 0.107,
        saturday: 1.25,
        sunday: 1.50,
        holiday: 2.25,
        night: 1.25,
        note: '호주 예시: 세율 15%, 연금/보험 10.7%, 토 1.25·일 1.5·공휴 2.25',
      ),
      'New Zealand': _CountryPreset(
        baseWage: 20,
        currency: 'NZD',
        tax: 0.24,
        local: 0.00,
        insurance: 0.03,
        saturday: 1.0,
        sunday: 1.0,
        holiday: 1.5,
        night: 1.0,
        note: '뉴질랜드 예시: 공휴일 1.5배, 보험 3%',
      ),
      'United Kingdom': _CountryPreset(
        baseWage: 20,
        currency: 'GBP',
        tax: 0.20,
        local: 0.00,
        insurance: 0.08,
        saturday: 1.0,
        sunday: 1.0,
        holiday: 1.0,
        night: 1.0,
        note: '영국 예시: 소득세 20%, NI 8% (주말/공휴 가산은 계약에 따름)',
      ),
      'United States': _CountryPreset(
        baseWage: 20,
        currency: 'USD',
        tax: 0.22,
        local: 0.05,
        insurance: 0.0765,
        saturday: 1.0,
        sunday: 1.0,
        holiday: 1.0,
        night: 1.0,
        note: '미국 예시: 연방 22% + 주세 5% + FICA 7.65% (초과근무 1.5배)',
      ),
      'Japan': _CountryPreset(
        baseWage: 20,
        currency: 'JPY',
        tax: 0.10,
        local: 0.10,
        insurance: 0.14,
        saturday: 1.0,
        sunday: 1.0,
        holiday: 1.35,
        night: 1.25,
        note: '일본 예시: 잔업 1.25배, 심야 1.25배, 법정휴일 1.35배',
      ),
      'South Korea': _CountryPreset(
        baseWage: 20,
        currency: 'KRW',
        tax: 0.06,
        local: 0.02,
        insurance: 0.09,
        saturday: 1.0,
        sunday: 1.5,
        holiday: 1.5,
        night: 1.5,
        note: '한국 예시: 연장/야간/휴일 1.5배, 지방세 2%, 보험 9%',
      ),
      'France': _CountryPreset(
        baseWage: 20,
        currency: 'EUR',
        tax: 0.11,
        local: 0.00,
        insurance: 0.22,
        saturday: 1.0,
        sunday: 1.0,
        holiday: 2.0,
        night: 1.0,
        note: '프랑스 예시: 임금세 11% + 사회부담 22%, 5월1일 2배',
      ),
      'Italy': _CountryPreset(
        baseWage: 20,
        currency: 'EUR',
        tax: 0.15,
        local: 0.00,
        insurance: 0.10,
        saturday: 1.0,
        sunday: 1.0,
        holiday: 1.0,
        night: 1.0,
        note: '이탈리아 예시: IRPEF 15% + 보험 10% (가산율은 CCNL에 따름)',
      ),
    };

    final preset = presets[country];
    if (preset == null) return;

    _baseWage.text = preset.baseWage.toStringAsFixed(2);
    _currency = preset.currency;
    _tax.text = (preset.tax * 100).toStringAsFixed(2);
    _localTax.text = (preset.local * 100).toStringAsFixed(2);
    _insurance.text = (preset.insurance * 100).toStringAsFixed(2);
    _sat.text = preset.saturday.toStringAsFixed(2);
    _sun.text = preset.sunday.toStringAsFixed(2);
    _holiday.text = preset.holiday.toStringAsFixed(2);
    _night.text = preset.night.toStringAsFixed(2);
    _taxNote = preset.note;
  }

  void _save() {
    final newRule = PayRule(
      baseWage: double.tryParse(_baseWage.text) ?? 0,
      saturdayMultiplier: double.tryParse(_sat.text) ?? 1,
      sundayMultiplier: double.tryParse(_sun.text) ?? 1,
      holidayMultiplier: double.tryParse(_holiday.text) ?? 1,
      nightMultiplier: double.tryParse(_night.text) ?? 1,
      taxRate: (double.tryParse(_tax.text) ?? 0) / 100,
      localTaxRate: (double.tryParse(_localTax.text) ?? 0) / 100,
      insuranceRate: (double.tryParse(_insurance.text) ?? 0) / 100,
      annualLeaveTotalHours: double.tryParse(_leaveTotal.text) ?? 0,
      annualLeaveUsedHours: double.tryParse(_leaveUsed.text) ?? 0,
      leaveAccrualPerHour: double.tryParse(_leaveAccrual.text) ?? 0,
      payCycleLengthDays: int.tryParse(_payCycleLength.text) ?? 7,
      payPeriodStartWeekday: _periodStartWeekday,
      paydayWeekday: _paydayWeekday,
      cycleAnchorDate: DateTime(
          _cycleAnchorDate.year, _cycleAnchorDate.month, _cycleAnchorDate.day),
      country: _country,
      taxNote: _taxNote,
      currency: _currency,
    );

    ref.read(payRuleProvider.notifier).update(newRule);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장되었습니다.')),
      );
    }
  }

  Future<void> _exportBackup() async {
    final backup = await Storage.exportBackup();
    await Share.share(backup, subject: 'employeeee backup');
  }

  Future<void> _importBackup() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Import backup'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: TextField(
            controller: controller,
            maxLines: 14,
            decoration: const InputDecoration(
              labelText: 'Paste backup JSON',
              alignLabelWithHint: true,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      controller.dispose();
      return;
    }

    final ok = await Storage.importBackup(controller.text);
    controller.dispose();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup JSON is invalid.')),
      );
      return;
    }

    ref.invalidate(payRuleProvider);
    ref.invalidate(workEntriesProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup imported.')),
    );
  }

  DateTime _defaultCycleAnchor(PayRule rule) {
    final today = DateTime.now();
    final date = DateTime(today.year, today.month, today.day);
    final offset =
        (date.weekday - rule.payPeriodStartWeekday) % rule.payCycleLengthDays;
    return date.subtract(Duration(days: offset));
  }
}

class _CountryItem {
  const _CountryItem({
    required this.flag,
    required this.currency,
    required this.country,
  });

  final String flag;
  final String currency;
  final String country;
}

class _CountryPreset {
  const _CountryPreset({
    required this.baseWage,
    required this.currency,
    required this.tax,
    required this.local,
    required this.insurance,
    required this.saturday,
    required this.sunday,
    required this.holiday,
    required this.night,
    required this.note,
  });

  final double baseWage;
  final String currency;
  final double tax;
  final double local;
  final double insurance;
  final double saturday;
  final double sunday;
  final double holiday;
  final double night;
  final String note;
}
