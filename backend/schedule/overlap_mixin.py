# schedules/overlap_mixin.py
from functools import reduce
from operator import or_

from django.db import transaction
from django.db.models import Q
from django.utils.dateparse import parse_datetime
from django.utils import timezone as dj_tz
from rest_framework import status
from rest_framework.response import Response

from .models import ScheduleType                # ★
from resources.models import Resource           # ★

def _members_q(members):
    return Q(members__in=members)

class OverlapSafeCreateMixin:
    """
    POST 時に
      ■ personal / team … 時刻が交差 かつ members が 1 人でも重複
      ■ resource       … 時刻が交差 かつ 同じ resource
    があれば 409。 ?force=true なら競合を整理してから登録。
    """

    def create(self, request, *args, **kwargs):
        data   = request.data
        force  = request.query_params.get('force') == 'true'

        # ─────── 対象時間帯 ───────
        start  = parse_datetime(data['start_time'])
        end    = parse_datetime(data['end_time'])
        if dj_tz.is_naive(start):
            start = dj_tz.make_aware(start, dj_tz.get_default_timezone())
        if dj_tz.is_naive(end):
            end   = dj_tz.make_aware(end,   dj_tz.get_default_timezone())

        # ─────── スケジュール種別 ───────
        schedule_type = data.get('schedule_type')

        qs_overlap = self.get_overlap_queryset().filter(
            start_time__lt=end,
            end_time__gt=start,
        )

        # ===== ① RESOURCE 予定 =====
        if schedule_type == ScheduleType.RESOURCE:
            res_id   = data.get('resource_id') or data.get('resource')
            resource = Resource.objects.filter(pk=res_id).first()
            if resource:
                qs_overlap = qs_overlap.filter(resource=resource)
            else:
                qs_overlap = qs_overlap.none()

            if qs_overlap.exists() and not force:
                ser = self.get_serializer(qs_overlap, many=True)
                return Response(
                    {'detail': 'resource_overlap', 'conflicts': ser.data},
                    status=status.HTTP_409_CONFLICT
                )

            with transaction.atomic():
                qs_overlap.delete()          # ← 競合は丸ごと削除
                return super().create(request, *args, **kwargs)

        # ===== ② PERSONAL / TEAM 予定 =====
        from django.contrib.auth import get_user_model
        User = get_user_model()
        member_ids = data.get('member_ids') or []
        members = User.objects.filter(id__in=member_ids)

        if not members.exists():                     # 空なら作成者だけ
            members = User.objects.filter(id=request.user.id)

        qs_overlap = qs_overlap.filter(_members_q(members)).distinct()

        if qs_overlap.exists() and not force:
            ser = self.get_serializer(qs_overlap, many=True)
            return Response(
                {'detail': 'member_overlap', 'conflicts': ser.data},
                status=status.HTTP_409_CONFLICT
            )

        # ─ force=true → かぶったメンバーだけ remove、残らなければ delete
        with transaction.atomic():
            for sc in qs_overlap.select_for_update():
                dup = sc.members.filter(id__in=members.values_list('id', flat=True))
                sc.members.remove(*dup)
                if sc.members.count() == 0:
                    sc.delete()

            return super().create(request, *args, **kwargs)
