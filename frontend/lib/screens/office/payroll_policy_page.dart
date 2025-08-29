import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/office/payroll_policy_model.dart';
import 'package:frontend/providers/office/payroll_policy_provider.dart';
import 'package:frontend/widgets/schedule_widget/time_picker_modal.dart';

class PayrollPolicyPage extends ConsumerStatefulWidget {
  const PayrollPolicyPage({super.key});
  @override
  ConsumerState<PayrollPolicyPage> createState() => _PayrollPolicyPageState();
}

class _PayrollPolicyPageState extends ConsumerState<PayrollPolicyPage> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(payrollPolicyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('会社設定'),
        actions: [
          if (state is AsyncData<PayrollPolicyModel>)
            TextButton(
              onPressed: _saving ? null : () => _onSave(state.value),
              child: _saving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('保存'),
            ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('読み込み失敗: $e')),
        data: (model) => Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ===========================
              // ★ ここから「締日・支払日」セクション（追加）
              // ===========================
              Text('締日・支払日', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),

              _Dropdown<int>(
                label: '締日',
                // null セーフに 0(月末) を既定に
                value: model.closingDay ?? 0,
                items: _closingDayItems(),
                onChanged: (v) => setState(() => model.closingDay = v ?? 0),
              ),
              const SizedBox(height: 12),

              _Dropdown<int>(
                label: '支払日',
                value: model.payDay ?? 0,
                items: _closingDayItems(),
                onChanged: (v) => setState(() => model.payDay = v ?? 0),
              ),
              const SizedBox(height: 12),

              _Dropdown<int>(
                label: '支払月',
                value: model.payMonthOffset ?? 1,
                items: const [
                  DropdownMenuItem(value: 0, child: Text('当月')),
                  DropdownMenuItem(value: 1, child: Text('翌月')),
                  DropdownMenuItem(value: 2, child: Text('翌々月')),
                ],
                onChanged: (v) => setState(() => model.payMonthOffset = v ?? 1),
              ),

              const SizedBox(height: 8),
              Text(
                '例: 締日15日 + 支払月=翌月 + 支払日=月末 → 翌月末に支払い',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),

              const SizedBox(height: 16),
              const Divider(height: 32),
              // ===========================
              // ★ ここまで追加
              // ===========================

              _NumberField(
                label: '丸め単位(分)',
                initial: model.timeGranularityMinutes.toString(),
                onSaved: (v) => model.timeGranularityMinutes = int.tryParse(v ?? '') ?? 15,
              ),
              const SizedBox(height: 12),

              _Dropdown<String>(
                label: '丸め方法',
                value: model.roundingMode,
                items: const [
                  DropdownMenuItem(value: 'nearest', child: Text('四捨五入')),
                  DropdownMenuItem(value: 'up', child: Text('切り上げ')),
                  DropdownMenuItem(value: 'down', child: Text('切り捨て')),
                ],
                onChanged: (v) => setState(() => model.roundingMode = v ?? 'nearest'),
              ),

              const Divider(height: 32),

              Text('休憩時間設定', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...model.breaks.asMap().entries.map((e) {
                final idx = e.key;
                final b = e.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0), // 行間にゆとり
                  child: Row(
                    children: [
                      Expanded(child: _TimeField(label: '開始', initial: b.start, onChanged: (v) => b.start = v)),
                      const SizedBox(width: 12),
                      Expanded(child: _TimeField(label: '終了', initial: b.end, onChanged: (v) => b.end = v)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => setState(() => model.breaks.removeAt(idx)),
                      ),
                    ],
                  ),
                );
              }),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('休憩を追加'),
                  onPressed: () => setState(() => model.breaks.add(BreakWindow(start: '10:00', end: '10:30'))),
                ),
              ),

              const Divider(height: 32),
              Text('残業 / 深夜', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              _TimeField(
                label: '残業開始時刻',
                initial: model.overtimeStartsAt.substring(0, 5),
                onChanged: (v) => model.overtimeStartsAt = _hhmmToHhmmss(v),
              ),
              const SizedBox(height: 12),
              _NumberField(
                label: '残業倍率',
                initial: model.overtimeRateMultiplier,
                onSaved: (v) => model.overtimeRateMultiplier = (v ?? '1.25'),
              ),
              const SizedBox(height: 12),
              _TimeField(
                label: '深夜開始',
                initial: model.nightStartsAt.substring(0, 5),
                onChanged: (v) => model.nightStartsAt = _hhmmToHhmmss(v),
              ),
              const SizedBox(height: 12),
              _TimeField(
                label: '深夜終了',
                initial: model.nightEndsAt.substring(0, 5),
                onChanged: (v) => model.nightEndsAt = _hhmmToHhmmss(v),
              ),
              const SizedBox(height: 12),
              _NumberField(
                label: '深夜倍率',
                initial: model.nightRateMultiplier,
                onSaved: (v) => model.nightRateMultiplier = (v ?? '1.25'),
              ),

              const Divider(height: 32),
              Text('休日（会社の運用ルール）', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: [
                  _check('日', model.weekly.sun, (v) => setState(() => model.weekly.sun = v)),
                  _check('月', model.weekly.mon, (v) => setState(() => model.weekly.mon = v)),
                  _check('火', model.weekly.tue, (v) => setState(() => model.weekly.tue = v)),
                  _check('水', model.weekly.wed, (v) => setState(() => model.weekly.wed = v)),
                  _check('木', model.weekly.thu, (v) => setState(() => model.weekly.thu = v)),
                  _check('金', model.weekly.fri, (v) => setState(() => model.weekly.fri = v)),
                  _check('土', model.weekly.sat, (v) => setState(() => model.weekly.sat = v)),
                  _check('祝', model.weekly.holiday, (v) => setState(() => model.weekly.holiday = v)),
                ],
              ),
              const SizedBox(height: 8),

              Text('イレギュラー休業日（追加/削除）'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final d in model.customHolidays)
                    InputChip(
                      label: Text(d),
                      onDeleted: () => setState(() => model.customHolidays.remove(d)),
                    ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('日付追加'),
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: now,
                        firstDate: DateTime(now.year - 1, 1, 1),
                        lastDate: DateTime(now.year + 2, 12, 31),
                      );
                      if (picked != null) {
                        final s =
                            '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                        setState(() => model.customHolidays.add(s));
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),
              TextFormField(
                initialValue: model.notes,
                maxLines: 3,
                decoration: const InputDecoration(labelText: '備考'),
                onSaved: (v) => model.notes = v ?? '',
              ),
              const SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }

  // --- ヘルパ: 「月末/1〜28日」の選択肢生成（★追加） ---
  List<DropdownMenuItem<int>> _closingDayItems() {
    final items = <DropdownMenuItem<int>>[
      const DropdownMenuItem(value: 0, child: Text('月末')),
    ];
    for (var d = 1; d <= 28; d++) {
      items.add(DropdownMenuItem(value: d, child: Text('$d日')));
    }
    return items;
  }

  Widget _check(String label, bool v, void Function(bool) onChanged) {
    return FilterChip(
      label: Text(label),
      selected: v,
      onSelected: (x) => onChanged(x),
    );
  }

  Future<void> _onSave(PayrollPolicyModel m) async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _saving = true);
    try {
      await ref.read(payrollPolicyProvider.notifier).save(m);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('保存しました')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('保存失敗: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _hhmmToHhmmss(String v) {
    final parts = v.split(':');
    if (parts.length >= 2) return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}:00';
    return '00:00:00';
  }
}

class _NumberField extends StatelessWidget {
  final String label;
  final String? initial;
  final FormFieldSetter<String>? onSaved;
  const _NumberField({required this.label, this.initial, this.onSaved});
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initial,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
      onSaved: onSaved,
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const _Dropdown({required this.label, required this.value, required this.items, required this.onChanged, super.key});
  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: DropdownButton<T>(
        isExpanded: true,
        value: value,
        items: items,
        onChanged: onChanged,
        underline: const SizedBox.shrink(),
      ),
    );
  }
}

class _TimeField extends StatefulWidget {
  final String label;
  final String initial; // 'HH:MM'
  final ValueChanged<String> onChanged;
  const _TimeField({required this.label, required this.initial, required this.onChanged, super.key});
  @override
  State<_TimeField> createState() => _TimeFieldState();
}

class _TimeFieldState extends State<_TimeField> {
  late String val;
  @override
  void initState() {
    super.initState();
    val = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      controller: TextEditingController(text: val),
      decoration: InputDecoration(labelText: widget.label, suffixIcon: const Icon(Icons.access_time)),
      onTap: () {
        final parts = val.split(':');
        final now = DateTime.now();
        final init = DateTime(
          now.year,
          now.month,
          now.day,
          int.tryParse(parts[0]) ?? 0,
          int.tryParse(parts[1]) ?? 0,
        );

        showTimePickerModal(
          context: context,
          initialDateTime: init,
          onTimePicked: (dt) {
            final s = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
            setState(() => val = s);
            widget.onChanged(s);
            // Navigator.of(context).pop(); // すぐ閉じたい場合は有効化
          },
        );
      },
    );
  }
}

