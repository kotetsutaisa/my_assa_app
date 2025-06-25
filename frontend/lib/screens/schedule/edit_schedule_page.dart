import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/schedule_model.dart';
import 'package:frontend/models/site_model.dart';
import 'package:frontend/models/work_category_model.dart';
import 'package:frontend/providers/my_personal_schedule_provider.dart';
import 'package:frontend/providers/work_category_provider.dart';
import 'package:frontend/widgets/schedule_widget/date_dropdown_picker.dart';
import 'package:frontend/widgets/schedule_widget/label_with_button_row.dart';
import 'package:frontend/widgets/schedule_widget/label_with_widget_row.dart';
import 'package:frontend/widgets/schedule_widget/site_selector_modal.dart';
import 'package:frontend/widgets/schedule_widget/time_picker_modal.dart';
import 'package:frontend/widgets/schedule_widget/work_selector_model.dart';
import 'package:intl/intl.dart';

class EditSchedulePage extends ConsumerStatefulWidget {
  final ScheduleModel schedule;
  const EditSchedulePage({super.key, required this.schedule});

  @override
  ConsumerState<EditSchedulePage> createState() => _EditSchedulePage();
}

class _EditSchedulePage extends ConsumerState<EditSchedulePage> {
  late SiteModel? _selectedSite;
  late WorkCategoryModel? _selectedWorkCategory;
  late DateTime _selectedStartDate;
  late DateTime _selectedEndDate;

  late DateTime _startTime;
  late DateTime _endTime;

  @override
  void initState() {
    super.initState();
    final sch = widget.schedule;
    _selectedSite = sch.site;
    _selectedWorkCategory = sch.workCategory;
    _selectedStartDate = sch.startTime;
    _selectedEndDate   = sch.endTime;
    _startTime         = sch.startTime;
    _endTime           = sch.endTime;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          '編集',
          style: Theme.of(context).textTheme.titleLarge,
        ),
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
              try {
                // ---------- 必須チェック ----------
                if (_selectedSite == null) {
                  _showError('現場は必須です');
                  return;
                }
                if (_selectedWorkCategory == null) {
                  _showError('作業内容は必須です');
                  return;
                }

                // ---------- 開始／終了 DateTime を合成 ----------
                final startDateTime = DateTime(
                  _selectedStartDate.year,
                  _selectedStartDate.month,
                  _selectedStartDate.day,
                  _startTime.hour,
                  _startTime.minute,
                );

                final endDateTime = DateTime(
                  _selectedEndDate.year,
                  _selectedEndDate.month,
                  _selectedEndDate.day,
                  _endTime.hour,
                  _endTime.minute,
                );

                if (!endDateTime.isAfter(startDateTime)) {
                  _showError('終了日時は開始日時より後にしてください');
                  return;
                }

                // ---------- 追加 API 呼び出し（StateNotifier 経由） ----------
                await ref.read(myPersonalScheduleMapProvider.notifier).updateSchedule(
                  id                  : widget.schedule.id,
                  selectedSite        : _selectedSite!,
                  selectedWorkCategory: _selectedWorkCategory!,
                  selectedStartDate   : _selectedStartDate,
                  startTime           : _startTime,
                  selectedEndDate     : _selectedEndDate,
                  endTime             : _endTime,
                );

                if (mounted) Navigator.pop(context);          // 登録成功 → 画面を閉じる
              } catch (e) {
                _showError('登録に失敗しました: $e');
              }
            },
            child: Text(
              '変更',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),

      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Center(
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      LabelWithButtonRow(
                        label: '現場',
                        value: _selectedSite?.name ?? widget.schedule.siteName,
                        onTap: () {
                          showSiteSelectorModal(
                            context: context,
                            onSelected: (site) {
                              setState(() {
                                _selectedSite = site;
                              });
                            },
                          );
                        },
                      ),
                      const Divider(),
                      LabelWithButtonRow(
                        label: '作業内容',
                        value: _selectedWorkCategory?.name ?? widget.schedule.workCategory!.name,
                        onTap: () async {
                          await showWorkSelectorModal(
                            context: context,
                            onSelected: (work) {
                              setState(() {
                                _selectedWorkCategory = work;
                              });
                            }
                          );
                          // モーダル閉じた後にカテゴリ一覧から削除されていないか確認
                          final workCategories = ref.read(workCategoryListProvider).value ?? [];
                          final exists = workCategories.any((w) => w.id == _selectedWorkCategory?.id);

                          if (!exists) {
                            setState(() {
                              _selectedWorkCategory = null; // 削除されていたらクリア
                            });
                          }
                        }
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32),

                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

                  child: Column(
                    children: [

                      // ----- 開始日 -----
                      LabelWithWidgetRow(
                        label: '開始日',
                        time: Text(
                          DateFormat.Hm().format(_startTime),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        onTimeTap: () {
                          showTimePickerModal(
                            context: context,
                            initialDateTime: _startTime,
                            onTimePicked: (newTime) {
                              setState(() => _startTime = newTime);
                            },
                          );
                        },
                        child: DateDropdownPicker(
                          selectedDate: _selectedStartDate,
                          onDateSelected: (date) {
                            setState(() {
                              _selectedStartDate = date;
                            });
                          },
                        ),
                      ),
                      const Divider(),

                      // ----- 終了日 -----
                      LabelWithWidgetRow(
                        label: '終了日',
                        time: Text(
                          DateFormat.Hm().format(_endTime),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        onTimeTap: () {
                          showTimePickerModal(
                            context: context,
                            initialDateTime: _endTime,
                            onTimePicked: (newTime) {
                              setState(() => _endTime = newTime);
                            },
                          );
                        },
                        child: DateDropdownPicker(
                          selectedDate: _selectedEndDate,
                          onDateSelected: (date) {
                            setState(() => _selectedEndDate = date);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}