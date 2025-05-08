import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/api/company_api.dart';
import 'package:frontend/exceptions/api_exception.dart';
import 'package:frontend/providers/company_provider.dart';

class CompanyCreatePage extends ConsumerStatefulWidget {
  const CompanyCreatePage({super.key});

  @override
  ConsumerState<CompanyCreatePage> createState() => _CompanyCreatePage();
}

class _CompanyCreatePage extends ConsumerState<CompanyCreatePage> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
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
      appBar: AppBar(
        title: Text('Fj', style: Theme.of(context).textTheme.headlineLarge),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - kToolbarHeight - 150, // 中央揃えのため
              ),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
            
                  children: [
                    Text(
                      '会社グループを作成',
                      style: Theme.of(context).textTheme.headlineLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
            
                    Center(
                      child: SizedBox(
                        width: 280,
                        child: TextField(
                          controller: _nameController,
                          keyboardType: TextInputType.name,
                          decoration: InputDecoration(labelText: '会社名'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
            
                    Center(
                      child: SizedBox(
                        width: 280,
                        child: TextField(
                          controller: _addressController,
                          keyboardType: TextInputType.name,
                          decoration: InputDecoration(labelText: '会社の住所'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
            
                    Center(
                      child: SizedBox(
                        width: 280,
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(labelText: '会社の電話番号'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
            
                    Center(
                      child: SizedBox(
                        width: 280,
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              final company = await registerCompany(
                                ref: ref,
                                companyName: _nameController.text.trim(),
                                companyAddress: _addressController.text.trim(),
                                companyPhone: _phoneController.text.trim(),
                              );
            
                              // Riverpodで状態を更新
                              ref.read(companyProvider.notifier).state = company;
            
                              // 遷移 or 成功ダイアログなど
                              Navigator.pushReplacementNamed(context, '/home');
                            } on ApiException catch (e) {
                              _showError(context, e.message);
            
                              if (e.statusCode == 401) {
                                Navigator.pushReplacementNamed(context, '/login');
                              }
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
                            '会社グループ作成の申請',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
