import 'package:frontend/models/message_model.dart';
import 'package:frontend/models/last_message_model.dart';

extension ToLastMessage on MessageModel {
  LastMessage toLastMessage() {
    return LastMessage(
      content: body['text'] as String?,
      createdAt: createdAt,
    );
  }
}
