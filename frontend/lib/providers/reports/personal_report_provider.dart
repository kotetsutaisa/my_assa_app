// lib/providers/reports/personal_report_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/providers/dio_provider.dart';
import 'package:frontend/models/reports/personal_report_model.dart';
import 'package:frontend/api/personal_reports_api.dart';

/// 一覧の検索条件
class PersonalReportListQuery {
  final DateTime? start;
  final DateTime? end;
  /// 'me' または ユーザーID文字列（int の場合は toString 済み）
  final String? userIdParam;

  const PersonalReportListQuery({this.start, this.end, this.userIdParam});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalReportListQuery &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end &&
          userIdParam == other.userIdParam;

  @override
  int get hashCode => Object.hash(start, end, userIdParam);
}

/// 一覧 Notifier（Family）
class PersonalReportListNotifier
    extends StateNotifier<AsyncValue<List<PersonalReportModel>>> {
  final Ref ref;
  final PersonalReportListQuery query;

  PersonalReportListNotifier(this.ref, this.query)
      : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch() async {
    state = const AsyncLoading();
    try {
      final dio = ref.read(dioProvider);
      final list = await fetchPersonalReports(
        dio,
        start: query.start,
        end: query.end,
        userIdParam: query.userIdParam,
      );
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => fetch();

  /// 作成 → 再取得
  Future<PersonalReportModel> create({
    required PersonalReportModel model,
    int? userId,
  }) async {
    final dio = ref.read(dioProvider);
    final created = await createPersonalReport(
      dio: dio,
      model: model,
      userId: userId,
    );
    ref.invalidate(personalReportListProvider);
    return created;
  }

  /// 更新（例：status を変える / entries を上書き）
  Future<PersonalReportModel> update({
    required String id,
    required Map<String, dynamic> patch,
  }) async {
    final dio = ref.read(dioProvider);
    final updated = await updatePersonalReport(dio: dio, id: id, patch: patch);
    ref.invalidate(personalReportListProvider);
    return updated;
  }

  /// 削除 → 再取得
  Future<void> remove(String id) async {
    final dio = ref.read(dioProvider);
    await deletePersonalReport(dio, id);
    ref.invalidate(personalReportListProvider);
  }
}

/// Family Provider（一覧）
final personalReportListProvider = StateNotifierProvider.family<
    PersonalReportListNotifier,
    AsyncValue<List<PersonalReportModel>>,
    PersonalReportListQuery>((ref, query) => PersonalReportListNotifier(ref, query));


/// 詳細 Notifier（1件）
class PersonalReportDetailNotifier
    extends StateNotifier<AsyncValue<PersonalReportModel>> {
  final Ref ref;
  final String id;

  PersonalReportDetailNotifier(this.ref, this.id)
      : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch() async {
    state = const AsyncLoading();
    try {
      final dio = ref.read(dioProvider);
      final data = await fetchPersonalReportDetail(dio, id);
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 部分更新（status や entries 等）
  Future<PersonalReportModel> patch(Map<String, dynamic> patch) async {
    final dio = ref.read(dioProvider);
    final updated = await updatePersonalReport(dio: dio, id: id, patch: patch);
    state = AsyncValue.data(updated);
    return updated;
  }

  /// 削除（呼び出し側で pop など画面遷移制御）
  Future<void> remove() async {
    final dio = ref.read(dioProvider);
    await deletePersonalReport(dio, id);
  }
}

/// Family Provider（詳細）
final personalReportDetailProvider = StateNotifierProvider.family<
    PersonalReportDetailNotifier,
    AsyncValue<PersonalReportModel>,
    String>((ref, id) => PersonalReportDetailNotifier(ref, id));
