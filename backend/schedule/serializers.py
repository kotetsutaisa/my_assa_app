from rest_framework import serializers
from .models import WorkCategory, Schedule, ScheduleType
from site_app.models import Site
from site_app.serializers import SiteSerializer
from users.serializers import SimpleUserSerializer
from django.utils import timezone as dj_tz
from django.contrib.auth import get_user_model
from resources.models import Resource

User = get_user_model()


# 作業内容
class WorkCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = WorkCategory
        fields = ['id', 'name']


# スケジュール
class ScheduleSerializer(serializers.ModelSerializer):
    site = SiteSerializer(read_only=True)
    site_id = serializers.PrimaryKeyRelatedField(
        queryset=Site.objects.all(),
        source='site',
        write_only=True
    )
    members = serializers.SerializerMethodField()
    member_ids = serializers.PrimaryKeyRelatedField(
        queryset=User.objects.all(),
        many=True,
        write_only=True,
        required=False,
    )
    work_category = WorkCategorySerializer(read_only=True)
    work_category_id = serializers.PrimaryKeyRelatedField(
        queryset=WorkCategory.objects.all(),
        source='work_category',
        write_only=True
    )
    site_name = serializers.CharField(source='site.name', read_only=True)

    resource_id = serializers.PrimaryKeyRelatedField(
        queryset=Resource.objects.none(),
        source='resource',
        allow_null=True,
        required=False,
        write_only = True,
    )
    resource = serializers.StringRelatedField(read_only=True)

    class Meta:
        model = Schedule
        fields = (
            'id',
            # -- FK --
            'site', 'site_id', 'site_name',
            'work_category', 'work_category_id',
            'resource', 'resource_id',
            # -- core --
            'start_time', 'end_time', 'schedule_type',
            # -- members --
            'members', 'member_ids',
            # -- meta --
            'created_at',
        )

    def __init__(self, *args, **kwargs):
        """
        リクエストユーザーの company に属するオブジェクトだけ
        PrimaryKeyRelatedField の queryset に流し込む
        """
        super().__init__(*args, **kwargs)
        user = self.context["request"].user
        company = getattr(user, "company", None)

        if company:
            self.fields["site_id"].queryset          = Site.objects.filter(company=company)
            self.fields["work_category_id"].queryset = WorkCategory.objects.filter(company=company)
            self.fields["resource_id"].queryset      = Resource.objects.filter(company=company)

    def get_members(self, obj):
        return SimpleUserSerializer(obj.members.all(), many=True).data

    def create(self, validated_data):
        members = validated_data.pop('member_ids', [])
        user = self.context['request'].user

        if validated_data.get("schedule_type") == "personal" and not members:
            members = [user]

        validated_data['company'] = user.company
        validated_data['created_by'] = user

        schedule = Schedule.objects.create(**validated_data)
        schedule.members.set(members)
        return schedule

    def update(self, instance, validated_data):
        members = validated_data.pop('member_ids', serializers.empty)

        # company / created_by を変更不能に
        validated_data.pop('company', None)
        validated_data.pop('created_by', None)

        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()

        if members is not serializers.empty:      # ← キーが来た時だけ更新
            instance.members.set(members)

        return instance

    def validate(self, data):
        start = data.get("start_time") or getattr(self.instance, "start_time", None)
        end   = data.get("end_time")   or getattr(self.instance, "end_time",   None)

        # aware にそろえる
        if start and dj_tz.is_naive(start):
            start = dj_tz.make_aware(start, dj_tz.get_default_timezone())
            data["start_time"] = start
        if end and dj_tz.is_naive(end):
            end = dj_tz.make_aware(end, dj_tz.get_default_timezone())
            data["end_time"] = end

        if start and end and start >= end:
            raise serializers.ValidationError("終了日時は開始日時より後にしてください。")

        # リソース予定なら resource は必須
        schedule_type = data.get("schedule_type") or getattr(self.instance, "schedule_type", None)
        resource      = data.get("resource")      or getattr(self.instance, "resource", None)
        if schedule_type == ScheduleType.RESOURCE and resource is None:
            raise serializers.ValidationError({"resource_id": "リソース予定では resource_id が必須です。"})

        return data
