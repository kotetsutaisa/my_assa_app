import 'package:flutter/material.dart';
import 'package:frontend/models/conversation_model.dart';
import 'package:frontend/models/simple_user_model.dart';

@immutable
class ConvInviModel {
  final ConversationModel? conversation;
  final bool isInvited;
  final SimpleUserModel? invitedBy;

  ConvInviModel ({
    required this.conversation,
    required this.isInvited,
    this.invitedBy,
  });

  factory ConvInviModel.fromJson(Map<String, dynamic> json) {
    return ConvInviModel(
      conversation: ConversationModel.fromJson(json['conversation']),
      isInvited: json['is_invited'] as bool,
      invitedBy: json['invited_by'] != null
          ? SimpleUserModel.fromJson(json['invited_by'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'conversation': conversation?.toJson(),
    'is_invited': isInvited,
    'invited_by': invitedBy?.toJson(),
  };

  ConvInviModel copyWith({
    ConversationModel? conversation,
    bool? isInvited,
    SimpleUserModel? invitedBy,
  }) {
    return ConvInviModel(
      conversation: conversation ?? this.conversation,
      isInvited: isInvited ?? this.isInvited,
      invitedBy: invitedBy ?? this.invitedBy,
    );
  }
}