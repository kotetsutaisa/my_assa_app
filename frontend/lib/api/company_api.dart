import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../exceptions/api_exception.dart';
import '../providers/dio_provider.dart';
import '../models/company_model.dart';

Future<Company> registerCompany({
  required WidgetRef ref,
  required String companyName,
  required String companyAddress,
  required String companyPhone,
}) async {
  // ---------- バリデーション ----------
  if (companyName.trim().isEmpty) {
    throw ApiException('会社名を入力してください');
  }

  final trimmedAddress = companyAddress.trim();
  final addressRegex = RegExp(r'^[\p{L}\p{N}\p{P}\p{Zs}ー－・々〆〤]+$', unicode: true);
  if (trimmedAddress.isEmpty ||
      !addressRegex.hasMatch(trimmedAddress)) {
    throw ApiException('住所の形式が正しくありません');
  }

  final trimmedPhone = companyPhone.trim().replaceAll('-', '');
  final phoneRegex = RegExp(r'^\+?\d{9,15}$');
  if (!phoneRegex.hasMatch(trimmedPhone)) {
    throw ApiException('電話番号は9〜15桁の数字（先頭+可）で入力してください');
  }

  // ---------- API 呼び出し ----------
  final dio = ref.watch(dioProvider);

  late Response res;
  try {
    res = await dio.post(
      'companies/create/',                  // ← 複数形に修正
      data: {
        'name': companyName.trim(),
        'address': trimmedAddress,
        'phone': trimmedPhone,
      },
    );
  } on DioException catch (e) {
    // ネットワーク / タイムアウト
    throw ApiException(e.message ?? '通信エラー', e.response?.statusCode);
  }

  // ---------- 成否判定 ----------
  switch (res.statusCode) {
    case 201:
      return Company.fromJson(res.data);      // ← モデル化
    case 400:
      throw ApiException('入力エラー: ${res.data}', 400);
    case 401:
      throw ApiException('認証エラー', 401);
    default:
      throw ApiException(
        'サーバエラー: ${res.statusCode} - ${res.statusMessage}',
        res.statusCode,
      );
  }
}


// --- 会社グループに参加する ---
Future<void> joinCompany({
  required WidgetRef ref,
  required String inviteCode,
}) async {
  // --- 入力バリデーション ---
  final trimmedCode = inviteCode.trim();
  final codeRegex = RegExp(r'^[A-Z0-9]{12}$'); // 英大文字＋数字12桁

  if (!codeRegex.hasMatch(trimmedCode)) {
    throw ApiException('招待コードは大文字の英数字12桁で入力してください。');
  }

  // --- API 通信 ---
  final dio = ref.watch(dioProvider);
  late Response res;

  try {
    res = await dio.post(
      'companies/join/',
      data: {'code': trimmedCode},
    );
  } on DioException catch (e) {
    if (e.response != null && e.response?.statusCode == 400) {
      final data = e.response?.data;

      // ❶ codeフィールドのエラーを優先的に見る
      if (data is Map<String, dynamic>) {
        final codeErrors = data['code'];
        if (codeErrors is List && codeErrors.isNotEmpty) {
          throw ApiException(codeErrors.first.toString());
        }
      }

      // ❷ fallbackとしてdetailを見る
      final msg = data['detail'] ?? '招待コードが無効です。';
      throw ApiException(msg.toString());
    }

    // ❸ それ以外の通信エラー
    throw ApiException('通信エラーが発生しました。', e.response?.statusCode);
  }

  // --- レスポンス確認 ---
  switch (res.statusCode) {
    case 200:
      return;
    case 400:
      throw ApiException('入力エラー: ${res.data}', 400);
    case 401:
      throw ApiException('認証エラー。ログインし直してください。', 401);
    default:
      throw ApiException(
        'サーバーエラー: ${res.statusCode} - ${res.statusMessage}',
        res.statusCode,
      );
  }
}

