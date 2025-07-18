/// バックエンドの Role(models.TextChoices) と 1:1 対応
enum UserRole { admin, manager, member, unknown }

extension UserRoleX on UserRole {
  /// API 文字列（POST/PATCH 時に利用）
  String get apiValue {
    switch (this) {
      case UserRole.admin:   return 'admin';
      case UserRole.manager: return 'manager';
      case UserRole.member:  return 'member';
      case UserRole.unknown: return 'member'; // Fallback 送信時は member に寄せる等
    }
  }

  /// 表示用ラベル（必要に応じてローカライズ）
  String get labelJa {
    switch (this) {
      case UserRole.admin:   return '管理者';
      case UserRole.manager: return '部長';
      case UserRole.member:  return '一般';
      case UserRole.unknown: return '一般';
    }
  }

  /// 権限チェックに便利
  bool get canManageResources =>
      this == UserRole.admin || this == UserRole.manager;

  /// JSON → enum 変換ヘルパ
  static UserRole fromApi(String? value) {
    switch (value) {
      case 'admin':   return UserRole.admin;
      case 'manager': return UserRole.manager;
      case 'member':  return UserRole.member;
      default:        return UserRole.unknown;
    }
  }
}
