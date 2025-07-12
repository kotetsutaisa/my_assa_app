from datetime import timezone as dt_timezone
from timeline.permissions import IsCompanyMember
from django.utils.dateparse import parse_datetime
from django.utils import timezone as dj_tz
from django.db.models import Q, Subquery, OuterRef

from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.exceptions import ValidationError
from .models import WorkCategory, Schedule, ScheduleType
from .serializers import WorkCategorySerializer, ScheduleSerializer
from .overlap_mixin import OverlapSafeCreateMixin
from companies.models import TeamMember

# 作業内容作成・一覧取得
class WorkCategoryListCreateAPIView(generics.ListCreateAPIView):
    serializer_class = WorkCategorySerializer
    permission_classes = [permissions.IsAuthenticated, IsCompanyMember]

    def get_queryset(self):
        # ログインユーザーの会社に紐づく作業カテゴリのみ
        return WorkCategory.objects.filter(
            company=self.request.user.company,
            is_active=True
        ).order_by('name')

    def perform_create(self, serializer):
        name = serializer.validated_data.get('name')
        company = self.request.user.company
        created_by = self.request.user

        # すでに同じ名前の作業カテゴリが存在するかチェック（非アクティブも含めて）
        existing = WorkCategory.objects.filter(company=company, name=name).first()

        if existing:
            # ① すでに存在している（is_active=True or False）
            if not existing.is_active:
                # 再利用として is_active を True に復活させる処理
                existing.is_active = True
                existing.save(update_fields=["is_active"])
                self.instance = existing
                return Response(self.get_serializer(existing).data, status=status.HTTP_200_OK)
            else:
                # ② すでにアクティブ → エラーとして扱いたい場合は以下のように raise
                raise ValidationError({'name': 'この作業内容はすでに存在します。'})
        else:
            # ③ 存在しなければ通常通り作成
            serializer.save(company=company, created_by=created_by)


# 作業内容削除（論理削除に変更）
class WorkCategoryDestroyView(generics.DestroyAPIView):
    queryset = WorkCategory.objects.all()
    serializer_class = WorkCategorySerializer
    permission_classes = [permissions.IsAuthenticated, IsCompanyMember]

    def delete(self, request, *args, **kwargs):
        instance = self.get_object()
        instance.is_active = False  # ← ここで論理削除
        instance.save()
        return Response(status=status.HTTP_204_NO_CONTENT)



# 自分の月単位のスケジュール
class MyMonthlyScheduleAPIView(OverlapSafeCreateMixin, generics.ListCreateAPIView):
    serializer_class = ScheduleSerializer
    permission_classes = [permissions.IsAuthenticated, IsCompanyMember]

    def get_queryset(self):
        user = self.request.user
        
        qs = (
            Schedule.objects
            .filter(company=user.company)
            .filter(
                Q(schedule_type="personal", members=user) |
                Q(schedule_type="team", members=user)
            )
            .select_related("site", "work_category")
            .prefetch_related("members")
        )


        # クエリパラメータから start/end を取得
        start_param = self.request.query_params.get("start")   # 例: 2025-07-01T00:00:00Z
        end_param   = self.request.query_params.get("end")     # 例: 2025-07-31T23:59:59Z

        if start_param and end_param:
            start = parse_datetime(start_param)
            end   = parse_datetime(end_param)

            # ISO 文字列→datetime 変換に失敗した場合は None
            if start and end:
                if dj_tz.is_naive(start):
                    start = dj_tz.make_aware(start, dj_tz.get_default_timezone())
                if dj_tz.is_naive(end):
                    end   = dj_tz.make_aware(end, dj_tz.get_default_timezone())

                qs = qs.filter(
                    start_time__lt=end,   #   予定開始 < 期間終端
                    end_time__gt=start,   # & 予定終了 > 期間開始
                )

        return qs.order_by("start_time")
    
    def perform_create(self, serializer):
        """
        POST /api/schedule/my-monthly/ で呼ばれる。
        - company と created_by を自動セット
        - 個人予定(schedule_type==personal)で members が空なら作成者を追加
        """
        user = self.request.user

        # company / created_by を強制的に上書きして保存
        schedule = serializer.save(
            company    = user.company,
            created_by = user,
        )

        # メンバー未指定なら自分を入れる
        if (schedule.schedule_type == ScheduleType.PERSONAL
                and schedule.members.count() == 0):
            schedule.members.add(user)



class ScheduleDetailAPIView(generics.RetrieveUpdateDestroyAPIView):
    """
    GET    /api/schedule/<uuid:pk>/  … 1 件取得
    PATCH  /api/schedule/<uuid:pk>/  … 部分更新
    PUT    /api/schedule/<uuid:pk>/  … 全体更新
    DELETE /api/schedule/<uuid:pk>/  … 削除
    """
    serializer_class   = ScheduleSerializer
    permission_classes = [permissions.IsAuthenticated, IsCompanyMember]

    # 会社が一致するデータだけ操作可能
    def get_queryset(self):
        user = self.request.user
        return (
            Schedule.objects
            .filter(company=user.company)
            .select_related("site", "work_category")
            .prefetch_related("members")
        )
    



class TeamMonthlyScheduleAPIView(OverlapSafeCreateMixin, generics.ListCreateAPIView):
    """
    GET  /api/schedule/team-monthly/?start=2025-07-01T00:00:00Z&end=2025-07-31T23:59:59Z
    POST /api/schedule/team-monthly/
    """
    serializer_class   = ScheduleSerializer
    permission_classes = [permissions.IsAuthenticated, IsCompanyMember]

    # ---- 取得 ----
    def get_queryset(self):
        user = self.request.user

        my_team_ids = (
            TeamMember.objects
            .filter(user=user, is_active=True)
            .values_list("team_id", flat=True)
        )

        qs = (
            Schedule.objects
            .filter(
                company=user.company,
                schedule_type=ScheduleType.TEAM,
                teams__in     = Subquery(my_team_ids)
            )
            .distinct()
            .select_related("site", "work_category")
            .prefetch_related("members", "teams")
        )

        start_param = self.request.query_params.get("start")
        end_param   = self.request.query_params.get("end")

        if start_param and end_param:
            start = parse_datetime(start_param)
            end   = parse_datetime(end_param)
            if start and end:
                if dj_tz.is_naive(start):
                    start = dj_tz.make_aware(start, dj_tz.get_default_timezone())
                if dj_tz.is_naive(end):
                    end   = dj_tz.make_aware(end, dj_tz.get_default_timezone())
                qs = qs.filter(
                    start_time__lt=end,   #   予定開始 < 期間終端
                    end_time__gt=start,   # & 予定終了 > 期間開始
                )

        return qs.order_by("start_time")
    

    # ---------- 重複判定用 (POST) ----------
    def get_overlap_queryset(self):
        """
        POST 時はこちらを使う → company 内の全スケジュール
        (schedule_type で絞らない)
        """
        user = self.request.user
        return (
            Schedule.objects
            .filter(company=user.company)
            .select_related("site", "work_category")
            .prefetch_related("members")
        )



    # ---- 作成 ----
    def perform_create(self, serializer):
        """
        - schedule_type を TEAM に固定
        - members が空なら作成者を必ず含める
        """
        user = self.request.user
        team_ids = self.request.data.get('team_ids', [])

        # schedule_type を強制的にチームに
        schedule = serializer.save(
            company       = user.company,
            created_by    = user,
            schedule_type = ScheduleType.TEAM,           # ★ ここが重要
        )

        if team_ids:
            schedule.teams.set(team_ids)

        if schedule.members.count() == 0:
            schedule.members.add(user)