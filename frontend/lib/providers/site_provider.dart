import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/api/site_api.dart';
import 'package:frontend/models/site_model.dart';
import 'package:frontend/providers/dio_provider.dart';

class SiteListNotifier extends AsyncNotifier<List<SiteModel>> {
  @override
  Future<List<SiteModel>> build() async {
    final dio = ref.read(dioProvider);
    return await fetchSite(dio); // ← Dioを渡す！
  }
}

// --- Provider登録 ---
final siteListProvider =
    AsyncNotifierProvider<SiteListNotifier, List<SiteModel>>(() => SiteListNotifier());