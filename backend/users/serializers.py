# users/serializers.py
from __future__ import annotations

import re
from typing import Any, Dict

from django.conf import settings
from django.contrib.auth import authenticate, get_user_model
from django.db import IntegrityError, transaction
from django.utils.timezone import now

from rest_framework import serializers
from rest_framework.exceptions import ValidationError
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.tokens import RefreshToken

from companies.models import Company  # 明示インポート
from companies.serializers import CompanyCreateSerializer

User = get_user_model()

# --------------------------------------------------
# 共通ユーティリティ
# --------------------------------------------------
EMAIL_RE = re.compile(
    r"^(?=.{6,254}$)(?=.{1,64}@)[A-Za-z0-9!#$%&'*+\-/=?^_`{|}~.]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"
)
ACCOUNT_ID_RE = re.compile(r"^@[\w\-\.]{7,29}$")  # 「@」+英数/._- で 8〜30 文字

def normalize_email(value: str) -> str:
    """大小・全角半角を吸収。"""
    return value.strip().lower()

# --------------------------------------------------
# 1. ユーザー情報シリアライザ（参照用）
# --------------------------------------------------
class SimpleUserSerializer(serializers.ModelSerializer):
    iconimg = serializers.ImageField(use_url=True)

    class Meta:
        model = User
        fields = ("id", "email", "username", "account_id", "iconimg")


class FullUserSerializer(serializers.ModelSerializer):
    iconimg = serializers.ImageField(use_url=True)
    company = CompanyCreateSerializer(read_only=True)

    class Meta:
        model = User
        fields = (
            "id",
            "email",
            "username",
            "account_id",
            "iconimg",
            "bio",
            "company",
            "role",
            "is_active",
            "date_joined",
        )

# --------------------------------------------------
# 2. JWT ログイン
# --------------------------------------------------
class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    username_field = User.EMAIL_FIELD  # メールログイン

    default_error_messages = {
        "no_active": "このアカウントは無効化されています。",
        "invalid": "メールアドレスまたはパスワードが間違っています。",
        "required": "メールアドレスとパスワードは必須です。",
    }

    def validate(self, attrs: Dict[str, Any]) -> Dict[str, str]:
        email = attrs.get("email")
        password = attrs.get("password")

        if not email or not password:
            raise ValidationError(self.error_messages["required"])

        user = authenticate(
            request=self.context.get("request"),
            username=normalize_email(email),
            password=password,
        )

        if not user:
            raise ValidationError(self.error_messages["invalid"])

        if not user.is_active:
            raise ValidationError(self.error_messages["no_active"])

        refresh = self.get_token(user)
        # カスタムクレーム → Flutter 側のアクセス制御が楽になる
        refresh["role"] = user.role
        refresh["company_id"] = user.company_id

        return {"refresh": str(refresh), "access": str(refresh.access_token)}

# --------------------------------------------------
# 3. ユーザー登録
# --------------------------------------------------
class CustomUserCreateSerializer(serializers.ModelSerializer):
    # ---------- フィールド定義 ----------
    password = serializers.CharField(write_only=True, min_length=8)
    bio = serializers.CharField(required=False, allow_blank=True)
    iconimg = serializers.ImageField(required=False, allow_null=True)

    # 所属会社は「招待コード」経由で後から紐付けるケースが多い想定で任意
    company = serializers.PrimaryKeyRelatedField(
        queryset=Company.objects.all(), required=False, allow_null=True
    )

    class Meta:
        model = User
        fields = (
            "email",
            "password",
            "username",
            "account_id",
            "iconimg",
            "bio",
            "company",
        )

    # ---------- バリデーション ----------
    def validate_email(self, value: str) -> str:
        email = normalize_email(value)
        if not EMAIL_RE.match(email):
            raise ValidationError("メールアドレスの形式が正しくありません。")
        if User.objects.filter(email=email).exists():
            raise ValidationError("このメールアドレスは既に登録されています。")
        return email

    def validate_account_id(self, value: str) -> str:
        if not ACCOUNT_ID_RE.match(value):
            raise ValidationError(
                "@ から始まる英数字・._- で 8〜30 文字で入力してください。"
            )
        if User.objects.filter(account_id=value).exists():
            raise ValidationError("このアカウントIDは既に使われています。")
        return value

    def validate_username(self, value: str) -> str:
        if not value.strip():
            raise ValidationError("ユーザー名を入力してください。")
        return value.strip()

    # ---------- 作成処理 ----------
    @transaction.atomic
    def create(self, validated_data: Dict[str, Any]) -> Dict[str, Any]:
        # pop で重複データを抜きつつ加工
        password = validated_data.pop("password")
        email = validated_data.pop("email").lower()

        # 競合書き込み対策：IntegrityError を握りつぶして ValidationError へ
        try:
            user = User.objects.create(
                email=email, date_joined=now(), **validated_data
            )
        except IntegrityError:
            raise ValidationError("登録に失敗しました。再度お試しください。")

        user.set_password(password)
        user.save(update_fields=["password"])

        refresh = RefreshToken.for_user(user)
        return {
            "user": SimpleUserSerializer(user).data,
            "refresh": str(refresh),
            "access": str(refresh.access_token),
        }
    


# ----- プロフィール編集用 -----
class UserUpdateSerializer(serializers.ModelSerializer):
    email = serializers.EmailField(read_only=True)
    class Meta:
        model = User
        fields = ('id', 'email', 'username', 'bio', 'iconimg', 'account_id')

    def validate_account_id(self, value):
        user = self.instance
        if User.objects.exclude(pk=user.pk).filter(account_id=value).exists():
            raise serializers.ValidationError("このアカウントIDは既に使われています。")
        return value

    def update(self, instance, validated_data):
        instance.username = validated_data.get('username', instance.username)
        instance.bio = validated_data.get('bio', instance.bio)
        instance.account_id = validated_data.get('account_id', instance.account_id)
        instance.iconimg = validated_data.get('iconimg', instance.iconimg)
        instance.save()
        return instance

