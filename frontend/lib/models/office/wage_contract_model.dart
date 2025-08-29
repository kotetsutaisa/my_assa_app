// lib/models/office/wage_contract_model.dart
class WageContractModel {
  final int id;
  final int userId;
  final String payType; // 'monthly'|'daily'|'hourly'|'piecework'
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
  final String? monthlySalary;
  final String? dailyWage;
  final String? hourlyWage;
  final Map<String, dynamic> pieceworkSchemaJson;
  final bool overrideCompanyPolicy;
  final String? customOvertimeRateMultiplier;
  final String? customNightRateMultiplier;

  WageContractModel({
    required this.id,
    required this.userId,
    required this.payType,
    required this.effectiveFrom,
    this.effectiveTo,
    this.monthlySalary,
    this.dailyWage,
    this.hourlyWage,
    this.pieceworkSchemaJson = const {},
    this.overrideCompanyPolicy = false,
    this.customOvertimeRateMultiplier,
    this.customNightRateMultiplier,
  });

  factory WageContractModel.fromJson(Map<String, dynamic> j) {
    return WageContractModel(
      id: j['id'],
      userId: j['user_id'] ?? j['user'] ?? 0,
      payType: j['pay_type'],
      effectiveFrom: DateTime.parse(j['effective_from']),
      effectiveTo: j['effective_to'] != null ? DateTime.parse(j['effective_to']) : null,
      monthlySalary: j['monthly_salary']?.toString(),
      dailyWage: j['daily_wage']?.toString(),
      hourlyWage: j['hourly_wage']?.toString(),
      pieceworkSchemaJson: Map<String, dynamic>.from(j['piecework_schema_json'] ?? const {}),
      overrideCompanyPolicy: j['override_company_policy'] ?? false,
      customOvertimeRateMultiplier: j['custom_overtime_rate_multiplier']?.toString(),
      customNightRateMultiplier: j['custom_night_rate_multiplier']?.toString(),
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'user_id': userId,
        'pay_type': payType,
        'effective_from': _d(effectiveFrom),
        'effective_to': effectiveTo != null ? _d(effectiveTo!) : null,
        'monthly_salary': monthlySalary,
        'daily_wage': dailyWage,
        'hourly_wage': hourlyWage,
        'piecework_schema_json': pieceworkSchemaJson,
        'override_company_policy': overrideCompanyPolicy,
        'custom_overtime_rate_multiplier': customOvertimeRateMultiplier,
        'custom_night_rate_multiplier': customNightRateMultiplier,
      };

  Map<String, dynamic> toPatchJson() => {
        'pay_type': payType,
        'effective_from': _d(effectiveFrom),
        'effective_to': effectiveTo != null ? _d(effectiveTo!) : null,
        'monthly_salary': monthlySalary,
        'daily_wage': dailyWage,
        'hourly_wage': hourlyWage,
        'piecework_schema_json': pieceworkSchemaJson,
        'override_company_policy': overrideCompanyPolicy,
        'custom_overtime_rate_multiplier': customOvertimeRateMultiplier,
        'custom_night_rate_multiplier': customNightRateMultiplier,
      };

  String _d(DateTime x) => '${x.year.toString().padLeft(4, '0')}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}';
}
