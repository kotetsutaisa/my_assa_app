import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/user_api.dart';
import '../utils/token_manager.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();

    @override
    void dispose() {
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
                title: Text(
                    'Fj',
                    style: Theme.of(context).textTheme.headlineLarge,
                ),
            ),

            // body
            body: Padding(
                // パディング
                padding: const EdgeInsets.all(24),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,

                    children: [
                        Text(
                            'ログイン',
                            style: Theme.of(context).textTheme.headlineLarge,
                            textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),

                        // メールアドレス
                        Center (
                            child: SizedBox(
                                width: 280,
                                child: TextField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    autocorrect: false,
                                    decoration: InputDecoration(
                                        labelText: 'メールアドレス',
                                        hintText: 'example@example.com',

                                        border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(
                                                color: Color.fromRGBO(224, 224, 224, 1),
                                                width: 1.5,
                                            ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(
                                                color: Color.fromRGBO(39, 39, 39, 1),
                                                width: 2.0,
                                            ),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        labelStyle: TextStyle(
                                            fontSize: 14,
                                            color: Color.fromRGBO(100, 100, 100, 1),
                                        ),
                                    ),
                                ),
                            ),
                        ),
                        
                        const SizedBox(height: 16),

                        // パスワード
                        Center(
                            child: SizedBox(
                                width: 280,
                                child: TextField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    decoration: InputDecoration(
                                        labelText: 'パスワード',

                                        border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(
                                                color: Color.fromRGBO(224, 224, 224, 1),
                                                width: 1.5,
                                            ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(
                                                color: Color.fromRGBO(39, 39, 39, 1),
                                                width: 2.0,
                                            ),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        labelStyle: TextStyle(
                                            fontSize: 14,
                                            color: Color.fromRGBO(100, 100, 100, 1),
                                        ),
                                    ),
                                ),
                            ),
                        ),

                        const SizedBox(height: 30),
                        
                        // ログインボタン
                        Center(
                            child: SizedBox(
                                width: 280,
                                child: ElevatedButton(
                                    onPressed: () async {
                                        try {
                                            final tokens = await loginUser(
                                                email: _emailController.text,
                                                password: _passwordController.text,
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
                                        'ログイン',
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                        ),
                                    ),
                                ),
                            ),
                        ),

                        const SizedBox(height: 30),

                        // パスワードを忘れた方はこちら
                        Center (
                            child: Text.rich(
                                TextSpan (
                                    text: 'パスワードを忘れた方は',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                    children: [
                                        TextSpan(
                                            text: 'こちら',
                                            style: TextStyle(
                                                color: Colors.blue,
                                                decoration: TextDecoration.underline,
                                            )
                                        )
                                    ],
                                ),
                            ),
                        ),
                        const SizedBox(height: 30),

                        // ユーザー作成ボタン
                        Center(
                            child: SizedBox(
                                width: 280,
                                child: ElevatedButton(
                                    onPressed: () {
                                        Navigator.pushNamed(context, '/register');
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
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                        ),
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
