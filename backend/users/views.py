from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework import generics
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.permissions import AllowAny
from rest_framework_simplejwt.views import TokenRefreshView

from django.contrib.auth import get_user_model

from .serializers import CustomTokenObtainPairSerializer
from .serializers import CustomUserCreateSerializer
from .serializers import FullUserSerializer

User = get_user_model()

# ----------------------------
# JWTログインAPI
# メールアドレスとパスワードを受け取り、JWTトークン（access + refresh）を返す
# ----------------------------
class CustomTokenObtainPairView(TokenObtainPairView):
    permission_classes = [AllowAny]
    serializer_class = CustomTokenObtainPairSerializer      # 独自のシリアライザーでログイン処理を拡張


# ----------------------------
# ユーザー登録API
# 登録と同時にJWTトークンを発行し、ログイン状態にできるようにする
# ※ CreateAPIViewを使っていないのは、serializer.save() が辞書を返すため
# ----------------------------
class UserRegisterView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = CustomUserCreateSerializer(data=request.data)
        if serializer.is_valid():
            data = serializer.save()  # user情報 + トークン（辞書形式）
            return Response(data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    

# ----------------------------
# 最小限のCurrentUserの取得
# シリアライザーはSimpleUserSerializer
# ----------------------------
class GetCurrentUser(APIView):
    permission_classes = [IsAuthenticated]

    """
    現在ログイン中のユーザー情報を取得するエンドポイント。
    JWTトークンが有効であれば、ユーザー情報を返す。
    """
    def get(self, request):
        currentUser = request.user
        serializer = FullUserSerializer(currentUser)
        return Response(
            {
                "message": "ユーザー情報を取得しました。",
                "user": serializer.data
            },
            status=status.HTTP_200_OK
        )
    


class CustomTokenRefreshView(TokenRefreshView):
    """
    リフレッシュ用のカスタムビュー（必要なら独自Serializerも使う）
    """
    pass