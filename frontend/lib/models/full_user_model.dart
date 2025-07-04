import 'package:frontend/models/company_model.dart';
import 'package:frontend/models/team_info_model.dart';

class FullUserModel {
  final int id;
  final String email;
  final String username;
  final String accountId;
  final String? iconUrl;     // Image は URL だけ保持
  final String? bio;
  final Company? company;
  final String role;         // 'admin' / 'manager' / 'member'
  final bool isActive;
  final DateTime dateJoined;
  final TeamInfo? team; // 所属チーム情報

  const FullUserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.accountId,
    this.iconUrl,
    this.bio,
    this.company,
    required this.role,
    required this.isActive,
    required this.dateJoined,
    this.team,
  });

  /// JSON → Model
  factory FullUserModel.fromJson(Map<String, dynamic> json) {
    return FullUserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      username: json['username'] as String,
      accountId: json['account_id'] as String,
      iconUrl: json['iconimg'] as String?,
      bio: json['bio'] as String?,
      company: json['company'] != null
          ? Company.fromJson(json['company'])
          : null,
      role: json['role'] as String,
      isActive: json['is_active'] as bool,
      dateJoined: DateTime.parse(json['date_joined']).toLocal(),
      team: json['team'] != null ? TeamInfo.fromJson(json['team']) : null,
    );
  }

  /// Model → JSON（必要なら）
  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'username': username,
        'account_id': accountId,
        'iconimg': iconUrl,
        'bio': bio,
        'company': company?.toJson(),
        'role': role,
        'is_active': isActive,
        'date_joined': dateJoined.toIso8601String(),
        'team': team?.toJson(),
      };
}