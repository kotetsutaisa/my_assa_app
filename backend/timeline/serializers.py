from rest_framework import serializers
from .models import Post

class PostSerializer(serializers.ModelSerializer):
    user_username = serializers.CharField(source='user.username', read_only=True)  # ユーザー名
    user_account_id = serializers.CharField(source='user.account_id', read_only=True)  # アカウントID
    user_iconimg = serializers.ImageField(source='user.iconimg', read_only=True)  # ユーザーアイコン

    class Meta:
        model = Post
        fields = [
            'id',
            'user',             # ユーザーID
            'user_username',    # ユーザー名
            'user_account_id',  # アカウントID
            'user_iconimg',     # ユーザーアイコン
            'content',          # 本文
            'image',            # 画像
            'views',            # 閲覧数
            'created_at',       # 作成日時
        ]
