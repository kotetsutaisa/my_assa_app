from django.contrib import admin
from .models import Post, Like, Comment, PostReadStatus

# モデルを管理画面に登録
admin.site.register(Post)
admin.site.register(Like)
admin.site.register(Comment)
admin.site.register(PostReadStatus)
