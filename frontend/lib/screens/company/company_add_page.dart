import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/api/company_api.dart';

class CompanyAddPage extends ConsumerStatefulWidget {
  const CompanyAddPage({super.key});

  @override
  ConsumerState<CompanyAddPage> createState() => _CompanyAddPage();
}

class _CompanyAddPage extends ConsumerState<CompanyAddPage> {

  final _invitationController = TextEditingController();

  @override
  void dispose() {
    _invitationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Fj',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                '会社グループに参加',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            SizedBox(height: 50),
            Center(
              child: Text(
                '招待コードを発行してもらい入力してください',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: SizedBox(
                width: 280,
                child: TextField(
                  controller: _invitationController,
                  keyboardType: TextInputType.name,
                  decoration: InputDecoration(
                    labelText: '招待コード',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            Center(
              child: SizedBox(
                width: 280,
                child: ElevatedButton(
                  onPressed: () async {

                    final code = _invitationController.text.trim();
                    if (code.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('招待コードを入力してください'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    try {
                      await joinCompany(ref: ref, inviteCode: _invitationController.text);
                      if (!mounted) return;
                      Navigator.pushReplacementNamed(context, '/home');
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: Colors.red,
                        ),
                      );
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
                    '参加する',
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
