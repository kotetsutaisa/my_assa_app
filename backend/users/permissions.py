from rest_framework import permissions


class IsCompanyMember(permissions.BasePermission):
    """
    ユーザーが会社に所属しており、かつ承認済みかを確認
    """
    message = "会社に所属していない、または未承認です。"

    def has_permission(self, request, view):
        user = request.user
        return user.is_authenticated and user.company and user.company.is_approved
