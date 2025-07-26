// ユーザー情報を使いやすくする

import 'package:frontend/exceptions/user_role.dart';
import 'package:frontend/models/company_model.dart';
import 'package:frontend/models/team_info_model.dart';

class UserModel {
  final int id;
  final String email;
  final String username;
  final String accountId;
  final String? iconimg;
  final String? bio;
  final Company? company;
  final UserRole role;
  final List<TeamInfo> teams;

  // 引数セットと値代入
  // requiredは引数を必須にしてる
  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.accountId,
    required this.role,
    this.iconimg,
    this.bio,
    this.company,
    this.teams = const [],
  });

  // factory = "インスタンス作成の柔軟なコントローラー"
  // 引数で受け取ったMap型のjsonをUserModelにセット(インスタンス化)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final teamsJson = (json['teams'] as List?) ?? const [];
    return UserModel(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      accountId: json['account_id'],
      bio: json['bio'] ?? '',
      iconimg: json['iconimg'],
      company: json['company'] != null ? Company.fromJson(json['company']) : null,
      role: UserRoleX.fromApi(json['role'] as String?),
      teams    : teamsJson.map((t) => TeamInfo.fromJson(t as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson({bool includeRole = true, bool includeCompany = false}) {
    final map = <String, dynamic>{
      'id'        : id,
      'username'  : username,
      'account_id': accountId,
      'email'     : email,
      'iconimg'   : iconimg,
      'bio'       : bio,
    };
    if (includeRole) {
      map['role'] = role.apiValue;
    }
    if (includeCompany && company != null) {
      // API が company ID だけ受け付けるなら company.id に書き換え
      map['company'] = company!.id;
    }
    return map;
  }


  // ---------------- copyWith ----------------
  UserModel copyWith({
    String? email,
    String? username,
    String? accountId,
    String? iconimg,
    String? bio,
    Company? company,
    UserRole? role,
    List<TeamInfo>? teams,
  }) {
    return UserModel(
      id        : id,
      email     : email     ?? this.email,
      username  : username  ?? this.username,
      accountId : accountId ?? this.accountId,
      iconimg   : iconimg   ?? this.iconimg,
      bio       : bio       ?? this.bio,
      company   : company   ?? this.company,
      role      : role      ?? this.role,
      teams     : teams     ?? this.teams,
    );
  }

  // 権限ショートカット
  bool get isAdmin   => role == UserRole.admin;
  bool get isManager => role == UserRole.manager;
  bool get isMember  => role == UserRole.member || role == UserRole.unknown;
  bool get canManageResources => role.canManageResources;
  bool get hasTeam          => teams.isNotEmpty;
}
