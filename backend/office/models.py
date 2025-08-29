from decimal import Decimal
from datetime import time as dtime

from django.conf import settings
from django.db import models
from django.db.models import Q
from companies.models import Company
from django.core.exceptions import ValidationError


class RoundingMode(models.TextChoices):
    NEAREST = "nearest", "Nearest (四捨五入)"
    UP      = "up",      "Ceil (切り上げ)"
    DOWN    = "down",    "Floor (切り捨て)"


def default_break_template():
    # 例: 10:00-10:30 / 12:00-13:00 / 15:00-15:30
    return [
        {"start": "10:00", "end": "10:30"},
        {"start": "12:00", "end": "13:00"},
        {"start": "15:00", "end": "15:30"},
    ]


def default_weekly_holidays():
    # 会社が任意でチェックボックス設定する前提の初期値
    # 例: 日曜/祝日 休み
    return {"sun": True, "mon": False, "tue": False, "wed": False, "thu": False, "fri": False, "sat": False, "holiday": False}


def empty_list():
    return []


def empty_dict():
    return {}


class CompanyPayrollPolicy(models.Model):
    """
    会社単位の給与計算ポリシー（1社=1レコード）
    """
    company = models.OneToOneField(Company, on_delete=models.CASCADE, related_name="payroll_policy")

    # 丸め
    time_granularity_minutes = models.PositiveSmallIntegerField(default=15)
    rounding_mode = models.CharField(max_length=10, choices=RoundingMode.choices, default=RoundingMode.NEAREST)

    # 休憩テンプレ（勤務帯と交差した分を控除）
    break_template_json = models.JSONField(default=default_break_template, help_text="[{start:'HH:MM', end:'HH:MM'}, ...]")

    # 残業・深夜
    overtime_starts_at = models.TimeField(default=dtime(17, 0))
    overtime_rate_multiplier = models.DecimalField(max_digits=5, decimal_places=2, default=Decimal("1.25"))

    night_starts_at = models.TimeField(default=dtime(22, 0))
    night_ends_at   = models.TimeField(default=dtime(5, 0))
    night_rate_multiplier = models.DecimalField(max_digits=5, decimal_places=2, default=Decimal("1.25"))

    # 休日（法定は無視。会社が選ぶ）
    weekly_holidays = models.JSONField(default=default_weekly_holidays)
    custom_holidays = models.JSONField(default=empty_list)   # ['YYYY-MM-DD', ...]
    custom_workdays = models.JSONField(default=empty_list)   # 例外的な出勤日（将来用）

    # 出来高の会社デフォルト等（将来拡張口）
    piecework_defaults_json = models.JSONField(default=empty_dict, blank=True)

    # 0=月末, 1〜28=その日で締め
    closing_day = models.PositiveSmallIntegerField(default=0, help_text="0=end-of-month, 1-28")
    # 0=月末, 1〜28=その日が支払日
    pay_day = models.PositiveSmallIntegerField(default=0, help_text="0=end-of-month, 1-28")
    # 支払月オフセット（当月=0, 翌月=1, 翌々月=2...）
    pay_month_offset = models.SmallIntegerField(default=1)

    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def clean(self):
        for field in ("closing_day", "pay_day"):
            v = getattr(self, field)
            if not (v == 0 or 1 <= v <= 28):
                raise ValidationError({field: "0(=月末) または 1〜28 を指定してください。"})
            
    # 便宜用：会社設定として一意（既存運用に合わせていればOK）
    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["company"], name="uniq_company_policy"),
        ]

    def __str__(self) -> str:
        return f"PayrollPolicy<{self.company_id}>"


class PayType(models.TextChoices):
    MONTHLY   = "monthly",   "月給"
    DAILY     = "daily",     "日給"
    HOURLY    = "hourly",    "時給"
    PIECEWORK = "piecework", "出来高"


class WageContract(models.Model):
    """
    従業員ごとの賃金契約（履歴化前提：期間で管理）
    """
    company = models.ForeignKey(Company, on_delete=models.CASCADE, related_name="wage_contracts")
    user    = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="wage_contracts")

    effective_from = models.DateField()
    effective_to   = models.DateField(null=True, blank=True)

    pay_type = models.CharField(max_length=20, choices=PayType.choices)

    # 単価（pay_type に応じてどれかを主に使用）
    monthly_salary = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    daily_wage     = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    hourly_wage    = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)

    piecework_schema_json = models.JSONField(default=empty_dict, blank=True)

    # 会社ポリシーの一部上書き（MVPは率のみ）
    override_company_policy = models.BooleanField(default=False)
    custom_overtime_rate_multiplier = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    custom_night_rate_multiplier    = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)

    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="created_wage_contracts")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [
            models.Index(fields=["company", "user", "effective_from"]),
        ]
        # 金額必須の簡易チェック（出来高は自由）
        constraints = [
            models.CheckConstraint(
                name="wagecontract_amount_by_type",
                check=(
                    Q(pay_type="monthly", monthly_salary__isnull=False) |
                    Q(pay_type="daily",   daily_wage__isnull=False) |
                    Q(pay_type="hourly",  hourly_wage__isnull=False) |
                    Q(pay_type="piecework")
                ),
            )
        ]

    def __str__(self) -> str:
        return f"WageContract<{self.company_id}:{self.user_id}:{self.pay_type} {self.effective_from}>"

