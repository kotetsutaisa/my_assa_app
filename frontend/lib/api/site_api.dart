import 'package:dio/dio.dart';
import 'package:frontend/models/site_model.dart';


// 投稿一覧取得
Future<List<SiteModel>> fetchSite(Dio dio) async {
  try {
    final response = await dio.get('sites/');
    final List<dynamic> jsonList = response.data;
    return jsonList.map((json) => SiteModel.fromJson(json)).toList();
  } on DioException catch (e) {
    print('現場一覧取得エラー: ${e.message}');
    throw Exception('現場の取得に失敗しました');
  }
}

Future<void> createSite(
  Dio dio, 
  String name,
  String address,
  String generalContractorName,
  String managerName,
  String managerPhone,
  String? startDate,
  String? endDate,
  String? memo,
) async {
  // --- バリデーション ---
  const prefectures = [
    '北海道', '青森県', '岩手県', '宮城県', '秋田県', '山形県', '福島県',
    '茨城県', '栃木県', '群馬県', '埼玉県', '千葉県', '東京都', '神奈川県',
    '新潟県', '富山県', '石川県', '福井県', '山梨県', '長野県',
    '岐阜県', '静岡県', '愛知県', '三重県',
    '滋賀県', '京都府', '大阪府', '兵庫県', '奈良県', '和歌山県',
    '鳥取県', '島根県', '岡山県', '広島県', '山口県',
    '徳島県', '香川県', '愛媛県', '高知県',
    '福岡県', '佐賀県', '長崎県', '熊本県', '大分県', '宮崎県', '鹿児島県', '沖縄県',
  ];

  if (name.trim().isEmpty) {
    throw Exception('現場名を入力してください');
  }

  if (!prefectures.any((pref) => address.startsWith(pref))) {
    throw Exception('住所は都道府県から始めてください');
  }

  if (address.length < 10) {
    throw Exception('住所が短すぎます（詳細まで入力してください）');
  }

  if (managerPhone.trim().isEmpty) {
    throw Exception('電話番号を入力してください');
  }

  if (!RegExp(r'^\d{10,11}$').hasMatch(managerPhone)) {
    throw Exception('電話番号は10桁または11桁の数字で入力してください');
  }

  // --- 日付バリデーション ---
  if (startDate != null && endDate != null) {
    final start = DateTime.tryParse(startDate);
    final end = DateTime.tryParse(endDate);

    if (start != null && end != null && end.isBefore(start)) {
      throw Exception('終了日は開始日以降の日付を選択してください');
    }
  }

  if (startDate == null || endDate == null) {
    throw Exception('施工開始日と終了日を選択してください');
  }


  // --- 送信処理 ---
  try {
    await dio.post(
      'sites/',
      data: {
        'name': name,
        'address' : address,
        'general_contractor_name': generalContractorName,
        'manager_name': managerName,
        'manager_phone': managerPhone,
        'memo': memo,
        'start_date': startDate.split('T').first,
        'end_date': endDate.split('T').first,
      }
    );
  } on DioException catch (e) {
    print('現場作成エラー: ${e.message}');
    throw Exception('現場の作成に失敗しました');
  }
}