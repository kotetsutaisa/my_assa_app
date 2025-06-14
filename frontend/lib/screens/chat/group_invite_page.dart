import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/api/invitation_api.dart';
import 'package:frontend/models/candidate_user_model.dart';
import 'package:frontend/models/conversation_model.dart';
import 'package:frontend/providers/current_page_provider.dart';
import 'package:frontend/providers/dio_provider.dart';
import 'package:frontend/providers/invite_candidates_provider.dart';
import 'package:frontend/providers/message_provider.dart';
import 'package:frontend/screens/chat/message_page.dart';
import 'package:frontend/utils/image_helper.dart';

class GroupInvitePage extends ConsumerStatefulWidget {
  final ConversationModel conversation;

  const GroupInvitePage({Key? key, required this.conversation}) : super(key: key);

  @override
  ConsumerState<GroupInvitePage> createState() => _GroupInvitePage();
}

class _GroupInvitePage extends ConsumerState<GroupInvitePage> {
  List<CandidateUserModel> selectedUsers = [];
  bool isSubmitting = false;

  void toggleUser(CandidateUserModel user) {
    setState(() {
      if (selectedUsers.any((u) => u.id == user.id)) {
        selectedUsers.removeWhere((u) => u.id == user.id);
      } else {
        selectedUsers.add(user);
      }
    });
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
        actions: selectedUsers.isNotEmpty
            ? [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final dio = ref.read(dioProvider);
                          final partnerIds = selectedUsers.map((u) => u.id).toList();

                          setState(() {
                            isSubmitting = true;
                          });

                          try {
                            await createInvite(
                              dio: dio,
                              conversationId: widget.conversation.id,
                              partnerIds: partnerIds,
                            );

                            final notifier = ref.read(messageListProvider(widget.conversation.id).notifier);
                            await notifier.fetch();  // ← システムメッセージを取得

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('招待が完了しました')),
                              );

                              Navigator.popUntil(context, (route) => route.isFirst);
                              ref.read(currentPageProvider.notifier).state =
                                  MessagePage(conversation: widget.conversation);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('招待に失敗しました: $e')),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() {
                                isSubmitting = false;
                              });
                            }
                          }
                        },
                  child: Text(
                    '招待',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ]
            : null,
      ),
      body: candidatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('エラー: $err')),
        data: (users) => Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final isSelected = selectedUsers.any((u) => u.id == user.id);

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundImage: user.iconimg != null
                          ? CachedNetworkImageProvider(resolveImageUrl(user.iconimg))
                          : null,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: user.iconimg == null
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                    title: Text(user.username),
                    trailing: user.isInvited == true
                      ? Text(
                        '招待中',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      )

                      : Checkbox(
                          value: isSelected,
                          onChanged: (_) => toggleUser(user),
                        ),
                    onTap: () => toggleUser(user),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


