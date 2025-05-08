import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/api/date_api.dart';
import 'package:frontend/providers/post_list_provider.dart';
import 'package:frontend/widgets/post_button.dart';
import 'package:frontend/widgets/sub_header.dart';
class TimelineTabPage extends ConsumerWidget {
  const TimelineTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postListProvider);

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
                      return Container(
                        decoration: BoxDecoration(
                          // color: post.isImportant
                          //   ? const Color.fromARGB(255, 255, 233, 233)
                          //   : null,
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                post.userIconImg != null
                                  ? CircleAvatar(
                                      radius: 15,
                                      backgroundImage: NetworkImage('http://10.0.2.2:8000${post.userIconImg}'),
                                      backgroundColor: Colors.grey[200],
                                    )
                                  : CircleAvatar(
                                      radius: 15,
                                      backgroundColor: Theme.of(context).primaryColor,
                                      child: Icon(Icons.person, color: Colors.white),
                                    ),

                                Text(
                                  post.isImportant ? '重要' : '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(post.userUsername, style: Theme.of(context).textTheme.bodyLarge),
                                          const SizedBox(width: 10),
                                          Text(post.userAccountId, style: Theme.of(context).textTheme.bodySmall),
                                          const SizedBox(width: 10),
                                        ],
                                      ),
                                      Text(
                                        formatPostDate(post.createdAt),
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(post.content, style: Theme.of(context).textTheme.bodyMedium),
                                  
                                  post.isImportant
                                      ? Padding(
                                        padding: const EdgeInsets.only(top: 20),
                                        child: SizedBox(
                                          width: 120,
                                          child: ElevatedButton(
                                              onPressed: () {},
                                              style: ElevatedButton.styleFrom(
                                                padding: EdgeInsets.symmetric(vertical: 5),
                                                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                                                elevation: 0, 
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(50),
                                                  side: BorderSide(
                                                    color: Theme.of(context).colorScheme.secondary, // 好きな色に
                                                    width: 1, // 太さを調整可能
                                                  ),
                                        
                                                ),
                                              ),
                                              child: Text(
                                                '確認しました',
                                                style: Theme.of(context).textTheme.bodyMedium,
                                              ),
                                            ),
                                        ),
                                      )
                                      : SizedBox.shrink(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

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

