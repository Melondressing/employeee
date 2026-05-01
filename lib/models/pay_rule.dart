enum WorkType { weekday, saturday, sunday, holiday }

enum EmploymentType { fullTime, partTime, casual }

extension EmploymentTypeLabel on EmploymentType {
  String get label {
    switch (this) {
      case EmploymentType.fullTime:
        return 'Full-time';
      case EmploymentType.partTime:
        return 'Part-time';
      case EmploymentType.casual:
        return 'Casual';
    }
  }

  String get shortLabel {
    switch (this) {
      case EmploymentType.fullTime:
        return '풀타임';
      case EmploymentType.partTime:
        return '파트타임';
      case EmploymentType.casual:
        return '캐주얼';
    }
  }
}

/// Pay configuration and multipliers.
class PayRule {
  PayRule({
    required this.baseWage,
    this.employeeName = '',
    this.employerName = '',
    this.positionTitle = '',
    this.payrollId = '',
    this.employmentType = EmploymentType.partTime,
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
  final String employeeName;
  final String employerName;
  final String positionTitle;
  final String payrollId;
  final EmploymentType employmentType;
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

  bool get isCasual => employmentType == EmploymentType.casual;

  double get effectiveLeaveAccrualPerHour {
    return isCasual ? 0 : leaveAccrualPerHour;
  }

  PayRule copyWith({
    double? baseWage,
    String? employeeName,
    String? employerName,
    String? positionTitle,
    String? payrollId,
    EmploymentType? employmentType,
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
      employeeName: employeeName ?? this.employeeName,
      employerName: employerName ?? this.employerName,
      positionTitle: positionTitle ?? this.positionTitle,
      payrollId: payrollId ?? this.payrollId,
      employmentType: employmentType ?? this.employmentType,
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
        'employeeName': employeeName,
        'employerName': employerName,
        'positionTitle': positionTitle,
        'payrollId': payrollId,
        'employmentType': employmentType.name,
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
      employeeName: json['employeeName']?.toString() ?? '',
      employerName: json['employerName']?.toString() ?? '',
      positionTitle: json['positionTitle']?.toString() ?? '',
      payrollId: json['payrollId']?.toString() ?? '',
      employmentType: _employmentTypeFromJson(json['employmentType']),
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

  static EmploymentType _employmentTypeFromJson(dynamic value) {
    if (value is int && value >= 0 && value < EmploymentType.values.length) {
      return EmploymentType.values[value];
    }
    final raw = value?.toString();
    return EmploymentType.values.firstWhere(
      (type) => type.name == raw,
      orElse: () => EmploymentType.partTime,
    );
  }
}
