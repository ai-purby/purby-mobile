import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../app_colors.dart';

// ─── Auth Screen (로그인 / 회원가입) ─────────────────────────────────────────
class AuthScreen extends StatefulWidget {
  final Function(bool autoLogin, String email, String token) onLogin;
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

  Future<void> _sendVerifyCode() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = '올바른 이메일을 입력해주세요.');
      return;
    }
    setState(() { _sendingCode = true; _error = ''; });

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/auth/send-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      if (response.statusCode == 200) {
        setState(() { _codeSent = true; _sendingCode = false; });
      } else {
        setState(() { _error = '이메일 전송에 실패했습니다.'; _sendingCode = false; });
      }
    } catch (e) {
      setState(() { _error = '서버 연결에 실패했습니다.'; _sendingCode = false; });
    }
  }

  Future<void> _verifyCode() async {
    final email = _emailCtrl.text.trim();
    final code = _codeCtrl.text.trim();

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/auth/verify-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      );
      if (response.statusCode == 200) {
        setState(() { _codeVerified = true; _error = ''; });
      } else {
        setState(() => _error = '인증번호가 올바르지 않습니다.');
      }
    } catch (e) {
      setState(() => _error = '서버 연결에 실패했습니다.');
    }
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pw = _pwCtrl.text;

    if (_isLogin) {
      // 로그인 — 백엔드에서 확인
      try {
        final response = await http.post(
          Uri.parse('http://10.0.2.2:8000/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': pw}),
        );
        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          final token = body['access_token'] as String;
          widget.onLogin(_autoLogin, email, token);
        } else {
          final body = jsonDecode(response.body);
          setState(() => _error = body['detail'] ?? '이메일 또는 비밀번호가 올바르지 않습니다.');
        }
      } catch (e) {
        setState(() => _error = '서버 연결에 실패했습니다.');
      }
    } else {
      // 회원가입 — 유효성 검사
      if (!_codeVerified) {
        setState(() => _error = '이메일 인증을 완료해주세요.');
        return;
      }
      if (pw.isEmpty) {
        setState(() => _error = '비밀번호를 입력해주세요.');
        return;
      }
      if (pw != _pw2Ctrl.text) {
        setState(() => _error = '비밀번호가 일치하지 않습니다.');
        return;
      }

      // 회원가입 — 백엔드에 저장 (중복 체크 포함)
      try {
        final response = await http.post(
          Uri.parse('http://10.0.2.2:8000/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': pw}),
        );
        if (!mounted) return;
        if (response.statusCode == 200 || response.statusCode == 201) {
          setState(() {
            _error = '';
            _isLogin = true;
            _codeSent = false;
            _codeVerified = false;
            _emailCtrl.clear();
            _pwCtrl.clear();
            _pw2Ctrl.clear();
            _codeCtrl.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('회원가입이 완료되었습니다. 로그인해주세요.')),
          );
        } else {
          final body = jsonDecode(response.body);
          setState(() => _error = body['detail'] ?? '회원가입에 실패했습니다.');
        }
      } catch (e) {
        setState(() => _error = '서버 연결에 실패했습니다.');
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
                      onPressed: () => _verifyCode(),
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
                onPressed: () => _submit(),
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