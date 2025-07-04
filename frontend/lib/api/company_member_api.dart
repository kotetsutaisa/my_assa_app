import 'package:dio/dio.dart';
import 'package:frontend/models/member_entry_model.dart';

// 権限やチームごとのユーザー一覧取得
Future<List<MemberEntry>> fetchCompanyMembers(Dio dio) async {
  final res = await dio.get('companies/team-members/');

  // API からは List<dynamic> が返る想定
  final List<dynamic> raw = res.data as List<dynamic>;

  return raw
      .map((e) => MemberEntry.fromJson(e as Map<String, dynamic>))
      .toList();
}