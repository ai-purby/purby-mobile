import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const PersonaFrameApp());

// ─── Colors (다크모드 대응) ──────────────────────────────────────────────────
class AppColors {
  static bool isDark = false;
  // 다크모드 무관 — static const 유지
  static const Color accent  = Color(0xFF3A78C9);
  static const Color accent2 = Color(0x243A78C9);
  static const Color gold    = Color(0xFFA07828);
  static const Color green   = Color(0xFF2A9C70);
  static const Color red     = Color(0xFFD94040);
  // 다크모드 대응 — getter
  static Color get bg    => isDark ? const Color(0xFF13111C) : const Color(0xFFF0EDE6);
  static Color get panel => isDark ? const Color(0xFF1C1A2A) : const Color(0xEBFCFAF7);
  static Color get t1    => isDark ? const Color(0xFFEEEDF8) : const Color(0xFF181620);
  static Color get t2    => isDark ? const Color(0xFF9895B0) : const Color(0xFF58566A);
  static Color get t3    => isDark ? const Color(0xFF5C5A74) : const Color(0xFFA09EB8);
  static Color get border      => isDark ? const Color(0x503A78C9) : const Color(0x243A78C9);
  static Color get borderLight => isDark ? const Color(0x25FFFFFF) : const Color(0xCCFFFFFF);
}

// ─── App Root (isDark + aiName 전역 상태) ────────────────────────────────────
class PersonaFrameApp extends StatefulWidget {
  const PersonaFrameApp({super.key});
  @override
  State<PersonaFrameApp> createState() => _PersonaFrameAppState();
}

class _PersonaFrameAppState extends State<PersonaFrameApp> {
  bool _isDark = false;
  String _aiName = '퍼비';
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDark = prefs.getBool('is_dark') ?? false;
      if (prefs.getBool('logged_in') ?? false) _loggedIn = true;
    });
  }

  Future<void> _setDark(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark', val);
    setState(() => _isDark = val);
  }

  Future<void> _login(bool autoLogin) async {
    if (autoLogin) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('logged_in', true);
    }
    setState(() => _loggedIn = true);
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('logged_in', false);
    setState(() => _loggedIn = false);
  }

  @override
  Widget build(BuildContext context) {
    AppColors.isDark = _isDark;
    return MaterialApp(
      title: 'Persona Frame',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: _isDark ? Brightness.dark : Brightness.light,
        ),
      ),
      home: _loggedIn
          ? MainScreen(
              isDark: _isDark,
              aiName: _aiName,
              onDarkToggle: _setDark,
              onNameChange: (n) => setState(() => _aiName = n),
              onLogout: _logout,
            )
          : AuthScreen(onLogin: _login),
    );
  }
}

// ─── MainScreen ──────────────────────────────────────────────────────────────
class MainScreen extends StatefulWidget {
  final bool isDark;
  final String aiName;
  final ValueChanged<bool> onDarkToggle;
  final ValueChanged<String> onNameChange;
  final VoidCallback onLogout;
  const MainScreen({
    super.key,
    required this.isDark,
    required this.aiName,
    required this.onDarkToggle,
    required this.onNameChange,
    required this.onLogout,
  });
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Map<String, dynamic>> _schedules = [];

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('schedules');
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      setState(() {
        _schedules.addAll(list.map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          m['color'] = Color(m['color'] as int);
          return m;
        }));
      });
    }
  }

  Future<void> _saveSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _schedules.map((s) {
      final m = Map<String, dynamic>.from(s);
      m['color'] = (s['color'] as Color).value;
      return m;
    }).toList();
    await prefs.setString('schedules', jsonEncode(list));
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(aiName: widget.aiName, schedules: _schedules),
      ScheduleScreen(
        schedules: _schedules,
        onSchedulesChanged: (updated) {
          setState(() {
            _schedules
              ..clear()
              ..addAll(updated);
          });
          _saveSchedules();
        },
      ),
      SettingsScreen(
        isDark: widget.isDark,
        aiName: widget.aiName,
        onDarkToggle: widget.onDarkToggle,
        onNameChange: widget.onNameChange,
        onLogout: widget.onLogout,
      ),
    ];
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(child: Column(children: [
        Expanded(child: screens[_currentIndex]),
        Container(
          height: 70,
          decoration: BoxDecoration(
            color: AppColors.panel,
            border: Border(top: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: Row(children: [
            _nav(Icons.home_rounded, '홈', 0),
            _nav(Icons.calendar_month_rounded, '일정', 1),
            _nav(Icons.settings_rounded, '설정', 2),
          ]),
        ),
      ])),
    );
  }

  Widget _nav(IconData icon, String label, int idx) {
    final on = _currentIndex == idx;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _currentIndex = idx),
      behavior: HitTestBehavior.opaque,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 24, color: on ? AppColors.accent : AppColors.t3),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.w600, color: on ? AppColors.accent : AppColors.t3)),
      ]),
    ));
  }
}

// ─── HomeScreen ───────────────────────────────────────────────────────────────
class HomeScreen extends StatelessWidget {
  final String aiName;
  final List<Map<String, dynamic>> schedules;
  const HomeScreen({super.key, required this.aiName, required this.schedules});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
        decoration: BoxDecoration(
          color: AppColors.panel,
          border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('홈', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.t1)),
          Text('안녕, $aiName! 👋', style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.t3)),
        ]),
      ),
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          QuickActionsCard(), const SizedBox(height: 12),
          TodayScheduleCard(schedules: schedules), const SizedBox(height: 12),
          AiResultsCard(), const SizedBox(height: 20),
        ]),
      )),
    ]);
  }
}



// ─── QuickActionsCard ─────────────────────────────────────────────────────────
class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('앱 직접 제어', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.t1)),
        const SizedBox(height: 12),
        GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.55, children: [
          _tile(Icons.music_note_rounded, '음악 재생', '버튼 탭 → 액자에 재생'),
          _tile(Icons.timer_rounded, '타이머 설정', '뽀모도로 25분 시작'),
          _tile(Icons.people_rounded, '일과 회고', 'AI 요약 받기'),
          _tile(Icons.logout_rounded, '절전 모드', '액자 즉시 절전'),
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
            child: const Text('즉시', style: TextStyle(fontSize: 7, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.green, letterSpacing: 1))),
        ]),
        const Spacer(),
        Text(title, style: TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.t1)),
        const SizedBox(height: 2),
        Text(sub, style: TextStyle(fontSize: 9, fontFamily: 'monospace', color: AppColors.t3)),
      ]),
    );
  }
}

// ─── TodayScheduleCard ────────────────────────────────────────────────────────
class TodayScheduleCard extends StatelessWidget {
  final List<Map<String, dynamic>> schedules;
  const TodayScheduleCard({super.key, required this.schedules});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('오늘 일정', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.t1)),
        const SizedBox(height: 12),
        if (schedules.isEmpty)
          Text('등록된 일정이 없습니다.', style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.t3))
        else
          ...schedules.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _SchedItem(
              time: s['time'] as String,
              title: s['title'] as String,
              color: s['color'] as Color,
              done: s['done'] as bool? ?? false,
              isNow: s['isNow'] as bool? ?? false,
            ),
          )),
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
          Text(time, style: TextStyle(fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.w600, color: AppColors.t3, letterSpacing: 1)),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.t1)),
        ])),
        if (isNow) Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(color: const Color(0x1A3A78C9), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0x333A78C9))),
          child: const Text('NOW', style: TextStyle(fontSize: 8, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.accent))),
      ]),
    ));
  }
}

// ─── AiResultsCard ────────────────────────────────────────────────────────────
class AiResultsCard extends StatelessWidget {
  const AiResultsCard({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('AI 처리 결과', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.t1)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: AppColors.accent2, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border)),
            child: Text('대기 중', style: TextStyle(fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.t3, letterSpacing: 1)),
          ),
        ]),
        const SizedBox(height: 20),
        Center(child: Column(children: [
          Icon(Icons.sensors_rounded, size: 32, color: AppColors.t3),
          const SizedBox(height: 10),
          Text('AI 명령 결과가 여기에 표시됩니다', style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.t3)),
          const SizedBox(height: 4),
          Text('실시간 연동 준비 중', style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.t3.withValues(alpha: 0.6), letterSpacing: 1)),
        ])),
        const SizedBox(height: 20),
      ]),
    );
  }
}

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
      builder: (ctx) => _AddSheet(
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

// ─── SettingsScreen ───────────────────────────────────────────────────────────
class SettingsScreen extends StatefulWidget {
  final bool isDark;
  final String aiName;
  final ValueChanged<bool> onDarkToggle;
  final ValueChanged<String> onNameChange;
  final VoidCallback onLogout;
  const SettingsScreen({
    super.key,
    required this.isDark,
    required this.aiName,
    required this.onDarkToggle,
    required this.onNameChange,
    required this.onLogout,
  });
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool sleepEnabled = true, schedAlert = true;
  TimeOfDay sleepStart = const TimeOfDay(hour: 2, minute: 0);
  TimeOfDay sleepEnd   = const TimeOfDay(hour: 6, minute: 0);
  bool _briefingEnabled = false;
  TimeOfDay _briefingTime = const TimeOfDay(hour: 7, minute: 0);
  bool _retroEnabled = false;
  TimeOfDay _retroTime = const TimeOfDay(hour: 22, minute: 0);
  double _volume = 0.5;
  double _brightness = 0.8;
  String _personality = '친근한';
  bool _isConnected = false;
  String _deviceIp = '';
  final _ipCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBriefing();
  }

  Future<void> _loadBriefing() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _briefingEnabled = prefs.getBool('briefing_enabled') ?? false;
      _briefingTime = TimeOfDay(
        hour: prefs.getInt('briefing_hour') ?? 7,
        minute: prefs.getInt('briefing_minute') ?? 0,
      );
      _retroEnabled = prefs.getBool('retro_enabled') ?? false;
      _retroTime = TimeOfDay(
        hour: prefs.getInt('retro_hour') ?? 22,
        minute: prefs.getInt('retro_minute') ?? 0,
      );
      _volume = prefs.getDouble('volume') ?? 0.5;
      _brightness = prefs.getDouble('brightness') ?? 0.8;
      _personality = prefs.getString('personality') ?? '친근한';
      _deviceIp = prefs.getString('device_ip') ?? '';
      _isConnected = prefs.getBool('device_connected') ?? false;
      if (_deviceIp.isNotEmpty) _ipCtrl.text = _deviceIp;
    });
  }

  Future<void> _saveBriefing() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('briefing_enabled', _briefingEnabled);
    await prefs.setInt('briefing_hour', _briefingTime.hour);
    await prefs.setInt('briefing_minute', _briefingTime.minute);
  }

  Future<void> _saveRetro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('retro_enabled', _retroEnabled);
    await prefs.setInt('retro_hour', _retroTime.hour);
    await prefs.setInt('retro_minute', _retroTime.minute);
  }

  Future<void> _pickBriefingTime() async {
    final picked = await showTimePicker(context: context, initialTime: _briefingTime);
    if (picked != null) {
      setState(() => _briefingTime = picked);
      _saveBriefing();
    }
  }

  Future<void> _saveDisplay() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('volume', _volume);
    await prefs.setDouble('brightness', _brightness);
  }

  void _showFactoryResetDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(Icons.warning_amber_rounded, size: 20, color: AppColors.gold),
          const SizedBox(width: 8),
          Text('공장 초기화', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.t1)),
        ]),
        content: Text('디바이스의 모든 설정이 초기화됩니다.\n이 작업은 되돌릴 수 없습니다.', style: TextStyle(fontSize: 13, fontFamily: 'monospace', color: AppColors.t2, height: 1.6)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('취소', style: TextStyle(color: AppColors.t3, fontFamily: 'monospace'))),
          TextButton(
            onPressed: () { Navigator.pop(ctx); /* TODO: 실제 초기화 명령 전송 */ },
            child: Text('초기화', style: TextStyle(color: AppColors.gold, fontFamily: 'monospace', fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _connectDevice() async {
    final ip = _ipCtrl.text.trim();
    if (ip.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('device_ip', ip);
    await prefs.setBool('device_connected', true);
    setState(() { _deviceIp = ip; _isConnected = true; });
  }

  Future<void> _disconnectDevice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('device_connected', false);
    setState(() => _isConnected = false);
  }

  Future<void> _savePersonality(String val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('personality', val);
    setState(() => _personality = val);
  }

  static const _personalities = [
    ('친근한',   Icons.favorite_rounded,        '따뜻하고 다정하게 대화해요',   Color(0xFFD94040)),
    ('전문적인', Icons.business_center_rounded,  '정확하고 간결하게 답해요',    Color(0xFF3A78C9)),
    ('유쾌한',   Icons.mood_rounded,             '유머 있고 활발하게 대화해요', Color(0xFFA07828)),
    ('차분한',   Icons.self_improvement_rounded, '조용하고 침착하게 말해요',    Color(0xFF2A9C70)),
    ('엄격한',   Icons.fitness_center_rounded,   '집중력 있는 피드백을 줘요',   Color(0xFF58566A)),
  ];

  void _showPersonalityModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.t3.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Row(children: [
              Container(width: 36, height: 36,
                decoration: BoxDecoration(color: AppColors.accent2, borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.psychology_rounded, size: 18, color: AppColors.accent)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('퍼비 성격 선택', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.t1)),
                Text('AI 의 말투와 응답 스타일', style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.t3)),
              ]),
            ]),
            const SizedBox(height: 20),
            ..._personalities.map((item) {
              final (label, icon, desc, color) = item;
              final selected = _personality == label;
              return GestureDetector(
                onTap: () {
                  _savePersonality(label);
                  setModal(() {});
                  Navigator.pop(ctx);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: selected ? color.withValues(alpha: 0.08) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: selected ? color.withValues(alpha: 0.5) : AppColors.border, width: selected ? 1.5 : 1),
                  ),
                  child: Row(children: [
                    Container(width: 34, height: 34,
                      decoration: BoxDecoration(color: color.withValues(alpha: selected ? 0.18 : 0.08), borderRadius: BorderRadius.circular(10)),
                      child: Icon(icon, size: 17, color: color.withValues(alpha: selected ? 1.0 : 0.5))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? color : AppColors.t2)),
                      const SizedBox(height: 2),
                      Text(desc, style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.t3)),
                    ])),
                    if (selected)
                      Icon(Icons.check_circle_rounded, size: 20, color: color),
                  ]),
                ),
              );
            }),
          ]),
        ),
      ),
    );
  }

  Future<void> _pickRetroTime() async {
    final picked = await showTimePicker(context: context, initialTime: _retroTime);
    if (picked != null) {
      setState(() => _retroTime = picked);
      _saveRetro();
    }
  }

  @override
  void dispose() {
    _ipCtrl.dispose();
    super.dispose();
  }

  String _fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickSleepTime(bool isStart) async {
    final p = await showTimePicker(
      context: context,
      initialTime: isStart ? sleepStart : sleepEnd,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    if (p != null) setState(() => isStart ? sleepStart = p : sleepEnd = p);
  }

  void _showNameDialog() {
    final ctrl = TextEditingController(text: widget.aiName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('AI 이름 설정', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.t1)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('"[이름]야" 라고 부르면 활성화돼요.',
            style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.t3)),
          const SizedBox(height: 14),
          TextField(
            controller: ctrl, autofocus: true, maxLength: 10,
            style: TextStyle(fontSize: 16, fontFamily: 'monospace', color: AppColors.t1),
            decoration: InputDecoration(
              hintText: '이름을 입력하세요',
              hintStyle: TextStyle(color: AppColors.t3, fontFamily: 'monospace'),
              counterStyle: TextStyle(color: AppColors.t3, fontSize: 10),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.accent)),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('취소', style: TextStyle(color: AppColors.t3))),
          TextButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) widget.onNameChange(ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('저장', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
          ),
        ],
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
          Text('설정', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.t1)),
          GestureDetector(
            onTap: widget.onLogout,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.red.withValues(alpha: 0.35)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.logout_rounded, size: 12, color: AppColors.red),
                const SizedBox(width: 4),
                Text('로그아웃', style: TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.red)),
              ]),
            ),
          ),
        ]),
      ),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [

        // ── 디바이스 연결
        Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.green.withValues(alpha: 0.08), AppColors.green.withValues(alpha: 0.02)]),
            borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.green.withValues(alpha: 0.2))),
          child: Column(children: [
            Row(children: [
              Container(width: 42, height: 42,
                decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.green.withValues(alpha: 0.2))),
                child: const Icon(Icons.monitor_rounded, size: 22, color: AppColors.green)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('DEVICE', style: TextStyle(fontSize: 9, fontFamily: 'monospace', color: AppColors.t3, letterSpacing: 1.5)),
                const SizedBox(height: 4),
                Text('Persona Frame', style: TextStyle(fontSize: 14, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.t1)),
                const SizedBox(height: 3),
                Text('192.168.0.14 · 동기화 중', style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.t3)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.green.withValues(alpha: 0.25))),
                child: Text('Connected', style: TextStyle(fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.green, letterSpacing: 1)),
              ),
            ]),
            const SizedBox(height: 12),
            ClipRRect(borderRadius: BorderRadius.circular(2),
              child: const LinearProgressIndicator(value: 0.7, minHeight: 3, backgroundColor: Color(0x19000000), color: AppColors.green)),
          ])),
        const SizedBox(height: 12),


        // ── 다크 / 라이트 모드 토글 (NEW)
        Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.accent2, borderRadius: BorderRadius.circular(10)),
              child: Icon(widget.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, size: 18, color: AppColors.accent)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('테마', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.t1)),
              const SizedBox(height: 3),
              Text(widget.isDark ? '어두운 모드 사용 중' : '밝은 모드 사용 중', style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.t3)),
            ])),
            Switch(value: widget.isDark, onChanged: widget.onDarkToggle, activeColor: AppColors.accent),
          ])),
        const SizedBox(height: 12),

        // ── 퍼비 성격 설정
        GestureDetector(
          onTap: _showPersonalityModal,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
            child: Row(children: [
              Container(width: 36, height: 36,
                decoration: BoxDecoration(color: AppColors.accent2, borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.psychology_rounded, size: 18, color: AppColors.accent)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('퍼비 성격', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.t1)),
                Text('AI 의 말투와 응답 스타일을 설정해요', style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.t3)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.accent2, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                child: Text(_personality, style: TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.accent)),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.t3),
            ]),
          ),
        ),
        const SizedBox(height: 12),

        // ── 절전 시간 설정
        Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('절전 시간 설정', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.t1)),
            const SizedBox(height: 8),
            Text('설정 시간 동안 Persona Frame이 절전 모드로 자동 전환됩니다.', style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.t3)),
            const SizedBox(height: 12),
            Row(children: [
              _timeBox('시작', _fmt(sleepStart), () => _pickSleepTime(true)),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('—', style: TextStyle(fontSize: 16, fontFamily: 'monospace', color: AppColors.t3))),
              _timeBox('종료', _fmt(sleepEnd), () => _pickSleepTime(false)),
            ]),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('절전 모드 활성화', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.t1)),
                const SizedBox(height: 3),
                Text('설정 시간에 자동 전환', style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.t3)),
              ]),
              Switch(value: sleepEnabled, onChanged: (v) => setState(() => sleepEnabled = v), activeColor: AppColors.accent),
            ]),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.monitor_rounded, size: 15, color: AppColors.t2),
                label: Text('화면 끄기', style: TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.t2, letterSpacing: 1)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ])),
        const SizedBox(height: 12),

        // ── 아침 브리핑
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 36, height: 36,
                decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.wb_twilight_rounded, size: 18, color: AppColors.gold)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('아침 브리핑', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.t1)),
                Text('설정 시간에 오늘 일정을 요약해드려요', style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.t3)),
              ])),
              Switch(
                value: _briefingEnabled,
                onChanged: (v) { setState(() => _briefingEnabled = v); _saveBriefing(); },
                activeColor: AppColors.accent,
              ),
            ]),
            if (_briefingEnabled) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('브리핑 시간', style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.t2)),
                GestureDetector(
                  onTap: _pickBriefingTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.accent2, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(_fmt(_briefingTime), style: const TextStyle(fontSize: 18, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.accent, letterSpacing: 1)),
                      const SizedBox(width: 8),
                      const Icon(Icons.edit_rounded, size: 12, color: AppColors.accent),
                    ]),
                  ),
                ),
              ]),
            ],
          ]),
        ),
        const SizedBox(height: 12),

        // ── 회고 시간
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 36, height: 36,
                decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.auto_stories_rounded, size: 18, color: AppColors.accent)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('회고 시간', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.t1)),
                Text('설정 시간에 하루를 돌아보는 알림을 드려요', style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.t3)),
              ])),
              Switch(
                value: _retroEnabled,
                onChanged: (v) { setState(() => _retroEnabled = v); _saveRetro(); },
                activeColor: AppColors.accent,
              ),
            ]),
            if (_retroEnabled) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('회고 시간', style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.t2)),
                GestureDetector(
                  onTap: _pickRetroTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.accent2, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(_fmt(_retroTime), style: const TextStyle(fontSize: 18, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.accent, letterSpacing: 1)),
                      const SizedBox(width: 8),
                      const Icon(Icons.edit_rounded, size: 12, color: AppColors.accent),
                    ]),
                  ),
                ),
              ]),
            ],
          ]),
        ),
        const SizedBox(height: 12),

        // ── 볼륨 / 밝기
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: Column(children: [
            _sliderRow(
              icon: Icons.volume_up_rounded,
              label: '볼륨',
              value: _volume,
              color: AppColors.accent,
              onChanged: (v) { setState(() => _volume = v); _saveDisplay(); },
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            _sliderRow(
              icon: Icons.brightness_6_rounded,
              label: '밝기',
              value: _brightness,
              color: AppColors.gold,
              onChanged: (v) { setState(() => _brightness = v); _saveDisplay(); },
            ),
          ]),
        ),
        const SizedBox(height: 12),

        // ── 알림 설정
        Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('알림 설정', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.t1)),
            const SizedBox(height: 12),
            _alertRow(Icons.notifications_rounded, '모바일 알림', '시작 10분 전', schedAlert, (v) => setState(() => schedAlert = v)),
          ])),
        const SizedBox(height: 12),

        // ── 디바이스 관리
        Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('디바이스 관리', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.t1)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _isConnected ? AppColors.green.withValues(alpha: 0.12) : AppColors.t3.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _isConnected ? AppColors.green.withValues(alpha: 0.3) : AppColors.border),
                ),
                child: Text(_isConnected ? '연결됨' : '미연결', style: TextStyle(fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: _isConnected ? AppColors.green : AppColors.t3, letterSpacing: 1)),
              ),
            ]),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            if (_isConnected) ...[
              // 연결된 상태
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.green.withValues(alpha: 0.2))),
                child: Row(children: [
                  Icon(Icons.monitor_rounded, size: 20, color: AppColors.green),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Persona Frame', style: TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.t1)),
                    const SizedBox(height: 2),
                    Text(_deviceIp, style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.t3)),
                  ])),
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
                ]),
              ),
              const SizedBox(height: 12),
              _btn('공장 초기화', AppColors.gold, AppColors.gold.withValues(alpha: 0.25), _showFactoryResetDialog),
              const SizedBox(height: 8),
              _btn('연결 해제', AppColors.red, AppColors.red.withValues(alpha: 0.25), _disconnectDevice),
            ] else ...[
              // 미연결 상태 — IP 입력
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('IP 주소', style: TextStyle(fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.t3, letterSpacing: 2)),
                const SizedBox(height: 7),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _ipCtrl,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(fontSize: 14, fontFamily: 'monospace', color: AppColors.t1),
                      decoration: InputDecoration(
                        hintText: '192.168.0.14',
                        hintStyle: TextStyle(color: AppColors.t3, fontSize: 13, fontFamily: 'monospace'),
                        filled: true, fillColor: AppColors.bg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _connectDevice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text('연결', style: TextStyle(fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.w700)),
                  ),
                ]),
              ]),
            ],
          ])),
        const SizedBox(height: 12),
        Text('Persona Frame v1.0.0 · 2026', style: TextStyle(fontSize: 8, fontFamily: 'monospace', color: AppColors.t3, letterSpacing: 2)),
        const SizedBox(height: 20),
      ]))),
    ]);
  }

  Widget _timeBox(String label, String value, VoidCallback onTap) {
    return Expanded(child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
        child: Column(children: [
          Text(label, style: TextStyle(fontSize: 8, fontFamily: 'monospace', color: AppColors.t3, letterSpacing: 1.5)),
          const SizedBox(height: 5),
          Text(value, style: TextStyle(fontSize: 20, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.t1, letterSpacing: -1)),
          const SizedBox(height: 3),
          Text('탭하여 변경', style: TextStyle(fontSize: 7, fontFamily: 'monospace', color: AppColors.t3)),
        ]),
      ),
    ));
  }

  Widget _alertRow(IconData icon, String title, String sub, bool val, ValueChanged<bool> onChanged) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Row(children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.accent2, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: AppColors.accent)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.t1)),
        const SizedBox(height: 3),
        Text(sub, style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.t3)),
      ])),
      Switch(value: val, onChanged: onChanged, activeColor: AppColors.accent),
    ]));
  }

  Widget _btn(String text, Color color, Color borderColor, [VoidCallback? onPressed]) {
    return SizedBox(width: double.infinity, child: OutlinedButton(
      onPressed: onPressed ?? () {},
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12), side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      child: Text(text, style: TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: color, letterSpacing: 1.5)),
    ));
  }

  Widget _sliderRow({required IconData icon, required String label, required double value, required Color color, required ValueChanged<double> onChanged}) {
    return Row(children: [
      Container(width: 34, height: 34,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 17, color: color)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.t1)),
          Text('${(value * 100).round()}%', style: TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: color)),
        ]),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: color,
            inactiveTrackColor: color.withValues(alpha: 0.15),
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.15),
          ),
          child: Slider(value: value, min: 0, max: 1, onChanged: onChanged),
        ),
      ])),
    ]);
  }
}

class _AddSheet extends StatefulWidget {
  final int colorCount;
  final List<Color> colors;
  final void Function(Map<String, dynamic>) onAdd;
  const _AddSheet({required this.colorCount, required this.colors, required this.onAdd});
  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  final _titleCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);

  @override
  void dispose() {
    _titleCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 38, height: 4, decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Align(alignment: Alignment.centerLeft, child: Text('일정 추가', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.t1))),
            const SizedBox(height: 14),
            _field('일정 이름', '예) 팀 미팅, 운동', _titleCtrl),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _timePicker('시작 시간', _startTime, (t) => setState(() => _startTime = t))),
              const SizedBox(width: 10),
              Expanded(child: _timePicker('종료 시간', _endTime, (t) => setState(() => _endTime = t))),
            ]),
            const SizedBox(height: 12),
            _field('메모 (선택)', '추가 메모', _memoCtrl),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () {
                if (_titleCtrl.text.trim().isEmpty) return;
                widget.onAdd({
                  'time': '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                  'title': _titleCtrl.text.trim(),
                  'color': widget.colors[widget.colorCount % widget.colors.length],
                  'done': false,
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
              ),
              child: const Text('일정 등록', style: TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w700, letterSpacing: 1)),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _field(String label, String hint, TextEditingController ctrl) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 8, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.t3, letterSpacing: 2)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.t1),
        decoration: InputDecoration(
          hintText: hint, hintStyle: TextStyle(color: AppColors.t3, fontSize: 13),
          filled: true, fillColor: Colors.white.withValues(alpha: 0.65),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.accent)),
        ),
      ),
    ]);
  }

  Widget _timePicker(String label, TimeOfDay time, ValueChanged<TimeOfDay> onChanged) {
    return GestureDetector(
      onTap: () async {
        final p = await showTimePicker(context: context, initialTime: time);
        if (p != null) onChanged(p);
      },
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 8, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.t3, letterSpacing: 2)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.65), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
          child: Text('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.t1)),
        ),
      ]),
    );
  }
}

// ─── Auth Screen (로그인 / 회원가입) ─────────────────────────────────────────
class AuthScreen extends StatefulWidget {
  final Function(bool autoLogin) onLogin;
  const AuthScreen({super.key, required this.onLogin});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pw2Ctrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _pwVisible = false;
  String _error = '';
  bool _sendingCode = false;
  bool _codeSent = false;
  bool _codeVerified = false;
  String _sentCode = '';
  bool _autoLogin = false;

  @override
  void initState() {
    super.initState();
    _loadAutoLogin();
  }

  Future<void> _loadAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _autoLogin = prefs.getBool('auto_login') ?? false);
  }

  Future<void> _setAutoLogin(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_login', val);
    setState(() => _autoLogin = val);
  }

  static const _adminEmail = 'sin629370@gmail.com';
  static const _adminPw = 'jikosh12@';
  // Gmail 앱 비밀번호 (Google 계정 → 보안 → 앱 비밀번호)
  static const _senderAppPw = 'YOUR_GMAIL_APP_PASSWORD';

  Future<void> _sendVerifyCode() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = '올바른 이메일을 입력해주세요.');
      return;
    }
    setState(() { _sendingCode = true; _error = ''; });

    final code = (100000 + Random().nextInt(900000)).toString();
    try {
      final smtp = gmail(_adminEmail, _senderAppPw);
      final msg = Message()
        ..from = Address(_adminEmail, 'Persona Frame')
        ..recipients.add(email)
        ..subject = '[Persona Frame] 이메일 인증번호'
        ..text = '인증번호: $code\n\n이 코드는 10분간 유효합니다.';
      await send(msg, smtp);
      setState(() { _sentCode = code; _codeSent = true; _sendingCode = false; });
    } catch (_) {
      setState(() { _error = '이메일 전송에 실패했습니다. 앱 비밀번호를 확인해주세요.'; _sendingCode = false; });
    }
  }

  void _verifyCode() {
    if (_codeCtrl.text.trim() == _sentCode) {
      setState(() { _codeVerified = true; _error = ''; });
    } else {
      setState(() => _error = '인증번호가 올바르지 않습니다.');
    }
  }

  void _submit() {
    final email = _emailCtrl.text.trim();
    final pw = _pwCtrl.text;
    if (_isLogin) {
      if (email == _adminEmail && pw == _adminPw) {
        widget.onLogin(_autoLogin);
      } else {
        setState(() => _error = '이메일 또는 비밀번호가 올바르지 않습니다.');
      }
    } else {
      if (!_codeVerified) {
        setState(() => _error = '이메일 인증을 완료해주세요.');
        return;
      }
      if (pw.isEmpty) {
        setState(() => _error = '비밀번호를 입력해주세요.');
      } else if (pw != _pw2Ctrl.text) {
        setState(() => _error = '비밀번호가 일치하지 않습니다.');
      } else {
        setState(() => _error = '관리자만 접근 가능합니다.');
      }
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _pw2Ctrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(children: [
            const SizedBox(height: 60),
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: AppColors.accent2,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.window_rounded, size: 32, color: AppColors.accent),
            ),
            const SizedBox(height: 16),
            const Text('Persona Frame', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, fontFamily: 'monospace', color: AppColors.accent, letterSpacing: 1)),
            const SizedBox(height: 6),
            Text('스마트 액자 컨트롤 앱', style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.t3, letterSpacing: 2)),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Row(children: [
                _tab('로그인', _isLogin, () => setState(() => _isLogin = true)),
                _tab('회원가입', !_isLogin, () => setState(() => _isLogin = false)),
              ]),
            ),
            const SizedBox(height: 28),
            _authField('이메일', 'example@email.com', _emailCtrl, TextInputType.emailAddress),
            if (!_isLogin) ...[
              const SizedBox(height: 10),
              // 인증번호 발송 버튼 / 인증 완료 표시
              if (!_codeVerified)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _sendingCode ? null : _sendVerifyCode,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: AppColors.accent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                    ),
                    child: _sendingCode
                        ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))
                        : Text(_codeSent ? '인증번호 재발송' : '인증번호 발송', style: TextStyle(fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.accent)),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(11), border: Border.all(color: AppColors.green.withValues(alpha: 0.3))),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.check_circle_rounded, size: 16, color: AppColors.green),
                    const SizedBox(width: 6),
                    Text('이메일 인증 완료', style: TextStyle(fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.green)),
                  ]),
                ),
              // 인증번호 입력 필드
              if (_codeSent && !_codeVerified) ...[
                const SizedBox(height: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('인증번호', style: TextStyle(fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.t3, letterSpacing: 2)),
                  const SizedBox(height: 7),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _codeCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        style: TextStyle(fontSize: 20, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.t1, letterSpacing: 6),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: '000000', hintStyle: TextStyle(color: AppColors.t3, fontSize: 18, letterSpacing: 6),
                          filled: true, fillColor: AppColors.panel,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: BorderSide(color: AppColors.border)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: BorderSide(color: AppColors.border)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _verifyCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                        elevation: 0,
                      ),
                      child: const Text('확인', style: TextStyle(fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.w700)),
                    ),
                  ]),
                ]),
              ],
            ],
            const SizedBox(height: 14),
            _pwField('비밀번호', _pwCtrl),
            if (!_isLogin) ...[
              const SizedBox(height: 14),
              _pwField('비밀번호 확인', _pw2Ctrl),
            ],
            if (_isLogin) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _setAutoLogin(!_autoLogin),
                behavior: HitTestBehavior.opaque,
                child: Row(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      color: _autoLogin ? AppColors.accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: _autoLogin ? AppColors.accent : AppColors.t3, width: 1.5),
                    ),
                    child: _autoLogin
                        ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text('자동 로그인', style: TextStyle(fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.w600, color: AppColors.t2)),
                ]),
              ),
            ],
            const SizedBox(height: 28),
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: AppColors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.red.withValues(alpha: 0.25))),
                  child: Text(_error, style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.red)),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                  elevation: 0,
                ),
                child: Text(_isLogin ? '로그인' : '회원가입', style: const TextStyle(fontSize: 14, fontFamily: 'monospace', fontWeight: FontWeight.w700, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(_isLogin ? '계정이 없으신가요?' : '이미 계정이 있으신가요?', style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.t3)),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => setState(() => _isLogin = !_isLogin),
                child: Text(_isLogin ? '회원가입' : '로그인', style: const TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.accent)),
              ),
            ]),
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }

  Widget _tab(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: active ? Colors.white : AppColors.t3)),
        ),
      ),
    );
  }

  Widget _authField(String label, String hint, TextEditingController ctrl, TextInputType type) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.t3, letterSpacing: 2)),
      const SizedBox(height: 7),
      TextField(
        controller: ctrl,
        keyboardType: type,
        style: TextStyle(fontSize: 14, color: AppColors.t1),
        decoration: InputDecoration(
          hintText: hint, hintStyle: TextStyle(color: AppColors.t3, fontSize: 13),
          filled: true, fillColor: AppColors.panel,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
        ),
      ),
    ]);
  }

  Widget _pwField(String label, TextEditingController ctrl) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.t3, letterSpacing: 2)),
      const SizedBox(height: 7),
      TextField(
        controller: ctrl,
        obscureText: !_pwVisible,
        style: TextStyle(fontSize: 14, color: AppColors.t1),
        decoration: InputDecoration(
          hintText: '••••••••', hintStyle: TextStyle(color: AppColors.t3, fontSize: 13),
          filled: true, fillColor: AppColors.panel,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
          suffixIcon: IconButton(
            icon: Icon(_pwVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18, color: AppColors.t3),
            onPressed: () => setState(() => _pwVisible = !_pwVisible),
          ),
        ),
      ),
    ]);
  }
}
