import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/conversation_model.dart';
import 'package:frontend/screens/chat/group_invite_page.dart';
import 'package:frontend/screens/chat/group_list_page.dart';
import 'package:frontend/widgets/group_chat_settings_widget.dart';

class GroupSettingsPage extends ConsumerStatefulWidget {
  final ConversationModel conversation;

  const GroupSettingsPage({Key? key, required this.conversation}) : super(key: key);

  @override
  ConsumerState<GroupSettingsPage> createState() => _GroupSettingsPage();
}

class _GroupSettingsPage extends ConsumerState<GroupSettingsPage> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GroupChatSettingsWidget(
        username: widget.conversation.title ?? '不明なグループ',
        userIconUrl: widget.conversation.icon,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          const Text('メンバー', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
          ListTile(
            leading: Icon(Icons.group, color: Theme.of(context).colorScheme.primary,),
            title: Text(
              'メンバー',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupListPage(conversation: widget.conversation),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.person_add, color: Theme.of(context).colorScheme.primary,),
            title: Text(
              'メンバーを招待',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupInvitePage(conversation: widget.conversation),
                ),
              );
            },
          ),

          const SizedBox(height: 20),
          const Text('その他', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text('グループを退会する', style: TextStyle(color: Colors.red)),
            onTap: () {
              // 退会処理
            },
          ),
        ],
      ),
    );
  }
}