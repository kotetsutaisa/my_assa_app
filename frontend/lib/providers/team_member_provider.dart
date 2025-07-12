/* team_member_provider.dart */

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/member_entry_model.dart';
import 'package:frontend/models/member_model.dart';           // ★ 選択モーダル用の軽量モデル
import 'package:frontend/models/full_user_model.dart';
import 'package:frontend/providers/company_member_provider.dart';

extension on FullUserModel {
  MemberModel toMemberModel() =>
      MemberModel(id: id.toString(), name: username, avatarUrl: iconUrl);
}

/// CompanyMemberList → List<MemberModel> に変換
final teamMemberListProvider =
    FutureProvider<List<MemberModel>>((ref) async {
  // companyMemberListProvider 自体が AsyncNotifier
  final entries = await ref.watch(companyMemberListProvider.future);

  return entries.expand<MemberModel>((e) {
    switch (e) {
      case SingleUserEntry(user: final u): return [u.toMemberModel()];
      case TeamEntry(members: final m):    return m.map((t) => t.user.toMemberModel());
    }
  }).toList();
});
