import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../app_colors.dart';

// ─── SettingsScreen ───────────────────────────────────────────────────────────
class SettingsScreen extends StatefulWidget {
  final bool isDark;
  final String aiName;
  final String email;
  final String token;
  final ValueChanged<bool> onDarkToggle;
  final ValueChanged<String> onNameChange;
  final VoidCallback onLogout;
  const SettingsScreen({
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
    _loadSettings();
  }

  TimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _fmtForApi(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _patchSettings(Map<String, dynamic> updates) async {
    try {
      await http.patch(
        Uri.parse('http://10.0.2.2:8000/settings'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'},
        body: jsonEncode(updates),
      );
    } catch (_) {}
  }

  Future<void> _loadSettings() async {
    // 디바이스 연결 정보는 SharedPreferences 유지 (API에 없음)
    final prefs = await SharedPreferences.getInstance();
    final e = widget.email;
    setState(() {
      _deviceIp = prefs.getString('${e}_device_ip') ?? '';
      _isConnected = prefs.getBool('${e}_device_connected') ?? false;
      if (_deviceIp.isNotEmpty) _ipCtrl.text = _deviceIp;
    });

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/settings'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final s = body['settings'] as Map<String, dynamic>;
        setState(() {
          _personality     = s['personality']      as String? ?? '친근한';
          sleepEnabled     = s['sleep_enabled']    as bool?   ?? true;
          sleepStart       = _parseTime(s['sleep_start']    as String? ?? '02:00');
          sleepEnd         = _parseTime(s['sleep_end']      as String? ?? '06:00');
          _briefingEnabled = s['briefing_enabled'] as bool?   ?? false;
          _briefingTime    = _parseTime(s['briefing_time']  as String? ?? '07:00');
          _retroEnabled    = s['retro_enabled']    as bool?   ?? false;
          _retroTime       = _parseTime(s['retro_time']     as String? ?? '22:00');
          _volume          = (s['volume']          as num?)?.toDouble() ?? 0.5;
          _brightness      = (s['brightness']      as num?)?.toDouble() ?? 0.8;
        });
      }
    } catch (_) {}
  }

  Future<void> _pickBriefingTime() async {
    final picked = await showTimePicker(context: context, initialTime: _briefingTime);
    if (picked != null) {
      setState(() => _briefingTime = picked);
      _patchSettings({'briefing_enabled': _briefingEnabled, 'briefing_time': _fmtForApi(picked)});
    }
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
        content: Text('디바이스의 모든 설정이 초기화됩니다.\n이 작업은 되돌릴 수 없습니다.', style: TextStyle(fontSize: 13, color: AppColors.t2, height: 1.6)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('취소', style: TextStyle(color: AppColors.t3))),
          TextButton(
            onPressed: () { Navigator.pop(ctx); /* TODO: 실제 초기화 명령 전송 */ },
            child: Text('초기화', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _connectDevice() async {
    final ip = _ipCtrl.text.trim();
    if (ip.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final e = widget.email;
    await prefs.setString('${e}_device_ip', ip);
    await prefs.setBool('${e}_device_connected', true);
    setState(() { _deviceIp = ip; _isConnected = true; });
  }

  Future<void> _disconnectDevice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${widget.email}_device_connected', false);
    setState(() => _isConnected = false);
  }

  Future<void> _savePersonality(String val) async {
    setState(() => _personality = val);
    _patchSettings({'personality': val});
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.t3.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Row(children: [
              Container(width: 36, height: 36,
                decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.psychology_rounded, size: 18, color: AppColors.accent)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('퍼비 성격 선택', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.t1)),
                Text('AI 의 말투와 응답 스타일', style: TextStyle(fontSize: 10, color: AppColors.t3)),
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
                      Text(desc, style: TextStyle(fontSize: 10, color: AppColors.t3)),
                    ])),
                    if (selected) Icon(Icons.check_circle_rounded, size: 20, color: color),
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
      _patchSettings({'retro_enabled': _retroEnabled, 'retro_time': _fmtForApi(picked)});
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
    if (p != null) {
      setState(() => isStart ? sleepStart = p : sleepEnd = p);
      _patchSettings({'sleep_start': _fmtForApi(sleepStart), 'sleep_end': _fmtForApi(sleepEnd)});
    }
  }

  void _showNameDialog() {
    final ctrl = TextEditingController(text: widget.aiName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('내 이름 설정', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.t1)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('홈 화면 인사말에 표시될 이름을 입력하세요.',
            style: TextStyle(fontSize: 11, color: AppColors.t3)),
          const SizedBox(height: 14),
          TextField(
            controller: ctrl, autofocus: true, maxLength: 10,
            style: TextStyle(fontSize: 16, color: AppColors.t1),
            decoration: InputDecoration(
              hintText: '이름을 입력하세요',
              hintStyle: TextStyle(color: AppColors.t3),
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
              if (ctrl.text.trim().isNotEmpty) {
                widget.onNameChange(ctrl.text.trim());
                _patchSettings({'ai_name': ctrl.text.trim()});
              }
              Navigator.pop(ctx);
            },
            child: const Text('저장', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── build ────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── 헤더
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('설정', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.t1)),
        ),
      ),

      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ══ 프로필 섹션
          _sectionLabel('프로필'),
          _card([
            _row(
              iconBg: AppColors.accent,
              icon: Icons.person_rounded,
              title: '내 이름',
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(widget.aiName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.t2)),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.t3),
              ]),
              onTap: _showNameDialog,
            ),
            _divider(),
            _row(
              iconBg: const Color(0xFF8B5CF6),
              icon: Icons.psychology_rounded,
              title: '퍼비 성격',
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12)),
                  child: Text(_personality, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accent)),
                ),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.t3),
              ]),
              onTap: _showPersonalityModal,
            ),
            _divider(),
            _row(
              iconBg: const Color(0xFF64748B),
              icon: widget.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              title: widget.isDark ? '다크 모드' : '라이트 모드',
              trailing: Switch(value: widget.isDark, onChanged: widget.onDarkToggle, activeColor: AppColors.accent),
            ),
          ]),
          const SizedBox(height: 20),

          // ══ 시간 설정 섹션
          _sectionLabel('시간 설정'),
          _card([
            // 절전 시간 — pill 버튼 2개
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: const Color(0xFF0EA5E9).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.bedtime_rounded, size: 17, color: Color(0xFF0EA5E9)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('절전 시간', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.t1)),
                  Text('설정 시간에 액자가 절전으로 전환됩니다', style: TextStyle(fontSize: 11, color: AppColors.t3)),
                ])),
                Switch(value: sleepEnabled, onChanged: (v) { setState(() => sleepEnabled = v); _patchSettings({'sleep_enabled': v}); }, activeColor: AppColors.accent),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(children: [
                _sleepPill('시작', _fmt(sleepStart), () => _pickSleepTime(true)),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('→', style: TextStyle(fontSize: 16, color: AppColors.t3))),
                _sleepPill('종료', _fmt(sleepEnd), () => _pickSleepTime(false)),
              ]),
            ),
            _divider(),
            // 아침 브리핑
            _row(
              iconBg: AppColors.gold,
              icon: Icons.wb_twilight_rounded,
              title: '아침 브리핑',
              subtitle: '오늘 일정을 요약해드려요',
              trailing: Switch(
                value: _briefingEnabled,
                onChanged: (v) { setState(() => _briefingEnabled = v); _patchSettings({'briefing_enabled': v, 'briefing_time': _fmtForApi(_briefingTime)}); },
                activeColor: AppColors.accent,
              ),
            ),
            if (_briefingEnabled) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(60, 0, 16, 14),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('브리핑 시간', style: TextStyle(fontSize: 12, color: AppColors.t3)),
                  GestureDetector(
                    onTap: _pickBriefingTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(_fmt(_briefingTime), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.accent, letterSpacing: 1)),
                        const SizedBox(width: 6),
                        const Icon(Icons.edit_rounded, size: 12, color: AppColors.accent),
                      ]),
                    ),
                  ),
                ]),
              ),
            ],
            _divider(),
            // 회고 시간
            _row(
              iconBg: const Color(0xFF6B5CE7),
              icon: Icons.auto_stories_rounded,
              title: '회고 시간',
              subtitle: '하루를 돌아보는 알림을 드려요',
              trailing: Switch(
                value: _retroEnabled,
                onChanged: (v) { setState(() => _retroEnabled = v); _patchSettings({'retro_enabled': v, 'retro_time': _fmtForApi(_retroTime)}); },
                activeColor: AppColors.accent,
              ),
            ),
            if (_retroEnabled) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(60, 0, 16, 14),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('회고 시간', style: TextStyle(fontSize: 12, color: AppColors.t3)),
                  GestureDetector(
                    onTap: _pickRetroTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(_fmt(_retroTime), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.accent, letterSpacing: 1)),
                        const SizedBox(width: 6),
                        const Icon(Icons.edit_rounded, size: 12, color: AppColors.accent),
                      ]),
                    ),
                  ),
                ]),
              ),
            ],
          ]),
          const SizedBox(height: 20),

          // ══ 알림 섹션
          _sectionLabel('알림'),
          _card([
            _row(
              iconBg: const Color(0xFFEF4444),
              icon: Icons.notifications_rounded,
              title: '모바일 알림',
              subtitle: '일정 시작 10분 전 알림',
              trailing: Switch(value: schedAlert, onChanged: (v) => setState(() => schedAlert = v), activeColor: AppColors.accent),
            ),
          ]),
          const SizedBox(height: 20),

          // ══ 디스플레이 섹션
          _sectionLabel('디스플레이'),
          _card([
            _sliderRow(
              iconBg: const Color(0xFF6B5CE7),
              icon: Icons.volume_up_rounded,
              label: '볼륨',
              value: _volume,
              color: AppColors.accent,
              onChanged: (v) { setState(() => _volume = v); _patchSettings({'volume': v}); },
            ),
            _divider(),
            _sliderRow(
              iconBg: AppColors.gold,
              icon: Icons.brightness_6_rounded,
              label: '밝기',
              value: _brightness,
              color: AppColors.gold,
              onChanged: (v) { setState(() => _brightness = v); _patchSettings({'brightness': v}); },
            ),
            _divider(),
            _row(
              iconBg: const Color(0xFF475569),
              icon: Icons.monitor_rounded,
              title: '화면 끄기',
              subtitle: '액자 화면 즉시 끄기',
              trailing: Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.t3),
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 20),

          // ══ 앱 정보 섹션
          _sectionLabel('앱 정보'),
          _card([
            // 디바이스 연결 상태
            _row(
              iconBg: _isConnected ? AppColors.green : const Color(0xFF94A3B8),
              icon: Icons.router_rounded,
              title: '디바이스 연결',
              subtitle: _isConnected ? _deviceIp : '연결되지 않음',
              trailing: _isConnected
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12)),
                      child: Text('연결됨', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.green)),
                    )
                  : Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.t3),
            ),
            // IP 입력 (미연결 시)
            if (!_isConnected)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _ipCtrl,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(fontSize: 14, color: AppColors.t1),
                      decoration: InputDecoration(
                        hintText: '192.168.0.14',
                        hintStyle: TextStyle(color: AppColors.t3, fontSize: 13),
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
                    child: const Text('연결', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),
            // 연결된 경우 연결 해제 / 공장 초기화
            if (_isConnected) ...[
              _divider(),
              _row(
                iconBg: AppColors.gold,
                icon: Icons.restart_alt_rounded,
                title: '공장 초기화',
                subtitle: '모든 설정을 초기값으로 되돌립니다',
                trailing: Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.t3),
                onTap: _showFactoryResetDialog,
              ),
              _divider(),
              _row(
                iconBg: AppColors.red,
                icon: Icons.link_off_rounded,
                title: '연결 해제',
                titleColor: AppColors.red,
                trailing: Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.t3),
                onTap: _disconnectDevice,
              ),
            ],
            _divider(),
            _row(
              iconBg: const Color(0xFF6B5CE7),
              icon: Icons.info_outline_rounded,
              title: '버전 정보',
              subtitle: 'Persona Frame v1.0.0 · 2026',
              trailing: const SizedBox.shrink(),
            ),
            _divider(),
            // 로그아웃 (빨간색)
            _row(
              iconBg: AppColors.red.withValues(alpha: 0.15),
              icon: Icons.logout_rounded,
              title: '로그아웃',
              titleColor: AppColors.red,
              trailing: Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.red.withValues(alpha: 0.5)),
              onTap: widget.onLogout,
            ),
          ]),
          const SizedBox(height: 20),
        ]),
      )),
    ]);
  }

  // ── 헬퍼 위젯들 ─────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.t3, letterSpacing: 0.5)),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: AppColors.border),
    );
  }

  Widget _row({
    required Color iconBg,
    required IconData icon,
    required String title,
    String? subtitle,
    Color? titleColor,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 17, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: titleColor ?? AppColors.t1)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 11, color: AppColors.t3)),
            ],
          ])),
          trailing,
        ]),
      ),
    );
  }

  Widget _sleepPill(String label, String time, VoidCallback onTap) {
    return Expanded(child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.20)),
        ),
        child: Column(children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.t3)),
          const SizedBox(height: 4),
          Text(time, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.accent, letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text('탭하여 변경', style: TextStyle(fontSize: 9, color: AppColors.t3)),
        ]),
      ),
    ));
  }

  Widget _sliderRow({
    required Color iconBg,
    required IconData icon,
    required String label,
    required double value,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 17, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.t1)),
            Text('${(value * 100).round()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ]),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.12),
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.12),
            ),
            child: Slider(value: value, min: 0, max: 1, onChanged: onChanged),
          ),
        ])),
      ]),
    );
  }
}
