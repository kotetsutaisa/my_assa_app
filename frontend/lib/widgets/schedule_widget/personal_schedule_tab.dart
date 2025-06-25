import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/schedule_model.dart';
import 'package:frontend/providers/my_personal_schedule_provider.dart';
import 'package:frontend/screens/schedule/edit_schedule_page.dart';
import 'package:frontend/utils/holiday_data.dart';
import 'package:frontend/widgets/schedule_widget/schedule_actions.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class PersonalScheduleTab extends ConsumerStatefulWidget {
  const PersonalScheduleTab({super.key});

  @override
  ConsumerState<PersonalScheduleTab> createState() => _PersonalScheduleTabState();
}

class _PersonalScheduleTabState extends ConsumerState<PersonalScheduleTab> {
  static const _rowH = 60.0;
  static const _circle = 28.0;

  DateTime _focused = DateTime.now();
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    _selected = _focused;
    initializeDateFormatting('ja_JP', null);

    final start = DateTime(_focused.year, _focused.month, 1);
    final end   = DateTime(_focused.year, _focused.month + 1, 0);
    Future.microtask(() {
      ref.read(myPersonalScheduleMapProvider.notifier).fetch(start, end);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Map<DateOnly, List<ScheduleModel>>
    final map = ref.watch(myPersonalScheduleMapProvider)
                   .maybeWhen(data: (m) => m, orElse: () => {});

    // 選択日の予定（なければ空リスト）
    final selectedKey = _selected != null ? DateUtils.dateOnly(_selected!) : null;
    final List<ScheduleModel> todays = selectedKey != null ? (map[selectedKey] ?? []) : [];

    return Column(
      children: [
        // ---------------- カレンダー ----------------
        TableCalendar<ScheduleModel>(
          locale: 'ja_JP',
          firstDay : DateTime.utc(2020, 1, 1),
          lastDay  : DateTime.utc(2030, 12, 31),
          focusedDay: _focused,
          selectedDayPredicate: (d) => isSameDay(_selected, d),
          rowHeight: _rowH,
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const { CalendarFormat.month: '月', },

          eventLoader: (day) => map[DateUtils.dateOnly(day)] ?? [],

          onDaySelected: (sel, foc) {
            setState(() { _selected = sel; _focused = foc; });
          },
          headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),

          calendarBuilders: CalendarBuilders<ScheduleModel>(
            dowBuilder: _buildDow,
            defaultBuilder : (ctx, d, f) => _buildNum(ctx, d),
            todayBuilder   : (ctx, d, f) => _buildCircle(ctx, d, Colors.orange),
            selectedBuilder: (ctx, d, f) => _buildCircle(ctx, d, Colors.blue),
            markerBuilder  : _buildSiteNameMarker,
          ),
        ),

        const SizedBox(height: 12),
        // ---------------- 詳細リスト ----------------
        Expanded(
          child: todays.isEmpty
              ? const Center(child: Text('予定なし', style: TextStyle(color: Colors.grey)))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: todays.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final s = todays[index];
                    final timeFmt = DateFormat('HH:mm');
                    return ListTile(
                      leading : const Icon(Icons.work_outline),
                      title   : Text(s.siteName),
                      subtitle: Text(
                        '${timeFmt.format(s.startTime)} - ${timeFmt.format(s.endTime)}'
                        '${s.workCategory != null ? ' ・ ${s.workCategory!.name}' : ''}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_horiz),
                        onPressed: () => showScheduleActionSheet(
                          context : context,
                          schedule: s,
                          onEdit  : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditSchedulePage(schedule: s,),
                              ),
                            );
                          },
                          onDelete: () async {
                            final notifier = ref.read(myPersonalScheduleMapProvider.notifier);
                            await notifier.deleteSchedule(s.id);

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${s.siteName} を削除しました'),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ---------- builder 共通部 ----------
  Widget _buildDow(BuildContext ctx, DateTime day) {
    final label = ['月','火','水','木','金','土','日'][day.weekday - 1];
    final c = day.weekday == 7 ? Colors.red
            : day.weekday == 6 ? Colors.blue
            : Colors.black87;
    return Center(child: Text(label, style: TextStyle(color: c, fontWeight: FontWeight.bold)));
  }

  Widget _buildNum(BuildContext ctx, DateTime day) {
    final c = (isJapaneseHoliday(day) || day.weekday == 7)
        ? Colors.red
        : day.weekday == 6 ? Colors.blue : Colors.black87;
    return Center(child: Text('${day.day}', style: TextStyle(color: c)));
  }

  Widget _buildCircle(BuildContext ctx, DateTime day, Color color) {
    return Center(
      child: Container(
        width: _circle, height: _circle,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        alignment: Alignment.center,
        child: Text('${day.day}', style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildSiteNameMarker(BuildContext ctx, DateTime day, List<ScheduleModel> ev) {
    if (ev.isEmpty) return const SizedBox.shrink();
    return Positioned(
      bottom: 2, left: 2, right: 2,
      child: Text(ev.first.siteName,
        style: const TextStyle(fontSize: 9, color: Colors.grey),
        overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
    );
  }
}




