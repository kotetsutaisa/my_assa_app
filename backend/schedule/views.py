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
    
    def get_overlap_queryset(self):
        user = self.request.user
        return (
            Schedule.objects
            .filter(
                company=user.company,
                schedule_type__in=[ScheduleType.PERSONAL, ScheduleType.TEAM],
            )
            .select_related("site", "work_category")
            .prefetch_related("members", "teams")
        )
    
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
    GET  /api/schedule/team-monthly/?start=2025-07-01T00:00:00Z&end=2025-07-31T23:59:59Z[&team_id=<uuid>] 
    POST /api/schedule/team-monthly/
      - POST は OverlapSafeCreateMixin により重複整理ロジック適用
    """
    serializer_class   = ScheduleSerializer
    permission_classes = [permissions.IsAuthenticated, IsCompanyMember]

    # ---- 取得 ----
    def get_queryset(self):
        user = self.request.user

        # ユーザーが “アクティブで所属するチーム” の ID 一覧
        my_team_ids = TeamMember.objects.filter(
            user=user,
            is_active=True
        ).values_list("team_id", flat=True)

        qs = (
            Schedule.objects
            .filter(
                company=user.company,
                schedule_type=ScheduleType.TEAM,
                teams__in=my_team_ids,          # 自分が所属するチームに紐づく予定のみ
            )
            .select_related("site", "work_category", "resource")
            .prefetch_related("members", "teams")
            .distinct()
        )

        # 期間フィルタ（交差条件）
        start_param = self.request.query_params.get("start")
        end_param   = self.request.query_params.get("end")
        if start_param and end_param:
            start = parse_datetime(start_param)
            end   = parse_datetime(end_param)
            if start and end:
                if dj_tz.is_naive(start):
                    start = dj_tz.make_aware(start, dj_tz.get_default_timezone())
                if dj_tz.is_naive(end):
                    end = dj_tz.make_aware(end, dj_tz.get_default_timezone())
                qs = qs.filter(
                    start_time__lt=end,    # 予定開始 < 期間の終端
                    end_time__gt=start,    # 予定終了 > 期間の開始
                )

        # ---- ★ team_id パラメータで追加絞り込み ----
        team_id_param = self.request.query_params.get("team_id")
        if team_id_param:
            qs = qs.filter(teams__id=team_id_param)

        return qs.order_by("start_time")

    # ---- 重複判定用 (POST) ----
    def get_overlap_queryset(self):
        """
        重複チェックでは schedule_type を限定せず、
        同一 company 内の全予定（personal / team / resource）を対象にする。
        """
        user = self.request.user
        return (
            Schedule.objects
            .filter(company=user.company)
            .select_related("site", "work_category", "resource")
            .prefetch_related("members", "teams")
        )

    # ---- 作成 ----
    def perform_create(self, serializer):
        """
        schedule_type を強制的に TEAM として保存。
        team_ids / member_ids の処理は serializer 側で行う前提。
        （team_ids を View で扱いたい場合はコメントを参照）
        """
        user = self.request.user

        # もし View 側で team_ids を拾ってバリデーションしたい場合:
        # team_ids = self.request.data.get("team_ids", [])
        # if not team_ids:
        #     raise ValidationError({"team_ids": "チームを1つ以上指定してください。"})

        schedule = serializer.save(
            company=user.company,
            created_by=user,
            schedule_type=ScheduleType.TEAM,
        )

        # members が空なら作成者を補完（運用ポリシーに応じて）
        if schedule.members.count() == 0:
            schedule.members.add(user)


# リソーススケジュール
class ResourceMonthlyScheduleAPIView(OverlapSafeCreateMixin, generics.ListCreateAPIView):
    """
    GET  /api/schedule/resource-monthly/?start=...&end=...&resource_id=<uuid>
    POST /api/schedule/resource-monthly/[?force=true]
    """
    serializer_class   = ScheduleSerializer
    permission_classes = [permissions.IsAuthenticated, IsCompanyMember]

    # --------- 取得 ---------
    def get_queryset(self):
        user = self.request.user

        qs = (
            Schedule.objects
            .filter(
                company=user.company,
                schedule_type=ScheduleType.RESOURCE,
            )
            .select_related("site", "work_category", "resource")
            .prefetch_related("members", "teams")
        )

        # リソースで絞る（任意）
        res_id = self.request.query_params.get("resource_id")
        if res_id:
            qs = qs.filter(resource_id=res_id)

        # 期間指定（交差判定）
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
                    start_time__lt=end,   # 予定開始 < 期間終端
                    end_time__gt=start,   # 予定終了 > 期間開始
                )

        return qs.order_by("start_time")

    # --------- 重複判定用クエリセット (POST 時) ---------
    def get_overlap_queryset(self):
        """
        create() 内で Mixin が呼ぶ。
        RESOURCE の衝突判定には会社内の全スケジュールを対象にする。
        """
        user = self.request.user
        return (
            Schedule.objects
            .filter(company=user.company)
            .select_related("site", "work_category", "resource")
            .prefetch_related("members", "teams")
        )

    # --------- 作成 ---------
    def perform_create(self, serializer):
        """
        schedule_type を RESOURCE に固定し、
        company / created_by を付与して保存。
        """
        user = self.request.user
        schedule = serializer.save(
            company       = user.company,
            created_by    = user,
            schedule_type = ScheduleType.RESOURCE,
        )
        # members は任意。必要ならここで初期値を突っ込む処理を入れる
        return schedule