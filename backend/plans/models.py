from django.db import models

class Plan(models.Model):
    name = models.CharField(max_length=100)  # プラン名（例：ベーシック、スタンダード、プレミアム）
    price = models.PositiveIntegerField()  # 月額料金（円）
    user_limit = models.PositiveIntegerField(default=10)  # 標準ユーザー数制限
    description = models.TextField(blank=True, null=True)  # プラン説明（オプション）
    created_at = models.DateTimeField(auto_now_add=True)  # 作成日

    def __str__(self):
        return f"{self.name}（{self.price}円）"
