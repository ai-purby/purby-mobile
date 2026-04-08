import 'package:flutter/material.dart';
import '../app_colors.dart';

// ─── QuickActionsCard ─────────────────────────────────────────────────────────
class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('앱 직접 제어', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.t1)),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.6,
          children: [
            _tile(Icons.music_note_rounded,   '음악 재생',  '버튼 탭 → 액자에 재생', const Color(0xFF6B5CE7)),
            _tile(Icons.timer_rounded,         '타이머 설정', '뽀모도로 25분 시작',   const Color(0xFF2A9C70)),
            _tile(Icons.people_rounded,        '일과 회고',  'AI 요약 받기',         const Color(0xFFA07828)),
            _tile(Icons.power_settings_new_rounded, '절전 모드', '액자 즉시 절전',   const Color(0xFF94A3B8)),
          ],
        ),
      ]),
    );
  }

  static Widget _tile(IconData icon, String title, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 15, color: color),
        ),
        const Spacer(),
        Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.t1)),
        const SizedBox(height: 2),
        Text(sub, style: TextStyle(fontSize: 9, color: AppColors.t3)),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('오늘 일정', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.t1)),
          Text('${schedules.length}개', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent)),
        ]),
        const SizedBox(height: 12),
        if (schedules.isEmpty)
          Center(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('등록된 일정이 없습니다.', style: TextStyle(fontSize: 13, color: AppColors.t3)),
          ))
        else
          ...schedules.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
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
    return Opacity(
      opacity: done ? 0.5 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isNow ? AppColors.accent.withValues(alpha: 0.06) : AppColors.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isNow ? AppColors.accent.withValues(alpha: 0.20) : AppColors.border),
        ),
        child: Row(children: [
          Container(width: 8, height: 8,
            decoration: BoxDecoration(
              color: color, shape: BoxShape.circle,
              boxShadow: isNow ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 5)] : null,
            )),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(time, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.t3, letterSpacing: 1)),
            const SizedBox(height: 2),
            Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.t1,
              decoration: done ? TextDecoration.lineThrough : null)),
          ])),
          if (isNow)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8)),
              child: const Text('NOW', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.accent)),
            ),
        ]),
      ),
    );
  }
}

// ─── AiResultsCard ────────────────────────────────────────────────────────────
class AiResultsCard extends StatelessWidget {
  const AiResultsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('AI 처리 로그', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.t1)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('대기 중', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.t3)),
          ),
        ]),
        const SizedBox(height: 24),
        Center(child: Column(children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.sensors_rounded, size: 28, color: AppColors.accent.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 12),
          Text('AI 명령 결과가 여기에 표시됩니다', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.t2)),
          const SizedBox(height: 4),
          Text('실시간 연동 준비 중', style: TextStyle(fontSize: 11, color: AppColors.t3)),
        ])),
        const SizedBox(height: 20),
      ]),
    );
  }
}
