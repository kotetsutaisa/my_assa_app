import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/constants/site_colors.dart';
import 'package:frontend/models/resource_model.dart';
import 'package:frontend/models/schedule_model.dart';
import 'package:frontend/models/simple_user_model.dart';
import 'package:frontend/providers/resource_schedule_provider.dart';
import 'package:frontend/providers/selected_resource_date_provider.dart' hide resourceScheduleMapProvider;
import 'package:frontend/providers/team_schedule_provider.dart';
import 'package:frontend/screens/track/edit_resource_shedule_page.dart';
import 'package:frontend/utils/holiday_data.dart';
import 'package:frontend/utils/image_helper.dart';
import 'package:frontend/utils/site_color_util.dart';
import 'package:frontend/widgets/schedule_widget/schedule_actions.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class ResourceScheduleWidget extends ConsumerStatefulWidget {
  final ResourceModel resource;
  const ResourceScheduleWidget({super.key, required this.resource});

  @override
  ConsumerState<ResourceScheduleWidget> createState() => _ResourceScheduleWidget();
}

class _ResourceScheduleWidget extends ConsumerState<ResourceScheduleWidget> {
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
      ref
        .read(resourceScheduleMapProvider(widget.resource.id).notifier)
        .fetch(start, end);
    });
  }

  @override
  Widget build(BuildContext context) {
    final map = ref.watch(resourceScheduleMapProvider(widget.resource.id))
                   .maybeWhen(data: (m) => m, orElse: () => {});

    final key    = _selected != null ? DateUtils.dateOnly(_selected!) : null;
    final todays = key != null ? (map[key] ?? []) : <ScheduleModel>[];

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        /* ────── カレンダー ────── */
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
              ref.read(selectedResourceDateProvider.notifier).state = sel;

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

        /* ────── 詳細リスト ────── */
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
                  final s  = todays[index];
                  final tf = DateFormat('HH:mm');

                  /* ★ メンバー情報（List<SimpleUserModel> 想定） */
                  final members = s.members;       // ← ScheduleModel にあるメンバー配列
                  /* ------------------ */

                  return ListTile(
                    isThreeLine: true,
                    leading: IconButton(
                      icon: const Icon(Icons.more_horiz),
                      onPressed: () => _showActions(context, s),
                    ),

                    /* ---- タイトル & サブタイトル ---- */
                    title   : Text(s.siteName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${tf.format(s.startTime)} - ${tf.format(s.endTime)}'
                          '${s.workCategory != null ? ' ・ ${s.workCategory!.name}' : ''}',
                        ),

                        /* ---- ↓ メンバー一覧 ↓ ---- */
                        if (members.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Wrap(
                            spacing   : 12,
                            runSpacing: 8,
                            children  : members.map<Widget>((SimpleUserModel u) {
                              final img = u.iconimg;
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: 
                                      (img != null && img.isNotEmpty) ? Colors.transparent : Theme.of(context).primaryColor,
                                    backgroundImage: (img != null && img.isNotEmpty)
                                      ? CachedNetworkImageProvider(resolveImageUrl(img))
                                      : null,
                                    child: (img == null || img.isEmpty)
                                      ? Icon(Icons.person,
                                          color: Colors.white,
                                          size: 16)
                                      : null,
                                  ),
                                  const SizedBox(height: 2),
                                  SizedBox(
                                    width: 48,
                                    child: Text(
                                      u.username,
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
                      ],
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
    ref.read(resourceScheduleMapProvider(widget.resource.id).notifier).fetch(start, end);
  }

  void _showActions(BuildContext ctx, ScheduleModel s) => showScheduleActionSheet(
    context : ctx,
    schedule: s,
    onEdit  : () => Navigator.push(ctx,
        MaterialPageRoute(builder: (_) => EditResourceSchedulePage(schedule: s))),
    onDelete: () async {
      await ref.read(teamScheduleMapProvider.notifier).deleteSchedule(s.id);
      await ref
          .read(resourceScheduleMapProvider(widget.resource.id).notifier)
          .deleteSchedule(s.id);
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
  }
}