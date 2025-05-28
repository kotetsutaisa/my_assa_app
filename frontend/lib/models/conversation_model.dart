import 'package:frontend/models/simple_user_model.dart';

class ConversationModel {
    final String id;
    final String? title;
    final bool isGroup;
    final String? icon;
    final DateTime updatedAt;
    final SimpleUserModel? partner;

    ConversationModel({
        required this.id,
        required this.title,
        required this.isGroup,
        required this.icon,
        required this.updatedAt,
        this.partner,
    });

    factory ConversationModel.fromJson(Map<String, dynamic> json) {
        return ConversationModel(
            id: json['id'] as String,
            title: json['title'] as String?,
            isGroup: json['is_group'] as bool,
            icon: json['icon'] as String?,
            updatedAt: DateTime.parse(json['updated_at'] as String),
            partner: json['partner_user'] != null
                ? SimpleUserModel.fromJson(json['partner_user'])
                : null,
        );
    }

    Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'is_group': isGroup,
        'icon': icon,
        'updated_at': updatedAt.toIso8601String(),
        'partner_user': partner?.toJson(),
      };
}
