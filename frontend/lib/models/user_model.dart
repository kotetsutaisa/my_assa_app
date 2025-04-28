// ユーザー情報を使いやすくする

class UserModel {
  final int id;
  final String email;
  final String username;
  final String accountId;
  final String? iconimg;

  // 引数セットと値代入
  // requiredは引数を必須にしてる
  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.accountId,
    this.iconimg,
  });

  // factory = "インスタンス作成の柔軟なコントローラー"
  // 引数で受け取ったMap型のjsonをUserModelにセット(インスタンス化)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      accountId: json['account_id'],
      iconimg: json['iconimg'],
    );
  }
}
