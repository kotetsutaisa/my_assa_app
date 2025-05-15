class CommentModel {
  final int    id;
  final int    post;              // FK
  final String userUsername;
  final String userAccountId;
  final String? userIconImg;
  final String content;
  final String createdAt;

  CommentModel({
    required this.id,
    required this.post,
    required this.userUsername,
    required this.userAccountId,
    this.userIconImg,
    required this.content,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) => CommentModel(
        id: json['id'],
        post: json['post'],
        userUsername: json['user_username'],
        userAccountId: json['user_account_id'],
        userIconImg: json['user_iconimg'],
        content: json['content'],
        createdAt: json['created_at'],
      );
}
