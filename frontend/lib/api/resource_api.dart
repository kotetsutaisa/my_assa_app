import 'package:dio/dio.dart';

import '../models/resource_model.dart';
import '../models/resource_category_model.dart';

/// --------------------
/// リソースカテゴリ
/// --------------------
Future<List<ResourceCategoryModel>> fetchResourceCategories(Dio dio) async {
  final res = await dio.get('resources/categories/');
  return (res.data as List)
      .map((j) => ResourceCategoryModel.fromJson(j))
      .toList();
}

/// --------------------
/// リソース
/// --------------------

/// 一覧（⚠️ 会社スコープはバックエンド側で認証ユーザーの company に絞られている前提）
Future<List<ResourceModel>> fetchResources(Dio dio) async {
  final res = await dio.get('resources/');
  return (res.data as List).map((j) => ResourceModel.fromJson(j)).toList();
}

/// 1 件取得（編集画面を直接開く想定などで使用）
Future<ResourceModel> fetchResourceDetail(Dio dio, String resourceId) async {
  final res = await dio.get('resources/$resourceId/');
  return ResourceModel.fromJson(res.data as Map<String, dynamic>);
}

/// 作成
Future<ResourceModel> createResource(Dio dio, ResourceModel payload) async {
  final res = await dio.post('resources/', data: payload.toJson());
  return ResourceModel.fromJson(res.data as Map<String, dynamic>);
}

/// 更新（部分更新）
Future<ResourceModel> updateResource(
  Dio dio, {
  required String resourceId,
  required Map<String, dynamic> payload,
}) async {
  // PATCH に渡す payload は ResourceModel#toJson() で必要項目だけ抽出がおすすめ
  final res = await dio.patch('resources/$resourceId/', data: payload);
  return ResourceModel.fromJson(res.data as Map<String, dynamic>);
}

/// 削除
Future<void> deleteResource(Dio dio, String resourceId) async {
  await dio.delete('resources/$resourceId/');
}
