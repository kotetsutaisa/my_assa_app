import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/models/member_model.dart';
import 'package:frontend/providers/team_member_provider.dart';
import 'package:frontend/widgets/common/avatar.dart';

/// 単一メンバー選択モーダル（戻り値: MemberModel?）
/// - UI: 左=アイコン / 中=ユーザー名 / 右=ラジオボタン（完全再現）
/// - [initialSelectedId] には現在選択中のメンバーID（String?）を渡せます
/// - [resolveUrl] は相対URL→絶対URL化などしたい場合に渡してください（未指定なら素通し）
Future<MemberModel?> showSingleMemberSelectorModal({
  required BuildContext context,
  String? initialSelectedId,
  String Function(String)? resolveUrl,
}) {
  return showModalBottomSheet<MemberModel?>(
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

          // モーダル内の一時選択状態
          String? tempSelectedId = initialSelectedId;

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
                          width: 40,
                          height: 4,
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

                              final avatar = buildAvatar(
                                context: ctx,
                                imageUrl: m.avatarUrl,
                                radius: 18,
                                resolveUrl: resolveUrl ?? (p) => p,
                              );

                              return RadioListTile<String>(
                                // 並び: [secondary(アイコン)] [title(名前)] [ラジオ(右端)]
                                controlAffinity: ListTileControlAffinity.trailing,
                                secondary: avatar,
                                title: Text(m.name),
                                value: m.id,
                                groupValue: tempSelectedId,
                                onChanged: (v) => setStateModal(() {
                                  tempSelectedId = v;
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
                                  if (tempSelectedId == null) {
                                    Navigator.pop(ctx, null);
                                    return;
                                  }
                                  final picked = members.firstWhere(
                                    (m) => m.id == tempSelectedId,
                                    orElse: () => members.first, // 基本来ない想定
                                  );
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


