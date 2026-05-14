import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';
import 'screens/auth_screen.dart';
import 'screens/main_screen.dart';
import 'screens/qr_scan_screen.dart';

void main() => runApp(const PersonaFrameApp());

// ─── App Root (isDark + aiName 전역 상태) ────────────────────────────────────
class PersonaFrameApp extends StatefulWidget {
  const PersonaFrameApp({super.key});
  @override
  State<PersonaFrameApp> createState() => _PersonaFrameAppState();
}

class _PersonaFrameAppState extends State<PersonaFrameApp> {
  bool _isDark = false;
  String _aiName = '';
  bool _loggedIn = false;
  bool _deviceLinked = false;
  bool _autoLogin = false;
  String _currentEmail = '';
  String _token = '';

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('logged_in_email') ?? '';
    final token = prefs.getString('auth_token') ?? '';
    if ((prefs.getBool('logged_in') ?? false) && email.isNotEmpty && token.isNotEmpty) {
      setState(() {
        _currentEmail = email;
        _token = token;
        _isDark = prefs.getBool('${email}_is_dark') ?? false;
        _aiName = prefs.getString('${email}_ai_name') ?? '';
        _loggedIn = true;
        _deviceLinked = prefs.getBool('${email}_device_linked') ?? false;
        _autoLogin = true;
      });
    }
  }

  Future<void> _setDark(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_currentEmail}_is_dark', val);
    setState(() => _isDark = val);
  }

  Future<void> _login(bool autoLogin, String email, String token, {bool isNew = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (autoLogin) {
      await prefs.setBool('logged_in', true);
      await prefs.setString('logged_in_email', email);
      await prefs.setString('auth_token', token);
    }
    final linked = isNew ? false : true;
    setState(() {
      _currentEmail = email;
      _token = token;
      _autoLogin = autoLogin;
      _isDark = prefs.getBool('${email}_is_dark') ?? false;
      _aiName = prefs.getString('${email}_ai_name') ?? '';
      _loggedIn = true;
      _deviceLinked = linked;
    });
  }

  Future<void> _onDeviceLinked(bool autoLogin, String email, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${email}_device_linked', true);
    setState(() { _deviceLinked = true; });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('logged_in', false);
    await prefs.remove('logged_in_email');
    await prefs.remove('auth_token');
    setState(() { _loggedIn = false; _currentEmail = ''; _aiName = ''; _token = ''; });
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
      home: !_loggedIn
          ? AuthScreen(onLogin: _login)
          : !_deviceLinked
              ? QrScanScreen(
                  token: _token,
                  email: _currentEmail,
                  autoLogin: _autoLogin,
                  onLinked: _onDeviceLinked,
                  onLogout: _logout,
                )
              : MainScreen(
                  isDark: _isDark,
                  aiName: _aiName,
                  email: _currentEmail,
                  token: _token,
                  onDarkToggle: _setDark,
                  onNameChange: (n) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('${_currentEmail}_ai_name', n);
                    setState(() => _aiName = n);
                  },
                  onLogout: _logout,
                ),
    );
  }
}
