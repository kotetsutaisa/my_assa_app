# users/views.py
from __future__ import annotations

from django.contrib.auth import get_user_model
from rest_framework.parsers import MultiPartParser, FormParser
from django.db import transaction
from rest_framework import generics, status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import UserRateThrottle
from rest_framework.serializers import ValidationError
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)

from .serializers import (
    CustomTokenObtainPairSerializer,
    CustomUserCreateSerializer,
    FullUserSerializer, UserUpdateSerializer,
    SimpleUserSerializer,
)
from .permissions import IsCompanyMember

User = get_user_model()

# --------------------------------------------------
# 1. 共通: レート制限クラス
# --------------------------------------------------
class BurstRateThrottle(UserRateThrottle):   # 短期スパイク
    rate = "20/min"

class SustainedRateThrottle(UserRateThrottle):  # 1 日あたり
    rate = "2000/day"


# --------------------------------------------------
# 2. 認証トークン取得
# --------------------------------------------------
class CustomTokenObtainPairView(TokenObtainPairView):
    permission_classes = [AllowAny]
    serializer_class = CustomTokenObtainPairSerializer
    throttle_classes = [BurstRateThrottle, SustainedRateThrottle]


# --------------------------------------------------
# 3. ユーザー登録
#    - GenericAPIView で拡張性確保
#    - serializer.save() が dict を返す前提で create を override
# --------------------------------------------------
class UserRegisterView(generics.GenericAPIView):
    permission_classes = [AllowAny]
    serializer_class = CustomUserCreateSerializer
    throttle_classes = [BurstRateThrottle, SustainedRateThrottle]

    @transaction.atomic
    def post(self, request, *args, **kwargs):
        """
        新規登録 & JWT 発行
        """
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.save()          # <- dict が返る
        return Response(data, status=status.HTTP_201_CREATED)


# --------------------------------------------------
# 4. 現在ユーザー取得
#    - RetrieveAPIView を使うと将来 company 絞り込みも楽
# --------------------------------------------------
class GetCurrentUser(generics.RetrieveAPIView):
    permission_classes = [IsAuthenticated]
    throttle_classes = [BurstRateThrottle]
    serializer_class = FullUserSerializer

    def get_object(self):
        return self.request.user  # queryset 不要


# --------------------------------------------------
# 5. リフレッシュトークン
# --------------------------------------------------
class CustomTokenRefreshView(TokenRefreshView):
    throttle_classes = [BurstRateThrottle]


# --------------------------------------------------
# 6. プロフィール編集
# --------------------------------------------------

class UpdateCurrentUser(generics.UpdateAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = UserUpdateSerializer
    parser_classes = [MultiPartParser, FormParser] 

    def get_object(self):
        return self.request.user
    

# --------------------------------------------------
# 7. 同じ会社のユーザーを全て取得
# --------------------------------------------------

class ConpanyUserAPIView(generics.ListAPIView):
    serializer_class = SimpleUserSerializer
    permission_classes = [IsCompanyMember,]

    def get_queryset(self):
        user = self.request.user
        return (
            User.objects
                .filter(company=user.company, is_active=True)
                .exclude(id=user.id)
                .select_related('company')
        )