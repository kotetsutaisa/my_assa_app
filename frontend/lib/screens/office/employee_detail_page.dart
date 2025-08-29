// lib/screens/office/employee_detail_page.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/models/office/employee_detail_summary_model.dart';
import 'package:frontend/models/office/wage_contract_model.dart';
import 'package:frontend/providers/dio_provider.dart';
import 'package:frontend/api/office_api.dart';
import 'package:frontend/providers/office/employee_detail_summary_provider.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:frontend/providers/office/office_employees_provider.dart';
import 'package:frontend/widgets/common/avatar.dart';
import 'package:frontend/utils/image_helper.dart'; // resolveImageUrl

class EmployeeDetailPage extends ConsumerStatefulWidget {
  const EmployeeDetailPage({super.key, required this.userId});
  final int userId;

  @override
  ConsumerState<EmployeeDetailPage> createState() => _EmployeeDetailPageState();
}

class _EmployeeDetailPageState extends ConsumerState<EmployeeDetailPage> {
  // ---- Form State ----
  final _formKey = GlobalKey<FormState>();

  String _payType = 'hourly'; // 初期値（後でサーバ値で上書き）
  final _monthlyCtrl = TextEditingController();
  final _dailyCtrl   = TextEditingController();
  final _hourlyCtrl  = TextEditingController();

  DateTime? _effectiveFrom;
  DateTime? _effectiveTo;

  bool _overrideCompany = false;
  final _otRateCtrl   = TextEditingController(); // custom_overtime_rate_multiplier
  final _nightRateCtrl= TextEditingController(); // custom_night_rate_multiplier

  final _pieceworkCtrl = TextEditingController(); // JSON文字列

  bool _initialized = false; // Provider読み込み後の1回きり初期化フラグ
  bool _saving = false;

  @override
  void dispose() {
    _monthlyCtrl.dispose();
    _dailyCtrl.dispose();
    _hourlyCtrl.dispose();
    _otRateCtrl.dispose();
    _nightRateCtrl.dispose();
    _pieceworkCtrl.dispose();
    super.dispose();
  }

  // === UI helpers ===
  String _d(DateTime? x) {
    if (x == null) return '未設定';
    return '${x.year.toString().padLeft(4, '0')}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate({required bool from}) async {
    final initial = (from ? _effectiveFrom : _effectiveTo) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked == null) return;
    setState(() {
      if (from) {
        _effectiveFrom = DateUtils.dateOnly(picked);
      } else {
        _effectiveTo = DateUtils.dateOnly(picked);
      }
    });
  }

  // 有効開始日／終了日の説明（日本語）
  Widget _effectiveDatesHelp() {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(
        '有効開始日：この契約が適用され始める日\n'
        '有効終了日：契約の最終日（空欄のまま=終了未定／継続）',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }

  // 小数やカンマ/通貨記号が来ても「整数文字列」に正規化するヘルパー
  String _asIntStr(String? v) {
    if (v == null) return '';
    final cleaned = v.replaceAll(RegExp(r'[^\d\.]'), ''); // 数字と小数点以外を除去
    if (cleaned.isEmpty) return '';
    final d = double.tryParse(cleaned);
    if (d == null) return cleaned.replaceAll('.', ''); // どうしても数値化できない時は小数点除去
    return d.truncate().toString(); // 小数部は表示しない＝切り捨て
  }

  bool get _showMonthly => _payType == 'monthly';
  bool get _showDaily   => _payType == 'daily';
  bool get _showHourly  => _payType == 'hourly';
  bool get _showPiece   => _payType == 'piecework';

  // === 保存 ===
  Future<void> _onSave(EmployeeDetailSummary summary) async {
    // 入力検証
    if (!_formKey.currentState!.validate()) return;

    // piecework_schema_json のパース
    Map<String, dynamic> piecework;
    final raw = _pieceworkCtrl.text.trim();
    if (raw.isEmpty) {
      piecework = const {};
    } else {
      try {
        final decoded = json.decode(raw);
        if (decoded is Map<String, dynamic>) {
          piecework = decoded;
        } else {
          throw const FormatException('JSONはオブジェクト形式で入力してください');
        }
      } catch (e) {
        _snack('出来高スキーマのJSONが不正です: $e');
        return;
      }
    }

    // pay_typeに応じた必須項目チェック（念のため）
    if (_showMonthly && (_monthlyCtrl.text.trim().isEmpty)) {
      _snack('月給を入力してください'); return;
    }
    if (_showDaily && (_dailyCtrl.text.trim().isEmpty)) {
      _snack('日給を入力してください'); return;
    }
    if (_showHourly && (_hourlyCtrl.text.trim().isEmpty)) {
      _snack('時給を入力してください'); return;
    }
    if (_effectiveFrom == null) {
      _snack('有効開始日を選択してください'); return;
    }

    setState(() => _saving = true);
    try {
      final dio = ref.read(dioProvider);
      final userId = summary.user.id;

      final monthlyText = _asIntStr(_monthlyCtrl.text);
      final dailyText   = _asIntStr(_dailyCtrl.text);
      final hourlyText  = _asIntStr(_hourlyCtrl.text);

      final model = WageContractModel(
        id: summary.currentContract?.id ?? 0,
        userId: userId,
        payType: _payType,
        effectiveFrom: _effectiveFrom!,
        effectiveTo  : _effectiveTo,
        monthlySalary: monthlyText.isEmpty ? null : monthlyText,
        dailyWage    : dailyText.isEmpty   ? null : dailyText,
        hourlyWage   : hourlyText.isEmpty  ? null : hourlyText,
        pieceworkSchemaJson: piecework,
        overrideCompanyPolicy: _overrideCompany,
        customOvertimeRateMultiplier: _otRateCtrl.text.trim().isEmpty ? null : _otRateCtrl.text.trim(),
        customNightRateMultiplier   : _nightRateCtrl.text.trim().isEmpty ? null : _nightRateCtrl.text.trim(),
      );

      if (summary.currentContract == null) {
        // 新規作成
        await createWageContractForUser(dio, model: model);
      } else {
        // 更新（PATCH）
        await patchWageContractById(dio, id: summary.currentContract!.id, patch: model.toPatchJson());
      }

      // 一覧の再取得（OfficeEmployeesNotifier）
      await ref.read(officeEmployeesProvider.notifier).refresh();

      // 戻る
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      _snack('保存に失敗しました: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  // 初期値の流し込み
  void _ensureInitFromSummary(EmployeeDetailSummary s) {
    if (_initialized) return;

    final c = s.currentContract;
    if (c == null) {
      // 契約なし → 未設定表示 & 入力は空
      _payType = 'hourly'; // デフォルトは任意。ここでは 'hourly'
      _monthlyCtrl.text = '';
      _dailyCtrl.text   = '';
      _hourlyCtrl.text  = '';
      _effectiveFrom    = null;
      _effectiveTo      = null;
      _overrideCompany  = false;
      _otRateCtrl.text  = '';
      _nightRateCtrl.text = '';
      _pieceworkCtrl.text = '';
    } else {
      _payType = c.payType;
      _monthlyCtrl.text = _asIntStr(c.monthlySalary);
      _dailyCtrl.text   = _asIntStr(c.dailyWage);
      _hourlyCtrl.text  = _asIntStr(c.hourlyWage);
      _effectiveFrom    = c.effectiveFrom;
      _effectiveTo      = c.effectiveTo;
      _overrideCompany  = c.overrideCompanyPolicy;
      _otRateCtrl.text  = c.customOvertimeRateMultiplier ?? '';
      _nightRateCtrl.text = c.customNightRateMultiplier ?? '';
      _pieceworkCtrl.text = jsonEncode(c.pieceworkSchemaJson);
    }
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    // 二重ガード（admin/clerk 以外はブロック）
    final me = ref.watch(userProvider);
    final allowed = me?.isAdmin == true || me?.isClerk == true;
    if (!allowed) {
      return Scaffold(
        appBar: AppBar(title: const Text('給料詳細')),
        body: const Center(child: Text('権限がありません')),
      );
    }

    final summaryAsync = ref.watch(employeeDetailSummaryProvider(widget.userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('給料設定'),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // 画面タップでキーボード収納
        child: summaryAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 40),
                const SizedBox(height: 12),
                Text('読み込みに失敗しました\n$e', textAlign: TextAlign.center),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => ref.refresh(employeeDetailSummaryProvider(widget.userId)),
                  child: const Text('再読み込み'),
                ),
              ],
            ),
          ),
          data: (summary) {
            _ensureInitFromSummary(summary);
            final u = summary.user;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // ===== ヘッダ：アイコン & ユーザー名 =====
                    Center(
                      child: Column(
                        children: [
                          buildAvatar(
                            context: context,
                            imageUrl: u.iconimg,
                            radius: 36,
                            resolveUrl: resolveImageUrl,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            u.username,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          // account_id / 役職 / 所属チーム（先頭）
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              _pill(context, '@${u.accountId}'),
                              _pill(context, u.roleJa),
                              _pill(context, u.primaryTeamName),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Divider(height: 1),

                    const SizedBox(height: 16),

                    // ===== 詳細（編集可能フォーム） =====
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('契約情報（現在の契約）',
                        style: Theme.of(context).textTheme.titleMedium),
                    ),
                    const SizedBox(height: 12),

                    // 参考表示：現在の主表示
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '現在の設定: ${summary.labels.mainRateLabel ?? '未設定'}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- pay_type ---
                    DropdownButtonFormField<String>(
                      value: _payType,
                      decoration: const InputDecoration(
                        labelText: '賃金方式',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'monthly', child: Text('月給')),
                        DropdownMenuItem(value: 'daily',   child: Text('日給')),
                        DropdownMenuItem(value: 'hourly',  child: Text('時給')),
                        DropdownMenuItem(value: 'piecework', child: Text('出来高')),
                      ],
                      onChanged: (v) => setState(() => _payType = v ?? 'hourly'),
                    ),
                    const SizedBox(height: 12),

                    // --- 金額フィールド（方式に応じて1つだけ活性化） ---
                    if (_showMonthly)
                      TextFormField(
                        controller: _monthlyCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: '月給（円）',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (_showMonthly && (v == null || v.trim().isEmpty)) {
                            return '月給を入力してください';
                          }
                          return null;
                        },
                      ),
                    if (_showDaily)
                      TextFormField(
                        controller: _dailyCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: '日給（円）',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (_showDaily && (v == null || v.trim().isEmpty)) {
                            return '日給を入力してください';
                          }
                          return null;
                        },
                      ),
                    if (_showHourly)
                      TextFormField(
                        controller: _hourlyCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: '時給（円）',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (_showHourly && (v == null || v.trim().isEmpty)) {
                            return '時給を入力してください';
                          }
                          return null;
                        },
                      ),
                    if (_showPiece)
                      TextFormField(
                        controller: _pieceworkCtrl,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: '出来高スキーマ（JSON）',
                          hintText: '{"key":"value"}',
                          border: OutlineInputBorder(),
                        ),
                      ),

                    const SizedBox(height: 12),

                    // --- 有効期間 ---
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => _pickDate(from: true),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    '有効開始日: ${_d(_effectiveFrom)}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.calendar_month),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => _pickDate(from: false),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    '有効終了日: ${_d(_effectiveTo)}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.calendar_month),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    _effectiveDatesHelp(),

                    const SizedBox(height: 12),

                    // --- 会社ポリシー上書き ---
                    SwitchListTile.adaptive(
                      value: _overrideCompany,
                      onChanged: (v) => setState(() => _overrideCompany = v),
                      title: const Text('会社共通ルールを上書きする'),
                      subtitle: const Text('ONのときは残業/深夜の倍率を個別設定'),
                      contentPadding: EdgeInsets.zero,
                    ),

                    if (_overrideCompany) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _otRateCtrl,
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: '残業倍率（例: 1.25）',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _nightRateCtrl,
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: '深夜倍率（例: 1.25）',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),

                    // 保存ボタン（削除なし）
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : () => _onSave(summary),
                        icon: _saving
                            ? const SizedBox(
                                height: 18, width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save),
                        label: Text(_saving ? '保存中…' : '保存'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ラベル風チップ
  Widget _pill(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
