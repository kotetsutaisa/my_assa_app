import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/utils/constants.dart';
import '../utils/token_manager.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: apiBaseUrl, // ← 本番では dart-define で切り替える！
    ),
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  // --- リクエスト時：トークンを自動付与 ---
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final accessToken = await getAccessToken();
      if (accessToken != null) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
      handler.next(options);
    },

    // --- 401のとき：トークンリフレッシュしてリトライ ---
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        final success = await refreshAccessToken();
        if (success) {
          final newToken = await getAccessToken();
          if (newToken != null) {
            error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            final clone = await dio.fetch(error.requestOptions);
            return handler.resolve(clone);
          }
        }
      }
      handler.next(error);
    },
  ));

  // --- ログ出力（開発用） ---
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    logPrint: print,
  ));

  // --- 自動リトライ ---
  dio.interceptors.add(
    RetryInterceptor(
      dio: dio,
      logPrint: print,
      retries: 3,
      retryDelays: const [
        Duration(seconds: 1),
        Duration(seconds: 2),
        Duration(seconds: 3),
      ]
    ),
  );
  return dio;
});


