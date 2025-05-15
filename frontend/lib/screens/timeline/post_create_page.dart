import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/utils/constants.dart';
import 'package:image_picker/image_picker.dart';

import '../../api/post_api.dart';
import '../../providers/dio_provider.dart';
import '../../providers/post_list_provider.dart';
import '../../providers/user_provider.dart';

class PostCreatePage extends ConsumerStatefulWidget {
  const PostCreatePage({super.key});

  @override
  ConsumerState<PostCreatePage> createState() => _PostCreatePageState();
}

class _PostCreatePageState extends ConsumerState<PostCreatePage> {
  final _contentController = TextEditingController();
  final _focusNode = FocusNode();

  final List<XFile> _imageFiles = [];

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
        isImportant: _isImportant,
        imageFiles: _imageFiles,
      );

      // 🔽 投稿後、画像付きの最新投稿を取得して Provider に追加
      final posts = await fetchPosts(dio);
      final latestPost = posts.first;
      ref.read(postListProvider.notifier).addPost(latestPost);

      if (mounted) Navigator.of(context).pop();
    } catch (e, st) {
      debugPrintStack(stackTrace: st, label: e.toString());
      _showError('投稿に失敗しました。もう一度お試しください。');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String resolveImageUrl(String path) {
    if (path.startsWith('http')) return path;
    final base = apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    return '$base$path';
  }

    /* ───────── 画像選択 (4 枚まで追加) ───────── */
  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final remain = 4 - _imageFiles.length;
    if (remain <= 0) return;

    final picked = await picker.pickMultiImage(imageQuality: 85);
    if (!mounted) return;

    if (picked.isNotEmpty) {
      setState(() {
        _imageFiles.addAll(
          picked.take(remain), // 上限 4 枚を厳守
        );
      });
    }

    // picker から戻った後にフォーカスを復帰
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) _focusNode.requestFocus();
    });
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
                            backgroundImage: CachedNetworkImageProvider(resolveImageUrl(user!.iconimg!)),
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
                  
                  /* ★ プレビュー：Wrap で複数表示 */
                  if (_imageFiles.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_imageFiles.length, (i) {
                        final file = _imageFiles[i];
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(file.path),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: InkWell(
                                onTap: () =>
                                    setState(() => _imageFiles.removeAt(i)),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  child: const Icon(Icons.close,
                                      size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),

                      
                  const Spacer(),
                ],
              ),
            ),

            // ====== フッター操作行 ======
            if (isKeyboardOpen)
              Positioned(
                bottom: bottomInset,
                left: 0,
                right: 0,
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.image),
                        label: Text(
                          _imageFiles.isEmpty
                            ? '画像を選択'
                            : '追加 (${_imageFiles.length}/4)',
                        ),
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

