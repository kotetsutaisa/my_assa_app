/* member_model.dart – 選択モーダル専用のシンプルなモデル */
class MemberModel {
  final String id;
  final String name;
  final String? avatarUrl;
  const MemberModel({
    required this.id,
    required this.name,
    this.avatarUrl,
  });
}

