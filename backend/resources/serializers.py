from rest_framework import serializers
from django.utils import timezone as dj_tz
from django.contrib.auth import get_user_model

from .models import ResourceCategory, Resource

User = get_user_model()
# ------------------------------------------------------------------
#   ResourceCategory  （例：トラック／バン／重機 …）
# ------------------------------------------------------------------
class ResourceCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model  = ResourceCategory
        fields = ("id", "name", "created_at")

    # ───────── 会社を自動セット ─────────
    def create(self, validated_data):
        user = self.context["request"].user
        return ResourceCategory.objects.create(
            company=user.company,
            **validated_data,
        )


# ------------------------------------------------------------------
#   Resource  （実際の車両・機械など）
# ------------------------------------------------------------------
class ResourceSerializer(serializers.ModelSerializer):
    # ─ 読取用：カテゴリを名前付きで返す
    category = ResourceCategorySerializer(read_only=True)

    # ─ 書込用：プルダウン選択等で ID を渡す
    category_id = serializers.PrimaryKeyRelatedField(
        queryset = ResourceCategory.objects.none(),      # ← __init__ で上書き
        source   = "category",
        allow_null = True,
        required   = False,
        write_only = True,
    )

    class Meta:
        model  = Resource
        fields = (
            "id",
            # 会社・作成者は自動付与なので出力のみ
            "company",          # read‑only
            "name",
            "category", "category_id",
            "maker",
            "plate_no",
            "capacityKg",
            "description",
            "is_active",
            "created_at", "updated_at",
        )
        read_only_fields = ("company", "created_at", "updated_at")

    # ------------------------------------------------------------
    # 会社毎に絞った queryset を仕込みたいので __init__ を override
    # ------------------------------------------------------------
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        request  = self.context.get("request")
        company  = getattr(request.user, "company", None) if request else None
        if company:
            self.fields["category_id"].queryset = (
                ResourceCategory.objects.filter(company=company)
            )

    # ---------------- 作成 ----------------
    def create(self, validated_data):
        return super().create(validated_data)

    # ---------------- 更新 ----------------
    def update(self, instance, validated_data):
        # company / created_by は固定なので除外
        validated_data.pop("company", None)
        validated_data.pop("created_by", None)

        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        return instance

    # ---------------- バリデーション ----------------
    def validate(self, attrs):
        """
        - 車両ナンバー(plate_no) が会社内で一意かどうか確認  
        - 更新時は **自分自身を除外** して重複検索する
        """
        request = self.context["request"]
        company = request.user.company

        # フォームから送られて来た値（PATCH なら部分的）
        new_plate = attrs.get("plate_no", getattr(self.instance, "plate_no", "")).strip()

        if new_plate:  # 空文字ならスキップ
            dup_qs = (
                Resource.objects
                .filter(company=company, plate_no=new_plate)      # 同じ会社 & 同じナンバー
            )
            if self.instance:                                      # 更新時は自分を除外
                dup_qs = dup_qs.exclude(pk=self.instance.pk)

            if dup_qs.exists():
                raise serializers.ValidationError(
                    {"plate_no": "このナンバーは既に登録されています。"}
                )

        return attrs
