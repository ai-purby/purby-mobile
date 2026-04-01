import 'package:flutter/material.dart';
import '../app_colors.dart';

// ─── QuickActionsCard ─────────────────────────────────────────────────────────
class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('앱 직접 제어', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.t1)),
        const SizedBox(height: 12),
        GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.55, children: [
          _tile(Icons.music_note_rounded, '음악 재생', '버튼 탭 → 액자에 재생'),
          _tile(Icons.timer_rounded, '타이머 설정', '뽀모도로 25분 시작'),
          _tile(Icons.people_rounded, '일과 회고', 'AI 요약 받기'),
          _tile(Icons.logout_rounded, '절전 모드', '액자 즉시 절전'),
        ]),
      ]),
    );
  }
  static Widget _tile(IconData icon, String title, String sub) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(width: 30, height: 30, decoration: BoxDecoration(color: AppColors.accent2, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 15, color: AppColors.accent)),
          Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: AppColors.green.withValues(alpha: 0.2))),
            child: const Text('즉시', style: TextStyle(fontSize: 7, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.green, letterSpacing: 1))),
        ]),
        const Spacer(),
        Text(title, style: TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.t1)),
        const SizedBox(height: 2),
        Text(sub, style: TextStyle(fontSize: 9, fontFamily: 'monospace', color: AppColors.t3)),
      ]),
    );
  }
}

// ─── TodayScheduleCard ────────────────────────────────────────────────────────
class TodayScheduleCard extends StatelessWidget {
  final List<Map<String, dynamic>> schedules;
  const TodayScheduleCard({super.key, required this.schedules});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('오늘 일정', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.t1)),
        const SizedBox(height: 12),
        if (schedules.isEmpty)
          Text('등록된 일정이 없습니다.', style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.t3))
        else
          ...schedules.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _SchedItem(
              time: s['time'] as String,
              title: s['title'] as String,
              color: s['color'] as Color,
              done: s['done'] as bool? ?? false,
              isNow: s['isNow'] as bool? ?? false,
            ),
          )),
      ]),
    );
  }
}

class _SchedItem extends StatelessWidget {
  final String time, title;
  final Color color;
  final bool done, isNow;
  const _SchedItem({required this.time, required this.title, required this.color, this.done = false, this.isNow = false});
  @override
  Widget build(BuildContext context) {
    return Opacity(opacity: done ? 0.45 : 1.0, child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: isNow ? const Color(0x123A78C9) : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: isNow ? const Color(0x383A78C9) : Colors.white.withValues(alpha: 0.75)),
      ),
      child: Row(children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle,
          boxShadow: isNow ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 5)] : null)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(time, style: TextStyle(fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.w600, color: AppColors.t3, letterSpacing: 1)),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.t1)),
        ])),
        if (isNow) Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(color: const Color(0x1A3A78C9), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0x333A78C9))),
          child: const Text('NOW', style: TextStyle(fontSize: 8, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.accent))),
      ]),
    ));
  }
}

// ─── AiResultsCard ────────────────────────────────────────────────────────────
class AiResultsCard extends StatelessWidget {
  const AiResultsCard({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('AI 처리 결과', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.t1)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: AppColors.accent2, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border)),
            child: Text('대기 중', style: TextStyle(fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.t3, letterSpacing: 1)),
          ),
        ]),
        const SizedBox(height: 20),
        Center(child: Column(children: [
          Icon(Icons.sensors_rounded, size: 32, color: AppColors.t3),
          const SizedBox(height: 10),
          Text('AI 명령 결과가 여기에 표시됩니다', style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.t3)),
          const SizedBox(height: 4),
          Text('실시간 연동 준비 중', style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.t3.withValues(alpha: 0.6), letterSpacing: 1)),
        ])),
        const SizedBox(height: 20),
      ]),
    );
  }
}
