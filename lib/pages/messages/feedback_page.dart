import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/stores.dart';
import '../../theme/med_theme.dart';
import '../../widgets/common.dart';
import '../auth/login_page.dart';
import 'chat_page.dart';

/// 反馈信息 — submit feedback; history shown in the feedback channel.
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _ctl = TextEditingController();
  String _type = '功能建议';
  bool _busy = false;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!context.read<AuthStore>().loggedIn) {
      showToast(context, '请先登录');
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginPage()));
      return;
    }
    if (_ctl.text.trim().length < 5) {
      showToast(context, '请至少输入 5 个字');
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read<MessagesStore>().feedback('[$_type] ${_ctl.text.trim()}');
      if (!mounted) return;
      showToast(context, '反馈已提交，感谢您的建议');
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ChatPage(channel: 'feedback', title: '反馈信息')));
    } catch (e) {
      if (mounted) showToast(context, '提交失败：$e');
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final T = MedTheme.of(context);
    return Scaffold(
      backgroundColor: T.bg,
      appBar: SubHeader(
        title: '反馈信息',
        trailing: TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatPage(channel: 'feedback', title: '反馈记录'))),
          child: Text('历史记录', style: TextStyle(color: T.primary, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: T.surface, borderRadius: BorderRadius.circular(16), boxShadow: T.shadowSm),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('反馈类型', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: T.ink)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final t in ['功能建议', '内容举报', '账号问题', '其它'])
                GestureDetector(
                  onTap: () => setState(() => _type = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(color: _type == t ? T.primary : T.bg, borderRadius: BorderRadius.circular(999)),
                    child: Text(t, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _type == t ? Colors.white : T.inkMuted)),
                  ),
                ),
            ]),
            const SizedBox(height: 18),
            Text('反馈内容', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: T.ink)),
            const SizedBox(height: 10),
            TextField(
              controller: _ctl,
              maxLines: 7,
              maxLength: 500,
              style: TextStyle(fontSize: 14, color: T.ink, height: 1.6),
              decoration: InputDecoration(
                hintText: '请描述您遇到的问题或建议，我们会尽快处理…',
                hintStyle: TextStyle(color: T.inkSubtle, fontSize: 13.5),
                filled: true,
                fillColor: T.bg,
                counterStyle: TextStyle(color: T.inkSubtle, fontSize: 11),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        PrimaryButton(label: '提交反馈', loading: _busy, onTap: _submit),
      ]),
    );
  }
}
