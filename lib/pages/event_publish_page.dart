import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/stores.dart';
import '../theme/med_theme.dart';
import '../widgets/common.dart';
import 'auth/login_page.dart';

/// 发起活动 — user-submitted event (pending until admin approves).
class EventPublishPage extends StatefulWidget {
  const EventPublishPage({super.key});

  @override
  State<EventPublishPage> createState() => _EventPublishPageState();
}

class _EventPublishPageState extends State<EventPublishPage> {
  final _title = TextEditingController(), _place = TextEditingController(), _detail = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_title, _place, _detail]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!context.read<AuthStore>().loggedIn) {
      showToast(context, '请先登录');
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginPage()));
      return;
    }
    if (_title.text.trim().isEmpty || _place.text.trim().isEmpty) {
      showToast(context, '请填写活动标题与地点');
      return;
    }
    setState(() => _busy = true);
    try {
      String two(int n) => n.toString().padLeft(2, '0');
      await context.read<EventsStore>().submit({
        'title': _title.text.trim(),
        'date': '${_date.year}-${two(_date.month)}-${two(_date.day)}',
        'time': '${two(_time.hour)}:${two(_time.minute)}',
        'place': _place.text.trim(),
        'detail': _detail.text.trim(),
      });
      if (!mounted) return;
      showToast(context, '活动已提交，审核通过后展示');
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showToast(context, '提交失败：$e');
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final T = MedTheme.of(context);
    String two(int n) => n.toString().padLeft(2, '0');
    return Scaffold(
      backgroundColor: T.bg,
      appBar: const SubHeader(title: '发起活动'),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: T.surface, borderRadius: BorderRadius.circular(16), boxShadow: T.shadowSm),
          child: Column(children: [
            AuthField(controller: _title, label: '活动标题 *'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _pick(T, '日期', '${_date.year}-${two(_date.month)}-${two(_date.day)}', () async {
                  final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                  if (d != null) setState(() => _date = d);
                }),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _pick(T, '时间', '${two(_time.hour)}:${two(_time.minute)}', () async {
                  final t = await showTimePicker(context: context, initialTime: _time);
                  if (t != null) setState(() => _time = t);
                }),
              ),
            ]),
            const SizedBox(height: 12),
            AuthField(controller: _place, label: '活动地点 *'),
            const SizedBox(height: 12),
            TextField(
              controller: _detail,
              maxLines: 6,
              style: TextStyle(color: T.ink, fontSize: 14, height: 1.6),
              decoration: InputDecoration(
                labelText: '活动详情',
                alignLabelWithHint: true,
                labelStyle: TextStyle(color: T.inkSubtle, fontSize: 13.5),
                filled: true, fillColor: T.surface,
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: T.divider)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: T.primary, width: 1.5)),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        Text('提交后由管理员审核，通过后在「义诊活动」与首页「活动报名」中展示。', style: TextStyle(fontSize: 12, color: T.inkSubtle, height: 1.5)),
        const SizedBox(height: 18),
        PrimaryButton(label: '提交活动', loading: _busy, onTap: _submit),
      ]),
    );
  }

  Widget _pick(MedTokens T, String label, String value, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: T.divider)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 11, color: T.inkSubtle)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 14, color: T.ink, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}
