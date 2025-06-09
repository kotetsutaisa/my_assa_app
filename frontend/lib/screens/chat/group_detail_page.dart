import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/api/conversation_api.dart';
import 'package:frontend/api/invitation_api.dart';
import 'package:frontend/models/convInvi_model.dart';
import 'package:frontend/models/conversation_model.dart';
import 'package:frontend/models/simple_user_model.dart';
import 'package:frontend/providers/conversation_list_provider.dart';
import 'package:frontend/providers/current_page_provider.dart';
import 'package:frontend/providers/dio_provider.dart';
import 'package:frontend/providers/selected_user_provider.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:frontend/screens/chat/message_page.dart';
import 'package:frontend/utils/constants.dart';
import 'package:image_picker/image_picker.dart';

class GroupDetailPage extends ConsumerStatefulWidget {

  const GroupDetailPage({super.key});

  @override
  ConsumerState<GroupDetailPage> createState() =>
      _GroupDetailPage();
}

class _GroupDetailPage extends ConsumerState<GroupDetailPage> {

  File? _selectedImage; // ← 選ばれた画像を保持
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _titleController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    // ウィジェットが表示された後にフォーカスを与える
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  String resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final base = apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    return '$base$path';
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> handleCreateConversation(
    WidgetRef ref, BuildContext context, String title, File? iconFile, List<int> partnerIds) async {
    final dio = ref.read(dioProvider);

    try {
       ConversationModel conversation = await createConversation(
        dio: dio,
        isGroup: true,
        title: title,
        iconFile: iconFile,
      );

      final ConvInviModel convInvi = ConvInviModel(
        conversation: conversation,
        isInvited: false,
        invitedBy: null,
      );

      await createInvite(
        dio: dio,
        conversationId: conversation.id,
        partnerIds: partnerIds,
      );

      ref.read(conversationListProvider.notifier).addConversation(convInvi);

      Navigator.popUntil(context, (route) => route.isFirst);

      ref.read(currentPageProvider.notifier).state = MessagePage(conversation: conversation);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('会話の作成に失敗しました: $e')),
      );
    }
  }

  Future<List<int>> partnerIdList(List<SimpleUserModel> selectedUsers) async {
    final List<int> partnerIds = [];

    for (final user in selectedUsers) {
      partnerIds.add(user.id);
    }

    return partnerIds;
  }

  @override
  Widget build(BuildContext context) {
    final selectedUsers = ref.watch(selectedUsersProvider);
    final my_user = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('グループプロフィール設定'),
        actions: [
          TextButton(
            onPressed: () async {
              final partnerIds = await partnerIdList(selectedUsers);
              await handleCreateConversation(
                ref,
                context,
                _titleController.text.trim(),
                _selectedImage,
                partnerIds
              );
            },
            child: Text(
              '作成',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),

      body: GestureDetector(
        behavior: HitTestBehavior.translucent, // ← 透明部分も検知
        onTap: () => FocusScope.of(context).unfocus(), // ← フォーカス解除
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: _selectedImage != null
                          ?  CircleAvatar(
                              radius: 40,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              backgroundImage: FileImage(_selectedImage!),
                            )
                          : CircleAvatar(
                              radius: 40,
                              backgroundColor: Theme.of(context).primaryColor,
                              child: const Icon(Icons.person, color: Colors.white, size: 40),
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

                  SizedBox(width: 12),

                  Expanded(
                    child: TextField(
                      controller: _titleController,
                      focusNode: _titleFocusNode,
                      style: Theme.of(context).textTheme.titleLarge,
                      decoration: InputDecoration(
                        hintText: 'グループ名を入力',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 50),

              Text(
                'メンバー${(selectedUsers.length+1).toString()}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),

              SizedBox(height: 30),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // ← 前の画面に戻る
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 48, // radius * 2
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline, // 枠の色
                              width: 1.0, // 枠の太さ
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.add,
                              color: Theme.of(context).primaryColor, // お好みで色を指定
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 48, // 固定幅にするとテキスト幅が整ってズレにくい
                          child: Text(
                            '追加',
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  Column(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: my_user?.iconimg != null
                            ? CachedNetworkImageProvider(resolveImageUrl(my_user!.iconimg))
                            : null,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: my_user?.iconimg == null
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 48, // 固定幅にするとテキスト幅が整ってズレにくい
                        child: Text(
                          my_user?.username ?? '',
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: selectedUsers.length,
                        itemBuilder: (context, index) {
                          final user = selectedUsers[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              children: [
                                SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundImage: user.iconimg != null
                                            ? CachedNetworkImageProvider(resolveImageUrl(user.iconimg))
                                            : null,
                                        backgroundColor: Theme.of(context).primaryColor,
                                        child: user.iconimg == null
                                            ? const Icon(Icons.person, color: Colors.white)
                                            : null,
                                      ),
                                      Positioned(
                                        top: -4,
                                        right: -4,
                                        child: GestureDetector(
                                          onTap: () {
                                            ref.read(selectedUsersProvider.notifier).removeUser(user);
                                          },
                                          child: Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1),
                                            ),
                                            child: Icon(
                                              Icons.close,
                                              color: Theme.of(context).colorScheme.primary,
                                              size: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  user.username,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}