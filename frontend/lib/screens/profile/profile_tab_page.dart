import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/my_post_list_provider.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:frontend/screens/profile/edit_profile_page.dart';
import 'package:frontend/utils/constants.dart';
import 'package:frontend/widgets/my_post_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';


class ProfileTabPage extends ConsumerStatefulWidget {
  const ProfileTabPage({super.key});

  @override
  ConsumerState<ProfileTabPage> createState() => _ProfileTabPage();
}

class _ProfileTabPage extends ConsumerState<ProfileTabPage> {

  String resolveImageUrl(String path) {
    if (path.startsWith('http')) return path;
    final base = apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    return '$base$path';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final myPostsAsync = ref.watch(myPostListProvider);


    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Center(
                          child: user?.iconimg != null
                              ? CircleAvatar(
                                  radius: 25,
                                  backgroundImage: CachedNetworkImageProvider(resolveImageUrl(user!.iconimg!)),
                                  backgroundColor: Colors.grey[200],
                                )
                              : CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Theme.of(context).primaryColor,
                                  child: const Icon(Icons.person, color: Colors.white, size: 30),
                                ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          user?.username ?? 'ゲスト',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          user?.accountId ?? '@sample',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          user?.email ?? '',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 15),
                        if (user?.bio != null && user!.bio!.isNotEmpty)
                          Text(
                            user.bio!,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                      ],
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => EditProfilePage()),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          side: BorderSide(color: Theme.of(context).colorScheme.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          foregroundColor: Theme.of(context).colorScheme.primary,
                        ),
                        child: const Text('編集', style: TextStyle(fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: Divider()),

            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                const TabBar(
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.blue,
                  tabs: [
                    Tab(text: 'タイムライン'),
                    Tab(text: '日報'),
                    Tab(text: 'スケジュール'),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              myPostsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('エラー: $e')),
                data: (posts) => MyPostList(posts: posts),
              ),
              const Center(child: Text('タブ2の内容')),
              const Center(child: Text('タブ3の内容')),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

