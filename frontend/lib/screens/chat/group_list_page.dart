import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/conversation_model.dart';
import 'package:frontend/providers/participants_provider.dart';
import 'package:frontend/utils/constants.dart';

class GroupListPage extends ConsumerStatefulWidget {
  final ConversationModel conversation;

  const GroupListPage({Key? key, required this.conversation}) : super(key: key);

  @override
  ConsumerState<GroupListPage> createState() => _GroupListPage();
}

class _GroupListPage extends ConsumerState<GroupListPage> {

  String resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final base = apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    return '$base$path';
  }

  @override
  Widget build(BuildContext context) {
    final participantsAsync = ref.watch(participantsProvider(widget.conversation.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'メンバー',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey.shade300,
            height: 1,
          ),
        ),
      ),

      body: participantsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('エラー: $err')),
        data: (participants) => ListView.builder(
          itemCount: participants.length,
          itemBuilder: (context, index) {
            final user = participants[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: user.iconimg != null
                    ? CircleAvatar(backgroundImage: NetworkImage(resolveImageUrl(user.iconimg!)))
                    : CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                title: Text(user.username),
              ),
            );
          },
        ),
      ),
    );
  }
}