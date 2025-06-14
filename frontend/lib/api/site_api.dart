import 'package:dio/dio.dart';
import 'package:frontend/models/site_model.dart';


// 投稿一覧取得
Future<List<SiteModel>> fetchSite(Dio dio) async {
  try {
    final response = await dio.get('sites/');
    final List<dynamic> jsonList = response.data;
    return jsonList.map((json) => SiteModel.fromJson(json)).toList();
  } on DioException catch (e) {
    print('現場一覧取得エラー: ${e.message}');
    throw Exception('現場の取得に失敗しました');
  }
}