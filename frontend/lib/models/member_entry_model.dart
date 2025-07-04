import 'package:frontend/models/full_user_model.dart';

sealed class MemberEntry {
  const MemberEntry();
  factory MemberEntry.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'admin':
      case 'no_team_manager':
      case 'no_team_member':
        return SingleUserEntry(
          type: json['type'] as String,
          user: FullUserModel.fromJson(json['user']),
        );
      case 'team':
        return TeamEntry(
          teamId: json['team_id'] as String,
          teamName: json['team_name'] as String,
          members: (json['members'] as List<dynamic>)
              .map((m) => TeamMemberInfo.fromJson(m as Map<String, dynamic>))
              .toList(),
        );
      default:
        throw ArgumentError('unknown type ${json['type']}');
    }
  }
}

/// ② user + type だけ持つ行
class SingleUserEntry extends MemberEntry {
  final String type;              // admin / no_team_manager / no_team_member
  final FullUserModel user;
  const SingleUserEntry({required this.type, required this.user});
}

/// ③ team 行
class TeamEntry extends MemberEntry {
  final String teamId;
  final String teamName;
  final List<TeamMemberInfo> members;
  const TeamEntry({
    required this.teamId,
    required this.teamName,
    required this.members,
  });
}

/// ④ team 内の各メンバー
class TeamMemberInfo {
  final FullUserModel user;
  final String role;   // leader / member
  const TeamMemberInfo({required this.user, required this.role});

  factory TeamMemberInfo.fromJson(Map<String, dynamic> json) {
    return TeamMemberInfo(
      user: FullUserModel.fromJson(json['user']),
      role: json['role'] as String,
    );
  }
}
