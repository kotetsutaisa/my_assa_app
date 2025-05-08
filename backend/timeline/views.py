from rest_framework import generics
from rest_framework.permissions import IsAuthenticated
from .permissions import IsCompanyMember
from .models import Post
from .serializers import PostSerializer
from drf_spectacular.utils import extend_schema

# --- 投稿一覧API ---
@extend_schema(
    summary="投稿一覧を取得",
    description="所属会社に紐づく投稿一覧を返します。",
    responses=PostSerializer,
)
class PostListView(generics.ListAPIView):
    serializer_class = PostSerializer
    permission_classes = [IsAuthenticated, IsCompanyMember]
    queryset = Post.objects.select_related('user').order_by('-created_at')

    def get_queryset(self):
        """
        通常は所属会社のみ。
        superuser (is_staff=True && is_superuser=True) は会社横断を将来使えるように
        フラグを見て切替。今は無効化しておく。
        """
        qs = self.queryset
        if not self.request.user.is_superuser:          # ←今はここでブロック
            qs = qs.filter(company=self.request.user.company)
        return qs.filter(user__is_active=True)
    

# --- 投稿作成 ---
@extend_schema(
    summary="投稿を作成",
    description="タイムラインに新しい投稿を作成します。",
    request=PostSerializer,
    responses=PostSerializer,
)
class PostCreateView(generics.CreateAPIView):
    serializer_class = PostSerializer
    permission_classes = [IsAuthenticated, IsCompanyMember]

    def perform_create(self, serializer):
        serializer.save(
            user=self.request.user,
            company=self.request.user.company,     # ★強制セット
            # is_important=self.request.data.get('is_important', False),
        )
