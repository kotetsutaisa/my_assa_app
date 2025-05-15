import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:frontend/api/date_api.dart';
import 'package:frontend/screens/timeline/comment_page.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../models/post_model.dart';
import '../api/post_api.dart';
import '../providers/dio_provider.dart';
import '../providers/my_post_list_provider.dart';
import '../utils/constants.dart';

class MyPostList extends ConsumerWidget {
  final List<PostModel> posts;

  const MyPostList({super.key, required this.posts});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String resolveImageUrl(String path) {
      if (path.startsWith('http')) return path;
      final base = apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');
      return '$base$path';
    }

    return ListView.separated(
      itemCount: posts.length,
      separatorBuilder: (_, __) => const Divider(height: 0),
      itemBuilder: (context, i) {
        final post = posts[i];

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CommentPage(post: post)),
            );
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 左カラム：アイコンと「重要」ラベル
                Column(
                  children: [
                    post.userIconImg != null
                        ? CircleAvatar(
                            radius: 20,
                            backgroundImage:
                                CachedNetworkImageProvider(resolveImageUrl(post.userIconImg!)),
                            backgroundColor: Colors.grey[200],
                          )
                        : CircleAvatar(
                            radius: 20,
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                            child: const Icon(Icons.person, color: Colors.white),
                          ),
                    if (post.isImportant)
                      const Text('重要',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          )),
                  ],
                ),
                const SizedBox(width: 12),

                // --- 右カラム：本文など
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ユーザー情報行
                      Row(
                        children: [
                          Text(post.userUsername, style: Theme.of(context).textTheme.bodyLarge),
                          const SizedBox(width: 10),
                          Text(post.userAccountId,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.secondary,
                                  )),
                          const Spacer(),
                          Text(formatPostDate(post.createdAt),
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(post.content,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.normal,
                              )),
                      if (post.images.isNotEmpty) ...[
                        const SizedBox(height: 10),
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
                          itemBuilder: (context, index) {
                            final url = resolveImageUrl(post.images[index]);
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
                                  imageUrl: url,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const SizedBox.shrink(),
                                  errorWidget: (context, url, error) => const Icon(Icons.error),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
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
                              ref.read(myPostListProvider.notifier).updatePost(safeUpdate);
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 8, 20, 8),
                              child: Row(
                                children: [
                                  Icon(
                                    post.isLiked ? Icons.favorite : Icons.favorite_border,
                                    size: 20,
                                    color: post.isLiked
                                        ? const Color.fromARGB(255, 255, 109, 157)
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  if (post.likesCount > 0)
                                    Text('${post.likesCount}',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Theme.of(context).colorScheme.secondary,
                                            )),
                                ],
                              ),
                            ),
                          ),
                          // コメント
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => CommentPage(post: post)),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  if (post.commentsCount > 0)
                                    Text('${post.commentsCount}',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Theme.of(context).colorScheme.secondary,
                                            )),
                                ],
                              ),
                            ),
                          ),
                          if (post.isImportant)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.remove_red_eye_outlined, size: 20, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text('${post.readCount}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).colorScheme.secondary,
                                          )),
                                ],
                              ),
                            ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

