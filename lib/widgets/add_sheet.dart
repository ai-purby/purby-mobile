import 'package:flutter/material.dart';
import '../app_colors.dart';

class AddSheet extends StatefulWidget {
  final int colorCount;
  final List<Color> colors;
  final void Function(Map<String, dynamic>) onAdd;
  const AddSheet({super.key, required this.colorCount, required this.colors, required this.onAdd});
  @override
  State<AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<AddSheet> {
  final _titleCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);

  @override
  void dispose() {
    _titleCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 38, height: 4, decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Align(alignment: Alignment.centerLeft, child: Text('일정 추가', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.t1))),
            const SizedBox(height: 14),
            _field('일정 이름', '예) 팀 미팅, 운동', _titleCtrl),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _timePicker('시작 시간', _startTime, (t) => setState(() => _startTime = t))),
              const SizedBox(width: 10),
              Expanded(child: _timePicker('종료 시간', _endTime, (t) => setState(() => _endTime = t))),
            ]),
            const SizedBox(height: 12),
            _field('메모 (선택)', '추가 메모', _memoCtrl),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () {
                if (_titleCtrl.text.trim().isEmpty) return;
                widget.onAdd({
                  'time': '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                  'title': _titleCtrl.text.trim(),
                  'color': widget.colors[widget.colorCount % widget.colors.length],
                  'done': false,
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
              ),
              child: const Text('일정 등록', style: TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w700, letterSpacing: 1)),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _field(String label, String hint, TextEditingController ctrl) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 8, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.t3, letterSpacing: 2)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.t1),
        decoration: InputDecoration(
          hintText: hint, hintStyle: TextStyle(color: AppColors.t3, fontSize: 13),
          filled: true, fillColor: Colors.white.withValues(alpha: 0.65),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.accent)),
        ),
      ),
    ]);
  }

  Widget _timePicker(String label, TimeOfDay time, ValueChanged<TimeOfDay> onChanged) {
    return GestureDetector(
      onTap: () async {
        final p = await showTimePicker(context: context, initialTime: time);
        if (p != null) onChanged(p);
      },
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 8, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppColors.t3, letterSpacing: 2)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.65), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
          child: Text('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.t1)),
        ),
      ]),
    );
  }
}
