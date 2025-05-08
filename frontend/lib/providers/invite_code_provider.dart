import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/invite_code_model.dart';
import 'package:frontend/providers/dio_provider.dart';

final inviteCodeProvider = StateNotifierProvider<InviteCodeNotifier, InviteCode?>((ref) {
  return InviteCodeNotifier(ref);
});

class InviteCodeNotifier extends StateNotifier<InviteCode?> {
  InviteCodeNotifier(this.ref) : super(null);

  final Ref ref;

  Future<void> fetchOrGenerateCode() async {
    final dio = ref.read(dioProvider);

    try {
      final res = await dio.post('companies/invite/');
      final data = InviteCode.fromJson(res.data);
      state = data;
    } catch (e) {
      print('❌ 招待コード取得エラー: $e');
      rethrow;
    }
  }

  void clear() {
    state = null;
  }
}
