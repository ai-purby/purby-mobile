import 'package:flutter/material.dart';

void main() {
  runApp(const PersonaFrameApp());
}

class PersonaFrameApp extends StatelessWidget {
  const PersonaFrameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Persona Frame',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFF0EDE6),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3A78C9),
          brightness: Brightness.light,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class AppColors {
  static const accent = Color(0xFF3A78C9);
  static const accent2 = Color(0x243A78C9);
  static const bg = Color(0xFFF0EDE6);
  static const panel = Color(0xEBFCFAF7);
  static const t1 = Color(0xFF181620);
  static const t2 = Color(0xFF58566A);
  static const t3 = Color(0xFFA09EB8);
  static const gold = Color(0xFFA07828);
  static const green = Color(0xFF2A9C70);
  static const red = Color(0xFFD94040);
  static const border = Color(0x243A78C9);
  static const borderLight = Color(0xCCFFFFFF);
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [const HomeScreen(), ScheduleScreen(), const SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [
          Expanded(child: _screens[_currentIndex]),
          Container(
            height: 70,
            decoration: const BoxDecoration(color: AppColors.panel, border: Border(top: BorderSide(color: AppColors.border, width: 1))),
            child: Row(children: [
              _nav(Icons.home_rounded, '\uD648', 0),
              _nav(Icons.calendar_month_rounded, '\uC77C\uC815', 1),
              _nav(Icons.settings_rounded, '\uC124\uC815', 2),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _nav(IconData icon, String label, int idx) {
    final on = _currentIndex == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = idx),
        behavior: HitTestBehavior.opaque,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 24, color: on ? AppColors.accent : AppColors.t3),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.w600, color: on ? AppColors.accent : AppColors.t3)),
        ]),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
        decoration: const BoxDecoration(color: AppColors.panel, border: Border(bottom: BorderSide(color: AppColors.border, width: 1))),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('\uD648', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.t1)),
          Container(width: 34, height: 34, decoration: BoxDecoration(color: AppColors.accent2, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
            child: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.accent)),
        ]),
      ),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: const [
            DeviceCard(), SizedBox(height: 12),
            WeatherCard(), SizedBox(height: 12),
            QuickActionsCard(), SizedBox(height: 12),
            TodayScheduleCard(), SizedBox(height: 12),
            AiResultsCard(), SizedBox(height: 20),
          ]),
        ),
      ),
    ]);
  }
}

class DeviceCard extends StatelessWidget {
  const DeviceCard({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0x1C3A78C9), Color(0x083A78C9)]),
        borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0x333A78C9)),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(width: 7, height: 7, decoration: BoxDecoration(color: AppColors.green, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.green.withValues(alpha: 0.3), blurRadius: 6, spreadRadius: 2)])),
            const SizedBox(width: 8),
            const Text('Persona Frame', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'monospace', color: AppColors.t1)),
          ]),
          pill('Connected', AppColors.green),
        ]),
        const SizedBox(height: 14),
        Row(children: [_stat('IP', '192.168.0.14'), const SizedBox(width: 8), _stat('\uC624\uB298 \uBA85\uB839', '12\uD68C'), const SizedBox(width: 8), _stat('\uB9C8\uC9C0\uB9C9 \uBA85\uB839', '13:42')]),
      ]),
    );
  }
  static Widget _stat(String label, String value) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withValues(alpha: 0.75))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 8, fontFamily: 'monospace', color: AppColors.t3, letterSpacing: 1.2)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.t1)),
      ]),
    ));
  }
  static Widget pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.25))),
      child: Text(text, style: TextStyle(fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: color, letterSpacing: 1)),
    );
  }
}

class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Row(children: [
        const Icon(Icons.wb_sunny_rounded, size: 48, color: AppColors.accent),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text('14\u00B0', style: TextStyle(fontSize: 32, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.t1, letterSpacing: -2)),
          Text('\uB9D1\uC74C \u00B7 \uCCB4\uAC10 11\u00B0C', style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.t3)),
        ]),
        const Spacer(),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          const Text('SEOUL, KR', style: TextStyle(fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.gold, letterSpacing: 3)),
          const SizedBox(height: 5),
          Row(children: [_tag('\uD83D\uDCA7 52%'), const SizedBox(width: 5), _tag('\uD83C\uDF2C 3.2 m/s')]),
        ]),
      ]),
    );
  }
  static Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(5), border: Border.all(color: Colors.black.withValues(alpha: 0.06))),
      child: Text(text, style: const TextStyle(fontSize: 9, fontFamily: 'monospace', color: AppColors.t3)),
    );
  }
}

class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('\uC571 \uC9C1\uC811 \uC81C\uC5B4', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.t1)),
        const SizedBox(height: 12),
        GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.55, children: [
          _tile(Icons.music_note_rounded, '\uC74C\uC545 \uC7AC\uC0DD', '\uBC84\uD2BC \uD0ED \u2192 \uC561\uC790\uC5D0 \uC7AC\uC0DD'),
          _tile(Icons.timer_rounded, '\uD0C0\uC774\uBA38 \uC124\uC815', '\uBF40\uBAA8\uB3C4\uB85C 25\uBD84 \uC2DC\uC791'),
          _tile(Icons.people_rounded, '\uC77C\uACFC \uD68C\uACE0', 'AI \uC694\uC57D \uBC1B\uAE30'),
          _tile(Icons.logout_rounded, '\uC808\uC804 \uBAA8\uB4DC', '\uC561\uC790 \uC989\uC2DC \uC808\uC804'),
        ]),
      ]),
    );
  }
  static Widget _tile(IconData icon, String title, String sub) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(width: 30, height: 30, decoration: BoxDecoration(color: AppColors.accent2, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 15, color: AppColors.accent)),
          Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: AppColors.green.withValues(alpha: 0.2))),
            child: const Text('\uC989\uC2DC', style: TextStyle(fontSize: 7, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.green, letterSpacing: 1))),
        ]),
        const Spacer(),
        Text(title, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.t1)),
        const SizedBox(height: 2),
        Text(sub, style: const TextStyle(fontSize: 9, fontFamily: 'monospace', color: AppColors.t3)),
      ]),
    );
  }
}

class TodayScheduleCard extends StatelessWidget {
  const TodayScheduleCard({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        Text('\uC624\uB298 \uC77C\uC815', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.t1)),
        SizedBox(height: 12),
        _SchedItem(time: '09:00', title: '\uD300 \uC2A4\uD0E0\uB4DC\uC5C5', color: Color(0xFF3A78C9), done: true),
        SizedBox(height: 6),
        _SchedItem(time: '11:00', title: '\uC2DC\uC2A4\uD15C \uBD84\uC11D \uC124\uACC4', color: Color(0xFFA07828), done: true),
        SizedBox(height: 6),
        _SchedItem(time: '14:00', title: 'Persona Frame \uD68C\uC758', color: Color(0xFF2A9C70), isNow: true),
        SizedBox(height: 6),
        _SchedItem(time: '17:00', title: 'API \uBA85\uC138\uC11C \uAC80\uD1A0', color: Color(0xFFC08000)),
      ]),
    );
  }
}

class _SchedItem extends StatelessWidget {
  final String time, title;
  final Color color;
  final bool done, isNow;
  const _SchedItem({required this.time, required this.title, required this.color, this.done = false, this.isNow = false});
  @override
  Widget build(BuildContext context) {
    return Opacity(opacity: done ? 0.45 : 1.0, child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: isNow ? const Color(0x123A78C9) : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: isNow ? const Color(0x383A78C9) : Colors.white.withValues(alpha: 0.75)),
      ),
      child: Row(children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle,
          boxShadow: isNow ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 5)] : null)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(time, style: const TextStyle(fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.w600, color: AppColors.t3, letterSpacing: 1)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.t1)),
        ])),
        if (isNow) Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(color: const Color(0x1A3A78C9), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0x333A78C9))),
          child: const Text('NOW', style: TextStyle(fontSize: 8, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.accent))),
      ]),
    ));
  }
}

class AiResultsCard extends StatelessWidget {
  const AiResultsCard({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('AI \uCC98\uB9AC \uACB0\uACFC', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.t1)),
        const SizedBox(height: 12),
        _res(Icons.check_rounded, '\uC77C\uC815 \uCD94\uAC00\uB428', '"\uB0B4\uC77C \uC624\uC804 10\uC2DC \uD68C\uC758 \uCD94\uAC00\uD574\uC918"', '13:42', false),
        const SizedBox(height: 8),
        _res(Icons.check_rounded, '\uC74C\uC545 \uC7AC\uC0DD \uC2DC\uC791\uB428', '"\uACF5\uBD80\uD560 \uB54C \uC88B\uC740 \uC74C\uC545 \uD2C0\uC5B4\uC918"', '11:05', false),
        const SizedBox(height: 8),
        _res(Icons.error_outline_rounded, '\uBA85\uB839 \uC778\uC2DD \uC2E4\uD328', 'STT \uC2E0\uD638 \uC57D\uD568 \u00B7 \uC7AC\uC2DC\uB3C4 \uD544\uC694', '09:30', true),
      ]),
    );
  }
  static Widget _res(IconData icon, String title, String cmd, String time, bool isErr) {
    final c = isErr ? AppColors.red : AppColors.green;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withValues(alpha: 0.75))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 3, height: 40, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Container(width: 28, height: 28, decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 14, color: c)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.t1)),
          const SizedBox(height: 3),
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(5)),
            child: Text(cmd, style: const TextStyle(fontSize: 9, fontFamily: 'monospace', color: AppColors.t3), overflow: TextOverflow.ellipsis)),
          const SizedBox(height: 4),
          Text(time, style: const TextStyle(fontSize: 8, fontFamily: 'monospace', color: AppColors.t3)),
        ])),
      ]),
    );
  }
}

class ScheduleScreen extends StatefulWidget {
  ScheduleScreen({super.key});
  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final List<Color> _colors = [
    const Color(0xFF3A78C9), const Color(0xFFA07828), const Color(0xFF2A9C70),
    const Color(0xFFC08000), const Color(0xFF7844C0), const Color(0xFFD94040),
  ];

  final List<Map<String, dynamic>> _schedules = [
    {'time': '09:00', 'title': '\uD300 \uC2A4\uD0E0\uB4DC\uC5C5', 'color': const Color(0xFF3A78C9), 'done': true},
    {'time': '11:00', 'title': '\uC2DC\uC2A4\uD15C \uBD84\uC11D \uC124\uACC4', 'color': const Color(0xFFA07828), 'done': true},
    {'time': '14:00', 'title': 'Persona Frame \uD68C\uC758', 'color': const Color(0xFF2A9C70), 'done': false, 'isNow': true},
    {'time': '17:00', 'title': 'API \uBA85\uC138\uC11C \uAC80\uD1A0', 'color': const Color(0xFFC08000), 'done': false},
    {'time': '20:00', 'title': '\uC800\uB141 \uC6B4\uB3D9', 'color': const Color(0xFF7844C0), 'done': false},
  ];

  final _titleController = TextEditingController();
  final _memoController = TextEditingController();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);

  void _showAddSheet() {
    _titleController.clear();
    _memoController.clear();
    _startTime = const TimeOfDay(hour: 9, minute: 0);
    _endTime = const TimeOfDay(hour: 10, minute: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Handle
              Container(width: 38, height: 4, decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              const Align(alignment: Alignment.centerLeft, child: Text('\uC77C\uC815 \uCD94\uAC00', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.t1))),
              const SizedBox(height: 14),
              // Title input
              _inputField('\uC77C\uC815 \uC774\uB984', '\uC608) \uD300 \uBBF8\uD305, \uC6B4\uB3D9', _titleController),
              const SizedBox(height: 12),
              // Time row
              Row(children: [
                Expanded(child: _timePickerField('\uC2DC\uC791 \uC2DC\uAC04', _startTime, (t) => setSheetState(() => _startTime = t))),
                const SizedBox(width: 10),
                Expanded(child: _timePickerField('\uC885\uB8CC \uC2DC\uAC04', _endTime, (t) => setSheetState(() => _endTime = t))),
              ]),
              const SizedBox(height: 12),
              // Memo input
              _inputField('\uBA54\uBAA8 (\uC120\uD0DD)', '\uCD94\uAC00 \uBA54\uBAA8', _memoController),
              const SizedBox(height: 16),
              // Add button
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () {
                  if (_titleController.text.trim().isEmpty) return;
                  setState(() {
                    _schedules.add({
                      'time': '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                      'title': _titleController.text.trim(),
                      'color': _colors[_schedules.length % _colors.length],
                      'done': false,
                    });
                    _schedules.sort((a, b) => (a['time'] as String).compareTo(b['time'] as String));
                  });
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                ),
                child: const Text('\uC77C\uC815 \uB4F1\uB85D', style: TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w700, letterSpacing: 1)),
              )),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _inputField(String label, String hint, TextEditingController controller) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 8, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.t3, letterSpacing: 2)),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.t1),
        decoration: InputDecoration(
          hintText: hint, hintStyle: const TextStyle(color: AppColors.t3, fontSize: 13),
          filled: true, fillColor: Colors.white.withValues(alpha: 0.65),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.accent)),
        ),
      ),
    ]);
  }

  Widget _timePickerField(String label, TimeOfDay time, ValueChanged<TimeOfDay> onChanged) {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(context: context, initialTime: time);
        if (picked != null) onChanged(picked);
      },
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 8, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.t3, letterSpacing: 2)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.65), borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Text('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.t1)),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
        decoration: const BoxDecoration(color: AppColors.panel, border: Border(bottom: BorderSide(color: AppColors.border, width: 1))),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('\uC77C\uC815', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.t1)),
          GestureDetector(
            onTap: _showAddSheet,
            child: Container(width: 34, height: 34, decoration: BoxDecoration(color: AppColors.accent2, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
              child: const Icon(Icons.add_rounded, size: 16, color: AppColors.accent)),
          ),
        ]),
      ),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: SizedBox(height: 72, child: ListView.builder(
          scrollDirection: Axis.horizontal, itemCount: 10,
          itemBuilder: (context, i) {
            final now = DateTime.now();
            final date = now.add(Duration(days: i - 3));
            final days = ['\uC77C', '\uC6D4', '\uD654', '\uC218', '\uBAA9', '\uAE08', '\uD1A0'];
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
            style: const TextStyle(fontSize: 9, fontFamily: 'monospace', letterSpacing: 2, color: AppColors.t3)),
          const SizedBox(height: 8),
          ..._schedules.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Dismissible(
              key: UniqueKey(),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(color: AppColors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.delete_rounded, color: AppColors.red),
              ),
              onDismissed: (_) => setState(() => _schedules.remove(s)),
              child: GestureDetector(
                onTap: () => setState(() => s['done'] = !(s['done'] as bool)),
                child: _schedItemWidget(s['time'], s['title'], s['color'], s['done'] ?? false, s['isNow'] ?? false),
              ),
            ),
          )).toList(),
          const SizedBox(height: 20),
        ]),
      )),
    ]);
  }

  static Widget _schedItemWidget(String time, String title, Color color, bool done, bool isNow) {
    return Container(
      decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Container(width: 3, height: 50, decoration: BoxDecoration(
          color: done ? Colors.black.withValues(alpha: 0.1) : color,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), bottomLeft: Radius.circular(14)))),
        Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: done ? Colors.black.withValues(alpha: 0.12) : color, shape: BoxShape.circle,
              boxShadow: isNow ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 5)] : null)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(time, style: const TextStyle(fontSize: 9, fontFamily: 'monospace', color: AppColors.t3, letterSpacing: 1)),
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

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool sleepEnabled = true, schedAlert = true, musicAlert = false, errorAlert = true;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
        decoration: const BoxDecoration(color: AppColors.panel, border: Border(bottom: BorderSide(color: AppColors.border, width: 1))),
        child: const Align(alignment: Alignment.centerLeft, child: Text('\uC124\uC815', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.t1))),
      ),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.green.withValues(alpha: 0.08), AppColors.green.withValues(alpha: 0.02)]),
            borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.green.withValues(alpha: 0.2))),
          child: Column(children: [
            Row(children: [
              Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.green.withValues(alpha: 0.2))),
                child: const Icon(Icons.monitor_rounded, size: 22, color: AppColors.green)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                Text('DEVICE', style: TextStyle(fontSize: 9, fontFamily: 'monospace', color: AppColors.t3, letterSpacing: 1.5)),
                SizedBox(height: 4),
                Text('Persona Frame', style: TextStyle(fontSize: 14, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.t1)),
                SizedBox(height: 3),
                Text('192.168.0.14 \u00B7 \uB3D9\uAE30\uD654 \uC911', style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.t3)),
              ])),
              DeviceCard.pill('Connected', AppColors.green),
            ]),
            const SizedBox(height: 12),
            ClipRRect(borderRadius: BorderRadius.circular(2), child: const LinearProgressIndicator(value: 0.7, minHeight: 3, backgroundColor: Color(0x19000000), color: AppColors.green)),
          ])),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('\uC808\uC804 \uC2DC\uAC04 \uC124\uC815', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.t1)),
            const SizedBox(height: 8),
            const Text('\uC124\uC815 \uC2DC\uAC04 \uB3D9\uC548 Persona Frame\uC774 \uC808\uC804 \uBAA8\uB4DC\uB85C \uC790\uB3D9 \uC804\uD658\uB429\uB2C8\uB2E4.', style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.t3)),
            const SizedBox(height: 12),
            Row(children: [
              _timeBox('\uC2DC\uC791', '02:00'),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('\u2014', style: TextStyle(fontSize: 16, fontFamily: 'monospace', color: AppColors.t3))),
              _timeBox('\uC885\uB8CC', '06:00'),
            ]),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                Text('\uC808\uC804 \uBAA8\uB4DC \uD65C\uC131\uD654', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.t1)),
                SizedBox(height: 3),
                Text('\uC124\uC815 \uC2DC\uAC04\uC5D0 \uC790\uB3D9 \uC804\uD658', style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.t3)),
              ]),
              Switch(value: sleepEnabled, onChanged: (v) => setState(() => sleepEnabled = v), activeColor: AppColors.accent),
            ]),
          ])),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('\uC54C\uB9BC \uC124\uC815', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.t1)),
            const SizedBox(height: 12),
            _alertRow(Icons.notifications_rounded, '\uC77C\uC815 \uC54C\uB9BC', '\uC2DC\uC791 10\uBD84 \uC804', schedAlert, (v) => setState(() => schedAlert = v)),
            const Divider(height: 1),
            _alertRow(Icons.music_note_rounded, '\uC74C\uC545 \uC54C\uB9BC', '\uD2B8\uB799 \uBCC0\uACBD \uC2DC', musicAlert, (v) => setState(() => musicAlert = v)),
            const Divider(height: 1),
            _alertRow(Icons.error_outline_rounded, '\uC624\uB958 \uC54C\uB9BC', 'AI \uC624\uB958 \uBC1C\uC0DD \uC2DC', errorAlert, (v) => setState(() => errorAlert = v)),
          ])),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('\uB514\uBC14\uC774\uC2A4 \uAD00\uB9AC', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.t1)),
            const SizedBox(height: 12),
            _btn('\uC0C8 \uB514\uBC14\uC774\uC2A4 \uC5F0\uACB0', AppColors.accent, AppColors.border),
            const SizedBox(height: 8),
            _btn('\uB370\uC774\uD130 \uB3D9\uAE30\uD654', AppColors.accent, AppColors.border),
            const SizedBox(height: 8),
            _btn('\uC5F0\uACB0 \uD574\uC81C', AppColors.red, AppColors.red.withValues(alpha: 0.25)),
          ])),
        const SizedBox(height: 12),
        const Text('Persona Frame v1.0.0 \u00B7 2026', style: TextStyle(fontSize: 8, fontFamily: 'monospace', color: AppColors.t3, letterSpacing: 2)),
        const SizedBox(height: 20),
      ]))),
    ]);
  }
  static Widget _timeBox(String label, String value) {
    return Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: Column(children: [
        Text(label, style: const TextStyle(fontSize: 8, fontFamily: 'monospace', color: AppColors.t3, letterSpacing: 1.5)),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontSize: 20, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.t1, letterSpacing: -1)),
      ])));
  }
  static Widget _alertRow(IconData icon, String title, String sub, bool val, ValueChanged<bool> onChanged) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Row(children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.accent2, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: AppColors.accent)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.t1)),
        const SizedBox(height: 3),
        Text(sub, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.t3)),
      ])),
      Switch(value: val, onChanged: onChanged, activeColor: AppColors.accent),
    ]));
  }
  static Widget _btn(String text, Color color, Color borderColor) {
    return SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () {},
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      child: Text(text, style: TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: color, letterSpacing: 1.5))));
  }
}
