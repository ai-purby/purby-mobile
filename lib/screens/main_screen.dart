import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../app_colors.dart';
import 'home_screen.dart';
import 'schedule_screen.dart';
import 'settings_screen.dart';
import 'manual_screen.dart';

// ─── MainScreen ──────────────────────────────────────────────────────────────
class MainScreen extends StatefulWidget {
  final bool isDark;
  final String aiName;
  final String email;
  final String token;
  final ValueChanged<bool> onDarkToggle;
  final ValueChanged<String> onNameChange;
  final VoidCallback onLogout;
  const MainScreen({
    super.key,
    required this.isDark,
    required this.aiName,
    required this.email,
    required this.token,
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

  final List<Color> _colors = [
    const Color(0xFF3A78C9), const Color(0xFFA07828), const Color(0xFF2A9C70),
    const Color(0xFFC08000), const Color(0xFF7844C0), const Color(0xFFD94040),
  ];

  @override
  void initState() {
    super.initState();
    _fetchTodaySchedules();
  }

  Future<void> _fetchTodaySchedules() async {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/schedules?date=$dateStr'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final list = body['schedules'] as List;
        setState(() {
          _schedules.clear();
          _schedules.addAll(list.asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value as Map<String, dynamic>;
            final startTime = DateTime.parse(e['start_time'] as String);
            return {
              'id': e['id'],
              'time': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
              'title': e['title'],
              'color': _colors[i % _colors.length],
              'done': e['is_done'] as bool,
              'isNow': false,
            };
          }));
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(aiName: widget.aiName, schedules: _schedules),
      ScheduleScreen(
        schedules: _schedules,
        email: widget.email,
        token: widget.token,
        onSchedulesChanged: (updated) {
          setState(() {
            _schedules
              ..clear()
              ..addAll(updated);
          });
        },
      ),
      const ManualScreen(),
      SettingsScreen(
        isDark: widget.isDark,
        aiName: widget.aiName,
        email: widget.email,
        token: widget.token,
        onDarkToggle: widget.onDarkToggle,
        onNameChange: widget.onNameChange,
        onLogout: widget.onLogout,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [
          Expanded(child: IndexedStack(index: _currentIndex, children: screens)),
          // ── 하단 네비게이션
          Container(
            height: 72,
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            decoration: BoxDecoration(
              color: AppColors.panel,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(children: [
              _nav(Icons.home_rounded, '홈', 0),
              _nav(Icons.calendar_month_rounded, '일정', 1),
              _nav(Icons.menu_book_rounded, '메뉴얼', 2),
              _nav(Icons.settings_rounded, '설정', 3),
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
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: on
                ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
                : const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: on ? AppColors.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 20, color: on ? Colors.white : AppColors.t3),
              if (on) ...[
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
