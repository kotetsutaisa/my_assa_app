import uuid
from datetime import datetime, timedelta
from django.conf import settings
from django.db import models
from django.utils.translation import gettext_lazy as _

# 会社/チーム/サイト/カテゴリは “文字参照” で依存を解消
# - companies.Company
# - companies.Team
# - site_app.Site
# - schedules.WorkCategory

class ReportStatus(models.TextChoices):
    DRAFT     = 'draft',     _('下書き')
    PENDING   = 'pending',   _('承認待ち')
    SUBMITTED = 'submitted', _('提出済み')
    LOCKED    = 'locked',    _('ロック（締め後）')


class ClosingPeriod(models.Model):
    """
    月次の締め情報（Phase5 で本格利用。Phase1ではスケルトン）
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    company = models.ForeignKey(
        'companies.Company',
        on_delete=models.CASCADE,
        related_name='closing_periods',
        verbose_name=_('会社')
    )
    # 対象月の1日を入れる想定（例：2025-07-01）
    year_month = models.DateField(_('対象月(1日を格納)'))
    closed     = models.BooleanField(default=False)
    closed_at  = models.DateTimeField(null=True, blank=True)
    closed_by  = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True, blank=True,
        related_name='performed_closings',
        verbose_name=_('締め実行者')
    )

    class Meta:
        verbose_name = _('締め期間')
        verbose_name_plural = _('締め期間一覧')
        unique_together = (('company', 'year_month'),)
        indexes = [
            models.Index(fields=['company', 'year_month']),
        ]

    def __str__(self) -> str:
        ym = self.year_month.strftime('%Y-%m')
        return f'{self.company} / {ym} / {"CLOSED" if self.closed else "OPEN"}'


# ===========================
#       チーム日報 (親)
# ===========================
class TeamReport(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    company = models.ForeignKey(
        'companies.Company',
        on_delete=models.CASCADE,
        related_name='team_reports',
        verbose_name=_('会社'),
    )
    team = models.ForeignKey(
        'companies.Team',
        on_delete=models.CASCADE,
        related_name='reports',
        verbose_name=_('チーム'),
    )
    date = models.DateField(_('日付'))

    status = models.CharField(
        max_length=16,
        choices=ReportStatus.choices,
        default=ReportStatus.DRAFT,
        verbose_name=_('ステータス'),
    )

    note = models.TextField(_('メモ'), blank=True, default='')

    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True, blank=True,
        related_name='created_team_reports',
        verbose_name=_('作成者'),
    )
    created_at = models.DateTimeField(auto_now_add=True)

    submitted_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        verbose_name = _('チーム日報')
        verbose_name_plural = _('チーム日報一覧')
        # 同一会社×同一チーム×同一日で一意
        unique_together = (('company', 'team', 'date'),)
        ordering = ['-date', 'team__name']
        indexes = [
            models.Index(fields=['company', 'team', 'date']),
            models.Index(fields=['status']),
        ]

    def __str__(self) -> str:
        return f'{self.date} / {self.team} ({self.get_status_display()})'


class TeamReportEntry(models.Model):
    """
    チーム日報の明細。
    - MVP要件：「現場 × 作業カテゴリ」に、**担当者(=メンバー)** を紐づけて列挙
    - 1日複数現場・複数カテゴリがありうるため、自由に複数行を持てる
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    report = models.ForeignKey(
        TeamReport,
        on_delete=models.CASCADE,
        related_name='entries',
        verbose_name=_('チーム日報'),
    )
    # 担当メンバー（作業員）
    member = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='team_report_entries',
        verbose_name=_('メンバー'),
    )
    # 現場（削除でレポートまで消えるのを避けたいなら PROTECT 推奨）
    site = models.ForeignKey(
        'site_app.Site',
        on_delete=models.PROTECT,
        related_name='team_report_entries',
        verbose_name=_('現場'),
    )
    # 作業カテゴリ（任意）
    work_category = models.ForeignKey(
        'schedule.WorkCategory',
        on_delete=models.SET_NULL,
        null=True, blank=True,
        related_name='team_report_entries',
        verbose_name=_('作業内容'),
    )

    start_time = models.TimeField(_('開始時刻'))
    end_time   = models.TimeField(_('終了時刻'))

    note = models.CharField(_('メモ'), max_length=255, blank=True, default='')

    class Meta:
        verbose_name = _('チーム日報明細')
        verbose_name_plural = _('チーム日報明細一覧')
        ordering = ['report', 'member__id']
        indexes = [
            models.Index(fields=['report']),
            models.Index(fields=['member']),
            models.Index(fields=['site']),
        ]

    def __str__(self) -> str:
        wc = self.work_category.name if self.work_category else '-'
        return f'{self.report.date} {self.member} / {self.site.name} / {wc}'


# ===========================
#      個人日報（親）
# ===========================
class PersonalReport(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    company = models.ForeignKey(
        'companies.Company',
        on_delete=models.CASCADE,
        related_name='personal_reports',
        verbose_name=_('会社'),
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='personal_reports',
        verbose_name=_('ユーザー'),
    )
    date = models.DateField(_('日付'))

    status = models.CharField(
        max_length=16,
        choices=ReportStatus.choices,
        default=ReportStatus.DRAFT,
        verbose_name=_('ステータス'),
    )

    # チーム日報からの自動生成であれば参照を保持（差分トラッキング用・任意）
    source_team_report = models.ForeignKey(
        TeamReport,
        on_delete=models.SET_NULL,
        null=True, blank=True,
        related_name='generated_personal_reports',
        verbose_name=_('生成元チーム日報'),
    )

    note = models.TextField(_('メモ'), blank=True, default='')

    approved_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True, blank=True,
        related_name='approved_personal_reports',
        verbose_name=_('承認者'),
    )
    approved_at = models.DateTimeField(null=True, blank=True)

    created_at   = models.DateTimeField(auto_now_add=True)
    submitted_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        verbose_name = _('個人日報')
        verbose_name_plural = _('個人日報一覧')
        # 同一会社×同一ユーザー×同一日で一意
        unique_together = (('company', 'user', 'date'),)
        ordering = ['-date', 'user__id']
        indexes = [
            models.Index(fields=['company', 'user', 'date']),
            models.Index(fields=['status']),
        ]

    def __str__(self) -> str:
        return f'{self.date} / {self.user} ({self.get_status_display()})'


class PersonalReportEntry(models.Model):
    """
    個人日報の明細。
    - MVP要件：「現場 × 作業カテゴリ」の列挙のみ
    - 差分チェックのため、生成元 TeamReportEntry を保持しておく
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    report = models.ForeignKey(
        PersonalReport,
        on_delete=models.CASCADE,
        related_name='entries',
        verbose_name=_('個人日報'),
    )
    site = models.ForeignKey(
        'site_app.Site',
        on_delete=models.PROTECT,
        related_name='personal_report_entries',
        verbose_name=_('現場'),
    )
    work_category = models.ForeignKey(
        'schedule.WorkCategory',
        on_delete=models.SET_NULL,
        null=True, blank=True,
        related_name='personal_report_entries',
        verbose_name=_('作業内容'),
    )

    start_time = models.TimeField(_('開始時刻'))
    end_time   = models.TimeField(_('終了時刻'))

    # チーム日報明細 → 個人日報明細の生成時に紐づける
    source_team_entry = models.ForeignKey(
        TeamReportEntry,
        on_delete=models.SET_NULL,
        null=True, blank=True,
        related_name='copied_to_personal_entries',
        verbose_name=_('生成元チーム明細'),
    )
    # 個人側で変更があれば True（締め時の差分同期で使用）
    changed_from_source = models.BooleanField(default=False)

    note = models.CharField(_('メモ'), max_length=255, blank=True, default='')

    class Meta:
        verbose_name = _('個人日報明細')
        verbose_name_plural = _('個人日報明細一覧')
        ordering = ['report_id']
        indexes = [
            models.Index(fields=['report']),
            models.Index(fields=['site']),
        ]

    def __str__(self) -> str:
        wc = self.work_category.name if self.work_category else '-'
        return f'{self.report.date} / {self.site.name} / {wc}'
    
    @property
    def work_minutes(self) -> int:
        base_date = self.report.date
        start_dt = datetime.combine(base_date, self.start_time)
        end_dt   = datetime.combine(base_date, self.end_time)
        if end_dt <= start_dt:
            end_dt += timedelta(days=1)  # 日付またぎ
        total = int((end_dt - start_dt).total_seconds() // 60)
        return max(0, total)


