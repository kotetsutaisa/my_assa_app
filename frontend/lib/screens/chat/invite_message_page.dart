import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/convInvi_model.dart';
import 'package:frontend/providers/conversation_list_provider.dart';
import 'package:frontend/providers/current_page_provider.dart';
import 'package:frontend/screens/chat/message_page.dart';
import 'package:frontend/widgets/chat_header.dart';

class InviteMessagePage extends ConsumerStatefulWidget {
  final ConvInviModel invite;

  const InviteMessagePage({Key? key, required this.invite}) : super(key: key);

  @override
  ConsumerState<InviteMessagePage> createState() => _InviteMessagePage();
}

class _InviteMessagePage extends ConsumerState<InviteMessagePage> {

  @override
  Widget build(BuildContext context) {
    final partnerUser = widget.invite.conversation!.partner;

    return Scaffold(
      appBar: ChatHeader(
        username: widget.invite.conversation!.isGroup
            ? widget.invite.conversation!.title ?? 'グループ'
            : partnerUser?.username ?? '不明なユーザー',
        userIconUrl: widget.invite.conversation!.isGroup
            ? widget.invite.conversation!.icon
            : partnerUser?.iconimg,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  children: [
                    SizedBox(height: 32),
                    Text(
                      '${widget.invite.invitedBy?.username ?? '不明なユーザー'}さんから招待が届いています',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    SizedBox(height: 36),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly, // または spaceBetween / center
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async{
                              final conversationNotifier = ref.read(conversationListProvider.notifier);
                              await conversationNotifier.participateInGroup(widget.invite.conversation!.id);
                              ref.read(currentPageProvider.notifier).state =
                                  MessagePage(conversation: widget.invite.conversation!);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              side: BorderSide(color: Theme.of(context).colorScheme.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              foregroundColor: Theme.of(context).colorScheme.primary,
                            ),
                            child: const Text('参加', style: TextStyle(fontSize: 14)),
                          ),
                        ),
                        const SizedBox(width: 32),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              ref.read(currentPageProvider.notifier).state =
                                  MessagePage(conversation: widget.invite.conversation!);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              side: BorderSide(color: Theme.of(context).colorScheme.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              foregroundColor: Theme.of(context).colorScheme.primary,
                            ),
                            child: const Text('辞退', style: TextStyle(fontSize: 14)),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}