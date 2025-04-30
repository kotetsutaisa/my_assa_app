class PostModel {
  final int id;
  final String content;
  final String? image;
  final String createdAt;
  final String userUsername;
  final String userAccountId;
  final String? userIconImg;

  PostModel({
    required this.id,
    required this.content,
    this.image,
    required this.createdAt,
    required this.userUsername,
    required this.userAccountId,
    this.userIconImg,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'],
      content: json['content'],
      image: json['image'],
      createdAt: json['created_at'],
      userUsername: json['user_username'],
      userAccountId: json['user_account_id'],
      userIconImg: json['user_iconimg'],
    );
  }
}
