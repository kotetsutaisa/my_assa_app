import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/conversation_model.dart';
import 'package:frontend/providers/invite_candidates_provider.dart';
import 'package:frontend/utils/constants.dart';

class GroupInvitePage extends ConsumerStatefulWidget {
  final ConversationModel conversation;

  const GroupInvitePage({Key? key, required this.conversation}) : super(key: key);

  @override
  ConsumerState<GroupInvitePage> createState() => _GroupInvitePage();
}

class _GroupInvitePage extends ConsumerState<GroupInvitePage> {

  String resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final base = apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    return '$base$path';
  }

  @override
  Widget build(BuildContext context) {
    final candidatesAsync = ref.watch(inviteCandidatesUserProvider(widget.conversation.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'メンバーを招待',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Theme.of(context).colorScheme.outline,
            height: 1,
          ),
        ),
      ),

      body: candidatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('エラー: $err')),
        data:(users) => ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: ListTile(
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