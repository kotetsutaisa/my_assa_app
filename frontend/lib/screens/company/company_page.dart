import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/full_user_model.dart';
import 'package:frontend/models/member_entry_model.dart';
import 'package:frontend/providers/company_member_provider.dart';
import 'package:frontend/providers/current_page_provider.dart';
import 'package:frontend/screens/profile/profile_tab_page.dart';
import 'package:frontend/utils/constants.dart';
import 'package:frontend/widgets/sub_header.dart';

class CompanyPage extends ConsumerStatefulWidget {
  const CompanyPage({super.key});

  @override
  ConsumerState<CompanyPage> createState() => _CompanyPage();
}

class _CompanyPage extends ConsumerState<CompanyPage> {

  String resolveImageUrl(String path) {
    if (path.startsWith('http')) return path;
    final base = apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    return '$base$path';
  }

  @override
  Widget build(BuildContext context) {
    final memberAsync = ref.watch(companyMemberListProvider);

    return Scaffold(
      body: memberAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Text('取得に失敗しました\n$e', textAlign: TextAlign.center),
        ),
        data: (entries) => RefreshIndicator(
          onRefresh: () => ref
              .read(companyMemberListProvider.notifier)
              .reload(),
          
          child: Column(
            children: [
              const SubHeader(title: '会社メンバー'),

              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  itemBuilder: (context, i) => _buildRow(entries[i]),
                  separatorBuilder: (_, __) => Divider(height: 0, color: Theme.of(context).colorScheme.outline),
                  itemCount: entries.length,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // メンバー or チーム行を描画
  Widget _buildRow(MemberEntry entry) {
    if (entry is SingleUserEntry) {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        leading: entry.user.iconUrl != null
          ? CircleAvatar(
              radius: 20,
              backgroundImage: CachedNetworkImageProvider(
                resolveImageUrl(entry.user.iconUrl!),
              ),
              backgroundColor: Colors.grey[200],
            )
          : CircleAvatar(
              radius: 20,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
        title: Text(entry.user.username),
        subtitle: Text(_getRoleLabel(entry.type, entry.user.role)),
        onTap: () => _goToProfile(context, entry.user),
      );
    } else if (entry is TeamEntry) {
      final teamName = entry.teamName;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...entry.members.map((m) {
            final imageUrl = m.user.iconUrl == null
              ? null
              : resolveImageUrl(m.user.iconUrl!);
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              leading: imageUrl != null
                  ? CircleAvatar(
                      radius: 22,
                      backgroundImage: CachedNetworkImageProvider(imageUrl),
                      backgroundColor: Colors.grey[200],
                    )
                  : CircleAvatar(
                      radius: 22,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
              title: Text(m.user.username),
              subtitle: Text(_getTeamMemberLabel(m.role, teamName)),
              onTap: () => _goToProfile(context, m.user),
            );
          }),
          Divider(height: 0, color: Theme.of(context).colorScheme.outline),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }


  String _getRoleLabel(String type, String role) {
    switch (type) {
      case 'admin':
        return '管理者';
      case 'no_team_manager':
        return 'マネージャー';
      case 'no_team_member':
        return '(未所属)';
      default:
        return role;
    }
  }


  String _getTeamMemberLabel(String role, String teamName) {
    switch (role) {
      case 'leader':
        return '($teamName) リーダー';
      case 'member':
        return '($teamName) メンバー';
      default:
        return role;
    }
  }

  void _goToProfile(BuildContext context, FullUserModel user) {
    ref.read(currentPageProvider.notifier).state =
      ProfileTabPage(userId: user.id);
    }
}
