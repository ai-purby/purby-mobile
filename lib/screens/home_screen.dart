import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../widgets/home_widgets.dart';

// ─── HomeScreen ───────────────────────────────────────────────────────────────
class HomeScreen extends StatelessWidget {
  final String aiName;
  final List<Map<String, dynamic>> schedules;
  final bool isConnected;
  const HomeScreen({super.key, required this.aiName, required this.schedules, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── 상단 헤더
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('홈', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.t1)),
            const SizedBox(height: 2),
            Text('Purby', style: TextStyle(fontSize: 12, color: AppColors.t3)),
          ]),
          // 디바이스 연결 상태 pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (isConnected ? AppColors.green : AppColors.t3).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: (isConnected ? AppColors.green : AppColors.t3).withValues(alpha: 0.25)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 7, height: 7,
                decoration: BoxDecoration(
                  color: isConnected ? AppColors.green : AppColors.t3,
                  shape: BoxShape.circle,
                  boxShadow: isConnected ? [BoxShadow(color: AppColors.green.withValues(alpha: 0.5), blurRadius: 4)] : null,
                )),
              const SizedBox(width: 6),
              Text(
                isConnected ? '디바이스 연결됨' : '디바이스 미연결',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isConnected ? AppColors.green : AppColors.t3),
              ),
            ]),
          ),
        ]),
      ),

      // ── 스크롤 영역
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // ── 캐릭터 + 인사말 카드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: AppColors.panel,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(children: [
              // 연보라 원형 배경 + 캐릭터
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('🤖', style: const TextStyle(fontSize: 56)),
                ),
              ),
              const SizedBox(height: 18),
              Text('안녕하세요! 👋', style: TextStyle(fontSize: 15, color: AppColors.t2, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text('${aiName.isNotEmpty ? aiName : '사용자'}님!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.t1)),
            ]),
          ),

          const SizedBox(height: 12),
          QuickActionsCard(),
          const SizedBox(height: 12),
          TodayScheduleCard(schedules: schedules),
          const SizedBox(height: 12),
          AiResultsCard(),
          const SizedBox(height: 20),
        ]),
      )),
    ]);
  }
}
