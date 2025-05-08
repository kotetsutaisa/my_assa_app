# companies/views.py
from rest_framework import status, permissions, generics
from rest_framework.response import Response
from django.db import transaction

from .models import Company
from .serializers import CompanyCreateSerializer
from .permissions import IsNotAffiliated
from .throttles import CompanyCreateThrottle   # 無効化したいなら削除
from utils.audit import register_event         # 監査フック
from rest_framework.permissions import IsAuthenticated
from .models import InviteCode
from .serializers import InviteCodeCreateSerializer
from .serializers import InviteCodeUseSerializer
from .permissions import IsCompanyAdminOrManager

class CompanyCreateAPIView(generics.GenericAPIView):
    """
    会社新規作成エンドポイント（要認証・所属なしユーザーのみ）。
    成功するとユーザーを 'admin' ロールで作成した会社に紐付け、
    is_approved=False のまま審査待ち状態で返す。
    """
    serializer_class = CompanyCreateSerializer
    permission_classes = [
        permissions.IsAuthenticated,
        IsNotAffiliated,         # カスタム
    ]
    throttle_classes = [CompanyCreateThrottle]  # 必要なければ外す

    # ------- POST /api/companies/ -------
    @transaction.atomic
    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(
            data=request.data,
            context=self.get_serializer_context()  # request を渡す
        )
        serializer.is_valid(raise_exception=True)
        company = serializer.save()               # Serializer 内で user 更新も完結

        # ---- 監査 or 通知フック ----
        register_event(
            actor=request.user,
            verb="request_company_creation",
            target=company,
            extra={"ip": request.META.get("REMOTE_ADDR")},
        )

        return Response(
            self.get_serializer(company).data,    # 作成済みオブジェクトを整形
            status=status.HTTP_201_CREATED,
        )

    def get_serializer_context(self):
        """Serializer に request を渡す。"""
        ctx = super().get_serializer_context()
        ctx["request"] = self.request
        return ctx


# --- 招待コード ---
class InviteCodeCreateView(generics.CreateAPIView):
    """
    管理者が所属する会社の招待コードを1件発行する（1日間有効・1人1回）
    """
    queryset = InviteCode.objects.all()
    serializer_class = InviteCodeCreateSerializer
    permission_classes = [IsAuthenticated, IsCompanyAdminOrManager]

    def get_queryset(self):
        """
        将来的に一覧表示する場合は、自分の会社のコードのみ表示できるよう制限
        """
        return InviteCode.objects.filter(company=self.request.user.company)
    


# --- 会社グループに参加 ---
class JoinCompanyView(generics.GenericAPIView):
    serializer_class = InviteCodeUseSerializer
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        serializer.save(user=request.user)  # 明示的に渡す
        return Response({"detail": "会社に参加しました"}, status=status.HTTP_200_OK)