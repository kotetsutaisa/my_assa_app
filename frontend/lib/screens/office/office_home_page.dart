// lib/pages/office/office_home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:frontend/screens/office/employee_list_page.dart';
import 'package:frontend/screens/office/payroll_policy_page.dart';

class OfficeHomePage extends ConsumerWidget {
  const OfficeHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    // ユーザー情報の読込待ち
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('事務')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // admin / clerk 以外は入れない（二重ガード）
    final allowed = user.isAdmin || user.isClerk;
    if (!allowed) {
      return Scaffold(
        appBar: AppBar(title: Text('事務')),
        body: Center(child: Text('権限がありません')),
      );
    }

    // --- UIのみ（将来ここから各画面へ遷移する）---
    return Scaffold(
      appBar: AppBar(title: const Text('事務')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('会社設定（休憩・残業・休日・丸め）'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => PayrollPolicyPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.badge),
            title: Text('従業員給料設定（賃金方式・単価）'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EmployeeListPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.receipt_long),
            title: Text('給与計算プレビュー / CSV'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => PayrollPolicyPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
