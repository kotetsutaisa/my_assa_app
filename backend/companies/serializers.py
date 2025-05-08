# companies/serializers.py
import re
from django.db import transaction
from rest_framework import serializers
from .models import Company
from .models import InviteCode
from datetime import timedelta
from django.utils import timezone
import secrets
import string
from .models import InviteCode

class CompanyCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Company
        fields = ['id', 'name', 'address', 'phone', 'is_approved']
        read_only_fields = ['id', 'is_approved']          # 返したいけど書き込み禁止

    # ---------- フィールド単体バリデーション ----------
    def validate_phone(self, value):
        if not re.fullmatch(r'^\+?\d{9,15}$', value):
            raise serializers.ValidationError(
                "電話番号は国際電話形式（数字9〜15桁、先頭+可）で入力してください。"
            )
        return value

    # ---------- 複合バリデーション ----------
    def validate(self, attrs):
        user = self.context['request'].user

        if getattr(user, 'company_id', None):
            raise serializers.ValidationError("既に会社に所属しています。")

        if Company.objects.filter(name=attrs['name']).exists():
            raise serializers.ValidationError("同じ会社名が登録済みです。")

        return attrs

    # ---------- 登録処理 ----------
    def create(self, validated_data):
        request = self.context['request']
        user = request.user

        with transaction.atomic():
            company = Company.objects.create(
                **validated_data,
                is_approved=False,
                requested_by=user
            )
            user.company = company
            user.role = 'admin'
            user.save(update_fields=['company', 'role'])

        # ここで通知タスクを投げてもOK
        return company



# --- 招待コード生成シリアライザー ---
class InviteCodeCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = InviteCode
        fields = ['code', 'expires_at', 'is_used']

        # codeとexpires_atはread_only（自動生成するため）
        read_only_fields = ['code', 'expires_at', 'is_used']

    def validate(self, attrs):
        user = self.context['request'].user

        if not user.company:
            raise serializers.ValidationError("会社に所属していません。")

        if not user.company.is_approved:
            raise serializers.ValidationError("会社が未承認のため、招待コードは発行できません。")

        if user.role != 'admin':
            raise serializers.ValidationError("招待コードの発行権限がありません。")

        return attrs

    def create(self, validated_data):
        request = self.context['request']
        user = request.user

        # ランダムな英数字12桁コードを生成
        generated_code = ''.join(secrets.choice(string.ascii_uppercase + string.digits) for _ in range(12))

        invite = InviteCode.objects.create(
            code=generated_code,
            company=user.company,
            created_by=user,
            expires_at=timezone.now() + timedelta(days=1),
        )

        return invite
    


# --- 会社グループに参加する ---
class InviteCodeUseSerializer(serializers.Serializer):
    code = serializers.CharField(max_length=12)

    def validate_code(self, value):
        value = value.strip().upper()  # 空白除去＋大文字統一（実務的）

        try:
            invite = InviteCode.objects.get(code=value)
        except InviteCode.DoesNotExist:
            raise serializers.ValidationError("入力した招待コードが間違っています。")  # タイポと区別

        if not invite.is_valid():
            raise serializers.ValidationError("この招待コードは無効または期限切れです。")

        self.invite = invite  # save()で使用するため保存
        return value

    def save(self, **kwargs):
        user = kwargs.get('user')
        invite = self.invite

        if user.company:
            raise serializers.ValidationError("すでに会社に所属しています。")

        # ユーザーに会社情報を割り当て
        user.company = invite.company
        user.role = 'member'
        user.save(update_fields=['company', 'role'])

        # 招待コードを使用済みに更新
        invite.is_used = True
        invite.save(update_fields=['is_used'])

        return user
