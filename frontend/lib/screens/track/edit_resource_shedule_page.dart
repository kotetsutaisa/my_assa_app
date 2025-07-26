import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/models/schedule_model.dart';
import 'package:frontend/models/site_model.dart';
import 'package:frontend/models/member_model.dart';                 // 運転手 = 既存 MemberModel を流用
import 'package:frontend/providers/team_member_provider.dart';      // 運転手一覧取得に流用
import 'package:frontend/providers/resource_schedule_provider.dart';// ★ 変更: リソース用 StateNotifier
import 'package:frontend/utils/constants.dart';
import 'package:frontend/widgets/schedule_widget/date_dropdown_picker.dart';
import 'package:frontend/widgets/schedule_widget/label_with_button_row.dart';
import 'package:frontend/widgets/schedule_widget/label_with_widget_row.dart';
import 'package:frontend/widgets/schedule_widget/site_selector_modal.dart';
import 'package:frontend/widgets/schedule_widget/time_picker_modal.dart';
import 'package:intl/intl.dart';

/// ★ 変更: リソーススケジュール編集ページ
class EditResourceSchedulePage extends ConsumerStatefulWidget {
  final ScheduleModel schedule;
  const EditResourceSchedulePage({super.key, required this.schedule});

  @override
  ConsumerState<EditResourceSchedulePage> createState() => _EditResourceSchedulePageState();
}

class _EditResourceSchedulePageState extends ConsumerState<EditResourceSchedulePage> {
  /* ── 選択中データ ── */
  late SiteModel? _selectedSite;
  // ★ 削除: WorkCategory は不要
  late final _selectedDrivers = <MemberModel>[]; // ★ 変更: メンバー → 運転手

  late DateTime _selectedStartDate;
  late DateTime _selectedEndDate;
  late DateTime _startTime;
  late DateTime _endTime;

  late final String _resourceId;              // ★ 追加: family Provider のキー用
  late final String _resourceName;            // ★ 追加: タイトル表示用

  @override
  void initState() {
    super.initState();
    final sch = widget.schedule;

    // ★ リソース情報取得（ScheduleModel 側の名前に合わせて適宜修正）
    _resourceId   = sch.resource?.id ?? '';     // resourceId プロパティ前提
    _resourceName = sch.resource?.name ?? '';   // resourceName が無ければ表示を工夫

    _selectedSite      = sch.site;
    _selectedStartDate = sch.startTime;
    _selectedEndDate   = sch.endTime;
    _startTime         = sch.startTime;
    _endTime           = sch.endTime;

    // ★ 運転手初期化（SimpleUserModel → MemberModel）
    _selectedDrivers.addAll(
      sch.members.map((u) => MemberModel(id: u.id.toString(), name: u.username, avatarUrl: u.iconimg)),
    );
  }

  /* ── 共通 util ── */
  void _showError(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  String _resolveImageUrl(String path) {
    if (path.startsWith('http')) return path;
    final base = apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    return '$base$path';
  }

  /* ── 運転手選択モーダル ── */
  Future<void> _showDriverSelector() async {
    final all = await ref.read(teamMemberListProvider.future); // 既存流用

    final result = await showModalBottomSheet<List<MemberModel>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final temp = [..._selectedDrivers];
        return StatefulBuilder(builder: (ctx, setModal) {
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
                Text('運転手を選択', style: Theme.of(ctx).textTheme.titleMedium), // ★ 変更
                const Divider(),
                SizedBox(
                  height: 360,
                  child: ListView.builder(
                    itemCount: all.length,
                    itemBuilder: (_, i) {
                      final m = all[i];
                      final checked    = temp.any((e) => e.id == m.id);
                      final hasAvatar  = m.avatarUrl?.isNotEmpty ?? false;

                      return CheckboxListTile(
                        secondary: CircleAvatar(
                          radius: 18,
                          backgroundImage: hasAvatar
                              ? CachedNetworkImageProvider(_resolveImageUrl(m.avatarUrl!))
                              : null,
                          backgroundColor: hasAvatar
                              ? null
                              : Theme.of(context).colorScheme.primary,
                          child: hasAvatar
                              ? null
                              : const Icon(Icons.person, color: Colors.white, size: 18),
                        ),
                        title: Text(m.name),
                        value: checked,
                        onChanged: (v) => setModal(() {
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

    if (result != null) setState(() {
      _selectedDrivers
        ..clear()
        ..addAll(result);
    });
  }

  /* ── build ── */
  @override
  Widget build(BuildContext context) {
    final driverLabel = _selectedDrivers.isEmpty ? '運転手を選択' : '${_selectedDrivers.length}名';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title : Text('${_resourceName} 予定編集', style: Theme.of(context).textTheme.titleLarge), // ★ 変更
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Theme.of(context).colorScheme.outline),
        ),
        actions: [
          TextButton(
            child: Text('変更', style: Theme.of(context).textTheme.bodyLarge),
            onPressed: _save,
          ),
        ],
      ),

      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              /* ── 上段カード ── */
              _InfoCard(children: [
                // ▼ リソース表示（編集不可）
                LabelWithButtonRow(
                  label: 'リソース',
                  value: _resourceName.isEmpty ? 'リソース' : _resourceName,
                  onTap : () {},                              // ★ 変更: ダミーで空関数
                ),
                const Divider(),

                // ▼ 現場選択（必須）
                LabelWithButtonRow(
                  label: '現場',
                  value: _selectedSite?.name ?? widget.schedule.siteName,
                  onTap : () => showSiteSelectorModal(
                    context: context,
                    onSelected: (s) => setState(() => _selectedSite = s),
                  ),
                ),
                const Divider(),

                // ▼ 運転手選択
                LabelWithButtonRow(
                  label: '運転手',
                  value: driverLabel,
                  onTap : _showDriverSelector,
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
                            backgroundColor: hasAvatar ? null : Theme.of(context).colorScheme.primary,
                            backgroundImage: hasAvatar
                                ? CachedNetworkImageProvider(_resolveImageUrl(m.avatarUrl!))
                                : null,
                            child: hasAvatar
                                ? null
                                : Icon(Icons.person,
                                    color: Colors.white,
                                    size: 20),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 48,
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

              /* ── 下段カード ── */
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

  /* ── 保存処理 ── */
  Future<void> _save() async {
    if (_selectedSite == null) return _showError('現場は必須です');   // ★ 変更: 作業内容チェック削除

    final start = DateTime(_selectedStartDate.year, _selectedStartDate.month, _selectedStartDate.day,
                           _startTime.hour, _startTime.minute);
    final end   = DateTime(_selectedEndDate.year, _selectedEndDate.month, _selectedEndDate.day,
                           _endTime.hour, _endTime.minute);
    if (!end.isAfter(start)) return _showError('終了日時は開始日時より後にしてください');

    try {
      await ref.read(resourceScheduleMapProvider(_resourceId).notifier).updateSchedule(
        id                : widget.schedule.id,
        selectedSite      : _selectedSite!,
        memberIds         : _selectedDrivers.map((e) => e.id).toList(), // ★ 変更: 運転手ID
        selectedStartDate : _selectedStartDate,
        startTime         : _startTime,
        selectedEndDate   : _selectedEndDate,
        endTime           : _endTime,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('更新に失敗しました: $e');
    }
  }
}

/* ── 共通カード ── */
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
