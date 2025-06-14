from rest_framework import serializers
from .models import Site
from datetime import date

class SiteSerializer(serializers.ModelSerializer):
    is_active = serializers.SerializerMethodField()

    class Meta:
        model = Site
        fields = (
            'id',
            'company',
            'name',
            'address',
            'latitude',
            'longitude',
            'general_contractor_name',
            'manager_name',
            'manager_phone',
            'memo',
            'start_date',
            'end_date',
            'created_at',
            'updated_at',
            'is_active',
        )

        read_only_fields = (
            'id',
            'company',
            'created_at',
            'updated_at',
        )

    def get_is_active(self, obj):
        if not obj.end_date:
            return True  # 終了日がなければ施工中
        return obj.end_date >= date.today()

    def validate_name(self, value):
        company = self.context['request'].user.company
        if self.instance is None and Site.objects.filter(company=company, name=value).exists():
            raise serializers.ValidationError("同じ名前の現場がすでに登録されています。")
        return value

    def validate_manager_phone(self, value):
        if value and not value.isdigit():
            raise serializers.ValidationError("電話番号は数字のみで入力してください。")
        if value and len(value) < 10:
            raise serializers.ValidationError("電話番号が短すぎます。")
        return value

    def validate(self, data):
        start = data.get("start_date")
        end = data.get("end_date")
        if start and end and start > end:
            raise serializers.ValidationError("作業開始日は終了日よりも前である必要があります。")
        return data