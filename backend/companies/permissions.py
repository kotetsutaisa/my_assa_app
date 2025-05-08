from rest_framework import permissions

class IsNotAffiliated(permissions.BasePermission):
    """
    すでに会社に所属しているユーザーは新規会社を作成できない。
    """
    message = "既に会社に所属しています。新しく会社を作成することはできません。"

    def has_permission(self, request, view):
        # 認証済み & company_id が null の場合のみ許可
        return request.user.is_authenticated and not getattr(request.user, "company_id", None)


class IsCompanyAdminOrManager(permissions.BasePermission):
    """
    管理者または部長（admin / manager）のみ許可される
    """
    message = "この操作を行う権限がありません。管理者または部長のみ実行できます。"

    def has_permission(self, request, view):
        return (
            request.user.is_authenticated and
            getattr(request.user, "role", None) in ["admin", "manager"]
        )