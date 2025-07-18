# app: resources / models.py
#
# “車両スケジュール” の MVP 用シンプルモデル
# ─────────────────────────────────────────
import uuid

from django.conf import settings
from django.db import models
from django.utils.translation import gettext_lazy as _


class ResourceCategory(models.Model):
    """
    例）トラック / ハイエース / ライトバン … を会社ごとに分類
    """
    company = models.ForeignKey(
        "companies.Company",
        on_delete=models.CASCADE,
        related_name="resource_categories",
        verbose_name=_("会社 (テナント)"),
    )
    name = models.CharField(_("カテゴリ名"), max_length=100)

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "リソースカテゴリ"
        verbose_name_plural = "リソースカテゴリ一覧"
        unique_together = ("company", "name")          # 会社内で重複禁止
        ordering = ["name"]

    def __str__(self) -> str:
        return f"{self.name}（{self.company.name}）"


class Resource(models.Model):
    """
    会社が保有・共有する “車両 / 重機 / その他資産” を表す
    MVP では必須＋最低限の管理に必要なカラムのみ。
    追加情報が必要になったら migration でカラムを増やす想定。
    """
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
        help_text=_("URL セーフ & シャーディングしやすい主キー"),
    )

    company = models.ForeignKey(
        "companies.Company",
        on_delete=models.CASCADE,
        related_name="resources",
        verbose_name=_("会社 (テナント)"),
    )

    # 任意のカテゴリ（null 可）
    category = models.ForeignKey(
        ResourceCategory,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="resources",
        verbose_name=_("カテゴリ"),
    )

    name = models.CharField(_("名称"), max_length=100)          # 例: ハイエース A 号

    maker      = models.CharField(_("メーカー"),   max_length=50, blank=True)
    plate_no   = models.CharField(_("ナンバー"),   max_length=15, blank=True)
    capacityKg = models.PositiveIntegerField(_("積載量(kg)"),    null=True, blank=True)


    description = models.TextField(_("備考"), blank=True, null=True)

    is_active = models.BooleanField(
        _("稼働中"),
        default=True,
        help_text=_("廃車・売却時に False にして論理削除として扱う"),
    )

    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="created_resources",
        verbose_name=_("登録者"),
    )

    created_at = models.DateTimeField(_("登録日時"), auto_now_add=True)
    updated_at = models.DateTimeField(_("更新日時"), auto_now=True)

    class Meta:
        verbose_name = "リソース"
        verbose_name_plural = "リソース一覧"
        ordering = ["name"]

    def __str__(self) -> str:
        return f"{self.name}（{self.company.name}）"
