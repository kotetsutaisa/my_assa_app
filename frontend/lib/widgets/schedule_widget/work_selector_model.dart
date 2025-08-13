import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/work_category_model.dart';
import 'package:frontend/providers/work_category_provider.dart';

Future<void> showWorkSelectorModal({
  required BuildContext context,
  required void Function(WorkCategoryModel) onSelected,
  VoidCallback? onCleared,                 // ← 追加：選択解除時のコールバック（任意）
  bool showClearOption = false,            // ← 追加：解除項目を表示するか（既定: 非表示）
  String clearLabel = '選択を解除',           // ← 追加：表示文言（任意）
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
          final workCategoryAsync = ref.watch(workCategoryListProvider);
          final TextEditingController controller = TextEditingController();
          final focusNode = FocusNode();

          return StatefulBuilder(
            builder: (context, setState) {
              controller.addListener(() {
                setState(() {}); // 入力に応じてリビルド
              });

              return Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: workCategoryAsync.when(
                  data: (works) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      

                      // 新規追加入力
                      TextField(
                        controller: controller,
                        keyboardType: TextInputType.text,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.add),
                          hintText: '新しい作業内容を入力',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          suffixIcon: controller.text.trim().isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.send, color: Colors.blue),
                                  onPressed: () async {
                                    final name = controller.text.trim();
                                    if (name.isNotEmpty) {
                                      await ref.read(workCategoryListProvider.notifier)
                                          .addWorkCategory(name);
                                      final categories = ref.read(workCategoryListProvider).value ?? [];
                                      final newCategory = categories.firstWhere(
                                        (c) => c.name == name,
                                        orElse: () => throw Exception('追加した作業内容が見つかりませんでした'),
                                      );
                                      Navigator.of(context).pop();
                                      onSelected(newCategory);
                                    }
                                  },
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),

                      // 解除オプション（任意表示）
                      if (showClearOption) ...[
                        ListTile(
                          leading: const Icon(Icons.clear),
                          title: Text(clearLabel),
                          onTap: () {
                            Navigator.of(context).pop();
                            onCleared?.call();
                          },
                        ),
                        const Divider(),
                      ],

                      // 既存一覧
                      ...works.map((work) => ListTile(
                            title: Text(work.name),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Color.fromARGB(255, 255, 115, 105),
                              ),
                              onPressed: () async {
                                final shouldDelete = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('削除確認'),
                                    content: Text('「${work.name}」を削除しますか？'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('キャンセル'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('削除'),
                                      ),
                                    ],
                                  ),
                                );
                                if ((shouldDelete ?? false) && work.id != null) {
                                  await ref.read(workCategoryListProvider.notifier).remove(work.id!);
                                } else if (work.id == null) {
                                  debugPrint('⚠️ idが null のため削除できません');
                                }
                              },
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                              onSelected(work);
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
    },
  );
}

