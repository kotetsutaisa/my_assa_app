import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/site_model.dart';
import 'package:frontend/providers/site_provider.dart';
import 'package:frontend/screens/site/site_create_page.dart';

Future<void> showSiteSelectorModal({
  required BuildContext context,
  required void Function(SiteModel) onSelected,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return Consumer(
        builder: (context, ref, _) {
          final siteListAsync = ref.watch(siteListProvider);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: siteListAsync.when(
              data: (sites) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('現場を追加'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SiteCreatePage(),
                        ),
                      );
                    },
                  ),
                  const Divider(),

                  ...sites.map((site) => ListTile(
                        title: Text(site.name),
                        onTap: () {
                          Navigator.of(context).pop();
                          onSelected(site);
                        },
                      )),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('読み込み失敗: $e')),
            ),
          );
        },
      );
    },
  );
}


