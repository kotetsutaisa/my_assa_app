class SimpleUserModel {
  final int id;
  final String email;
  final String username;
  final String accountId;
  final String? iconimg;

  SimpleUserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.accountId,
    this.iconimg,
  });

  factory SimpleUserModel.fromJson(Map<String, dynamic> json) {
    return SimpleUserModel(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      accountId: json['account_id'],
      iconimg: json['iconimg'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'username': username,
        'account_id': accountId,
        'iconimg': iconimg,
      };
}
