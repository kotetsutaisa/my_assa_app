import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/simple_user_model.dart';
import 'package:frontend/providers/selected_user_provider.dart';
import 'package:frontend/utils/image_helper.dart';

class UserMultiSelectList extends ConsumerWidget{
  final List<SimpleUserModel> users;

  const UserMultiSelectList({super.key, required this.users});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    final selectedUsers = ref.watch(selectedUsersProvider);

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final isSelected = selectedUsers.contains(user);

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
          trailing: Checkbox(
            value: isSelected,
            onChanged: (_) => ref.read(selectedUsersProvider.notifier).toggleUser(user),
          ),
          onTap: () => ref.read(selectedUsersProvider.notifier).toggleUser(user),
        );
      },
    );
  }
}