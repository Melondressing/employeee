import 'pay_rule.dart';

class WorkEntry {
  WorkEntry({
    required this.date,
    required this.start,
    required this.end,
    this.breakMinutes = 0,
    this.type = WorkType.weekday,
    this.note = '',
    this.isNight = false,
    this.leaveHoursUsed = 0,
  });

  final DateTime date;
  final DateTime start;
  final DateTime end;
  final int breakMinutes;
  final WorkType type;
  final String note;
  final bool isNight;
  final double leaveHoursUsed;

  double get paidHours =>
      end.difference(start).inMinutes / 60 - breakMinutes / 60.0;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'breakMinutes': breakMinutes,
        'type': type.index,
        'note': note,
        'isNight': isNight,
        'leaveHoursUsed': leaveHoursUsed,
      };

  factory WorkEntry.fromJson(Map<String, dynamic> json) {
    return WorkEntry(
      date: DateTime.parse(json['date']),
      start: DateTime.parse(json['start']),
      end: DateTime.parse(json['end']),
      breakMinutes: json['breakMinutes'] ?? 0,
      type: WorkType.values[json['type'] ?? 0],
      note: json['note'] ?? '',
      isNight: json['isNight'] ?? false,
      leaveHoursUsed: (json['leaveHoursUsed'] ?? 0).toDouble(),
    );
  }
}
