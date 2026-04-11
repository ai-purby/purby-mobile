import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_colors.dart';
import '../widgets/add_sheet.dart';

// ─── ScheduleScreen ───────────────────────────────────────────────────────────
class ScheduleScreen extends StatefulWidget {
  final List<Map<String, dynamic>> schedules;
  final void Function(List<Map<String, dynamic>>) onSchedulesChanged;
  final String email;
  const ScheduleScreen({super.key, required this.schedules, required this.onSchedulesChanged, required this.email});
  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late final ScrollController _dateScrollCtrl;
  late DateTime _selectedDate;
  late int _viewYear;
  late int _viewMonth;
  List<Map<String, dynamic>> _dateSchedules = [];

  final List<Color> _colors = [
    const Color(0xFF3A78C9), const Color(0xFFA07828), const Color(0xFF2A9C70),
    const Color(0xFFC08000), const Color(0xFF7844C0), const Color(0xFFD94040),
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = _today;
    _viewYear  = _today.year;
    _viewMonth = _today.month;
    final todayIdx = _today.day - 1;
    _dateScrollCtrl = ScrollController(
      initialScrollOffset: (todayIdx * 52.0 - 80).clamp(0.0, double.infinity),
    );
    _loadForDate(_selectedDate);
  }

  @override
  void dispose() {
    _dateScrollCtrl.dispose();
    super.dispose();
  }

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  bool get _isToday =>
      _selectedDate.year == _today.year &&
      _selectedDate.month == _today.month &&
      _selectedDate.day == _today.day;

  String _keyFor(DateTime d) =>
      '${widget.email}_schedules_${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(date));
    final list = raw != null ? (jsonDecode(raw) as List) : <dynamic>[];
    setState(() {
      _dateSchedules = list.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        m['color'] = Color(m['color'] as int);
        return m;
      }).toList();
    });
  }

  Future<void> _saveForDate() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _dateSchedules.map((s) {
      final m = Map<String, dynamic>.from(s);
      m['color'] = (s['color'] as Color).value;
      return m;
    }).toList();
    await prefs.setString(_keyFor(_selectedDate), jsonEncode(list));
    if (_isToday) widget.onSchedulesChanged(List.from(_dateSchedules));
  }

  void _selectDate(DateTime date) {
    setState(() => _selectedDate = date);
    _loadForDate(date);
  }

  // ── 연/월 변경 ──────────────────────────────────────────────────────────────
  void _changeView(int year, int month) {
    setState(() {
      _viewYear  = year;
      _viewMonth = month;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_dateScrollCtrl.hasClients) return;
      final now = DateTime.now();
      double offset = 0;
      if (year == now.year && month == now.month) {
        offset = ((now.day - 1) * 52.0 - 80).clamp(0.0, double.infinity);
      }
      _dateScrollCtrl.jumpTo(
        offset.clamp(0.0, _dateScrollCtrl.position.maxScrollExtent),
      );
    });
  }

  void _showMonthPicker() {
    int tempYear = _viewYear;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.panel,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // 드래그 핸들
              Container(width: 36, height: 4,
                decoration: BoxDecoration(color: AppColors.t3.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),

              // 연도 선택
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                IconButton(
                  onPressed: () => setModal(() => tempYear--),
                  icon: Icon(Icons.chevron_left_rounded, color: AppColors.t2),
                ),
                GestureDetector(
                  onTap: () {},
                  child: Text('$tempYear년',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.t1)),
                ),
                IconButton(
                  onPressed: () => setModal(() => tempYear++),
                  icon: Icon(Icons.chevron_right_rounded, color: AppColors.t2),
                ),
              ]),
              const SizedBox(height: 12),

              // 월 선택 그리드
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.6,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: List.generate(12, (i) {
                  final m = i + 1;
                  final isSelected = tempYear == _viewYear && m == _viewMonth;
                  final isCurrentMonth = tempYear == DateTime.now().year && m == DateTime.now().month;
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _changeView(tempYear, m);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accent : AppColors.bg,
                        borderRadius: BorderRadius.circular(12),
                        border: isCurrentMonth && !isSelected
                            ? Border.all(color: AppColors.accent.withValues(alpha: 0.4))
                            : null,
                      ),
                      child: Center(
                        child: Text('$m월',
                          style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.t1,
                          )),
                      ),
                    ),
                  );
                }),
              ),
            ]),
          );
        },
      ),
    );
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => AddSheet(
        colorCount: _dateSchedules.length,
        colors: _colors,
        onAdd: (entry) {
          setState(() {
            _dateSchedules.add(entry);
            _dateSchedules.sort((a, b) => (a['time'] as String).compareTo(b['time'] as String));
          });
          _saveForDate();
        },
      ),
    );
  }

  void _goToToday() {
    setState(() {
      _viewYear  = _today.year;
      _viewMonth = _today.month;
    });
    _selectDate(_today);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_dateScrollCtrl.hasClients) return;
      final offset = ((_today.day - 1) * 52.0 - 80).clamp(0.0, double.infinity);
      _dateScrollCtrl.jumpTo(
        offset.clamp(0.0, _dateScrollCtrl.position.maxScrollExtent),
      );
    });
  }

  String _dateLabel() {
    final diff = _selectedDate.difference(_today).inDays;
    if (diff == 0)  return '오늘';
    if (diff == -1) return '어제';
    if (diff == 1)  return '내일';
    if (diff < 0)   return '${-diff}일 전';
    return '$diff일 후';
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(_viewYear, _viewMonth);
    final days = ['일', '월', '화', '수', '목', '금', '토'];

    return Column(children: [
      // ── 헤더
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          // 탭하면 월 선택 시트
          GestureDetector(
            onTap: _showMonthPicker,
            child: Row(children: [
              Text('$_viewYear년 $_viewMonth월',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.t1)),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: AppColors.accent),
            ]),
          ),
          Row(children: [
            _headerPill('오늘', AppColors.accent.withValues(alpha: 0.10), AppColors.accent, _goToToday),
            const SizedBox(width: 8),
            _headerPill(null, AppColors.accent, AppColors.accent, _showAddSheet,
              icon: Icons.add_rounded),
          ]),
        ]),
      ),

      // ── 가로 날짜 스트립
      SizedBox(
        height: 96,
        child: ListView.builder(
          controller: _dateScrollCtrl,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          itemCount: daysInMonth,
          itemBuilder: (context, i) {
            final date = DateTime(_viewYear, _viewMonth, i + 1);
            final isSelected = date.year == _selectedDate.year &&
                date.month == _selectedDate.month &&
                date.day == _selectedDate.day;
            final now = DateTime.now();
            final isToday = date.year == now.year &&
                date.month == now.month &&
                date.day == now.day;
            return GestureDetector(
              onTap: () => _selectDate(date),
              child: Container(
                width: 44, margin: const EdgeInsets.only(right: 8),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(days[date.weekday % 7],
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.accent : AppColors.t3)),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accent
                          : isToday
                              ? AppColors.accent.withValues(alpha: 0.12)
                              : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isToday && !isSelected
                          ? Border.all(color: AppColors.accent.withValues(alpha: 0.4), width: 1.5)
                          : null,
                    ),
                    child: Center(
                      child: Text('${date.day}',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : AppColors.t1)),
                    ),
                  ),
                ]),
              ),
            );
          },
        ),
      ),

      // ── 선택 날짜 레이블
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [
          Text('${_selectedDate.month}월 ${_selectedDate.day}일',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.t1)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _isToday ? AppColors.accent.withValues(alpha: 0.10) : AppColors.border,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_dateLabel(),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: _isToday ? AppColors.accent : AppColors.t3)),
          ),
        ]),
      ),
      const SizedBox(height: 12),

      // ── 일정 목록
      Expanded(child: _dateSchedules.isEmpty
        ? _emptyState()
        : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _dateSchedules.length,
            itemBuilder: (context, index) {
              final s = _dateSchedules[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Dismissible(
                  key: UniqueKey(),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.delete_rounded, color: AppColors.red),
                  ),
                  onDismissed: (_) {
                    setState(() => _dateSchedules.remove(s));
                    _saveForDate();
                  },
                  child: GestureDetector(
                    onTap: () {
                      setState(() => s['done'] = !(s['done'] as bool));
                      _saveForDate();
                    },
                    child: _item(s['time'], s['title'], s['color'],
                        s['done'] ?? false, s['isNow'] ?? false),
                  ),
                ),
              );
            },
          ),
      ),
    ]);
  }

  // ── 헬퍼 위젯 ─────────────────────────────────────────────────────────────

  Widget _emptyState() {
    final isPast = _selectedDate.isBefore(_today);
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.08), shape: BoxShape.circle),
        child: Icon(
          isPast ? Icons.history_rounded : Icons.calendar_today_rounded,
          size: 36, color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      const SizedBox(height: 16),
      Text(isPast ? '이 날은 일정이 없었어요' : '아직 일정이 없어요',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.t2)),
      const SizedBox(height: 6),
      Text(isPast ? '새로운 날 일정을 추가해보세요' : '+ 버튼을 눌러 일정을 추가해보세요',
        style: TextStyle(fontSize: 12, color: AppColors.t3)),
    ]));
  }

  static Widget _item(String time, String title, Color color, bool done, bool isNow) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(width: 4, height: 60,
          decoration: BoxDecoration(
            color: done ? const Color(0xFFD0CFF0) : color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)))),
        Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(children: [
            Container(width: 8, height: 8,
              decoration: BoxDecoration(
                color: done ? const Color(0xFFD0CFF0) : color, shape: BoxShape.circle,
                boxShadow: isNow && !done
                    ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)] : null)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(time, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                color: AppColors.t3, letterSpacing: 1)),
              const SizedBox(height: 3),
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                color: AppColors.t1,
                decoration: done ? TextDecoration.lineThrough : null,
                decorationColor: AppColors.t3)),
            ])),
            if (done) _badge('완료', const Color(0xFF6B5CE7), const Color(0x1A6B5CE7)),
            if (isNow && !done) _badge('NOW', AppColors.green, AppColors.green.withValues(alpha: 0.10)),
          ]),
        )),
      ]),
    );
  }

  static Widget _badge(String text, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _headerPill(String? label, Color bg, Color fg, VoidCallback onTap, {IconData? icon}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: icon != null
            ? Icon(icon, size: 16, color: Colors.white)
            : Text(label!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
      ),
    );
  }
}
