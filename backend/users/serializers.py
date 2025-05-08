from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.tokens import RefreshToken

from rest_framework import serializers

from django.contrib.auth import authenticate
from django.contrib.auth import get_user_model

from companies.serializers import CompanyCreateSerializer

User = get_user_model()

# 最小限のユーザー情報を返すシリアライザー
class SimpleUserSerializer(serializers.ModelSerializer):
    iconimg = serializers.ImageField(use_url=True)

    class Meta:
        model = User
        fields = ['id', 'email', 'username', 'account_id', 'iconimg']

# 全てのユーザー情報を返すシリアライザー
class FullUserSerializer(serializers.ModelSerializer):
    iconimg = serializers.ImageField(use_url=True)
    company = CompanyCreateSerializer(read_only=True)

    class Meta:
        model = User
        fields = ['id', 'email','username', 'account_id', 'iconimg', 'bio', 'company', 'date_joined']


# ログイン用
class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    username_field = User.EMAIL_FIELD  # ← メールでログイン

    def validate(self, attrs):
        # リクエストボディからemailとpasswordを取得
        email = attrs.get("email")
        password = attrs.get("password")

        # 未入力チェック
        if email is None or password is None:
            raise serializers.ValidationError("メールアドレスとパスワードは必須です")

        # 認証処理（DBからユーザー探す）
        user = authenticate(request=self.context.get("request"), username=email, password=password)

        # 存在チェック、アクティブチェック
        if not user:
            raise serializers.ValidationError("メールアドレスまたはパスワードが間違っています")

        if not user.is_active:
            raise serializers.ValidationError("このアカウントは無効化されています")

        # JWTトークン生成
        refresh = self.get_token(user)

        return {
            'refresh': str(refresh),
            'access': str(refresh.access_token),
        }


# ユーザー登録用シリアライザー
# バリデーション＋パスワードのハッシュ化＋トークン発行まで一括で処理する
class CustomUserCreateSerializer(serializers.ModelSerializer):
    # パスワードは書き込み専用＆8文字以上に制限
    password = serializers.CharField(write_only=True, min_length=8)

    # 任意入力（プロフィール文）／空文字OK
    bio = serializers.CharField(required=False, allow_blank=True)  # ← null OK

    # 任意入力（アイコン画像）／nullも許容（未設定対応
    iconimg = serializers.ImageField(required=False, allow_null=True)  # ← null OK

    # 所属会社（外部キー）も任意でnull許容、関連モデルを動的に取得
    company = serializers.PrimaryKeyRelatedField(
        required=False,
        allow_null=True,
        queryset=User._meta.get_field('company').related_model.objects.all()
    )  # ← null OK

    # 対象モデルと使用するフィールドを指定
    class Meta:
        model = User
        fields = ['email', 'password', 'username', 'account_id', 'iconimg', 'bio', 'company']

    # メールアドレスの重複チェック
    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("このメールアドレスは既に使用されています。")
        return value
    
    # アカウントIDの形式チェック（@で始まり、8文字以上）
    def validate_account_id(self, value):
        if not value.startswith("@"):
            raise serializers.ValidationError("アカウントIDは @ から始めてください。")
        if len(value) < 8:
            raise serializers.ValidationError("アカウントIDは8文字以上で入力してください。")
        return value

    # ユーザー登録時の処理（DB保存 + トークン発行
    def create(self, validated_data):
        password = validated_data.pop('password')

        # emailとusernameをちゃんと分ける
        username = validated_data.pop('username')
        email = validated_data.get('email')

        user = User(username=username, email=email, **validated_data)
        user.set_password(password)
        user.save()

        refresh = RefreshToken.for_user(user)
        return {
            'user': SimpleUserSerializer(user).data,
            'refresh': str(refresh),
            'access': str(refresh.access_token),
        }