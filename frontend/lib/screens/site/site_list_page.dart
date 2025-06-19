import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/site_provider.dart';
import 'package:frontend/screens/site/site_create_page.dart';
import 'package:frontend/screens/site/site_detail_page.dart';
import 'package:frontend/widgets/post_button.dart';
import 'package:frontend/widgets/sub_header.dart';

// TODO: 権限があるユーザーのみ削除、変種ボタンを表示する


class SiteListPage extends ConsumerStatefulWidget {
  const SiteListPage({super.key});

  @override
  ConsumerState<SiteListPage> createState() => _SiteListPage();
}

class _SiteListPage extends ConsumerState<SiteListPage> {

  @override
  Widget build(BuildContext context) {
    final sitesAsync = ref.watch(siteListProvider);
    
    return Scaffold(
      body: sitesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('エラー: $err')),
        data: (siteList) => Stack(
          children: [
            Column(
              children: [
                Center(
                  child: SubHeader(
                    title: '現場一覧',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    itemCount: siteList.length,
                    itemBuilder: (context, index) {
                      final site = siteList[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: site.isActive ? Colors.green : Theme.of(context).colorScheme.outline,
                                ),
                                borderRadius: BorderRadius.circular(20), // 丸みの半径
                                color: site.isActive ? Colors.green.withOpacity(0.1) : Colors.transparent,
                              ),
                              child: Text(
                                site.isActive ? '施工中' : '施工終了',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: site.isActive
                                          ? Colors.green
                                          : Theme.of(context).colorScheme.secondary,
                                    ),
                              ),
                            ),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  site.name,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                                    borderRadius: BorderRadius.circular(5), 
                                  ),
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // ← ここで調整
                                      minimumSize: Size.zero, // ← 高さを最小限にする
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap, // ← タップ領域も縮める
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => SiteDetailPage(site: site),
                                        ),
                                      );
                                    },
                                    child: Text('詳細'),
                                  ),
                                )
                              ],
                            ),

                            Text(
                              site.address ?? '住所未登録'
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SiteCreatePage(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}