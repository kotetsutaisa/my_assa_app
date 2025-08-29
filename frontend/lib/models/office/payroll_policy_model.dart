// lib/models/office/payroll_policy_model.dart
class PayrollPolicyModel {
  final int id;

  int? closingDay;      // 0 = 月末, 1–28
  int? payDay;          // 0 = 月末, 1–28
  int? payMonthOffset;  // 0=当月, 1=翌月, 2=翌々月

  int timeGranularityMinutes;
  String roundingMode; // 'nearest' | 'up' | 'down'
  List<BreakWindow> breaks;
  String overtimeStartsAt; // 'HH:MM:SS'
  String overtimeRateMultiplier; // Decimal string
  String nightStartsAt; // 'HH:MM:SS'
  String nightEndsAt;   // 'HH:MM:SS'
  String nightRateMultiplier;
  WeeklyHolidays weekly;
  List<String> customHolidays;
  List<String> customWorkdays;
  Map<String, dynamic> pieceworkDefaultsJson;
  String notes;

  PayrollPolicyModel({
    required this.id,

    this.closingDay,
    this.payDay,
    this.payMonthOffset,

    required this.timeGranularityMinutes,
    required this.roundingMode,
    required this.breaks,
    required this.overtimeStartsAt,
    required this.overtimeRateMultiplier,
    required this.nightStartsAt,
    required this.nightEndsAt,
    required this.nightRateMultiplier,
    required this.weekly,
    required this.customHolidays,
    required this.customWorkdays,
    required this.pieceworkDefaultsJson,
    required this.notes,
  });

  factory PayrollPolicyModel.fromJson(Map<String, dynamic> j) {
    return PayrollPolicyModel(
      id: j['id'] ?? 0,

      closingDay: j['closing_day'] is int ? j['closing_day'] as int : (j['closing_day'] == null ? 0 : int.tryParse('${j['closing_day']}')),
      payDay: j['pay_day'] is int ? j['pay_day'] as int : (j['pay_day'] == null ? 0 : int.tryParse('${j['pay_day']}')),
      payMonthOffset: j['pay_month_offset'] is int ? j['pay_month_offset'] as int : (j['pay_month_offset'] == null ? 1 : int.tryParse('${j['pay_month_offset']}')),

      timeGranularityMinutes: j['time_granularity_minutes'] ?? 15,
      roundingMode: j['rounding_mode'] ?? 'nearest',
      breaks: ((j['break_template_json'] as List?) ?? const [])
          .map((e) => BreakWindow.fromJson(e as Map<String, dynamic>))
          .toList(),
      overtimeStartsAt: j['overtime_starts_at'] ?? '17:00:00',
      overtimeRateMultiplier: (j['overtime_rate_multiplier'] ?? '1.25').toString(),
      nightStartsAt: j['night_starts_at'] ?? '22:00:00',
      nightEndsAt: j['night_ends_at'] ?? '05:00:00',
      nightRateMultiplier: (j['night_rate_multiplier'] ?? '1.25').toString(),
      weekly: WeeklyHolidays.fromJson((j['weekly_holidays'] ?? const {}) as Map<String, dynamic>),
      customHolidays: List<String>.from(j['custom_holidays'] ?? const []),
      customWorkdays: List<String>.from(j['custom_workdays'] ?? const []),
      pieceworkDefaultsJson: Map<String, dynamic>.from(j['piecework_defaults_json'] ?? const {}),
      notes: j['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'closing_day': closingDay ?? 0,
        'pay_day': payDay ?? 0,
        'pay_month_offset': payMonthOffset ?? 1,
        'time_granularity_minutes': timeGranularityMinutes,
        'rounding_mode': roundingMode,
        'break_template_json': breaks.map((e) => e.toJson()).toList(),
        'overtime_starts_at': overtimeStartsAt,
        'overtime_rate_multiplier': overtimeRateMultiplier,
        'night_starts_at': nightStartsAt,
        'night_ends_at': nightEndsAt,
        'night_rate_multiplier': nightRateMultiplier,
        'weekly_holidays': weekly.toJson(),
        'custom_holidays': customHolidays,
        'custom_workdays': customWorkdays,
        'piecework_defaults_json': pieceworkDefaultsJson,
        'notes': notes,
      };
}

class BreakWindow {
  String start; // 'HH:MM'
  String end;   // 'HH:MM'
  BreakWindow({required this.start, required this.end});
  factory BreakWindow.fromJson(Map<String, dynamic> j) =>
      BreakWindow(start: j['start'] ?? '00:00', end: j['end'] ?? '00:00');
  Map<String, dynamic> toJson() => {'start': start, 'end': end};
}

class WeeklyHolidays {
  bool sun, mon, tue, wed, thu, fri, sat, holiday;
  WeeklyHolidays({
    required this.sun,
    required this.mon,
    required this.tue,
    required this.wed,
    required this.thu,
    required this.fri,
    required this.sat,
    required this.holiday,
  });
  factory WeeklyHolidays.fromJson(Map<String, dynamic> j) => WeeklyHolidays(
        sun: j['sun'] ?? false,
        mon: j['mon'] ?? false,
        tue: j['tue'] ?? false,
        wed: j['wed'] ?? false,
        thu: j['thu'] ?? false,
        fri: j['fri'] ?? false,
        sat: j['sat'] ?? false,
        holiday: j['holiday'] ?? false,
      );
  Map<String, dynamic> toJson() => {
        'sun': sun,
        'mon': mon,
        'tue': tue,
        'wed': wed,
        'thu': thu,
        'fri': fri,
        'sat': sat,
        'holiday': holiday,
      };
}
