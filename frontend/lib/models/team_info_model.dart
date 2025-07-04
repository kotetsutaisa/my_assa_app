class TeamInfo {
  final String id;      // UUID なので String
  final String name;
  final String role;    // 'leader' / 'member' など

  const TeamInfo({
    required this.id,
    required this.name,
    required this.role,
  });

  factory TeamInfo.fromJson(Map<String, dynamic> json) {
    return TeamInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
      };
}