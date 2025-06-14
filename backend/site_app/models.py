from django.db import models
import uuid
from django.utils.translation import gettext_lazy as _

class Site(models.Model):

    id = models.UUIDField(
        # 主キー
        primary_key=True,
        # ランダムなUUIDを生成
        default=uuid.uuid4,
        # 人間が手動でIDを入れることを防ぐ
        editable=False,
        help_text=_("URL セーフ & シャーディングしやすい主キー"),
    )

    company = models.ForeignKey(
        "companies.Company",
        on_delete=models.CASCADE,
        related_name="sites",
        verbose_name=_("会社"),
    )

    name = models.CharField(
        _("現場名"),
        max_length=100,
    )

    address = models.CharField(
        _("住所"),
        max_length=255
    )

    latitude = models.FloatField(
        _("緯度"),
        null=True,
        blank=True
    )

    longitude = models.FloatField(
        _("経度"),
        null=True,
        blank=True
    )

    general_contractor_name = models.CharField(
        _("ゼネコン名"),
        max_length=100,
        blank=True
    )

    manager_name = models.CharField(
        _("所長名"),
        max_length=50,
        blank=True
    )

    manager_phone = models.CharField(
        _("所長の電話番号"),
        max_length=20,
        blank=True
    )

    start_date = models.DateField(
        _("作業開始日"),
        null=True,
        blank=True
    )

    end_date = models.DateField(
        _("作業終了日"),
        null=True,
        blank=True
    )

    memo = models.TextField(
        _("備考"),
        blank=True,
        help_text=_("現場に関する注意点や特記事項など")
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    updated_at = models.DateTimeField(
        auto_now=True
    )

    def __str__(self):
        return self.name