import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final ValueChanged<bool> onDarkToggle;
  final ValueChanged<String> onNameChange;
  final VoidCallback onLogout;
  const MainScreen({
    super.key,
    required this.isDark,
    required this.aiName,
    required this.email,
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

  String get _todayKey {
    final now = DateTime.now();
    return '${widget.email}_schedules_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_todayKey);
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
    await prefs.setString(_todayKey, jsonEncode(list));
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(aiName: widget.aiName, schedules: _schedules),
      ScheduleScreen(
        schedules: _schedules,
        email: widget.email,
        onSchedulesChanged: (updated) {
          setState(() {
            _schedules
              ..clear()
              ..addAll(updated);
          });
          _saveSchedules();
        },
      ),
      const ManualScreen(),
      SettingsScreen(
        isDark: widget.isDark,
        aiName: widget.aiName,
        email: widget.email,
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
