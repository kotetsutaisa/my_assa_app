import 'package:dio/dio.dart';
import 'package:frontend/models/simple_user_model.dart';

Future<List<SimpleUserModel>> fetchCompanyUser(Dio dio) async {
  try {
    final response = await dio.get('users/company-users/');
    final List<dynamic> data = response.data;
    return data.map((json) => SimpleUserModel.fromJson(json)).toList();
  } on DioException catch (e) {
    print('📛 fetchCompanyUser error: ${e.message}');
    throw Exception('ユーザー一覧の取得に失敗しました');
  }
    
}