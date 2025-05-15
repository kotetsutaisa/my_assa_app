class PostModel {
  final int id;
  final int userId;
  final String content;
  final String? image;
  final String createdAt;
  final String userUsername;
  final String userAccountId;
  final bool isImportant;
  final String? userIconImg;
  final int likesCount;
  final bool isLiked;
  final int commentsCount;
  final bool isRead;
  final int readCount;
  final List<String> images;

  PostModel({
    required this.id,
    required this.userId,
    required this.content,
    this.image,
    required this.createdAt,
    required this.userUsername,
    required this.userAccountId,
    required this.isImportant,
    this.userIconImg,
    required this.likesCount,
    required this.isLiked,
    required this.commentsCount,
    required this.isRead,
    required this.readCount,
    required this.images,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'],
      userId: json['user_id'] as int,
      content: json['content'],
      image: json['image'],
      createdAt: json['created_at'],
      userUsername: json['user_username'],
      userAccountId: json['user_account_id'],
      isImportant:
          json['is_important'] == true || json['is_important'] == 'true',
      userIconImg: json['user_iconimg'],
      likesCount: (json['likes_count'] ?? 0) as int,
      isLiked: json['is_liked'] == true || json['is_liked'] == 'true',
      commentsCount: (json['comments_count'] ?? 0) as int,
      isRead: json['is_read'] == true || json['is_read'] == 'true',
      readCount: (json['read_count'] ?? 0) as int,
      images: List<String>.from(json['images'] ?? []),
    );
  }

  PostModel copyWith({
    int? id,
    int? userId,
    String? content,
    String? image,
    String? createdAt,
    String? userUsername,
    String? userAccountId,
    bool? isImportant,
    String? userIconImg,
    int? likesCount,
    bool? isLiked,
    int? commentsCount,
    bool? isRead,
    int? readCount,
    List<String>? images,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      image: image ?? this.image,
      createdAt: createdAt ?? this.createdAt,
      userUsername: userUsername ?? this.userUsername,
      userAccountId: userAccountId ?? this.userAccountId,
      isImportant: isImportant ?? this.isImportant,
      userIconImg: userIconImg ?? this.userIconImg,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      commentsCount: commentsCount ?? this.commentsCount,
      isRead: isRead ?? this.isRead,
      readCount: readCount ?? this.readCount,
      images: images ?? this.images,
    );
  }
}
