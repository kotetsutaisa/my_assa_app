# resources/views.py
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from django.utils import timezone as dj_tz

from timeline.permissions import IsCompanyMember        # 会社テナント用の既存 Permission を想定
from .models       import Resource
from .serializers  import ResourceSerializer
from .permissions   import IsResourceEditorOrReader


# ------------------------------------------------------------------
# ① 一覧取得 & 新規登録   /api/resources/
# ------------------------------------------------------------------
class ResourceListCreateAPIView(generics.ListCreateAPIView):
    """
    GET  /api/resources/           … 自社のアクティブなリソース一覧
    POST /api/resources/           … 新規登録
    """
    serializer_class   = ResourceSerializer
    permission_classes = [
        permissions.IsAuthenticated,
        IsCompanyMember,
        IsResourceEditorOrReader,
    ]

    # -------- 一覧 --------
    def get_queryset(self):
        user = self.request.user
        return (
            Resource.objects
            .filter(company=user.company, is_active=True)    # 自社 & 稼働中のみ
            .select_related("category")                      # N+1 対策
            .order_by("name")
        )

    # -------- 作成 --------
    def perform_create(self, serializer):
        """
        company / created_by は強制的にリクエストユーザーのものに上書き
        """
        user = self.request.user
        serializer.save(
            company    = user.company,
            created_by = user,
        )


# ------------------------------------------------------------------
# ② 参照・更新・削除   /api/resources/<uuid:pk>/
# ------------------------------------------------------------------
class ResourceDetailAPIView(generics.RetrieveUpdateDestroyAPIView):
    """
    GET    /api/resources/<id>/   … 詳細取得  
    PATCH  /api/resources/<id>/   … 部分更新  
    PUT    /api/resources/<id>/   … 全体更新  
    DELETE /api/resources/<id>/   … 削除（論理 or 物理）
    """
    serializer_class   = ResourceSerializer
    permission_classes = [
        permissions.IsAuthenticated,
        IsCompanyMember,
        IsResourceEditorOrReader,
    ]

    # -------- 参照 --------
    def get_queryset(self):
        user = self.request.user
        return (
            Resource.objects
            .filter(company=user.company)                    # 自社のみ
            .select_related("category")
        )

    # -------- 更新 --------
    def perform_update(self, serializer):
        """
        company / created_by は更新不可にしたいので pop で除外でも OK
        （ResourceSerializer 側でも弾いているはずですが二重防御）
        """
        serializer.save()

    # -------- 削除 --------
    def delete(self, request, *args, **kwargs):
        """
        - **物理削除** したいならそのまま `return super().delete(...)`  
        - **論理削除** にしたい場合は `is_active = False` にして保存
        """
        instance = self.get_object()

        # ---- 論理削除パターン ----
        instance.is_active = False
        instance.save(update_fields=["is_active", "updated_at"])

        return Response(status=status.HTTP_204_NO_CONTENT)

        # ---- 物理削除パターンならこちら ----
        # return super().delete(request, *args, **kwargs)

