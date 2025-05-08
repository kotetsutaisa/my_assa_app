from django.contrib.auth.models import AbstractUser
from django.db import models
from companies.models import Company
from django.utils.translation import gettext_lazy as _


# ユーザーの役職を表す列挙型
class Role(models.TextChoices):
    ADMIN = 'admin', _('管理者')
    MANAGER = 'manager', _('部長')
    MEMBER = 'member', _('一般')




# カスタムJWTユーザーテーブル
class CustomUser(AbstractUser):
    # ログイン時の内部ユニーク識別子
    username = models.CharField(max_length=50, unique=True, blank=False)

    # ユーザーが自由に設定できるID（@account_id用）
    account_id = models.CharField(max_length=30, unique=True, blank=False)

    # メールアドレス（ログインにも使う）
    email = models.EmailField(unique=True, blank=False)

    # プロフィールアイコン
    iconimg = models.ImageField(upload_to='profile_icons/', null=True, blank=True)

    # 自己紹介文
    bio = models.TextField(blank=True)

    # 役職（admin/manager/member）
    role = models.CharField(max_length=10, choices=Role.choices, default=Role.MEMBER)

    # 所属会社
    company = models.ForeignKey(Company, null=True, blank=True, on_delete=models.SET_NULL, related_name='members')

    # アカウント有効フラグ
    is_active = models.BooleanField(default=True)

    # 登録日時
    date_joined = models.DateTimeField(auto_now_add=True)

    # ログイン認証で使うフィールド
    USERNAME_FIELD = 'email'
    # ユーザー作成時に必要なフィールド
    REQUIRED_FIELDS = ['account_id', 'username']

    def __str__(self):
        return self.email

