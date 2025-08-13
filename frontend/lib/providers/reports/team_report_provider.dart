// lib/providers/reports/team_report_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/providers/dio_provider.dart';
import 'package:frontend/models/reports/team_report_model.dart';
import 'package:frontend/api/reports_api.dart';

/// 一覧の検索条件
class TeamReportListQuery {
  final DateTime? start;
  final DateTime? end;
  final String? teamId;   // UUID
  final int? memberId;    // user id

  const TeamReportListQuery({this.start, this.end, this.teamId, this.memberId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamReportListQuery &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end &&
          teamId == other.teamId &&
          memberId == other.memberId;

  @override
  int get hashCode =>
      Object.hash(start, end, teamId, memberId);
}

/// 一覧 Notifier（Family）
class TeamReportListNotifier
    extends StateNotifier<AsyncValue<List<TeamReportModel>>> {
  final Ref ref;
  final TeamReportListQuery query;

  TeamReportListNotifier(this.ref, this.query)
      : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch() async {
    state = const AsyncLoading();
    try {
      final dio = ref.read(dioProvider);
      final list = await fetchTeamReports(
        dio,
        start: query.start,
        end: query.end,
        teamId: query.teamId,
        memberId: query.memberId,
      );
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => fetch();

  /// 作成 → 再取得
  Future<TeamReportModel> create({
    required TeamReportModel model,
    required String teamId,
  }) async {
    final dio = ref.read(dioProvider);
    final created = await createTeamReport(dio: dio, model: model, teamId: teamId);
    
    ref.invalidate(teamReportListProvider);
    return created;
  }

  /// 更新（patch は model.toPayload(..., includeEntries: false) 等で用意）
  Future<TeamReportModel> update({
    required String id,
    required Map<String, dynamic> patch,
  }) async {
    final dio = ref.read(dioProvider);
    final updated = await updateTeamReport(dio: dio, id: id, patch: patch);
    ref.invalidate(teamReportListProvider);
    return updated;
  }

  Future<void> remove(String id) async {
    final dio = ref.read(dioProvider);
    await deleteTeamReport(dio, id);
    ref.invalidate(teamReportListProvider);
  }

  /// 個人下書き生成
  Future<GeneratePersonalResult> generatePersonalDraft({
    required String teamReportId,
    bool replaceExisting = true,
  }) async {
    final dio = ref.read(dioProvider);
    final result = await generatePersonalFromTeam(
      dio: dio,
      teamReportId: teamReportId,
      replaceExisting: replaceExisting,
    );
    return result;
  }
}

/// Family Provider（一覧）
final teamReportListProvider = StateNotifierProvider.family<
    TeamReportListNotifier,
    AsyncValue<List<TeamReportModel>>,
    TeamReportListQuery>((ref, query) => TeamReportListNotifier(ref, query));


/// 詳細 Notifier（1件）
class TeamReportDetailNotifier
    extends StateNotifier<AsyncValue<TeamReportModel>> {
  final Ref ref;
  final String id;

  TeamReportDetailNotifier(this.ref, this.id)
      : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch() async {
    state = const AsyncLoading();
    try {
      final dio = ref.read(dioProvider);
      final data = await fetchTeamReportDetail(dio, id);
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<TeamReportModel> patch(Map<String, dynamic> patch) async {
    final dio = ref.read(dioProvider);
    final updated = await updateTeamReport(dio: dio, id: id, patch: patch);
    state = AsyncValue.data(updated);
    return updated;
  }

  Future<void> remove() async {
    final dio = ref.read(dioProvider);
    await deleteTeamReport(dio, id);
    // 呼び出し側で画面遷移を戻す想定
  }

  Future<GeneratePersonalResult> generatePersonalDraft({bool replaceExisting = true}) async {
    final dio = ref.read(dioProvider);
    final result = await generatePersonalFromTeam(
      dio: dio,
      teamReportId: id,
      replaceExisting: replaceExisting,
    );
    return result;
  }
}

/// Family Provider（詳細）
final teamReportDetailProvider = StateNotifierProvider.family<
    TeamReportDetailNotifier,
    AsyncValue<TeamReportModel>,
    String>((ref, id) => TeamReportDetailNotifier(ref, id));
