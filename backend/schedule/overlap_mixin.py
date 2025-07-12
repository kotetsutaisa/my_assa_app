# schedules/overlap_mixin.py
from functools import reduce
from operator   import or_

from django.db      import transaction
from django.db.models import Q, Exists, OuterRef
from django.utils.dateparse import parse_datetime
from django.utils import timezone as dj_tz
from rest_framework import status
from rest_framework.response import Response

def _members_q(members):
    """members が 1 人でも一致する schedule を抽出する Q オブジェクト"""
    # `members__in` だけだと OR 条件なので OK
    return Q(members__in=members)

class OverlapSafeCreateMixin:
    """
    1) 同じ会社内で
       - 時刻が交差 かつ
       - members が 1 人でも重複
       …していれば 409 を返す
    2) ?force=true なら重複分だけを削除して登録
    """

    # POST 時だけ呼ばれる
    def create(self, request, *args, **kwargs):
        data   = request.data
        force  = request.query_params.get('force') == 'true'

        # ─── 対象時間帯 ───
        start  = parse_datetime(data['start_time'])
        end    = parse_datetime(data['end_time'])
        if dj_tz.is_naive(start):
            start = dj_tz.make_aware(start, dj_tz.get_default_timezone())
        if dj_tz.is_naive(end):
            end   = dj_tz.make_aware(end,   dj_tz.get_default_timezone())

        # ─── 対象メンバー ───
        from django.contrib.auth import get_user_model
        User = get_user_model()
        member_ids = data.get('member_ids') or []
        members = User.objects.filter(id__in=member_ids)

        # 作成者自身も「含めたい／含めたくない」は設計次第で調整
        if not members.exists():
            members = User.objects.filter(id=request.user.id)

        # ─── 重複検索 ───
        qs_overlap = (
            self.get_overlap_queryset()  # ← Mixin を付けた View によって違う
            .filter(
                start_time__lt=end,
                end_time__gt=start,
            )
            .filter(_members_q(members))
            .distinct()
        )

        if qs_overlap.exists() and not force:
            ser = self.get_serializer(qs_overlap, many=True)
            return Response(
                {'detail': 'overlap', 'conflicts': ser.data},
                status=status.HTTP_409_CONFLICT
            )

        # ─── force=true なら「かぶってるメンバーだけ外す」 ───
        with transaction.atomic():
            if qs_overlap.exists():
                for sc in qs_overlap.select_for_update():        # ロックして安全に
                    dup_members = sc.members.filter(id__in=members.values('id'))
                    sc.members.remove(*dup_members)
                    # メンバーゼロになったら schedule 自体を削除
                    if sc.members.count() == 0:
                        sc.delete()

            return super().create(request, *args, **kwargs)
