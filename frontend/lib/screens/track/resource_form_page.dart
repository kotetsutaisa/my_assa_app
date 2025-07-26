// lib/screens/track/resource_form_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/models/resource_model.dart';
import 'package:frontend/providers/resource_provider.dart'; // ResourceListNotifier / resourceListProvider

class ResourceFormPage extends ConsumerStatefulWidget {
  /// ★ 追加: initial が null なら「新規」、non-null なら「編集」
  final ResourceModel? initial;

  const ResourceFormPage({super.key, this.initial});

  @override
  ConsumerState<ResourceFormPage> createState() => _ResourceFormPageState();
}

class _ResourceFormPageState extends ConsumerState<ResourceFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl        = TextEditingController();
  final _makerCtrl       = TextEditingController();
  final _plateNoCtrl     = TextEditingController();
  final _capacityCtrl    = TextEditingController(); // 数値
  final _descriptionCtrl = TextEditingController();

  bool _isActive = true;
  bool _saving   = false;

  // ★ 追加: 編集時に元データを保持しておく（差分パッチを作りたい場合など）
  ResourceModel? get _original => widget.initial;
  bool get _isEdit => _original != null;

  @override
  void initState() {
    super.initState();

    // ★ 追加: 編集モードなら初期値をフォームに流し込む
    if (_isEdit) {
      final r = _original!;
      _nameCtrl.text        = r.name;
      _makerCtrl.text       = r.maker ?? '';
      _plateNoCtrl.text     = r.plateNo ?? '';
      _capacityCtrl.text    = r.capacityKg?.toString() ?? '';
      _descriptionCtrl.text = r.description ?? '';
      _isActive             = r.isActive;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _makerCtrl.dispose();
    _plateNoCtrl.dispose();
    _capacityCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  // ---------------- 保存処理 ----------------
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final capacity = _capacityCtrl.text.trim().isEmpty
          ? null
          : int.tryParse(_capacityCtrl.text.trim());

      if (_isEdit) {
        // -------- 編集 --------
        final id = _original!.id;

        // ★ PATCH ペイロード（必要十分なフィールドを送る）
        final patch = <String, dynamic>{
          'name'        : _nameCtrl.text.trim(),
          'maker'       : _makerCtrl.text.trim().isEmpty ? null : _makerCtrl.text.trim(),
          'plate_no'    : _plateNoCtrl.text.trim().isEmpty ? null : _plateNoCtrl.text.trim(),
          'capacityKg'  : capacity,
          'description' : _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
          'is_active'   : _isActive,
          // 'category': null, // MVPでは未使用なので送らない/必要ならここで
        };

        await ref.read(resourceListProvider.notifier).update(
          id: id,
          patch: patch,
        );

      } else {
        // -------- 新規作成 --------
        final newResource = ResourceModel(
          id         : '',                // 作成時は不要（toJsonで includeId=false）
          name       : _nameCtrl.text.trim(),
          maker      : _makerCtrl.text.trim().isEmpty ? null : _makerCtrl.text.trim(),
          plateNo    : _plateNoCtrl.text.trim().isEmpty ? null : _plateNoCtrl.text.trim(),
          capacityKg : capacity,
          description: _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
          isActive   : _isActive,
          category   : null,              // ★ カテゴリ機能は MVP で未使用
          categoryId : null,
          createdById: null,
          createdAt  : DateTime.now(),    // ダミー。API返却で正値に置き換わる
          updatedAt  : DateTime.now(),
        );

        await ref.read(resourceListProvider.notifier).add(newResource);
      }

      if (mounted) Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('${_isEdit ? '更新' : '登録'}に失敗しました: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('削除しますか？'),
        content: const Text('この車両を完全に削除します。よろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除する'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _saving = true);
    try {
      await ref.read(resourceListProvider.notifier)
          .remove(widget.initial!.id);   // ← initial は編集時のみ非 null
      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('削除に失敗しました: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final titleText = _isEdit ? '車両を編集' : '車両を登録';  // ★ タイトル出し分け
    final actionText = _isEdit ? '更新' : '保存';            // ★ ボタン文言出し分け

    return Scaffold(
      appBar: AppBar(
        title : Text(titleText, style: Theme.of(context).textTheme.titleLarge),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color : Theme.of(context).colorScheme.outline,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 18, width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(actionText, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _InfoCard(children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: '車両名',
                    hintText: '例: 4tユニック',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return '名称は必須です';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _makerCtrl,
                  decoration: const InputDecoration(
                    labelText: 'メーカー',
                    hintText: '(例) トヨタ'
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _plateNoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ナンバー',
                    hintText: '(例）福岡 100 あ 1234',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _capacityCtrl,
                  decoration: const InputDecoration(
                    labelText: '積載量(kg)',
                    hintText: '(例）4000',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionCtrl,
                  decoration: const InputDecoration(
                    labelText: '備考',
                  ),
                  maxLines: 3,
                ),
                
                if (_isEdit) ...[
                  const SizedBox(height: 32),
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('この車両を削除する'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      alignment: Alignment.centerLeft,
                    ),
                    onPressed: _saving ? null : _confirmDelete,
                  ),
                ],

                const SizedBox(height: 8),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

/* ─── シンプルカード ─── */
class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(children: children),
      );
}


