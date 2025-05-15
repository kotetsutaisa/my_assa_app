from rest_framework import serializers
from .models import Post, Comment, PostImage       # ★ PostImage を追加

class PostSerializer(serializers.ModelSerializer):
    # ------- ユーザー情報 -------
    user_username   = serializers.CharField(source='user.username', read_only=True)
    user_account_id = serializers.CharField(source='user.account_id', read_only=True)
    user_iconimg    = serializers.ImageField(source='user.iconimg', read_only=True)

    # ------- ログインユーザー -------
    user_id = serializers.IntegerField(source='user.id', read_only=True)

    # ------- アプリ固有 -------
    is_important = serializers.BooleanField(required=False, default=False)

    # ------- いいね -------
    likes_count = serializers.IntegerField(read_only=True, default=0)
    is_liked    = serializers.BooleanField(read_only=True, default=False)

    # ------- コメント数 -------
    comments_count = serializers.IntegerField(read_only=True, default=0)

    # ------- 既読 -------
    is_read    = serializers.BooleanField(read_only=True, default=False)
    read_count = serializers.IntegerField(read_only=True, default=0)

    # ------- 画像(2〜4枚目) ------- ★追加
    images = serializers.SerializerMethodField()

    def get_images(self, obj):
        """1枚目＋サブ画像の URL 一覧を順番付きで返す"""
        return obj.all_image_urls

    class Meta:
        model  = Post
        fields = [
            'id',
            'user_id',
            'user',
            'user_username',
            'user_account_id',
            'user_iconimg',
            'content',
            'image',          # 1枚目（後方互換）
            'images',         # 1〜4 枚の URL 配列  ←★
            'views',
            'likes_count',
            'is_liked',
            'is_important',
            'comments_count',
            'is_read',
            'read_count',
            'created_at',
        ]
        read_only_fields = ['user', 'views', 'created_at']

    # 本文バリデーションはそのまま
    def validate_content(self, value):
        if not value.strip():
            raise serializers.ValidationError("投稿内容を入力してください。")
        if len(value) > 1000:
            raise serializers.ValidationError("投稿内容は1000文字以内で入力してください。")
        return value


# ---------------- コメント ----------------
class CommentSerializer(serializers.ModelSerializer):
    user_username   = serializers.CharField(source='user.username',   read_only=True)
    user_account_id = serializers.CharField(source='user.account_id', read_only=True)
    user_iconimg    = serializers.ImageField(source='user.iconimg',   read_only=True)

    class Meta:
        model  = Comment
        fields = [
            'id', 'post', 'user',
            'user_username', 'user_account_id', 'user_iconimg',
            'content', 'created_at',
        ]
        read_only_fields = ['user', 'post', 'created_at']
