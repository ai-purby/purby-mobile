import 'package:flutter/material.dart';
import '../app_colors.dart';

// ─── ManualScreen ─────────────────────────────────────────────────────────────
class ManualScreen extends StatelessWidget {
  const ManualScreen({super.key});

  static const _items = [
    (
      Icons.monitor_rounded,
      Color(0xFF6B5CE7),
      '디바이스 연결',
      '앱과 액자를 같은 Wi-Fi에\n연결한 후 IP를 입력하세요',
    ),
    (
      Icons.qr_code_scanner_rounded,
      Color(0xFF2A9C70),
      'QR 스캔',
      'QR 코드로 빠르게\n디바이스를 등록하세요',
    ),
    (
      Icons.wifi_rounded,
      Color(0xFFA07828),
      'Wi-Fi 설정',
      '디바이스를 홈 네트워크에\n연결하는 방법을 안내해요',
    ),
    (
      Icons.notifications_rounded,
      Color(0xFF3A78C9),
      '알림 설정',
      '일정 알림과 브리핑 시간을\n원하는 대로 조정하세요',
    ),
    (
      Icons.build_rounded,
      Color(0xFFD94040),
      '문제해결',
      '연결 오류나 동작 이상 시\n이 가이드를 참고하세요',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── 헤더
      Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        color: Colors.transparent,
        child: Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              '디바이스 메뉴얼',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.t1),
            ),
            const SizedBox(height: 2),
            Text(
              'Persona Frame 사용 가이드',
              style: TextStyle(fontSize: 12, color: AppColors.t3),
            ),
          ]),
        ]),
      ),

      // ── 그리드
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.92,
          children: _items.map((item) => _card(item.$1, item.$2, item.$3, item.$4)).toList(),
        ),
      )),
    ]);
  }

  static Widget _card(IconData icon, Color color, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 24, color: color),
        ),
        const Spacer(),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF181620))),
        const SizedBox(height: 6),
        Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFFA09EB8), height: 1.5)),
      ]),
    );
  }
}
