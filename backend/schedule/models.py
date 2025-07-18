from django.db import models
import uuid
from django.utils.translation import gettext_lazy as _
from django.conf import settings

# 予定の種類
class ScheduleType(models.TextChoices):
    PERSONAL = 'personal', '個人'
    TEAM = 'team', 'チーム'
    RESOURCE = 'resource', 'リソース'

# 作業内容
class WorkCategory(models.Model):

    company = models.ForeignKey(
        "companies.Company",
        # 親が削除されたら全部削除
        on_delete=models.CASCADE,
        related_name="workCategorys",
        verbose_name=_("会社 (テナント)"),
    )

    name = models.CharField(
        _("作業内容"),
        max_length=100,
    )

    is_active = models.BooleanField(default=True)

    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        verbose_name=_("作成者"),
    )

    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name
    

class Schedule(models.Model):

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
        related_name="schedules",
        verbose_name=_("会社 (テナント)"),
    )

    site = models.ForeignKey(
        "site_app.Site",
        on_delete=models.CASCADE,
        related_name="schedules",
        verbose_name=_("現場"),
    )

    resource = models.ForeignKey(
        "resources.Resource",
        on_delete=models.SET_NULL,
        null=True, blank=True,
        related_name="schedules",
        verbose_name=_("対象リソース"),
    )

    start_time = models.DateTimeField(
        verbose_name=_("開始日時"),
    )

    end_time = models.DateTimeField(
        verbose_name=_("終了日時"),
    )

    schedule_type = models.CharField(
        max_length=20,
        choices=ScheduleType.choices,
        default=ScheduleType.PERSONAL,
        verbose_name=_("予定の種類"),
    )

    work_category = models.ForeignKey(
        WorkCategory,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="schedules",
        verbose_name=_("作業内容"),
    )

    members = models.ManyToManyField(
        settings.AUTH_USER_MODEL,
        related_name="assigned_schedules",
        verbose_name=_("参加メンバー"),
        blank=True,
    )

    teams = models.ManyToManyField(
        "companies.Team",
        related_name="schedules",
        verbose_name=_("対象チーム")
    )

    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name="created_schedules",
        verbose_name=_("作成者"),
    )

    created_at = models.DateTimeField(auto_now_add=True)

    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.site.name} - {self.work_category.name if self.work_category else '作業未設定'}"
