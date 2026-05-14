import 'package:flutter/material.dart';
import '../app_colors.dart';

class ManualScreen extends StatefulWidget {
  const ManualScreen({super.key});
  @override
  State<ManualScreen> createState() => _ManualScreenState();
}

class _ManualScreenState extends State<ManualScreen> {
  int? _expandedIndex;

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
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('디바이스 메뉴얼',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.t1)),
            const SizedBox(height: 2),
            Text('Purby 사용 가이드',
                style: TextStyle(fontSize: 12, color: AppColors.t3)),
          ]),
        ),
      ),

      // ── 카드 그리드
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          children: [
            for (int i = 0; i < _items.length; i += 2)
              Padding(
                padding: EdgeInsets.only(bottom: i + 2 < _items.length ? 12 : 0),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _buildCard(i)),
                      const SizedBox(width: 12),
                      if (i + 1 < _items.length)
                        Expanded(child: _buildCard(i + 1))
                      else
                        const Expanded(child: SizedBox()),
                    ],
                  ),
                ),
              ),
          ],
        ),
      )),
    ]);
  }

  Widget _buildCard(int index) {
    final (icon, color, title, desc) = _items[index];
    final isExpanded = _expandedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _expandedIndex = isExpanded ? null : index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isExpanded ? color.withValues(alpha: 0.06) : AppColors.panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isExpanded ? color.withValues(alpha: 0.35) : AppColors.border,
            width: isExpanded ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isExpanded ? 0.18 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 21, color: color),
              ),
              const Spacer(),
              Icon(
                isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                size: 18, color: AppColors.t3,
              ),
            ]),
            const SizedBox(height: 12),
            Text(title,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.t1)),
            if (isExpanded) ...[
              const SizedBox(height: 8),
              Text(desc,
                  style: TextStyle(fontSize: 11, color: AppColors.t3, height: 1.6)),
            ],
          ],
        ),
      ),
    );
  }
}
