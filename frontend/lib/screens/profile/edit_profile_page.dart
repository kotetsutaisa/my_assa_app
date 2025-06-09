import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/api/edit_profile_api.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:frontend/utils/constants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

// emailの変更はメール承認機能を実装してから

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _usernameController = TextEditingController();
  final _userIdController = TextEditingController();
  final _bioController = TextEditingController();

  late UserModel? user;

  File? _selectedImage; // ← 選ばれた画像を保持
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    user = ref.read(userProvider);
    if (user != null) {
      _usernameController.text = user!.username;
      _userIdController.text = user!.accountId;
      _bioController.text = user!.bio ?? '';
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  String resolveImageUrl(String path) {
    if (path.startsWith('http')) return path;
    final base = apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    return '$base$path';
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('プロフィール編集'),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                debugPrint('✅ updateProfile 実行開始');
                debugPrint('username: ${_usernameController.text.trim()}');
                debugPrint('accountId: ${_userIdController.text.trim()}');
                debugPrint('bio: ${_bioController.text.trim()}');
                debugPrint('iconImage: ${_selectedImage?.path ?? "なし"}');

                final updatedUser = await updateProfile(
                  ref: ref,
                  username: _usernameController.text.trim(),
                  accountId: _userIdController.text.trim(),
                  bio: _bioController.text.trim(),
                  iconImage: _selectedImage,
                );

                debugPrint('✅ updateProfile 成功: ${updatedUser.toJson()}');

                ref.read(userProvider.notifier).setUser(updatedUser);

                if (mounted) Navigator.pop(context);
              } catch (e, stack) {

                debugPrint('❌ updateProfile 失敗: $e');
                debugPrint('🔍 StackTrace: $stack');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(
              '保存',
              style: Theme.of(context).textTheme.bodyLarge,
              ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : (user?.iconimg != null
                              ? CachedNetworkImageProvider(
                                resolveImageUrl(user!.iconimg!)
                              )
                              : null) as ImageProvider?,
                      child: (user?.iconimg == null && _selectedImage == null)
                          ? const Icon(Icons.person, color: Colors.white, size: 40)
                          : null,
                    ),
                  ),

                  // プラスボタン
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(Icons.add, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),


            SizedBox(height: 30),

            Row(
              children: [
                const Text('名前', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: 'ユーザー名を入力',
                    ),
                  ),
                ),
              ],
            ),

            const Divider(),

            Row(
              children: [
                const Text('ID', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _userIdController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: 'アカウントIDを入力',
                    ),
                  ),
                ),
              ],
            ),

            const Divider(),
            const SizedBox(height: 15),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('自己紹介', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _bioController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: '自己紹介を入力',
                      isDense: true, // ← 高さを詰める
                      contentPadding: EdgeInsets.only(top: 0), // ← 上に詰める（調整可能）
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }
}
