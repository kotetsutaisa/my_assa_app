import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import 'package:frontend/providers/dio_provider.dart';
import 'package:frontend/models/team_info_model.dart';
import 'package:frontend/api/company_api.dart';

class TeamListNotifier extends StateNotifier<AsyncValue<List<TeamInfo>>> {
  final Ref ref;

  TeamListNotifier(this.ref) : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch() async {
    state = const AsyncLoading();
    try {
      final Dio dio = ref.read(dioProvider);
      final teams = await fetchCompanyTeams(dio);
      state = AsyncValue.data(teams);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => fetch();
}

final teamListProvider =
    StateNotifierProvider<TeamListNotifier, AsyncValue<List<TeamInfo>>>(
  (ref) => TeamListNotifier(ref),
);
