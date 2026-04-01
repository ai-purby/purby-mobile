import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';
import 'screens/auth_screen.dart';
import 'screens/main_screen.dart';

void main() => runApp(const PersonaFrameApp());

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
