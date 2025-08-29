# reports/views.py
from datetime import date as _date
from django.utils.dateparse import parse_date
from django.db import transaction
from django.db.models import Prefetch
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.exceptions import ValidationError

from timeline.permissions import IsCompanyMember
from companies.models import Company, TeamMember

from .permissions import CanGeneratePersonalDraft, IsAdminOrClerk
from .utils.closing import calc_closing_window
from .models import (
    TeamReport, TeamReportEntry,
    PersonalReport, PersonalReportEntry, ReportStatus,
    ClosingPeriod,
)
from .serializers import (
    PersonalReportSerializer,
    TeamReportSerializer,
    GeneratePersonalFromTeamSerializer,
    ClosingPreviewSerializer
)
from office.models import CompanyPayrollPolicy


def _parse_year_month(s: str) -> _date | None:
    """
    'YYYY-MM' → その月の1日 (date)
    """
    if not s:
        return None
    if len(s) == 7 and s[4] == "-":
        s = f"{s}-01"
    d = parse_date(s)
    if d is None:
        return None
    return _date(d.year, d.month, 1)


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




class ClosingPreviewAPIView(APIView):
    permission_classes = [IsAdminOrClerk, IsCompanyMember]

    def get(self, request):
        # year_month=YYYY-MM（無ければ当月）
        ym_str = request.query_params.get("year_month")
        today  = _date.today()
        year_month = _parse_year_month(ym_str) or _date(today.year, today.month, 1)

        # 会社設定
        company: Company = request.user.company
        policy, _ = CompanyPayrollPolicy.objects.get_or_create(company=company)

        win = calc_closing_window(year_month, policy.closing_day)

        qs = PersonalReport.objects.filter(
            company=company, date__gte=win.start, date__lte=win.end
        )
        counts = {
            "draft": qs.filter(status=ReportStatus.DRAFT).count(),
            "pending": qs.filter(status=ReportStatus.PENDING).count(),
            "submitted": qs.filter(status=ReportStatus.SUBMITTED).count(),
            "locked": qs.filter(status=ReportStatus.LOCKED).count(),
        }
        drafts  = list(qs.filter(status=ReportStatus.DRAFT).values_list("id", flat=True))
        pending = list(qs.filter(status=ReportStatus.PENDING).values_list("id", flat=True))

        # 既に締め済みか？
        already_closed = ClosingPeriod.objects.filter(company=company, year_month=year_month, closed=True).exists()

        data = {
            "year_month": year_month,
            "period_start": win.start,
            "period_end": win.end,
            "counts": counts,
            "drafts": drafts,
            "pending": pending,
            "already_closed": already_closed,
        }
        ser = ClosingPreviewSerializer(data)
        return Response(ser.data, status=200)
    
    

class ClosingRunAPIView(APIView):
    """
    POST body: {"year_month": "YYYY-MM"}
    - draft/pending が残っている場合: 409 を返す（仕様は好みで調整可）
    - 既に締め済み: 400
    """
    permission_classes = [IsAdminOrClerk, IsCompanyMember]

    @transaction.atomic
    def post(self, request):
        ym_str = request.data.get("year_month")
        if not ym_str:
            return Response({"detail": "year_month は必須です (YYYY-MM)."}, status=400)
        year_month = _parse_year_month(ym_str)
        if not year_month:
            return Response({"detail": "year_month のフォーマットが不正です。例: 2025-07"}, status=400)

        company: Company = request.user.company
        policy, _ = CompanyPayrollPolicy.objects.get_or_create(company=company)
        win = calc_closing_window(year_month, policy.closing_day)

        if ClosingPeriod.objects.filter(company=company, year_month=year_month, closed=True).exists():
            return Response({"detail": "この月は既に締め済みです。"}, status=400)

        qs = PersonalReport.objects.select_for_update().filter(
            company=company, date__gte=win.start, date__lte=win.end
        )
        count_draft   = qs.filter(status=ReportStatus.DRAFT).count()
        count_pending = qs.filter(status=ReportStatus.PENDING).count()
        if count_draft or count_pending:
            return Response({
                "detail": "未提出/承認待ちが残っています。",
                "draft": count_draft, "pending": count_pending
            }, status=409)

        # submitted → locked に更新
        updated = qs.filter(status=ReportStatus.SUBMITTED).update(status=ReportStatus.LOCKED)

        # ClosingPeriod を記録
        cp, _ = ClosingPeriod.objects.get_or_create(company=company, year_month=year_month)
        from django.utils import timezone as dj_tz
        cp.closed = True
        cp.closed_at = dj_tz.now()
        cp.closed_by = request.user
        cp.save(update_fields=["closed", "closed_at", "closed_by"])

        return Response({
            "closed": True,
            "period_start": win.start,
            "period_end": win.end,
            "locked_count": updated,
        }, status=200)
