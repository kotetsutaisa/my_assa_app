from rest_framework import generics, status, mixins
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404
from .permissions import IsCompanyMember, IsCommentAuthorOrCompanyAdmin
from .models import Post, Like, Comment, PostReadStatus, PostImage 
from .serializers import PostSerializer, CommentSerializer
from drf_spectacular.utils import extend_schema
from django.db.models import Count, Exists, OuterRef, Prefetch

# --- 投稿一覧API ---
@extend_schema(
    summary="投稿一覧を取得",
    description="所属会社に紐づく投稿一覧を返します。",
    responses=PostSerializer,
)
class PostListView(generics.ListAPIView):
    serializer_class   = PostSerializer
    permission_classes = [IsAuthenticated, IsCompanyMember]

    def get_queryset(self):
        user     = self.request.user
        company  = user.company

        # --- ?mine=true なら自分の投稿だけ ---
        mine = self.request.query_params.get('mine', '').lower() in {'1', 'true', 'yes'}

        qs = (
            Post.objects
                .filter(company=company, user__is_active=True)
                .select_related('user')
                .prefetch_related(                         # ★正しい related_name でプリフェッチ
                    Prefetch(
                        'sub_images',                      # ← extra_images → sub_images
                        queryset=PostImage.objects.order_by('order')
                    )
                )
                .annotate(
                    likes_count    = Count('likes'),
                    comments_count = Count('comments'),
                    read_count     = Count('read_statuses'),
                    is_liked       = Exists(Like.objects.filter(post=OuterRef('pk'), user=user)),
                    is_read        = Exists(PostReadStatus.objects.filter(post=OuterRef('pk'), user=user)),
                )
                .order_by('-created_at')
        )

        if mine:
            qs = qs.filter(user=user)

        return qs
    

# --- 投稿作成 ---
@extend_schema(
    summary="投稿を作成（画像最大4枚）",
    request=PostSerializer,
    responses=PostSerializer,
)
class PostCreateView(generics.CreateAPIView):
    serializer_class   = PostSerializer
    permission_classes = [IsAuthenticated, IsCompanyMember]

    def perform_create(self, serializer):
        user     = self.request.user
        company  = user.company
        files    = self.request.FILES                    # 短縮

        # --------------- 1枚目 ---------------
        first_image = files.get('images[0]') or files.get('image')

        post = serializer.save(
            user    = user,
            company = company,
            image   = first_image,       # None でも可
        )

        # --------------- 2〜4枚目 ---------------
        extras = [f for f in files.getlist('images') if f != first_image][:3]

        for idx, img in enumerate(extras, start=1):      # order=1,2,3
            PostImage.objects.create(
                post  = post,
                image = img,
                order = idx,
            )


# ------- いいねトグル -------
@extend_schema(
    summary="投稿をいいね／いいね解除",
    responses={200: PostSerializer},
)
class PostLikeToggleView(APIView):
    permission_classes = [IsAuthenticated, IsCompanyMember]

    def post(self, request, pk):
        post = generics.get_object_or_404(
            Post, pk=pk, company=request.user.company
        )
        like, created = Like.objects.get_or_create(
            post=post, user=request.user
        )
        if not created:
            # すでに存在 → いいね解除
            like.delete()

        # 最新状態を返す（likes_count / is_liked 付き）
        post_refresh = (
            Post.objects
            .filter(pk=pk)
            .annotate(
                likes_count=Count('likes'),
                comments_count=Count('comments'),
                is_liked=Exists(
                    Like.objects.filter(post=OuterRef('pk'), user=request.user)
                )
            )
            .select_related('user')
            .get()
        )
        serializer = PostSerializer(post_refresh)
        return Response(serializer.data, status=status.HTTP_200_OK)



# ------- コメント一覧 & 作成 -------
class CommentListCreateView(generics.ListCreateAPIView):
    serializer_class   = CommentSerializer
    permission_classes = [IsAuthenticated, IsCompanyMember]

    pagination_class = None          # 必要なら PageNumberPagination を設定

    def get_queryset(self):
        """
        /api/posts/<post_id>/comments/
        """
        post_id  = self.kwargs['post_id']
        company  = self.request.user.company
        return (
            Comment.objects
            .filter(post_id=post_id, company=company)
            .select_related('user')     # N+1 防止
        )

    def perform_create(self, serializer):
        post = get_object_or_404(
            Post, id=self.kwargs['post_id'], company=self.request.user.company
        )
        serializer.save(
            user=self.request.user,
            post=post,
            company=post.company,
        )


# ------- 詳細 / 更新 / 削除 -------
class CommentRetrieveUpdateDestroyView(
        mixins.UpdateModelMixin,
        mixins.DestroyModelMixin,
        generics.RetrieveAPIView
    ):
    serializer_class   = CommentSerializer
    permission_classes = [
        IsAuthenticated,
        IsCompanyMember,
        IsCommentAuthorOrCompanyAdmin,   # 上書き
    ]

    def get_queryset(self):
        company = self.request.user.company
        return Comment.objects.filter(company=company).select_related('user')
    


# ------- 既読トグル API -------
@extend_schema(
    summary="投稿を既読にする",
    responses={200: PostSerializer},
)
class PostReadView(APIView):
    permission_classes = [IsAuthenticated, IsCompanyMember]

    def post(self, request, pk):
        post = generics.get_object_or_404(
            Post, pk=pk, company=request.user.company
        )

        # ★ 既読レコードを作成（同一ユーザ・投稿ペアは unique_together）
        PostReadStatus.objects.get_or_create(post=post, user=request.user)

        # 最新状態（is_read / read_count）を返す
        post_refresh = (
            Post.objects
            .filter(pk=pk)
            .annotate(
                is_read=Exists(
                    PostReadStatus.objects.filter(
                        post=OuterRef('pk'), user=request.user
                    )
                ),
                read_count=Count('read_statuses'),
            )
            .select_related('user')
            .get()
        )
        return Response(
            PostSerializer(post_refresh).data,
            status=status.HTTP_200_OK,
        )