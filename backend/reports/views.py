# reports/views.py
from django.utils.dateparse import parse_date
from django.db.models import Prefetch
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.exceptions import ValidationError

from timeline.permissions import IsCompanyMember
from companies.models import Company

from .permissions import CanGeneratePersonalDraft
from .models import (
    TeamReport, TeamReportEntry,
    PersonalReport, PersonalReportEntry, ReportStatus,
)
from .serializers import (
    PersonalReportSerializer,
    TeamReportSerializer,
    GeneratePersonalFromTeamSerializer,
)
from companies.models import TeamMember


class PersonalReportListCreateAPIView(generics.ListCreateAPIView):
    """
    GET  /api/reports/personal/?start=YYYY-MM-DD&end=YYYY-MM-DD&user_id=<id|me>
    POST /api/reports/personal/
      - body は PersonalReportSerializer に準拠（entries ネスト）
    """
    serializer_class = PersonalReportSerializer
    permission_classes = [permissions.IsAuthenticated, IsCompanyMember]

    def get_queryset(self):
        user = self.request.user
        qs = (
            PersonalReport.objects
            .filter(company=user.company)
            .select_related("user")
            .prefetch_related(
                Prefetch(
                    "entries",
                    queryset=PersonalReportEntry.objects.select_related("site", "work_category")
                )
            )
            .order_by("-date", "-created_at")
        )

        start_str = self.request.query_params.get("start")
        end_str   = self.request.query_params.get("end")
        if start_str:
            start = parse_date(start_str)
            if start:
                qs = qs.filter(date__gte=start)
        if end_str:
            end = parse_date(end_str)
            if end:
                qs = qs.filter(date__lte=end)

        user_param = self.request.query_params.get("user_id")
        if user_param == "me":
            qs = qs.filter(user=user)
        elif user_param:
            qs = qs.filter(user_id=user_param)

        return qs

    def perform_create(self, serializer):
        serializer.save()  # company/user は serializer 内でセット


class PersonalReportDetailAPIView(generics.RetrieveUpdateDestroyAPIView):
    """
    GET    /api/reports/personal/<uuid:pk>/
    PATCH  /api/reports/personal/<uuid:pk>/
    DELETE /api/reports/personal/<uuid:pk>/
    """
    serializer_class = PersonalReportSerializer
    permission_classes = [permissions.IsAuthenticated, IsCompanyMember]

    def get_queryset(self):
        user = self.request.user
        return (
            PersonalReport.objects
            .filter(company=user.company)
            .select_related("user")
            .prefetch_related(
                Prefetch(
                    "entries",
                    queryset=PersonalReportEntry.objects.select_related("site", "work_category")
                )
            )
        )

    def perform_destroy(self, instance: PersonalReport):
        if instance.status == ReportStatus.LOCKED:  # ★ is_locked から修正
            raise ValidationError("締め後の日報は削除できません。")
        return super().perform_destroy(instance)
    

class PersonalReportApproveAPIView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsCompanyMember, CanGeneratePersonalDraft]

    def post(self, request, pk):
        pr = (
            PersonalReport.objects
            .select_related("user")
            .filter(company=request.user.company, id=pk)
            .first()
        )
        if not pr:
            return Response({"detail": "not found"}, status=404)
        if pr.status != ReportStatus.PENDING:
            return Response({"detail": "承認待ちではありません"}, status=400)

        me = request.user
        # admin / manager 判定（role フィールド or 補助プロパティのどちらでも可）
        role = getattr(me, "role", None)
        is_admin   = (role == "admin")   or bool(getattr(me, "is_admin", False))
        is_manager = (role == "manager") or bool(getattr(me, "is_manager", False))

        # 「投稿者が所属するチーム」の集合を取得
        author_team_ids = set(
            TeamMember.objects.filter(
                user_id=pr.user_id, is_active=True
            ).values_list("team_id", flat=True)
        )

        # 承認者が上記チームのいずれかで leader か？
        is_leader_of_authors_team = False
        if author_team_ids:
            is_leader_of_authors_team = TeamMember.objects.filter(
                user_id=me.id,
                role="leader",
                is_active=True,
                team_id__in=author_team_ids,
            ).exists()

        if not (is_admin or is_manager or is_leader_of_authors_team):
            return Response({"detail": "承認権限がありません"}, status=403)

        # 承認処理
        from django.utils import timezone as dj_tz
        now = dj_tz.now()
        pr.status = ReportStatus.SUBMITTED
        pr.submitted_at = now
        pr.approved_by = me
        pr.approved_at = now
        pr.save(update_fields=["status", "submitted_at", "approved_by", "approved_at"])
        return Response({"status": pr.status}, status=status.HTTP_200_OK)


class PersonalReportRejectAPIView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsCompanyMember, CanGeneratePersonalDraft]

    def post(self, request, pk):
        pr = PersonalReport.objects.filter(
            company=request.user.company, id=pk
        ).first()
        if not pr:
            return Response({"detail":"not found"}, status=404)
        if pr.status != ReportStatus.PENDING:
            return Response({"detail":"承認待ちではありません"}, status=400)

        # 同じくリーダー判定（上と同様）
        if not pr.source_team_report_id:
            return Response({"detail":"生成元が無いレポートは却下不要です"}, status=400)

        is_leader = TeamMember.objects.filter(
            team_id=pr.source_team_report.team_id, user=request.user, role="leader", is_active=True
        ).exists()
        if not is_leader and not getattr(request.user, "is_admin", False):
            return Response({"detail":"承認権限がありません"}, status=403)

        # 却下 → draft に戻す（必要ならコメント保存用フィールドを追加してもOK）
        pr.status = ReportStatus.DRAFT
        pr.save(update_fields=["status"])
        return Response({"status": pr.status}, status=status.HTTP_200_OK)


class TeamReportListCreateAPIView(generics.ListCreateAPIView):
    """
    GET  /api/reports/team/?start=YYYY-MM-DD&end=YYYY-MM-DD&team_id=<uuid>&member_id=<int>
    POST /api/reports/team/
      body: TeamReportSerializer（entries ネスト）
    """
    serializer_class = TeamReportSerializer
    permission_classes = [permissions.IsAuthenticated, IsCompanyMember]

    def get_queryset(self):
        user = self.request.user
        qs = (
            TeamReport.objects
            .filter(company=user.company)
            .select_related("team", "created_by")
            .prefetch_related(
                Prefetch(
                    "entries",
                    queryset=TeamReportEntry.objects.select_related("member", "site", "work_category")
                )
            )
            .order_by("-date", "-created_at")
        )

        # ---- filters ----
        start_str = self.request.query_params.get("start")
        end_str   = self.request.query_params.get("end")
        if start_str:
            start = parse_date(start_str)
            if start:
                qs = qs.filter(date__gte=start)
        if end_str:
            end = parse_date(end_str)
            if end:
                qs = qs.filter(date__lte=end)

        team_id = self.request.query_params.get("team_id")
        if team_id:
            qs = qs.filter(team_id=team_id)

        member_id = self.request.query_params.get("member_id")
        if member_id:
            qs = qs.filter(entries__member_id=member_id).distinct()

        return qs

    def perform_create(self, serializer):
        req = self.request
        company: Company = req.user.company
        serializer.save()  # company/created_by は serializer 内で設定済み


class TeamReportDetailAPIView(generics.RetrieveUpdateDestroyAPIView):
    """
    GET    /api/reports/team/<uuid:pk>/
    PATCH  /api/reports/team/<uuid:pk>/
    DELETE /api/reports/team/<uuid:pk>/
    """
    serializer_class = TeamReportSerializer
    permission_classes = [permissions.IsAuthenticated, IsCompanyMember]

    def get_queryset(self):
        user = self.request.user
        return (
            TeamReport.objects
            .filter(company=user.company)
            .select_related("team", "created_by")
            .prefetch_related(
                Prefetch(
                    "entries",
                    queryset=TeamReportEntry.objects.select_related("member", "site", "work_category")
                )
            )
        )


class TeamReportGeneratePersonalAPIView(APIView):
    """
    POST /api/reports/team/generate-personal/
    body: { "team_report_id": "<uuid>", "replace_existing": true }
    → チーム日報の記録から、個人日報（同日）の下書きを一括生成
    """
    permission_classes = [permissions.IsAuthenticated, IsCompanyMember, CanGeneratePersonalDraft]

    def post(self, request, *args, **kwargs):
        ser = GeneratePersonalFromTeamSerializer(data=request.data, context={"request": request})
        ser.is_valid(raise_exception=True)
        result = ser.save()
        return Response(result, status=status.HTTP_201_CREATED)

