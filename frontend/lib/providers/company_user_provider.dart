import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/api/company_user_api.dart';
import 'package:frontend/models/simple_user_model.dart';
import 'package:frontend/providers/dio_provider.dart';

final companyUserProvider = FutureProvider<List<SimpleUserModel>>((ref) async {
    final dio = ref.watch(dioProvider);
    return await fetchCompanyUser(dio);
});