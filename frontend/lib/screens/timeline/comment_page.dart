import 'package:cached_network_image/cached_network_image.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/api/comment_api.dart';
import 'package:frontend/api/post_api.dart';
import 'package:frontend/models/comment_model.dart';
import 'package:frontend/models/post_model.dart';
import 'package:frontend/providers/comment_list_provider.dart';
import 'package:frontend/providers/dio_provider.dart';
import 'package:frontend/providers/post_list_provider.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:frontend/utils/constants.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class CommentPage extends ConsumerStatefulWidget {
  const CommentPage({super.key, required this.post});
  final PostModel post;

  @override
  ConsumerState<CommentPage> createState() => _CommentPageState();
}

class _CommentPageState extends ConsumerState<CommentPage> {
  final _controller = TextEditingController();
  late bool _isRead;

  @override
  void initState() {
    super.initState();
    _isRead = widget.post.isRead;
  }

  String resolveImageUrl(String path) {
    if (path.startsWith('http')) return path;
    final base = apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$base/$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    final postList = ref.watch(postListProvider);
    final post = postList
            .whenData((l) =>
                l.firstWhere((p) => p.id == widget.post.id,
                    orElse: () => widget.post))
            .value ??
        widget.post;

    final commentsAsync = ref.watch(commentListProvider(post.id));
    final me = ref.watch(userProvider);
    final showConfirmButton =
        post.isImportant && !_isRead && me?.id != post.userId;

    //---↓ ここから画面 -------------------------------------------------------
    return Scaffold(
      appBar: AppBar(title: const Text('詳細')),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: CustomScrollView(
          slivers: [
            // ヘッダー
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: _PostHeader(
                  post: post,
                  showConfirmButton: showConfirmButton,
                  onConfirm: () async {
                    final dio = ref.read(dioProvider);
                    final updated = await markAsRead(dio, post.id);
                    ref.read(postListProvider.notifier).updatePost(updated);
                    setState(() => _isRead = true);
                  },
                  isRead: _isRead,
                  resolveImageUrl: resolveImageUrl,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: Divider(height: 0)),

            // コメント部（ローディング／エラー／一覧）
            commentsAsync.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('Error: $e')),
              ),
              data: (comments) => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _CommentTile(c: comments[i]),
                  childCount: comments.length,
                ),
              ),
            ),
          ],
        ),
      ),
      // 入力欄
      // ↓ Scaffold 内 bottomNavigationBar を差し替え
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          // キーボードが無いとき 8、あるときはその高さ＋8
          bottom: MediaQuery.of(context).viewInsets.bottom + 8,
        ),
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          top: false, // 上側の SafeArea は不要
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'コメントを入力',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () async {
                  final text = _controller.text.trim();
                  if (text.isEmpty) return;
                  final dio = ref.read(dioProvider);
                  final newC = await createComment(
                    dio: dio,
                    postId: post.id,
                    content: text,
                  );
                  ref
                      .read(commentListProvider(post.id).notifier)
                      .prependComment(newC);
                  ref
                      .read(postListProvider.notifier)
                      .incrementCommentCount(post.id);
                  _controller.clear();
                },
              ),
            ],
          ),
        ),
      ),

    );
  }
}

/* ─────────────────────── 以下ヘッダー＆コメントタイルは変更なし ───────────────────── */

class _PostHeader extends StatelessWidget {
  const _PostHeader({
    required this.post,
    required this.showConfirmButton,
    required this.onConfirm,
    required this.isRead,
    required this.resolveImageUrl,
  });

  final PostModel post;
  final bool showConfirmButton;
  final VoidCallback onConfirm;
  final bool isRead;
  final String Function(String) resolveImageUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            post.userIconImg != null
                ? CircleAvatar(
                    backgroundImage:
                        CachedNetworkImageProvider(resolveImageUrl(post.userIconImg!)),
                  )
                : CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.userUsername,
                    style: Theme.of(context).textTheme.titleLarge),
                Text(post.userAccountId,
                    style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.secondary)),
              ],
            ),
            const Spacer(),
            Text(post.isImportant ? '重要' : '',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 20),
        Text(post.content,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(fontWeight: FontWeight.normal)),
        if (post.images.isNotEmpty) ...[
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: post.images.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1,
            ),
            itemBuilder: (_, i) {
              final url = resolveImageUrl(post.images[i]);
              return GestureDetector(
                onTap: () {
                  final controller = PageController(initialPage: i);
                  context.pushTransparentRoute(
                    DismissiblePage(
                      onDismissed: () => Navigator.of(context).pop(),
                      isFullScreen: true,
                      direction: DismissiblePageDismissDirection.vertical,
                      child: Stack(
                        children: [
                          PhotoViewGallery.builder(
                            itemCount: post.images.length,
                            pageController: controller,
                            backgroundDecoration:
                                const BoxDecoration(color: Colors.black),
                            builder: (context, index) {
                              final image =
                                  resolveImageUrl(post.images[index]);
                              return PhotoViewGalleryPageOptions(
                                imageProvider:
                                    CachedNetworkImageProvider(image),
                                minScale: PhotoViewComputedScale.contained,
                                maxScale:
                                    PhotoViewComputedScale.covered * 2.5,
                              );
                            },
                          ),
                          Positioned(
                            top: 30,
                            right: 20,
                            child: Material(
                              color: Colors.transparent,
                              child: IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.white, size: 30),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const SizedBox(),
                    errorWidget: (_, __, ___) => const Icon(Icons.error),
                  ),
                ),
              );
            },
          ),
        ],
        const SizedBox(height: 20),
        Text(
          DateFormat('M月d日 H時mm分', 'ja')
              .format(DateTime.parse(post.createdAt)),
          style: TextStyle(
              fontSize: 14, color: Theme.of(context).colorScheme.secondary),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child: showConfirmButton
              ? Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        backgroundColor:
                            Theme.of(context).scaffoldBackgroundColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.secondary,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Text('確認しました',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.c});
  final CommentModel c;

  String resolveImageUrl(String path) {
    if (path.startsWith('http')) return path;
    final base = apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    return '$base$path';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: c.userIconImg != null
          ? CircleAvatar(
              backgroundImage:
                  CachedNetworkImageProvider(resolveImageUrl(c.userIconImg!)))
          : CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: const Icon(Icons.person, color: Colors.white)),
      title: Text(c.userUsername),
      subtitle: Text(c.content),
      trailing: Text(c.createdAt.substring(0, 10),
          style: Theme.of(context).textTheme.bodySmall),
    );
  }
}





