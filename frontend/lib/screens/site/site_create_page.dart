import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/api/site_api.dart';
import 'package:frontend/providers/dio_provider.dart';
import 'package:frontend/providers/site_provider.dart';

class SiteCreatePage extends ConsumerStatefulWidget {
  const SiteCreatePage({super.key});

  @override
  ConsumerState<SiteCreatePage> createState() => _SiteCreatePage();
}

class _SiteCreatePage extends ConsumerState<SiteCreatePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController generalContractorNameController = TextEditingController();
  final TextEditingController managerNameController = TextEditingController();
  final TextEditingController managerPhoneController = TextEditingController();
  final TextEditingController memoController = TextEditingController();

  DateTime? constructionStartDate;
  DateTime? constructionEndDate;

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          constructionStartDate = picked;
        } else {
          constructionEndDate = picked;
        }
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('現場登録'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Theme.of(context).colorScheme.outline,
            height: 1,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final dio = ref.read(dioProvider);
              try {
                await createSite(
                  dio,
                  nameController.text,
                  addressController.text,
                  generalContractorNameController.text,
                  managerNameController.text,
                  managerPhoneController.text,
                  constructionStartDate?.toIso8601String(),
                  constructionEndDate?.toIso8601String(),
                  memoController.text,
                );
                ref.invalidate(siteListProvider);
                Navigator.of(context).pop();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            },
            child: Text(
              '登録',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),

      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
          child: Column(
            children: [
              buildEditableCreateRow(context, '現場名', nameController),
              buildEditableCreateRow(
                context,
                '住所',
                addressController,
              ),
              buildEditableCreateRow(context, '元請け', generalContractorNameController),
              buildEditableCreateRow(context, '所長', managerNameController),
              buildEditableCreateRow(context, '電話番号', managerPhoneController),
              // 👇 施工期間
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 80,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text('施工期間', style: Theme.of(context).textTheme.bodyLarge),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => _selectDate(context, true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Theme.of(context).colorScheme.outline),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                constructionStartDate != null
                                    ? '開始日: ${constructionStartDate!.toLocal().toString().split(' ')[0]}'
                                    : '開始日を選択',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _selectDate(context, false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Theme.of(context).colorScheme.outline),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                constructionEndDate != null
                                    ? '終了日: ${constructionEndDate!.toLocal().toString().split(' ')[0]}'
                                    : '終了日を選択',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              buildEditableCreateRow(context, '備考', memoController, isMemo: true),
            ],
          ),
        ),
      ),
    );
  }
}

Widget buildEditableCreateRow(
  BuildContext context,
  String label,
  TextEditingController controller, {
  bool isMemo = false,
}) {
  final textStyle = Theme.of(context).textTheme.bodyLarge!;

  if (isMemo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // ← 上揃え
        children: [
          SizedBox(
            width: 80,
            child: Padding(
              padding: const EdgeInsets.only(top: 12), // ← 上に少し余白を足して揃える
              child: Text(label, style: textStyle),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 5,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }

  // 通常の1行入力
  return Padding(
    padding: const EdgeInsets.only(bottom: 32),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: textStyle),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              border: const OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    ),
  );
}
