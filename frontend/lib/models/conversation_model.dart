import 'dart:io';

import 'package:frontend/models/last_message_model.dart';
import 'package:frontend/models/simple_user_model.dart';

class ConversationModel {
    final String id;
    final String? title;
    final bool isGroup;
    final String? icon;
    final DateTime updatedAt;
    final SimpleUserModel? partner;
    final LastMessage? lastMessage;

    // 送信用の画像ファイル（Flutterだけで使用、fromJsonには関係ない）
    final File? iconFile;

    ConversationModel({
        required this.id,
        required this.title,
        required this.isGroup,
        required this.icon,
        required this.updatedAt,
        this.partner,
        this.lastMessage,
        this.iconFile,
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
            lastMessage: json['last_message'] != null
                ? LastMessage.fromJson(json['last_message'])
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
        'last_message': lastMessage?.toJson(),
      };

    ConversationModel copyWith({
        String? id,
        String? title,
        bool? isGroup,
        String? icon,
        DateTime? updatedAt,
        SimpleUserModel? partner,
        LastMessage? lastMessage,
        File? iconFile,
    }) {
        return ConversationModel(
        id: id ?? this.id,
        title: title ?? this.title,
        isGroup: isGroup ?? this.isGroup,
        icon: icon ?? this.icon,
        updatedAt: updatedAt ?? this.updatedAt,
        partner: partner ?? this.partner,
        lastMessage: lastMessage ?? this.lastMessage,
        iconFile: iconFile ?? this.iconFile,
        );
    }
}
