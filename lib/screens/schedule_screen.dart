import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../widgets/add_sheet.dart';

// ─── ScheduleScreen ───────────────────────────────────────────────────────────
class ScheduleScreen extends StatefulWidget {
  final List<Map<String, dynamic>> schedules;
  final void Function(List<Map<String, dynamic>>) onSchedulesChanged;
  const ScheduleScreen({super.key, required this.schedules, required this.onSchedulesChanged});
  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final List<Color> _colors = [
    const Color(0xFF3A78C9), const Color(0xFFA07828), const Color(0xFF2A9C70),
    const Color(0xFFC08000), const Color(0xFF7844C0), const Color(0xFFD94040),
  ];

  List<Map<String, dynamic>> get _schedules => widget.schedules;

  void _notify() => widget.onSchedulesChanged(List.from(_schedules));

  void _showAddSheet() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => AddSheet(
        colorCount: _schedules.length,
        colors: _colors,
        onAdd: (entry) {
          setState(() {
            _schedules.add(entry);
            _schedules.sort((a, b) => (a['time'] as String).compareTo(b['time'] as String));
          });
          _notify();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
        decoration: BoxDecoration(color: AppColors.panel, border: Border(bottom: BorderSide(color: AppColors.border, width: 1))),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('일정', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.t1)),
          GestureDetector(onTap: _showAddSheet,
            child: Container(width: 34, height: 34,
              decoration: BoxDecoration(color: AppColors.accent2, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
              child: const Icon(Icons.add_rounded, size: 16, color: AppColors.accent))),
        ]),
      ),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: SizedBox(height: 72, child: ListView.builder(
          scrollDirection: Axis.horizontal, itemCount: 10,
          itemBuilder: (context, i) {
            final now = DateTime.now();
            final date = now.add(Duration(days: i - 3));
            final days = ['일', '월', '화', '수', '목', '금', '토'];
            final isToday = i == 3;
            return Container(width: 44, margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: isToday ? AppColors.accent : Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isToday ? AppColors.accent : Colors.white.withValues(alpha: 0.65)),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(days[date.weekday % 7], style: TextStyle(fontSize: 8, fontFamily: 'monospace', color: isToday ? Colors.white70 : AppColors.t3)),
                const SizedBox(height: 4),
                Text('${date.day}', style: TextStyle(fontSize: 14, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: isToday ? Colors.white : AppColors.t1)),
                const SizedBox(height: 4),
                Container(width: 4, height: 4, decoration: BoxDecoration(color: isToday ? Colors.white70 : AppColors.accent, shape: BoxShape.circle)),
              ]),
            );
          },
        )),
      ),
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${DateTime.now().year}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().day.toString().padLeft(2, '0')}',
            style: TextStyle(fontSize: 9, fontFamily: 'monospace', letterSpacing: 2, color: AppColors.t3)),
          const SizedBox(height: 8),
          ..._schedules.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Dismissible(
              key: UniqueKey(),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(color: AppColors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.delete_rounded, color: AppColors.red)),
              onDismissed: (_) { setState(() => _schedules.remove(s)); _notify(); },
              child: GestureDetector(
                onTap: () { setState(() => s['done'] = !(s['done'] as bool)); _notify(); },
                child: _item(s['time'], s['title'], s['color'], s['done'] ?? false, s['isNow'] ?? false),
              ),
            ),
          )).toList(),
          const SizedBox(height: 20),
        ]),
      )),
    ]);
  }

  static Widget _item(String time, String title, Color color, bool done, bool isNow) {
    return Container(
      decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Container(width: 3, height: 50, decoration: BoxDecoration(
          color: done ? Colors.black.withValues(alpha: 0.1) : color,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), bottomLeft: Radius.circular(14)))),
        Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(
              color: done ? Colors.black.withValues(alpha: 0.12) : color, shape: BoxShape.circle,
              boxShadow: isNow ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 5)] : null)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(time, style: TextStyle(fontSize: 9, fontFamily: 'monospace', color: AppColors.t3, letterSpacing: 1)),
              const SizedBox(height: 3),
              Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.t1,
                decoration: done ? TextDecoration.lineThrough : null, decorationColor: AppColors.t3)),
            ])),
            if (done) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.accent2, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
              child: const Opacity(opacity: 0.5, child: Text('Done', style: TextStyle(fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.accent)))),
            if (isNow) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.green.withValues(alpha: 0.25))),
              child: const Text('NOW', style: TextStyle(fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.green))),
          ]))),
      ]),
    );
  }
}
