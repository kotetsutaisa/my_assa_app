import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/constants/site_colors.dart';
import 'package:frontend/models/schedule_model.dart';
import 'package:frontend/providers/my_personal_schedule_provider.dart';
import 'package:frontend/providers/selected_date_provider.dart';
import 'package:frontend/screens/schedule/edit_schedule_page.dart';
import 'package:frontend/utils/holiday_data.dart';
import 'package:frontend/utils/site_color_util.dart';
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
  static const _rowH   = 85.0;
  static const _circle = 28.0;

  DateTime _focused  = DateTime.now();
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
    final key = _selected != null ? DateUtils.dateOnly(_selected!) : null;

    final todays = key == null
        ? <ScheduleModel>[]
        : map.entries                        // ① 全キーを走査
            .expand((e) => e.value)          // ② 予定を 1 本ずつ取り出す
            .where((s) {                     // ③ 開始〜終了の間に key がある？
              final start = DateUtils.dateOnly(s.startTime);
              final end   = DateUtils.dateOnly(s.endTime);
              return !key.isBefore(start) && !key.isAfter(end);
            })
            .toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ---------- カレンダー ----------
        SliverToBoxAdapter(
          child: TableCalendar<ScheduleModel>(
            locale: 'ja_JP',
            firstDay : DateTime.utc(2020, 1, 1),
            lastDay  : DateTime.utc(2030, 12, 31),
            focusedDay: _focused,
            selectedDayPredicate: (d) => isSameDay(_selected, d),
            rowHeight: _rowH,
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const { CalendarFormat.month: '月', },
            eventLoader: (d) => map[DateUtils.dateOnly(d)] ?? [],
            onPageChanged: _onPageChanged,
            onDaySelected: (sel, foc) {
              // ❶ 共有プロバイダーを書き換え
              ref.read(selectedDateProvider.notifier).state = sel;

              // ❷ 既存のローカル状態も更新
              setState(() {
                _selected = sel;
                _focused  = foc;
              });
            },
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarBuilders: CalendarBuilders<ScheduleModel>(
              dowBuilder      : _buildDow,
              defaultBuilder  : (ctx, d, f) => _buildNum(ctx, d),
              todayBuilder    : (ctx, d, f) => _buildCircle(ctx, d, Colors.orange),
              selectedBuilder : (ctx, d, f) => _buildCircle(ctx, d, Colors.blue),
              markerBuilder   : _buildSiteNameMarker,
            ),
          ),
        ),

        const SliverPadding(padding: EdgeInsets.only(top: 12)),

        // ---------- 詳細リスト ----------
        todays.isEmpty
            ? const SliverToBoxAdapter(
                child: Center(
                  heightFactor: 4,
                  child: Text('予定なし', style: TextStyle(color: Colors.grey)),
                ),
              )
            : SliverList.separated(
                itemCount: todays.length,
                itemBuilder: (context, index) {
                  final s = todays[index];
                  final tf = DateFormat('HH:mm');
                  return ListTile(
                    leading: IconButton(
                      icon: const Icon(Icons.more_horiz),
                      onPressed: () => _showActions(context, s),
                    ),
                    title: Text(s.siteName),
                    subtitle: Text(
                      '${tf.format(s.startTime)} - ${tf.format(s.endTime)}'
                      '${s.workCategory != null ? ' ・ ${s.workCategory!.name}' : ''}',
                    ),
                  );
                },
                separatorBuilder: (_, __) => const Divider(height: 1),
              ),
      ],
    );
  }

  /* ───────── helpers ───────── */

  void _onPageChanged(DateTime focusedDay) {
    setState(() => _focused = focusedDay);

    final start = DateTime(focusedDay.year, focusedDay.month, 1);
    final end   = DateTime(focusedDay.year, focusedDay.month + 1, 0);
    ref.read(myPersonalScheduleMapProvider.notifier).fetch(start, end);
  }

  void _showActions(BuildContext ctx, ScheduleModel s) => showScheduleActionSheet(
    context : ctx,
    schedule: s,
    onEdit  : () => Navigator.push(ctx,
        MaterialPageRoute(builder: (_) => EditSchedulePage(schedule: s))),
    onDelete: () async {
      await ref.read(myPersonalScheduleMapProvider.notifier).deleteSchedule(s.id);
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('${s.siteName} を削除しました')),
        );
      }
    },
  );

  /* ───────── calendar builders ───────── */

  Widget _buildDow(BuildContext ctx, DateTime d) {
    const labels = ['月','火','水','木','金','土','日'];
    final c = d.weekday == 7
          ? Colors.red
          : d.weekday == 6 ? Colors.blue : Colors.black87;
    return Center(
      child: Text(labels[d.weekday - 1],
          style: TextStyle(color: c, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildNum(BuildContext ctx, DateTime d) {
    final c = (isJapaneseHoliday(d) || d.weekday == 7)
        ? Colors.red
        : d.weekday == 6 ? Colors.blue : Colors.black87;
    return Center(child: Text('${d.day}', style: TextStyle(color: c)));
  }

  Widget _buildCircle(BuildContext ctx, DateTime d, Color c) {
    return Center(
      child: Container(
        width: _circle,
        height: _circle,
        decoration: BoxDecoration(shape: BoxShape.circle, color: c),
        alignment: Alignment.center,
        child: Text('${d.day}', style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  /// ---------- ラベル描画: 2 件までは全部、3 件以上は 1 件＋ …+n ----------
  Widget _buildSiteNameMarker(
    BuildContext ctx,
    DateTime day,
    List<ScheduleModel> ev,
  ) {
    if (ev.isEmpty) return const SizedBox.shrink();

    const pillW    = 48.0;
    const fontSize = 8.0;

    final pills = <Widget>[];

    /* ① 何件まで文字チップを出すか決定 */
    final showCount = ev.length <= 2 ? ev.length : 1;

    /* ② 表示対象分だけチップを生成 */
    for (final s in ev.take(showCount)) {
      final id    = s.site.id;
      final color = (id != null && id.isNotEmpty)
          ? siteColor(id)
          : siteColorPalette.first;

      pills.add(Container(
        width      : pillW,
        alignment  : Alignment.center,
        padding    : const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
        margin     : const EdgeInsets.only(bottom: 1),
        decoration : BoxDecoration(
          color: color.withOpacity(0.20),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          s.siteName,
          maxLines : 1,
          overflow : TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style    : TextStyle(fontSize: fontSize, color: color, height: 1.1),
        ),
      ));
    }

    /* ③ もし 3 件以上あれば “…+n” を追加 */
    if (ev.length > 2) {
      pills.add(Container(
        width      : pillW,
        alignment  : Alignment.center,
        padding    : const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
        margin     : const EdgeInsets.only(bottom: 1),
        decoration : BoxDecoration(
          color: Colors.grey.withOpacity(0.20),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '…+${ev.length - 1}',
          style: const TextStyle(fontSize: fontSize, color: Colors.grey),
        ),
      ));
    }

    return Positioned(
      bottom : 2,
      left   : 2,
      right  : 2,
      child  : Wrap(
        spacing   : 2,
        runSpacing: 1,
        alignment : WrapAlignment.center,
        children  : pills,
      ),
    );

    // return IgnorePointer(
    //   child: Align(
    //     alignment: Alignment.bottomCenter,
    //     child: Padding(
    //       padding: const EdgeInsets.fromLTRB(2, 0, 2, 2),
    //       child: Wrap(
    //         spacing   : 2,
    //         runSpacing: 1,
    //         alignment : WrapAlignment.center,
    //         children  : pills,
    //       ),
    //     ),
    //   ),
    // );
  }
}





