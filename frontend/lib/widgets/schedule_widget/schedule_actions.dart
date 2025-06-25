import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/models/schedule_model.dart';

/// 予定カードの「︙」を押したときに呼び出す共通ボトムシート。
///
/// [onEdit]   … 編集ボタン押下時に呼ばれるコールバック（省略可）  
/// [onDelete] … 削除 OK 押下後に呼ばれる `Future` コールバック（省略可）
Future<void> showScheduleActionSheet({
  required BuildContext context,
  required ScheduleModel schedule,
  VoidCallback? onEdit,
  Future<void> Function()? onDelete,
}) {
  return showModalBottomSheet(
    context: context,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ---- 編集 ----
          ListTile(
            leading: const Icon(Icons.edit),
            title  : const Text('編集'),
            onTap  : () {
              Navigator.pop(context);   // シートを閉じる
              if (onEdit != null) onEdit();
            },
          ),
          // ---- 削除 ----
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title  : const Text('削除', style: TextStyle(color: Colors.red)),
            onTap  : () async {
              Navigator.pop(context);   // まずシートを閉じる
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title  : const Text('削除しますか？'),
                  content: Text(
                    '${schedule.siteName}\n'
                    '${DateFormat('yyyy/MM/dd').format(schedule.startTime)}',
                  ),
                  actions: [
                    TextButton(
                      child: const Text('キャンセル'),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    TextButton(
                      child: const Text('削除', style: TextStyle(color: Colors.red)),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ],
                ),
              );

              if (ok == true && onDelete != null) {
                await onDelete();
              }
            },
          ),
        ],
      ),
    ),
  );
}

