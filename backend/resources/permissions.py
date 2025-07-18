# resources/permissions.py
from rest_framework.permissions import BasePermission, SAFE_METHODS
from users.models import Role             # ← CustomUser.role の列挙

class IsResourceEditorOrReader(BasePermission):
    """
    - **GET / HEAD / OPTIONS (SAFE_METHODS)** : 同じ会社に属していれば誰でも OK  
    - **POST / PUT / PATCH / DELETE**        : admin か manager だけ
    """

    def _is_same_company(self, request, obj_company=None):
        """
        company 判定を 2 パターンで使い回す
        - View レベル   : obj_company=None
        - Object レベル : obj_company=instance.company
        """
        user_company = getattr(request.user, "company", None)
        return user_company and (obj_company is None or obj_company == user_company)

    # ---- View 単位の判定 --------------------------------------------------
    def has_permission(self, request, view):
        # 未ログインは一切 NG
        if not request.user or not request.user.is_authenticated:
            return False

        # 一覧取得など読み取り系は「同一会社なら」誰でも許可
        if request.method in SAFE_METHODS:
            return self._is_same_company(request)

        # 書き込み系は admin / manager だけ
        return (
            self._is_same_company(request) and
            request.user.role in (Role.ADMIN, Role.MANAGER)
        )

    # ---- オブジェクト単位の判定 ------------------------------------------
    def has_object_permission(self, request, view, obj):
        # company が一致しているかをまずチェック
        if not self._is_same_company(request, obj.company):
            return False

        # 読み取りは OK、書き込みは role も再確認
        if request.method in SAFE_METHODS:
            return True
        return request.user.role in (Role.ADMIN, Role.MANAGER)
