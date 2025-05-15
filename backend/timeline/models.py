from django.db import models
from django.conf import settings
from django.contrib.auth import get_user_model
from django.utils.functional import cached_property


# Django標準のユーザーモデルを取得
User = get_user_model()

# 投稿モデル
class Post(models.Model):

    """
    1枚目 … `image`
    2〜4枚目 … `extra_images` でぶら下がる `PostImage`
    """

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

    # ---- 本文・画像 ----
    content = models.TextField()
    image = models.ImageField(
        upload_to='post_images/', null=True, blank=True
    )

    # ---- メタ情報 ----
    views = models.PositiveIntegerField(default=0)
    is_important = models.BooleanField(default=False, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [
            models.Index(fields=['company', '-created_at']),
        ]
        ordering = ["-created_at"]

    def __str__(self):
        return f'{self.user.username}: {self.content[:20]}'

    @cached_property
    def all_image_urls(self):
        urls = []

        if self.image:
            urls.append(self.image.url)

        # ★ related_name=sub_images で取得
        for s in self.sub_images.all()[:3]:   # order 昇順（Meta.ordering）
            urls.append(s.image.url)

        return urls

    

class PostImage(models.Model):
    """
    Post に紐付く 2〜4 枚目の画像
    """
    post  = models.ForeignKey(
        Post,
        on_delete=models.CASCADE,
        related_name='sub_images',
    )
    image = models.ImageField(upload_to="post_images/")
    order = models.PositiveSmallIntegerField(default=1)  # 1〜3

    class Meta:
        ordering = ["order"]
        unique_together = ("post", "order")  # 同じ順序の重複防止

    def __str__(self) -> str:
        return f"[{self.post_id}] image#{self.order}"
    

# いいねモデル
class Like(models.Model):
    post = models.ForeignKey(Post, on_delete=models.CASCADE, related_name='likes')  # どの投稿へのいいねか
    user = models.ForeignKey(User, on_delete=models.CASCADE)  # いいねを押したユーザー
    created_at = models.DateTimeField(auto_now_add=True)  # いいね日時

    class Meta:
        unique_together = ('post', 'user')  # 同じユーザーが同じ投稿に複数いいねできない制約


# コメントモデル
class Comment(models.Model):
    post       = models.ForeignKey('Post', on_delete=models.CASCADE, related_name='comments')
    company    = models.ForeignKey('companies.Company', on_delete=models.CASCADE, db_index=True)
    user       = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    content    = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [
            models.Index(fields=['post', '-created_at']),   # 一覧ページ用
        ]
        ordering = ['-created_at']                          # デフォルト新着順

    def __str__(self):
        return f"{self.user.username}: {self.content[:20]}"


# 投稿既読モデル
class PostReadStatus(models.Model):
    post = models.ForeignKey(Post, on_delete=models.CASCADE, related_name='read_statuses')  # どの投稿を読んだか
    user = models.ForeignKey(User, on_delete=models.CASCADE)  # 読んだユーザー
    read_at = models.DateTimeField(auto_now_add=True)  # 既読日時

    class Meta:
        unique_together = ('post', 'user')  # 同じ投稿を同じユーザーが複数回既読登録しない制約
