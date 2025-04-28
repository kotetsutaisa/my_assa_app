import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/user_api.dart';
import '../utils/token_manager.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _nameController = TextEditingController();
  final _accountIdController = TextEditingController(text: '@');
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _accountIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ヘッダー
      appBar: AppBar(
        title: Text('Fj', style: Theme.of(context).textTheme.headlineLarge),
      ),

      // ボディー
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [
            Text(
              'アカウント作成',
              style: Theme.of(context).textTheme.headlineLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            //　名前
            Center(
              child: SizedBox(
                width: 280,
                child: TextField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  decoration: InputDecoration(
                    labelText: '名前',
                    hintText: 'フルネームで記入してください',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // アカウントID
            Center(
              child: SizedBox(
                width: 280,
                child: TextField(
                  controller: _accountIdController,
                  decoration: InputDecoration(labelText: 'アカウントID'),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // メールアドレス
            Center(
              child: SizedBox(
                width: 280,
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'メールアドレス',
                    hintText: 'example@example.com',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // パスワード
            Center(
              child: SizedBox(
                width: 280,
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'パスワード'),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // アカウント作成ボタン
            Center(
              child: SizedBox(
                width: 280,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      // 入力されたデータをサーバーに送信する関数を実行
                      final tokens = await registerUser(
                        username: _nameController.text.trim(),
                        accountId: _accountIdController.text.trim(),
                        email: _emailController.text.trim(),
                        password: _passwordController.text.trim(),
                      );
                      await saveTokens(tokens['access']!, tokens['refresh']!);
                      await fetchCurrentUser(context, ref);
                    } catch (e) {
                      _showError(context, e.toString());
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Color.fromRGBO(39, 39, 39, 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),

                  child: Text(
                    'アカウント作成',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
