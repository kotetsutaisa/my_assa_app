from rest_framework import generics
from .models import Post
from .serializers import PostSerializer
from rest_framework.permissions import AllowAny

# 投稿一覧API
class PostListView(generics.ListAPIView):
    queryset = Post.objects.all().order_by('-created_at')  # 最新順に並べる
    serializer_class = PostSerializer
    permission_classes = [AllowAny] 

