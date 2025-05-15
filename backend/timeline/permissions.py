from rest_framework import permissions
from users.models import Role


class IsCompanyMember(permissions.BasePermission):
    """
    ユーザーが会社に所属しており、かつ承認済みかを確認
    """
    message = "会社に所属していない、または未承認です。"

    def has_permission(self, request, view):
        user = request.user
        return user.is_authenticated and user.company and user.company.is_approved


class IsAdminOrManager(permissions.BasePermission):
    """
    管理者または部長ロールを持つユーザーに制限
    """
    message = "管理者または部長権限が必要です。"

    def has_permission(self, request, view):
        user = request.user
        return user.is_authenticated and user.role in [Role.ADMIN, Role.MANAGER]


class IsCompanyAdmin(permissions.BasePermission):
    """
    管理者ロール専用（例：会社設定の変更や招待コード発行）
    """
    message = "管理者権限が必要です。"

    def has_permission(self, request, view):
        user = request.user
        return user.is_authenticated and user.role == Role.ADMIN
    

class IsCommentAuthorOrCompanyAdmin(permissions.BasePermission):
    """
    更新・削除はコメント作者 または 会社 admin/manager のみ許可
    """
    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:          # GET, HEAD, OPTIONS
            return True
        user = request.user
        return (
            obj.user_id == user.id or
            user.role in [Role.ADMIN, Role.MANAGER]
        )