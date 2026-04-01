import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_colors.dart';

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

        // ── 다크 / 라이트 모드 토글
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
