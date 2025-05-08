import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/invite_code_provider.dart';
import 'package:frontend/widgets/sub_header.dart';

// 未実装機能一覧
// 招待コードのコピーボタン

class InvitePage extends ConsumerWidget {
  const InvitePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inviteCode = ref.watch(inviteCodeProvider);
    final notifier = ref.read(inviteCodeProvider.notifier);

    final isValid = inviteCode?.isValid ?? false;

    return Scaffold(
      body: Column(
        children: [
          Center(
            child: SubHeader(
              title: 'メンバー招待',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                SizedBox(height: 50),
                Text(
                  '会社メンバーがグループに参加するには\n招待コードを生成する必要があります',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 30),

                Text(
                  '下記のコードを参加させたいユーザーに\n送信してください',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 50),

                SizedBox(
                  width: 280,
                  child: ElevatedButton(
                    onPressed: () async {
                      await notifier.fetchOrGenerateCode();
                    },
                  
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Color.fromRGBO(39, 39, 39, 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  
                    child: Text(isValid ? '招待コードを再取得' : '招待コードを生成'),
                  ),
                ),
                const SizedBox(height: 50),
                if (inviteCode != null)
                  Column(
                    children: [
                      Text('招待コード : ${inviteCode.code}',
                        style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 10),
                      Text('有効期限 : 発行から24時間'),
                    ],
                  )
                else
                  const Text('現在、招待コードは発行されていません。'),

                
              ],
            ),
          ),
        ],
      ),
    );
  }
}
