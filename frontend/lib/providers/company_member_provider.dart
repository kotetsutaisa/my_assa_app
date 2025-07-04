import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/api/company_member_api.dart';
import 'package:frontend/models/member_entry_model.dart';
import 'package:frontend/providers/dio_provider.dart';

class CompanyMemberListNotifier
    extends AsyncNotifier<List<MemberEntry>> {

  @override
  Future<List<MemberEntry>> build() async {
    final dio = ref.read(dioProvider);
    return fetchCompanyMembers(dio);
  }

  /// 例）リストを最新化するだけ
  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final dio = ref.read(dioProvider);
      return fetchCompanyMembers(dio);
    });
  }

  // ここに add / remove / move-team などのメソッドを追加していける
}

final companyMemberListProvider =
    AsyncNotifierProvider<CompanyMemberListNotifier, List<MemberEntry>>(
        () => CompanyMemberListNotifier());
