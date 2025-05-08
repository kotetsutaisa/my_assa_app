class InviteCode {
  final String code;
  final DateTime expiresAt;
  final bool isUsed;

  InviteCode({
    required this.code,
    required this.expiresAt,
    required this.isUsed,
  });

  factory InviteCode.fromJson(Map<String, dynamic> json) {
    return InviteCode(
      code: json['code'],
      expiresAt: DateTime.parse(json['expires_at']),
      isUsed: json['is_used'],
    );
  }

  bool get isValid => !isUsed && expiresAt.isAfter(DateTime.now());
}
