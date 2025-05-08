class PostModel {
  final int id;
  final String content;
  final String? image;
  final String createdAt;
  final String userUsername;
  final String userAccountId;
  final bool isImportant;
  final String? userIconImg;

  PostModel({
    required this.id,
    required this.content,
    this.image,
    required this.createdAt,
    required this.userUsername,
    required this.userAccountId,
    required this.isImportant,
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
      isImportant: json['is_important'] as bool,
      userIconImg: json['user_iconimg'],
    );
  }
}
