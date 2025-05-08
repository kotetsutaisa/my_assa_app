from rest_framework import serializers
from .models import Post

class PostSerializer(serializers.ModelSerializer):
    user_username = serializers.CharField(source='user.username', read_only=True)  # ユーザー名
    user_account_id = serializers.CharField(source='user.account_id', read_only=True)  # アカウントID

    user_iconimg = serializers.ImageField(
        source='user.iconimg',
        read_only=True
    )

    is_important = serializers.BooleanField(required=False, default=False)

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
            'is_important',     # 重要な投稿
            'created_at',       # 作成日時
        ]
        read_only_fields = ['user', 'views', 'created_at']

    def validate_content(self, value):
        if not value.strip():
            raise serializers.ValidationError("投稿内容を入力してください。")
        if len(value) > 1000:
            raise serializers.ValidationError("投稿内容は1000文字以内で入力してください。")
        return value
