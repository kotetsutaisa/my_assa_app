import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/models/member_model.dart';
import 'package:frontend/providers/team_member_provider.dart';
import 'package:frontend/widgets/common/avatar.dart';

/// 複数メンバー選択モーダル（戻り値: List<MemberModel>?）
/// UI: 左=アイコン / 中=ユーザー名 / 右=チェックボックス
Future<List<MemberModel>?> showMultiMemberSelectorModal({
  required BuildContext context,
  List<String>? initialSelectedIds,
  String Function(String)? resolveUrl,
}) {
  return showModalBottomSheet<List<MemberModel>?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return Consumer(
        builder: (ctx, ref, _) {
          final membersAsync = ref.watch(teamMemberListProvider);

          // モーダル内の一時選択状態（IDで管理）
          final tempSelected = <String>{...(initialSelectedIds ?? const [])};

          return StatefulBuilder(
            builder: (ctx, setStateModal) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: membersAsync.when(
                  loading: () => const SizedBox(
                    height: 360,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, st) => SizedBox(
                    height: 360,
                    child: Center(child: Text('読み込み失敗: $e')),
                  ),
                  data: (members) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ハンドル
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          width: 40, height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Text('メンバーを選択', style: Theme.of(ctx).textTheme.titleMedium),
                        const Divider(),

                        SizedBox(
                          height: 360,
                          child: ListView.builder(
                            itemCount: members.length,
                            itemBuilder: (_, i) {
                              final m = members[i];
                              final checked = tempSelected.contains(m.id);

                              final avatar = buildAvatar(
                                context: ctx,
                                imageUrl: m.avatarUrl,
                                radius: 18,
                                resolveUrl: resolveUrl ?? (p) => p,
                              );

                              return CheckboxListTile(
                                controlAffinity: ListTileControlAffinity.trailing,
                                secondary: avatar,              // 左：アイコン
                                title: Text(m.name),            // 中：ユーザー名
                                value: checked,                 // 右：チェック
                                onChanged: (v) => setStateModal(() {
                                  if (v == true) {
                                    tempSelected.add(m.id);
                                  } else {
                                    tempSelected.remove(m.id);
                                  }
                                }),
                              );
                            },
                          ),
                        ),

                        const Divider(height: 1),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(ctx, null),
                                child: const Text('キャンセル'),
                              ),
                            ),
                            Expanded(
                              child: TextButton(
                                onPressed: () {
                                  final picked = members
                                      .where((m) => tempSelected.contains(m.id))
                                      .toList(growable: false);
                                  Navigator.pop(ctx, picked);
                                },
                                child: const Text('決定'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          );
        },
      );
    },
  );
}
