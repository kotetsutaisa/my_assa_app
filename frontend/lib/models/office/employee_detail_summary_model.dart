// lib/models/office/employee_detail_summary_model.dart
import 'package:frontend/models/simple_user_model.dart';
import 'package:frontend/models/office/wage_contract_model.dart';

class EmployeeDetailSummary {
  final SimpleUserModel user;
  final WageContractModel? currentContract;
  final EmployeeDetailLabels labels;
  final EmployeeDetailMeta meta;
  final DateTime? updatedAt;

  const EmployeeDetailSummary({
    required this.user,
    required this.currentContract,
    required this.labels,
    required this.meta,
    required this.updatedAt,
  });

  factory EmployeeDetailSummary.fromJson(Map<String, dynamic> json) {
    return EmployeeDetailSummary(
      user: SimpleUserModel.fromJson(json['user'] as Map<String, dynamic>),
      currentContract: json['current_contract'] == null
          ? null
          : WageContractModel.fromJson(json['current_contract'] as Map<String, dynamic>),
      labels: EmployeeDetailLabels.fromJson(json['labels'] as Map<String, dynamic>),
      meta: EmployeeDetailMeta.fromJson(json['meta'] as Map<String, dynamic>),
      updatedAt: (json['updated_at'] == null || (json['updated_at'] as String).isEmpty)
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'user': user.toJson(),
        'labels': labels.toJson(),
        'meta': meta.toJson(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  EmployeeDetailSummary copyWith({
    SimpleUserModel? user,
    WageContractModel? currentContract,
    EmployeeDetailLabels? labels,
    EmployeeDetailMeta? meta,
    DateTime? updatedAt,
  }) {
    return EmployeeDetailSummary(
      user: user ?? this.user,
      currentContract: currentContract ?? this.currentContract,
      labels: labels ?? this.labels,
      meta: meta ?? this.meta,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // 便利アクセサ（UIで使いやすく）
  String? get mainRateLabel => labels.mainRateLabel;
  String get roleLabelJa => labels.roleLabelJa;
  String get primaryTeamName => labels.primaryTeamName;
  bool get hasOverride => meta.hasOverride;
}

class EmployeeDetailLabels {
  final String? mainRateLabel;   // 例: "時給 ¥1,500" / "月給 ¥300,000" / "出来高（設定あり）" / null
  final String roleLabelJa;      // 例: "管理者" / "部長" / "事務員" / "一般"
  final String primaryTeamName;  // 例: "Aチーム"（チームが無ければ "—"）

  const EmployeeDetailLabels({
    required this.mainRateLabel,
    required this.roleLabelJa,
    required this.primaryTeamName,
  });

  factory EmployeeDetailLabels.fromJson(Map<String, dynamic> json) {
    return EmployeeDetailLabels(
      mainRateLabel: json['main_rate_label'] as String?,
      roleLabelJa: (json['role_label_ja'] as String?) ?? '—',
      primaryTeamName: (json['primary_team_name'] as String?) ?? '—',
    );
  }

  Map<String, dynamic> toJson() => {
        'main_rate_label': mainRateLabel,
        'role_label_ja': roleLabelJa,
        'primary_team_name': primaryTeamName,
      };

  EmployeeDetailLabels copyWith({
    String? mainRateLabel,
    String? roleLabelJa,
    String? primaryTeamName,
  }) {
    return EmployeeDetailLabels(
      mainRateLabel: mainRateLabel ?? this.mainRateLabel,
      roleLabelJa: roleLabelJa ?? this.roleLabelJa,
      primaryTeamName: primaryTeamName ?? this.primaryTeamName,
    );
  }
}

class EmployeeDetailMeta {
  final bool hasOverride; // 契約が会社ポリシーを上書きしているか

  const EmployeeDetailMeta({required this.hasOverride});

  factory EmployeeDetailMeta.fromJson(Map<String, dynamic> json) {
    return EmployeeDetailMeta(
      hasOverride: (json['has_override'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'has_override': hasOverride,
      };

  EmployeeDetailMeta copyWith({bool? hasOverride}) {
    return EmployeeDetailMeta(
      hasOverride: hasOverride ?? this.hasOverride,
    );
  }
}
