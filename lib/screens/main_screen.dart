import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_colors.dart';
import 'home_screen.dart';
import 'schedule_screen.dart';
import 'settings_screen.dart';

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
