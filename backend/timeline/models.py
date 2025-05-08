from django.db import models
from django.conf import settings
from django.contrib.auth import get_user_model

# Django標準のユーザーモデルを取得
User = get_user_model()

# 投稿モデル
class Post(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='posts'
    )
    company = models.ForeignKey(            # ★追加
        'companies.Company',
        on_delete=models.CASCADE,
        related_name='posts',
        db_index=True                       # フィルタ専用インデックス
    )
    content = models.TextField()
    image = models.ImageField(upload_to='post_images/', null=True, blank=True)
    views = models.PositiveIntegerField(default=0)
    is_important = models.BooleanField(default=False, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [
            models.Index(fields=['company', '-created_at']),
        ]

    def __str__(self):
        return f'{self.user.username}: {self.content[:20]}'


# いいねモデル
class Like(models.Model):
    post = models.ForeignKey(Post, on_delete=models.CASCADE, related_name='likes')  # どの投稿へのいいねか
    user = models.ForeignKey(User, on_delete=models.CASCADE)  # いいねを押したユーザー
    created_at = models.DateTimeField(auto_now_add=True)  # いいね日時

    class Meta:
        unique_together = ('post', 'user')  # 同じユーザーが同じ投稿に複数いいねできない制約


# コメントモデル
class Comment(models.Model):
    post = models.ForeignKey(Post, on_delete=models.CASCADE, related_name='comments')  # どの投稿へのコメントか
    user = models.ForeignKey(User, on_delete=models.CASCADE)  # コメントしたユーザー
    content = models.TextField()  # コメント本文
    created_at = models.DateTimeField(auto_now_add=True)  # コメント日時


# 投稿既読モデル
class PostReadStatus(models.Model):
    post = models.ForeignKey(Post, on_delete=models.CASCADE, related_name='read_statuses')  # どの投稿を読んだか
    user = models.ForeignKey(User, on_delete=models.CASCADE)  # 読んだユーザー
    read_at = models.DateTimeField(auto_now_add=True)  # 既読日時

    class Meta:
        unique_together = ('post', 'user')  # 同じ投稿を同じユーザーが複数回既読登録しない制約
