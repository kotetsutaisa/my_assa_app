import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/resource_model.dart';
import 'package:frontend/providers/selected_resource_date_provider.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:frontend/screens/track/create_resource_page.dart';
import 'package:frontend/screens/track/resource_form_page.dart';
import 'package:frontend/widgets/post_button.dart';
import 'package:frontend/widgets/schedule_widget/resource_schedule_widget.dart';

class ResourceDetailPage extends ConsumerWidget {
  final ResourceModel resource;

  const ResourceDetailPage({super.key, required this.resource});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return Scaffold(
      appBar: AppBar(
        title: Text(
          resource.name,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        actions: [
          _EditButton(resource: resource)
        ],
      ),
      body: ResourceScheduleWidget(resource: resource),
      floatingActionButton: PostButton(
        onPressed: () {
          final selectedResouceDate = ref.read(selectedResourceDateProvider);

          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CreateResourceSchedulePage(initialDate: selectedResouceDate, resource: resource)),
          );
        }
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}


class _EditButton extends ConsumerWidget {
  final ResourceModel resource;

  const _EditButton({super.key, required this.resource});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    // ❶ ログインしていない or 権限なし → ボタン非表示
    if (user == null || !user.canManageResources) {
      return const SizedBox.shrink();
    }

    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ResourceFormPage(initial: resource)),
        );
      },
      child: Text(
        '編集',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}