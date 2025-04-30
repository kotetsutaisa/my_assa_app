import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/api/date_api.dart';
import 'package:frontend/widgets/post_button.dart';
import 'package:frontend/widgets/sub_header.dart';
import '../api/post_api.dart';
import '../models/post_model.dart';

class TimelineTabPage extends ConsumerStatefulWidget {
  const TimelineTabPage({super.key});

  @override
  ConsumerState<TimelineTabPage> createState() => _TimelineTabPageState();
}

class _TimelineTabPageState extends ConsumerState<TimelineTabPage> {
  late Future<List<PostModel>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = fetchPosts(); // 起動時に投稿データを取得
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<PostModel>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // 通信中はローディング表示
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // エラー発生時
            return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // 投稿がない場合
            return const Center(child: Text('投稿がありません'));
          } else {
            // 投稿がある場合
            final posts = snapshot.data!;



            return  Stack(
              children: [
                Column(
                  children: [
                    // サブヘッダー
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
                              color: Theme.of(context).scaffoldBackgroundColor,
                              border: Border(
                                bottom: BorderSide(
                                  color: Theme.of(context). colorScheme.outline,
                                  width: 1,
                                ),
                              ),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 投稿者のアイコン
                                if (post.userIconImg != null)
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: CircleAvatar(
                                      radius: 25,
                                      backgroundImage: NetworkImage(
                                        'http://10.0.2.2:8000${post.userIconImg}',
                                      ),
                                      backgroundColor: Colors.grey[200],
                                    ),
                                  )
                                else
                                  CircleAvatar(
                                    radius: 15,
                                    backgroundColor: Theme.of(context).primaryColor,
                                    child: Icon(Icons.person, color: Colors.white),
                                  ),
                                const SizedBox(width: 10),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // ユーザー名とアカウントID
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              
                                              
                                              // ユーザー名
                                              Text(
                                                post.userUsername,
                                                style: Theme.of(context).textTheme.bodyLarge,
                                              ),
                                                          
                                              // アカウントID
                                              const SizedBox(width: 10),
                                              Text(
                                                post.userAccountId,
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: Theme.of(context).colorScheme.secondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                  
                                          // 投稿日時
                                          Text(
                                            formatPostDate(post.createdAt),
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      
                                      // 投稿本文
                                      Text(
                                        post.content,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
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

                // 右下固定の投稿ボタン
                Positioned(
                  bottom: 15,
                  right: 15,
                  child: PostButton(
                    onPressed: () {
                      // TODO: 投稿作成画面に飛ばす処理をここに書く
                      print('投稿ボタン押した');
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
