class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

// UI側での使い方
// try {
//   await registerCompany(...);
// } catch (e) {
//   if (e is ApiException && e.statusCode == 401) {
//     showSnackbar('ログインしてください');
//   } else {
//     showSnackbar(e.toString());
//   }
// }