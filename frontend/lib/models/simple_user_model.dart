import 'package:frontend/exceptions/user_role.dart';
import 'package:frontend/models/team_info_model.dart';

class SimpleUserModel {
  final int id;
  final String email;
  final String username;
  final String accountId;
  final String? iconimg;
  final UserRole role;
  final List<TeamInfo> teams;

  SimpleUserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.accountId,
    this.iconimg,
    required this.role,
    required this.teams,
  });

  factory SimpleUserModel.fromJson(Map<String, dynamic> json) {
    return SimpleUserModel(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      accountId: json['account_id'],
      iconimg: json['iconimg'],
      role: UserRoleX.fromApi(json['role'] as String?),
      teams: ((json['teams'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((e) => TeamInfo.fromJson(e))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'username': username,
    'account_id': accountId,
    'iconimg': iconimg,
    'role': role.apiValue,
    'teams': teams.map((t) => t.toJson()).toList(growable: false),
  };


  // --- UI ヘルパ ---
  String get roleJa => role.labelJa;
  String get primaryTeamName => teams.isEmpty ? '—' : teams.first.name;
  String get allTeamNames => teams.isEmpty ? '—' : teams.map((t) => t.name).join('・');
}
