import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../api/post_api.dart';
import '../models/post_model.dart';
import '../providers/dio_provider.dart';
import '../providers/post_list_provider.dart';
import '../providers/user_provider.dart';

class PostCreatePage extends ConsumerStatefulWidget {
  const PostCreatePage({super.key});

  @override
  ConsumerState<PostCreatePage> createState() => _PostCreatePageState();
}

class _PostCreatePageState extends ConsumerState<PostCreatePage> {
  final _contentController = TextEditingController();
  final _focusNode = FocusNode();
  XFile? _imageFile;
  bool _isLoading = false;
  bool _isImportant = false; // 重要フラグ

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _contentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submitPost() async {
    final dio = ref.read(dioProvider);
    final user = ref.read(userProvider);
    final content = _contentController.text.trim();

    if (user == null) {
      _showError('ユーザー情報を取得できませんでした。ログインし直してください。');
      return;
    }
    if (content.isEmpty) {
      _showError('本文を入力してください。');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await createPost(
        dio: dio,
        content: content,
        isImportant: _isImportant,      // ★ 送信
        imageFile: _imageFile,
      );

      final newPost = PostModel(
        id: 0,
        content: content,
        image: null,
        createdAt: DateTime.now().toIso8601String(),
        userUsername: user.username,
        userAccountId: user.accountId,
        userIconImg: user.iconimg,
        isImportant: _isImportant,      // ★ クライアントキャッシュも反映
      );
      ref.read(postListProvider.notifier).addPost(newPost);
      if (mounted) Navigator.of(context).pop();
    } catch (e, st) {
      debugPrintStack(stackTrace: st, label: e.toString());
      _showError('投稿に失敗しました。もう一度お試しください。');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _imageFile = image);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          centerTitle: true,
          title: const Text('新規投稿'),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: ElevatedButton(
                onPressed: _isLoading || user == null ? null : _submitPost,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('投稿', style: TextStyle(fontSize: 14)),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (user?.iconimg != null)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CircleAvatar(
                            radius: 25,
                            backgroundImage: NetworkImage('http://10.0.2.2:8000${user!.iconimg}'),
                            backgroundColor: Colors.grey[200],
                          ),
                        )
                      else
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _contentController,
                          focusNode: _focusNode,
                          minLines: 10,
                          maxLines: 10,
                          decoration: const InputDecoration(
                            hintText: '本文を入力したください',
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_imageFile != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(_imageFile!.path), height: 150),
                    ),
                  const Spacer(),
                ],
              ),
            ),
            if (isKeyboardOpen)
              Positioned(
                bottom: bottomInset,
                left: 0,
                right: 0,
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image),
                        label: const Text('画像を選択'),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() => _isImportant = !_isImportant),
                        icon: const Icon(Icons.priority_high),
                        label: const Text('重要な投稿'),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          backgroundColor: _isImportant
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.secondary,
                          foregroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

