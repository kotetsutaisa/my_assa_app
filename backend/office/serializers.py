from rest_framework import serializers
from users.serializers import SimpleUserSerializer
from users.models import Role
from django.contrib.auth import get_user_model

from companies.models import Company
from .models import CompanyPayrollPolicy, WageContract, PayType

User = get_user_model()

def _yen(v):
    if v is None:
        return None
    try:
        # 小数が来てもとりあえず四捨五入で見やすく
        iv = int(round(float(v)))
        return f"¥{iv:,}"
    except Exception:
        return f"¥{v}"
    

class WageContractSerializer(serializers.ModelSerializer):
    # 表示用に user の最低限フィールドを埋めるなら SerializerMethod などで拡張可（MVPはIDで十分）
    user_id = serializers.IntegerField(write_only=True)

    class Meta:
        model  = WageContract
        fields = (
            "id",
            "user_id",
            "pay_type",
            "effective_from",
            "effective_to",
            "monthly_salary",
            "daily_wage",
            "hourly_wage",
            "piecework_schema_json",
            "override_company_policy",
            "custom_overtime_rate_multiplier",
            "custom_night_rate_multiplier",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "created_at", "updated_at")

    # --- バリデーション ---
    def validate(self, attrs):
        pay_type = attrs.get("pay_type") or (self.instance.pay_type if self.instance else None)

        if pay_type == PayType.MONTHLY and not attrs.get("monthly_salary") and not getattr(self.instance, "monthly_salary", None):
            raise serializers.ValidationError({"monthly_salary": "月給を入力してください。"})
        if pay_type == PayType.DAILY and not attrs.get("daily_wage") and not getattr(self.instance, "daily_wage", None):
            raise serializers.ValidationError({"daily_wage": "日給を入力してください。"})
        if pay_type == PayType.HOURLY and not attrs.get("hourly_wage") and not getattr(self.instance, "hourly_wage", None):
            raise serializers.ValidationError({"hourly_wage": "時給を入力してください。"})

        return attrs

    def create(self, validated_data):
        request = self.context["request"]
        company: Company = request.user.company

        user_id = validated_data.pop("user_id")

        try:
            user = User.objects.get(id=user_id, company=company)
        except User.DoesNotExist:
            raise serializers.ValidationError({"user_id": "同じ会社のユーザーを指定してください。"})

        obj = WageContract.objects.create(
            company=company,
            user=user,
            created_by=request.user,
            **validated_data,
        )
        return obj

    def update(self, instance, validated_data):
        # user / company は更新不可（契約の主体が変わると履歴が壊れる）
        validated_data.pop("user_id", None)
        return super().update(instance, validated_data)

    

class EmployeeWithContractListItemSerializer(serializers.ModelSerializer):
    """
    ユーザー + 契約サマリー（main_rate_label / updated_at）
    - user: SimpleUserSerializer（既存）
    - main_rate_label: 方式に応じた見出し（例: "時給 ¥1,500"）
    - updated_at: 最新契約の updated_at（annotate 済み）
    """
    user = serializers.SerializerMethodField()
    main_rate_label = serializers.SerializerMethodField()
    updated_at = serializers.DateTimeField(source='contract_updated_at', allow_null=True, read_only=True)

    class Meta:
        model = User
        fields = ("user", "main_rate_label", "updated_at")

    def get_user(self, obj):
        return SimpleUserSerializer(obj, context=self.context).data

    def get_main_rate_label(self, obj):
        pay_type = getattr(obj, "contract_pay_type", None)
        if not pay_type:
            return None

        pay_type = str(pay_type)
        if pay_type == "hourly":
            rate = getattr(obj, "contract_hourly_wage", None)
            return f"時給 {_yen(rate)}" if rate is not None else "時給"
        if pay_type == "daily":
            rate = getattr(obj, "contract_daily_wage", None)
            return f"日給 {_yen(rate)}" if rate is not None else "日給"
        if pay_type == "monthly":
            rate = getattr(obj, "contract_monthly_salary", None)
            return f"月給 {_yen(rate)}" if rate is not None else "月給"
        if pay_type == "piecework":
            return "出来高（設定あり）"
        return None
    


class EmployeeDetailSummarySerializer(serializers.Serializer):
    """
    従業員詳細サマリー:
      - user: SimpleUserSerializer（読み取り専用）
      - current_contract: WageContractSerializer | null（読み取り専用）
      - labels: { main_rate_label, role_label_ja, primary_team_name }
      - meta:   { has_override }
      - updated_at: 現契約の updated_at（無ければ null）
    """
    user = SimpleUserSerializer(read_only=True)
    current_contract = WageContractSerializer(allow_null=True, read_only=True)
    labels = serializers.SerializerMethodField()
    meta = serializers.SerializerMethodField()
    updated_at = serializers.DateTimeField(allow_null=True)

    def get_labels(self, obj):
        # obj は view から渡された payload(dict)
        user_obj = obj.get("user")                 # CustomUser モデル
        contract_obj = obj.get("current_contract") # WageContract モデル or None

        # --- 契約のメインレート表示 ---
        main_rate_label = None
        if contract_obj is not None:
            t = getattr(contract_obj, "pay_type", None)
            if t == "hourly":
                main_rate_label = f"時給 {self._yen(getattr(contract_obj, 'hourly_wage', None))}"
            elif t == "daily":
                main_rate_label = f"日給 {self._yen(getattr(contract_obj, 'daily_wage', None))}"
            elif t == "monthly":
                main_rate_label = f"月給 {self._yen(getattr(contract_obj, 'monthly_salary', None))}"
            elif t == "piecework":
                main_rate_label = "出来高（設定あり）"

        # --- ユーザーの役職/チームは SimpleUserSerializer を一度だけ通して取得 ---
        user_data = SimpleUserSerializer(user_obj, context=self.context).data if user_obj else {}
        role_code = user_data.get("role")
        try:
            role_label_ja = Role(role_code).label
        except Exception:
            role_label_ja = Role.MEMBER.label

        teams = user_data.get("teams") or []
        primary_team_name = teams[0]["name"] if teams else "—"

        return {
            "main_rate_label": main_rate_label,
            "role_label_ja": role_label_ja,
            "primary_team_name": primary_team_name,
        }

    def get_meta(self, obj):
        contract_obj = obj.get("current_contract")
        return {
            "has_override": bool(
                contract_obj and getattr(contract_obj, "override_company_policy", False)
            )
        }

    @staticmethod
    def _yen(v):
        if v in (None, ""):
            return None
        try:
            iv = int(round(float(v)))
            return f"¥{iv:,}"
        except Exception:
            return f"¥{v}"
        


class CompanyPayrollPolicySerializer(serializers.ModelSerializer):
    class Meta:
        model  = CompanyPayrollPolicy
        fields = (
            "id",
            "time_granularity_minutes",
            "rounding_mode",
            "break_template_json",
            "overtime_starts_at",
            "overtime_rate_multiplier",
            "night_starts_at",
            "night_ends_at",
            "night_rate_multiplier",
            "weekly_holidays",
            "custom_holidays",
            "custom_workdays",
            "piecework_defaults_json",
            "notes",
            "closing_day",
            "pay_day",
            "pay_month_offset",
        )
        read_only_fields = ("id",)

    def update(self, instance, validated_data):
        # 単純更新（会社は変更不可）
        return super().update(instance, validated_data)
    
    def validate(self, attrs):
        # Model.clean にも検証あり。ここでも軽く二重チェック可
        for k in ("closing_day", "pay_day"):
            v = attrs.get(k)
            if v is not None and not (v == 0 or 1 <= v <= 28):
                raise serializers.ValidationError({k: "0(=月末) または 1〜28 を指定してください。"})
        return attrs