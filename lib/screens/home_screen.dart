import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../widgets/home_widgets.dart';

// ─── HomeScreen ───────────────────────────────────────────────────────────────
class HomeScreen extends StatelessWidget {
  final String aiName;
  final List<Map<String, dynamic>> schedules;
  const HomeScreen({super.key, required this.aiName, required this.schedules});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
        decoration: BoxDecoration(
          color: AppColors.panel,
          border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('홈', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.t1)),
          Text('안녕, $aiName! 👋', style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.t3)),
        ]),
      ),
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          QuickActionsCard(), const SizedBox(height: 12),
          TodayScheduleCard(schedules: schedules), const SizedBox(height: 12),
          AiResultsCard(), const SizedBox(height: 20),
        ]),
      )),
    ]);
  }
}
