import uuid
from django.utils.translation import gettext_lazy as _
from django.db import models
from plans.models import Plan  # プランと紐づける
from django.conf import settings
from django.utils import timezone
from django.core.exceptions import ValidationError

User = settings.AUTH_USER_MODEL

# --- 会社モデル ---
class Company(models.Model):
    name = models.CharField(max_length=255)  # 会社名
    plan = models.ForeignKey(Plan, on_delete=models.SET_NULL, null=True, blank=True)  # 契約プラン
    custom_user_limit = models.PositiveIntegerField(null=True, blank=True)  # 個別対応用の人数上書き
    address = models.CharField(max_length=255, blank=True, null=True)  # 住所（オプション）
    phone = models.CharField(max_length=50, blank=True, null=True)  # 電話番号（オプション）
    created_at = models.DateTimeField(auto_now_add=True)  # 登録日

    # 承認ステータス
    is_approved = models.BooleanField(default=False)  # 運営による承認が完了したか
    requested_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,  # ← ここを修正
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='requested_companies'
    )  # 登録申請者

    class Meta:
        verbose_name = "Company"
        verbose_name_plural = "Companies"

    def __str__(self):
        return self.name

    @property
    def user_limit(self):
        """会社が実際に使えるユーザー数"""
        if self.custom_user_limit:
            return self.custom_user_limit
        if self.plan:
            return self.plan.user_limit
        return None  # プランもカスタムも無い場合（レアケース）



# --- 招待コードモデル ---
class InviteCode(models.Model):
    # 招待コード（例: "XJ82FZKQWT9L"）を一意に管理
    code = models.CharField(max_length=12, unique=True)

    # この招待コードが紐づく会社（必須）
    company = models.ForeignKey(
        'Company',
        on_delete=models.CASCADE,
        related_name='invite_codes'  # company.invite_codes で一覧取得できる
    )

    # このコードを発行したユーザー（管理者）
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True  # 削除された場合でもコードだけは残す
    )

    # 発行日時（自動設定）
    created_at = models.DateTimeField(auto_now_add=True)

    # 有効期限（例: 発行から24時間）
    expires_at = models.DateTimeField()

    # すでに誰かが使用したかどうか（Trueなら使用済み）
    is_used = models.BooleanField(default=False)

    # このコードが有効かどうかを判定（ビューやAPIで使える便利メソッド）
    def is_valid(self):
        return not self.is_used and timezone.now() < self.expires_at

    # 管理画面などでの表示形式
    def __str__(self):
        return f"{self.code}（{self.company.name}）"
    

# --- 会社のチームモデル ---
class Team(models.Model):
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
        related_name="teams",
        verbose_name="会社"
    )

    name = models.CharField("チーム名", max_length=100)

    created_at = models.DateTimeField("作成日時", auto_now_add=True)

    class Meta:
        verbose_name = "チーム"
        verbose_name_plural = "チーム一覧"
        ordering = ['created_at']

    def __str__(self):
        return f"{self.name}（{self.company.name}）"

    @property
    def member_count(self):
        return self.members.count()
    

# チーム参加者モデル
class TeamMember(models.Model):
    ROLE_CHOICES = [
        ('leader', 'リーダー'),
        ('member', 'メンバー'),
    ]

    team = models.ForeignKey(
        Team,
        on_delete=models.CASCADE,
        related_name="members",
        verbose_name="所属チーム"
    )

    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="team_memberships",
        verbose_name="ユーザー"
    )

    role = models.CharField(
        "役割",
        max_length=20,
        choices=ROLE_CHOICES,
        default='member',
    )

    is_active = models.BooleanField(default=True)

    joined_at = models.DateTimeField("参加日時", auto_now_add=True)

    class Meta:
        verbose_name = "チームメンバー"
        verbose_name_plural = "チームメンバー一覧"
        unique_together = ('team', 'user')
        ordering = ['joined_at']

    def __str__(self):
        return f"{self.user.username}（{self.team.name}）: {self.get_role_display()}"
    
    def clean(self):
        if self.role == 'leader' and TeamMember.objects.filter(team=self.team, role='leader').exclude(pk=self.pk).exists():
            raise ValidationError("リーダーは1チームに1人までです。")
