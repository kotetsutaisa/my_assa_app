import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/resource_model.dart';
import 'package:frontend/models/site_model.dart';
import 'package:frontend/models/member_model.dart';               // ★ メンバーモデル
import 'package:frontend/providers/resource_schedule_provider.dart';
import 'package:frontend/providers/team_member_provider.dart';    // ★ 一覧取得プロバイダー
import 'package:frontend/utils/add_schedule_helper.dart';
import 'package:frontend/utils/constants.dart';

import 'package:frontend/widgets/schedule_widget/date_dropdown_picker.dart';
import 'package:frontend/widgets/schedule_widget/label_with_button_row.dart';
import 'package:frontend/widgets/schedule_widget/label_with_widget_row.dart';
import 'package:frontend/widgets/schedule_widget/site_selector_modal.dart';
import 'package:frontend/widgets/schedule_widget/time_picker_modal.dart';

import 'package:intl/intl.dart';


class CreateResourceSchedulePage extends ConsumerStatefulWidget {
  
  final ResourceModel resource;
  /// カレンダーでタップした日。指定が無ければ「今日」
  final DateTime initialDate;
  CreateResourceSchedulePage({super.key, required this.resource, DateTime? initialDate})
    : initialDate = initialDate ?? DateTime.now();

  @override
  ConsumerState<CreateResourceSchedulePage> createState() => _CreateResourceSchedulePage();
}

class _CreateResourceSchedulePage extends ConsumerState<CreateResourceSchedulePage> {
  /* ─── 選択中データ ─── */
  SiteModel?             _selectedSite;
  final _selectedDrivers = <MemberModel>[];

  // DateTime _selectedStartDate = DateTime.now();
  // DateTime _selectedEndDate   = DateTime.now();
  // DateTime _startTime = DateTime.now().copyWith(hour: 8,  minute: 0);
  // DateTime _endTime   = DateTime.now().copyWith(hour: 17, minute: 0);

  late DateTime _selectedStartDate;
  late DateTime _selectedEndDate;
  late DateTime _startTime;
  late DateTime _endTime;

  @override
  void initState() {
    super.initState();

    // カレンダーで選んだ日（＝ widget.initialDate）を使う
    final d = widget.initialDate;

    _selectedStartDate = d;
    _selectedEndDate   = d;

    // 8:00 – 17:00 も同じ日付で初期化
    _startTime = DateTime(d.year, d.month, d.day, 8);
    _endTime   = DateTime(d.year, d.month, d.day, 17);
  }

  void _showError(String msg) =>
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(msg)));


  String resolveImageUrl(String path) {
    if (path.startsWith('http')) return path;
    final base = apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    return '$base$path';
  }

  /* ─── メンバーセレクター ─── */
  Future<void> _showMemberSelector() async {
    final allMembers = await ref.read(teamMemberListProvider.future);

    final result = await showModalBottomSheet<List<MemberModel>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final temp = [..._selectedDrivers];              // 選択状態をモーダル内で複製
        return StatefulBuilder(builder: (ctx, setStateModal) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text('運転手を選択', style: Theme.of(ctx).textTheme.titleMedium),
                const Divider(),
                SizedBox(
                  height: 360,
                  child: ListView.builder(
                    itemCount: allMembers.length,
                    itemBuilder: (_, i) {
                      final m = allMembers[i];
                      final checked = temp.any((e) => e.id == m.id);

                      final avatar = CircleAvatar(
                        radius: 18,
                        backgroundImage: (m.avatarUrl != null && m.avatarUrl!.isNotEmpty)
                            ? CachedNetworkImageProvider(resolveImageUrl(m.avatarUrl!))
                            : null,
                        child: (m.avatarUrl == null || m.avatarUrl!.isEmpty)
                            ? Text(m.name.characters.first,
                                style: const TextStyle(color: Colors.white))
                            : null,
                      );

                      return CheckboxListTile(
                        secondary       : avatar,
                        title: Text(m.name),
                        value: checked,
                        onChanged: (v) => setStateModal(() {
                          v == true ? temp.add(m) : temp.removeWhere((e) => e.id == m.id);
                        }),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                Row(
                  children: [
                    Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル'))),
                    Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx, temp), child: const Text('決定'))),
                  ],
                )
              ],
            ),
          );
        });
      },
    );

    if (result != null) setState(() { _selectedDrivers
      ..clear()
      ..addAll(result);
    });
  }

  /* ─── build ─── */
  @override
  Widget build(BuildContext context) {
    final memberLabel = _selectedDrivers.isEmpty
        ? 'メンバーを選択'
        : '${_selectedDrivers.length}名';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('${widget.resource.name} 予定',
          style: Theme.of(context).textTheme.titleLarge),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Theme.of(context).colorScheme.outline),
        ),
        actions: [
          TextButton(
            child: Text('追加', style: Theme.of(context).textTheme.bodyLarge),
            onPressed: () async {
              /* ---- バリデーション ---- */
              if (_selectedSite == null)          return _showError('現場は必須です');

              final start = DateTime(_selectedStartDate.year, _selectedStartDate.month, _selectedStartDate.day,
                                     _startTime.hour, _startTime.minute);
              final end   = DateTime(_selectedEndDate.year,   _selectedEndDate.month,   _selectedEndDate.day,
                                     _endTime.hour,   _endTime.minute);
              if (!end.isAfter(start)) return _showError('終了日時は開始日時より後にしてください');

              try {
                await addScheduleWithConfirm(
                  context: context,
                  request: ({bool force = false}) async {
                    await ref.read(resourceScheduleMapProvider(widget.resource.id).notifier).addSchedule(
                      selectedSite        : _selectedSite!,
                      memberIds           : _selectedDrivers.map((e) => e.id).toList(),
                      selectedStartDate   : _selectedStartDate,
                      startTime           : _startTime,
                      selectedEndDate     : _selectedEndDate,
                      endTime             : _endTime,
                      force               : force,
                    );
                  },
                );
                if (mounted) Navigator.pop(context);
              } catch (e) {
                _showError('登録に失敗しました: $e');
              }
            },
          ),
        ],
      ),

      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              /* ── 上段 ── */
              _InfoCard(children: [
                // リソース名（固定表示）
                LabelWithButtonRow(
                  label: '車両',
                  value: widget.resource.name,
                  onTap: () {},   // 編集不可
                ),
                const Divider(),
                LabelWithButtonRow(
                  label: '現場',
                  value: _selectedSite?.name ?? '現場を選択',
                  onTap : () => showSiteSelectorModal(
                    context: context,
                    onSelected: (s) => setState(() => _selectedSite = s),
                  ),
                ),
                const Divider(),
                LabelWithButtonRow(
                  label: '運転手',
                  value: memberLabel,
                  onTap : _showMemberSelector,
                ),

                if (_selectedDrivers.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 16,
                    children: _selectedDrivers.map((m) {
                      final hasAvatar = (m.avatarUrl?.isNotEmpty ?? false);
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: hasAvatar
                                ? null
                                : Colors.white,
                            backgroundImage: hasAvatar
                                ? CachedNetworkImageProvider(
                                    resolveImageUrl(m.avatarUrl!),      // ここは hasAvatar が true
                                  )
                                : null,
                            child: hasAvatar
                                ? null
                                : Icon(Icons.person,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 20,
                                  ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 48,                     // 名前が長くても折り返し
                            child: Text(
                              m.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ]),

              const SizedBox(height: 32),

              /* ── 下段 ── */
              _InfoCard(children: [
                LabelWithWidgetRow(
                  label: '開始日',
                  time : Text(DateFormat.Hm().format(_startTime),
                      style: Theme.of(context).textTheme.bodyMedium),
                  onTimeTap: () => showTimePickerModal(
                    context: context,
                    initialDateTime: _startTime,
                    onTimePicked: (t) => setState(() => _startTime = t),
                  ),
                  child: DateDropdownPicker(
                    selectedDate  : _selectedStartDate,
                    onDateSelected: (d) => setState(() => _selectedStartDate = d),
                  ),
                ),
                const Divider(),
                LabelWithWidgetRow(
                  label: '終了日',
                  time : Text(DateFormat.Hm().format(_endTime),
                      style: Theme.of(context).textTheme.bodyMedium),
                  onTimeTap: () => showTimePickerModal(
                    context: context,
                    initialDateTime: _endTime,
                    onTimePicked: (t) => setState(() => _endTime = t),
                  ),
                  child: DateDropdownPicker(
                    selectedDate  : _selectedEndDate,
                    onDateSelected: (d) => setState(() => _selectedEndDate = d),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

/* ─── シンプルな白背景カード ─── */
class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(children: children),
      );
}