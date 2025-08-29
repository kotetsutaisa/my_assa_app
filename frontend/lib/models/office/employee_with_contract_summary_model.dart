// lib/models/office/employee_with_contract_summary_model.dart
import 'package:frontend/models/simple_user_model.dart';

class EmployeeWithContractSummary {
  final SimpleUserModel user;
  /// 例: "時給 ¥1,500" / "月給 ¥300,000" / "出来高（設定あり）" / null（契約なし）
  final String? mainRateLabel;
  /// ISO8601をDateTimeに。サーバー側がnullを返すこともあるのでnullable。
  final DateTime? updatedAt;

  const EmployeeWithContractSummary({
    required this.user,
    this.mainRateLabel,
    this.updatedAt,
  });

  factory EmployeeWithContractSummary.fromJson(Map<String, dynamic> json) {
    return EmployeeWithContractSummary(
      user: SimpleUserModel.fromJson(json['user'] as Map<String, dynamic>),
      mainRateLabel: json['main_rate_label'] as String?,
      updatedAt: (json['updated_at'] == null || (json['updated_at'] as String).isEmpty)
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'user': user.toJson(),
        'main_rate_label': mainRateLabel,
        'updated_at': updatedAt?.toIso8601String(),
      };

  EmployeeWithContractSummary copyWith({
    SimpleUserModel? user,
    String? mainRateLabel,
    DateTime? updatedAt,
  }) {
    return EmployeeWithContractSummary(
      user: user ?? this.user,
      mainRateLabel: mainRateLabel ?? this.mainRateLabel,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 一覧APIの配列をまとめてパースしたいとき用ユーティリティ
  static List<EmployeeWithContractSummary> listFromJson(List<dynamic> jsonList) {
    return jsonList
        .map((e) => EmployeeWithContractSummary.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}
