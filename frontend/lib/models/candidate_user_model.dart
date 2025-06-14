class CandidateUserModel {
  final int id;
  final String email;
  final String username;
  final String accountId;
  final String? iconimg;
  final bool isInvited;

  CandidateUserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.accountId,
    this.iconimg,
    required this.isInvited,
  });

  factory CandidateUserModel.fromJson(Map<String, dynamic> json) {
    return CandidateUserModel(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      accountId: json['account_id'],
      iconimg: json['iconimg'],
      isInvited: json['is_invited'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'username': username,
        'account_id': accountId,
        'iconimg': iconimg,
        'is_invited': isInvited,
      };
}