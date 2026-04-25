enum WorkType { weekday, saturday, sunday, holiday }

/// Pay configuration and multipliers.
class PayRule {
  PayRule({
    required this.baseWage,
    this.saturdayMultiplier = 1.25,
    this.sundayMultiplier = 1.5,
    this.holidayMultiplier = 2.0,
    this.taxRate = 0.15,
    this.localTaxRate = 0.0,
    this.insuranceRate = 0.0,
    this.nightMultiplier = 1.5,
    this.nightStartHour = 22,
    this.nightEndHour = 6,
    this.annualLeaveTotalHours = 0,
    this.annualLeaveUsedHours = 0,
    this.currency = 'AUD',
    this.payCycleLengthDays = 7,
    this.payPeriodStartWeekday = DateTime.monday,
    this.paydayWeekday = DateTime.friday,
    this.leaveAccrualPerHour = 0,
    this.country = 'Custom',
    this.taxNote = '',
    this.cycleAnchorDate,
  });

  final double baseWage;
  final double saturdayMultiplier;
  final double sundayMultiplier;
  final double holidayMultiplier;
  final double taxRate;
  final double localTaxRate; // 지방/주세 등
  final double insuranceRate; // 연금/보험
  final double nightMultiplier;
  final int nightStartHour;
  final int nightEndHour;
  final double annualLeaveTotalHours;
  final double annualLeaveUsedHours;
  final String currency;
  final int payCycleLengthDays; // usually 7
  final int payPeriodStartWeekday; // 1=Mon..7=Sun (cycle start)
  final int paydayWeekday; // payday following period end, 1..7
  final double leaveAccrualPerHour; // accrual hours per work hour
  final String country;
  final String taxNote;
  final DateTime? cycleAnchorDate;

  PayRule copyWith({
    double? baseWage,
    double? saturdayMultiplier,
    double? sundayMultiplier,
    double? holidayMultiplier,
    double? taxRate,
    double? localTaxRate,
    double? insuranceRate,
    double? nightMultiplier,
    int? nightStartHour,
    int? nightEndHour,
    double? annualLeaveTotalHours,
    double? annualLeaveUsedHours,
    String? currency,
    int? payCycleLengthDays,
    int? payPeriodStartWeekday,
    int? paydayWeekday,
    double? leaveAccrualPerHour,
    String? country,
    String? taxNote,
    DateTime? cycleAnchorDate,
  }) {
    return PayRule(
      baseWage: baseWage ?? this.baseWage,
      saturdayMultiplier: saturdayMultiplier ?? this.saturdayMultiplier,
      sundayMultiplier: sundayMultiplier ?? this.sundayMultiplier,
      holidayMultiplier: holidayMultiplier ?? this.holidayMultiplier,
      taxRate: taxRate ?? this.taxRate,
      localTaxRate: localTaxRate ?? this.localTaxRate,
      insuranceRate: insuranceRate ?? this.insuranceRate,
      nightMultiplier: nightMultiplier ?? this.nightMultiplier,
      nightStartHour: nightStartHour ?? this.nightStartHour,
      nightEndHour: nightEndHour ?? this.nightEndHour,
      annualLeaveTotalHours:
          annualLeaveTotalHours ?? this.annualLeaveTotalHours,
      annualLeaveUsedHours: annualLeaveUsedHours ?? this.annualLeaveUsedHours,
      currency: currency ?? this.currency,
      payCycleLengthDays: payCycleLengthDays ?? this.payCycleLengthDays,
      payPeriodStartWeekday:
          payPeriodStartWeekday ?? this.payPeriodStartWeekday,
      paydayWeekday: paydayWeekday ?? this.paydayWeekday,
      leaveAccrualPerHour: leaveAccrualPerHour ?? this.leaveAccrualPerHour,
      country: country ?? this.country,
      taxNote: taxNote ?? this.taxNote,
      cycleAnchorDate: cycleAnchorDate ?? this.cycleAnchorDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'baseWage': baseWage,
        'saturdayMultiplier': saturdayMultiplier,
        'sundayMultiplier': sundayMultiplier,
        'holidayMultiplier': holidayMultiplier,
        'taxRate': taxRate,
        'localTaxRate': localTaxRate,
        'insuranceRate': insuranceRate,
        'nightMultiplier': nightMultiplier,
        'nightStartHour': nightStartHour,
        'nightEndHour': nightEndHour,
        'annualLeaveTotalHours': annualLeaveTotalHours,
        'annualLeaveUsedHours': annualLeaveUsedHours,
        'currency': currency,
        'payCycleLengthDays': payCycleLengthDays,
        'payPeriodStartWeekday': payPeriodStartWeekday,
        'paydayWeekday': paydayWeekday,
        'leaveAccrualPerHour': leaveAccrualPerHour,
        'country': country,
        'taxNote': taxNote,
        'cycleAnchorDate': cycleAnchorDate?.toIso8601String(),
      };

  factory PayRule.fromJson(Map<String, dynamic> json) {
    return PayRule(
      baseWage: (json['baseWage'] ?? 0).toDouble(),
      saturdayMultiplier: (json['saturdayMultiplier'] ?? 1.25).toDouble(),
      sundayMultiplier: (json['sundayMultiplier'] ?? 1.5).toDouble(),
      holidayMultiplier: (json['holidayMultiplier'] ?? 2.0).toDouble(),
      taxRate: (json['taxRate'] ?? 0.15).toDouble(),
      localTaxRate: (json['localTaxRate'] ?? 0.0).toDouble(),
      insuranceRate: (json['insuranceRate'] ?? 0.0).toDouble(),
      nightMultiplier: (json['nightMultiplier'] ?? 1.5).toDouble(),
      nightStartHour: json['nightStartHour'] ?? 22,
      nightEndHour: json['nightEndHour'] ?? 6,
      annualLeaveTotalHours: (json['annualLeaveTotalHours'] ?? 0).toDouble(),
      annualLeaveUsedHours: (json['annualLeaveUsedHours'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'AUD',
      payCycleLengthDays: json['payCycleLengthDays'] ?? 7,
      payPeriodStartWeekday: json['payPeriodStartWeekday'] ?? DateTime.monday,
      paydayWeekday: json['paydayWeekday'] ?? DateTime.friday,
      leaveAccrualPerHour: (json['leaveAccrualPerHour'] ?? 0).toDouble(),
      country: json['country'] ?? 'Custom',
      taxNote: json['taxNote'] ?? '',
      cycleAnchorDate: json['cycleAnchorDate'] == null
          ? null
          : DateTime.tryParse(json['cycleAnchorDate'].toString()),
    );
  }
}
