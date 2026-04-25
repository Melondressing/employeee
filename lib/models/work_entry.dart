import 'dart:math';

import 'pay_rule.dart';

class WorkEntry {
  WorkEntry({
    String? id,
    required this.date,
    required this.start,
    required this.end,
    this.breakMinutes = 0,
    this.type = WorkType.weekday,
    this.note = '',
    this.isNight = false,
    this.leaveHoursUsed = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? generateId(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  final String id;
  final DateTime date;
  final DateTime start;
  final DateTime end;
  final int breakMinutes;
  final WorkType type;
  final String note;
  final bool isNight;
  final double leaveHoursUsed;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get paidHours =>
      end.difference(start).inMinutes / 60 - breakMinutes / 60.0;

  WorkEntry copyWith({
    String? id,
    DateTime? date,
    DateTime? start,
    DateTime? end,
    int? breakMinutes,
    WorkType? type,
    String? note,
    bool? isNight,
    double? leaveHoursUsed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      start: start ?? this.start,
      end: end ?? this.end,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      type: type ?? this.type,
      note: note ?? this.note,
      isNight: isNight ?? this.isNight,
      leaveHoursUsed: leaveHoursUsed ?? this.leaveHoursUsed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'breakMinutes': breakMinutes,
        'type': type.index,
        'note': note,
        'isNight': isNight,
        'leaveHoursUsed': leaveHoursUsed,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory WorkEntry.fromJson(Map<String, dynamic> json) {
    final date = DateTime.parse(json['date'] as String);
    final start = DateTime.parse(json['start'] as String);
    final end = DateTime.parse(json['end'] as String);
    final createdAt = _parseDateTime(json['createdAt']) ?? date;
    final updatedAt = _parseDateTime(json['updatedAt']) ?? createdAt;

    return WorkEntry(
      id: json['id'] as String?,
      date: date,
      start: start,
      end: end,
      breakMinutes: json['breakMinutes'] ?? 0,
      type: WorkType.values[json['type'] ?? 0],
      note: json['note'] ?? '',
      isNight: json['isNight'] ?? false,
      leaveHoursUsed: (json['leaveHoursUsed'] ?? 0).toDouble(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static String generateId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final rand = Random().nextInt(1 << 32).toRadixString(16);
    return 'we_${now}_$rand';
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
