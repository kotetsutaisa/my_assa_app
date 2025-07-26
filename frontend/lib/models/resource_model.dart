// lib/models/resource_model.dart
import 'resource_category_model.dart';

class ResourceModel {
  final String id;        // UUID 文字列
  final String name;

  // --- Optional details (MVP では nullable) -------------------------------
  final String? maker;
  final String? plateNo;
  final int?    capacityKg;
  final String? description;

  final bool   isActive;

  // ───────── リレーション ─────────

  /// *展開済み* のカテゴリ（/api/resources/ で `select_related` している前提）
  ///   - null ならバックエンドが `null` を返したケース
  final ResourceCategoryModel? category;

  /// *展開しない* エンドポイント用に ID だけ欲しい場合はこちらを参照
  ///   - `category` が null でも `categoryId` が入る時がある
  final int? categoryId;

  // ────────── メタ情報 ──────────────
  final String? createdById;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ResourceModel({
    required this.id,
    required this.name,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.maker,
    this.plateNo,
    this.capacityKg,
    this.description,
    this.category,
    this.categoryId,
    this.createdById,
  });

  // ------------------------ fromJson ------------------------
  factory ResourceModel.fromJson(Map<String, dynamic> json) {
    // category は null か {id:…, name:…}
    final cat = json['category'];
    return ResourceModel(
      id          : json['id']       as String,
      name        : json['name']     as String,
      maker       : json['maker']     as String?,
      plateNo     : json['plate_no']  as String?,
      capacityKg  : json['capacityKg'] as int?,
      description : json['description'] as String?,
      isActive    : json['is_active'] as bool? ?? true,
      category    : cat != null ? ResourceCategoryModel.fromJson(cat) : null,
      categoryId  : cat == null ? json['category'] as int? : cat['id'] as int,
      createdById : json['created_by']?.toString(),
      createdAt   : DateTime.parse(json['created_at'] as String),
      updatedAt   : DateTime.parse(json['updated_at'] as String),
    );
  }

  // ------------------------ toJson (POST / PATCH 用) ------------------------
  Map<String, dynamic> toJson({
    bool includeId = false,
  }) {
    final map = <String, dynamic>{
      'name'        : name,
      'maker'       : maker,
      'plate_no'    : plateNo,
      'capacityKg'  : capacityKg,
      'description' : description,
      'is_active'   : isActive,
    };
    if (includeId) map['id'] = id;
    return map;
  }
}
