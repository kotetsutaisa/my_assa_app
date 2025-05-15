import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/api/date_api.dart';
import 'package:frontend/api/post_api.dart';
import 'package:frontend/providers/dio_provider.dart';
import 'package:frontend/providers/post_list_provider.dart';
import 'package:frontend/providers/user_provider.dart';          // ★追加
import 'package:frontend/screens/timeline/comment_page.dart';
import 'package:frontend/utils/constants.dart';
import 'package:frontend/widgets/post_button.dart';
import 'package:frontend/widgets/sub_header.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';


class TimelineTabPage extends ConsumerWidget {
  const TimelineTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postListProvider);
    final me         = ref.watch(userProvider);                 // ★自分

    String resolveImageUrl(String path) {
      if (path.startsWith('http')) return path;
      final base = apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');
      return '$base$path';
    }

    return Scaffold(
      body: postsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('エラーが発生しました: $err')),
        data: (posts) => Stack(
          children: [
            Column(
              children: [
                Center(
                  child: SubHeader(
                    title: 'タイムライン',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];

                      final showConfirmButton = post.isImportant &&
                          !post.isRead &&
                          me?.id != post.userId;                // ★判定

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CommentPage(post: post),
                            ),
                          );
                        },

                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ----- 左カラム (アイコン/重要) -----
                              Column(
                                children: [
                                  post.userIconImg != null
                                      ? CircleAvatar(
                                          radius: 20,
                                          backgroundImage: CachedNetworkImageProvider(
                                              resolveImageUrl(post.userIconImg!)),
                                          backgroundColor: Colors.grey[200],
                                        )
                                      : CircleAvatar(
                                          radius: 20,
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                          child: const Icon(Icons.person,
                                              color: Colors.white),
                                        ),
                                  Text(
                                    post.isImportant ? '重要' : '',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),

                              // ----- 本体 -----
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ヘッダー行
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Text(post.userUsername,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge
                                                ),
                                            const SizedBox(width: 10),
                                            Text(post.userAccountId,
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: Theme.of(context).colorScheme.secondary,
                                                ),
                                            ),
                                          ],
                                        ),
                                        Text(formatPostDate(post.createdAt),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // 本文
                                    Text(post.content,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge?.copyWith(
                                              fontWeight: FontWeight.normal,
                                            )),
                                    const SizedBox(height: 10),

                                    if (post.images.isNotEmpty) ...[
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
                                          final imageUrl = resolveImageUrl(post.images[i]);
                                          return GestureDetector(
                                            onTap: () {
                                              final pageController = PageController(initialPage: i);

                                              context.pushTransparentRoute(
                                                DismissiblePage(
                                                  onDismissed: () => Navigator.of(context).pop(),
                                                  isFullScreen: true,
                                                  direction: DismissiblePageDismissDirection.vertical,
                                                  child: Stack(
                                                    children: [
                                                      PhotoViewGallery.builder(
                                                        itemCount: post.images.length,
                                                        pageController: pageController,
                                                        backgroundDecoration: const BoxDecoration(color: Colors.black),
                                                        builder: (context, index) {
                                                          final url = resolveImageUrl(post.images[index]);
                                                          return PhotoViewGalleryPageOptions(
                                                            imageProvider: CachedNetworkImageProvider(url),
                                                            minScale: PhotoViewComputedScale.contained * 1,
                                                            maxScale: PhotoViewComputedScale.covered * 2.5,
                                                          );
                                                        },
                                                        loadingBuilder: (context, event) => const SizedBox.shrink(),
                                                      ),

                                                      Positioned(
                                                        top: 30,
                                                        right: 20,
                                                        child: Material( 
                                                          color: Colors.transparent, // 背景は透明にする
                                                          child: IconButton(
                                                            icon: const Icon(Icons.close, color: Colors.white, size: 30),
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
                                                imageUrl: imageUrl,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) => const SizedBox.shrink(),
                                                errorWidget: (context, url, error) => const Icon(Icons.error),
                                              ),
                                            ),
                                          );
                                        }

                                      ),
                                      const SizedBox(height: 10),
                                    ],

                                    // いいね & コメント行
                                    Row(
                                      children: [
                                        // いいね
                                        InkWell(
                                          onTap: () async {
                                            final dio = ref.read(dioProvider);
                                            final updated = await toggleLike(dio, post.id);
                                            final safeUpdate = updated.copyWith(
                                              isRead: post.isRead,
                                              isImportant: post.isImportant,
                                            );
                                            ref
                                                .read(postListProvider.notifier)
                                                .updatePost(safeUpdate);
                                          },
                                          borderRadius: BorderRadius.circular(20),
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                0, 8, 20, 8),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  post.isLiked
                                                      ? Icons.favorite
                                                      : Icons.favorite_border,
                                                  size: 20,
                                                  color: post.isLiked
                                                      ? const Color.fromARGB(
                                                          255, 255, 109, 157)
                                                      : Colors.grey,
                                                ),
                                                const SizedBox(width: 4),
                                                if (post.likesCount > 0)
                                                  Text('${post.likesCount}',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall?.copyWith(
                                                            color: Theme.of(context).colorScheme.secondary,
                                                          ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        // コメント
                                        InkWell(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    CommentPage(post: post),
                                              ),
                                            );
                                          },
                                          borderRadius: BorderRadius.circular(20),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                    Icons.chat_bubble_outline,
                                                    size: 20,
                                                    color: Colors.grey),
                                                const SizedBox(width: 4),
                                                if (post.commentsCount > 0)
                                                  Text('${post.commentsCount}',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall?.copyWith(
                                                            color: Theme.of(context).colorScheme.secondary,
                                                          ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        post.isImportant
                                            ? Padding(
                                                padding: const EdgeInsets.symmetric(
                                                      horizontal: 12, vertical: 8),
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.remove_red_eye_outlined, size: 20, color: Colors.grey),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${post.readCount}',
                                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        color: Theme.of(context).colorScheme.secondary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : const SizedBox.shrink(),
                                      ],
                                    ),

                                    // ----- 確認ボタン -----
                                    AnimatedSize(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                      child: showConfirmButton
                                          ? Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 5),
                                              child: SizedBox(
                                                width: 120,
                                                child: ElevatedButton(
                                                  onPressed: () async {
                                                    final dio =
                                                        ref.read(dioProvider);
                                                    final updated = await markAsRead(
                                                        dio, post.id);
                                                    ref
                                                        .read(postListProvider
                                                            .notifier)
                                                        .updatePost(updated);
                                                  },
                                                  style: ElevatedButton
                                                      .styleFrom(
                                                    padding: const EdgeInsets
                                                            .symmetric(vertical: 5),
                                                    backgroundColor:
                                                        Theme.of(context)
                                                            .scaffoldBackgroundColor,
                                                    elevation: 0,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              50),
                                                      side: BorderSide(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .secondary,
                                                        width: 1,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Text('確認しました',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium),
                                                ),
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // ===== 右下投稿ボタン =====
            Positioned(
              bottom: 15,
              right: 15,
              child: PostButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/post/create');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


