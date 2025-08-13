# companies/views.py
from rest_framework import status, permissions, generics
from rest_framework.response import Response
from django.db import transaction

from .models import Company, Team, TeamMember
from .serializers import CompanyCreateSerializer
from .permissions import IsNotAffiliated
from .throttles import CompanyCreateThrottle   # 無効化したいなら削除
from utils.audit import register_event         # 監査フック
from django.contrib.auth import get_user_model
from rest_framework.permissions import IsAuthenticated
from .models import InviteCode
from .serializers import InviteCodeCreateSerializer
from .serializers import InviteCodeUseSerializer, TeamListItemSerializer
from .permissions import IsCompanyAdminOrManager
from timeline.permissions import IsCompanyMember
from users.serializers import FullUserSerializer
from django.db.models import Case, When, IntegerField, Prefetch, Count, Exists

User = get_user_model()

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
    


# 会社メンバーを権限・チームごとに表示
class CompanyMemberListCreateView(generics.ListCreateAPIView):
    permission_classes = [permissions.IsAuthenticated, IsCompanyMember]

    def list(self, request, *args, **kwargs):
        company = request.user.company

        # ────────────────────────────────
        # 1) admin
        # ────────────────────────────────
        admins = User.objects.filter(company=company, role='admin')

        # ────────────────────────────────
        # 2) チーム無所属 manager / member
        # ────────────────────────────────
        managers_no_team = User.objects.filter(
            company=company,
            role='manager',
            team_memberships__isnull=True
        )
        members_no_team = User.objects.filter(
            company=company,
            role='member',
            team_memberships__isnull=True
        )

        # ────────────────────────────────
        # 3) チーム（リーダーを先頭に並べ替えて取得）
        #    Case/When でソートキーを付ける
        # ────────────────────────────────
        leader_first = Case(
            When(role='leader', then=0),
            default=1,
            output_field=IntegerField()
        )

        teams = (
            Team.objects
            .filter(company=company)
            .prefetch_related(
                Prefetch(
                    'members',
                    queryset=(
                        TeamMember.objects
                        .select_related('user')
                        .annotate(_leader_first=leader_first)
                        .order_by('_leader_first', 'joined_at')
                    )
                )
            )
            .order_by('created_at')          # チーム自体の並び順（お好みで）
        )

        # ----------------------------------------------------------------
        # 返却ペイロードを構築
        # ----------------------------------------------------------------
        result = []

        # ① admin
        result.extend({
            "type": "admin",
            "user": FullUserSerializer(u).data,
        } for u in admins)

        # ② チーム無所属 manager
        result.extend({
            "type": "no_team_manager",
            "user": FullUserSerializer(u).data,
        } for u in managers_no_team)

        # ③ チーム（リーダー→メンバー順で members を作成）
        for team in teams:
            members_payload = [
                {
                    "user": FullUserSerializer(m.user).data,
                    "role": m.role,          # 'leader' / 'member'
                }
                for m in team.members.all()  # leader が先頭になる
            ]
            result.append({
                "type":       "team",
                "team_id":    team.id,
                "team_name":  team.name,
                "members":    members_payload,
            })

        # ④ チーム無所属 member
        result.extend({
            "type": "no_team_member",
            "user": FullUserSerializer(u).data,
        } for u in members_no_team)

        return Response(result)
    


class CompanyTeamListAPIView(generics.ListAPIView):
    """
    GET /api/companies/teams/
      - admin: 会社内の全チームを返す
      - leader: 自分が「leader」のチームのみ返す
      - その他: 空配列
    レスポンス: [{id, name, member_count, is_leader}, ...]
    """
    permission_classes = [permissions.IsAuthenticated, IsCompanyMember]
    serializer_class = TeamListItemSerializer

    def get_queryset(self):
        user = self.request.user
        qs = (
            Team.objects
            .filter(company=user.company)
            .annotate(
                member_count_db=Count("members"),
            )
            .order_by("created_at")
        )

        if getattr(user, "role", None) == "admin":
            return qs

        leader_team_ids = TeamMember.objects.filter(
            user=user, role="leader", team__company=user.company
        ).values_list("team_id", flat=True)

        if leader_team_ids.exists():
            return qs.filter(id__in=leader_team_ids)

        # 一般ユーザーはチーム選択不可 → 空
        return qs.none()