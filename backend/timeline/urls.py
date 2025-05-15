from django.urls import path
from .views import (
    PostListView, PostCreateView, PostLikeToggleView,
    CommentListCreateView, CommentRetrieveUpdateDestroyView,
    PostReadView
)


urlpatterns = [
    # ---- Posts ----
    path('', PostListView.as_view(), name='post-list'),
    path('create/', PostCreateView.as_view(), name='post-create'),
    path('<int:pk>/like/', PostLikeToggleView.as_view(), name='post-like'),

    # ---- read ----
    path('<int:pk>/read/', PostReadView.as_view(), name='post-read'),

    # ---- Comments ----
    path('<int:post_id>/comments/',           # 一覧 / 作成
         CommentListCreateView.as_view(), name='comment-list-create'),
    path('comments/<int:pk>/',                       # 取得 / 更新 / 削除
         CommentRetrieveUpdateDestroyView.as_view(), name='comment-detail'),
]
