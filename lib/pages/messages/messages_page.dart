import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/stores.dart';
import '../../theme/med_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/med_icons.dart';
import '../auth/login_page.dart';
import 'chat_page.dart';
import 'feedback_page.dart';

/// 消息 — 平台分享 / 反馈信息 / 系统通知 / 客服中心; private chats below. No bottom nav.
class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<MessagesStore>().refresh());
  }

  @override
  Widget build(BuildContext context) {
    final T = MedTheme.of(context);
    final auth = context.watch<AuthStore>();
    final m = context.watch<MessagesStore>();
    if (!auth.loggedIn) {
      return Scaffold(
        backgroundColor: T.bg,
        appBar: const SubHeader(title: '消息'),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 72, height: 72, decoration: BoxDecoration(shape: BoxShape.circle, color: T.primarySoft), child: Center(child: MedIcon(MedIcons.doctorChat, size: 32, color: T.primary))),
            const SizedBox(height: 14),
            Text('登录后查看消息', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: T.ink)),
            const SizedBox(height: 16),
            SizedBox(width: 160, child: PrimaryButton(label: '去登录', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginPage())))),
          ]),
        ),
      );
    }
    final channels = [
      ('share', '平台分享', MedIcons.send, T.tintSky),
      ('feedback', '反馈信息', MedIcons.doc, T.tintAmber),
      ('sysnotify', '系统通知', MedIcons.shieldPlus, T.tintMint),
      ('service', '客服中心', MedIcons.headset, T.tintIndigo),
    ];
    return Scaffold(
      backgroundColor: T.bg,
      appBar: const SubHeader(title: '消息'),
      body: RefreshIndicator(
        color: T.primary,
        onRefresh: m.refresh,
        child: ListView(padding: const EdgeInsets.all(14), children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(color: T.surface, borderRadius: BorderRadius.circular(16), boxShadow: T.shadowSm),
            child: Row(children: [
              for (final c in channels)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (c.$1 == 'feedback') {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FeedbackPage()));
                      } else {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatPage(channel: c.$1, title: c.$2)));
                      }
                    },
                    child: Column(children: [
                      Stack(clipBehavior: Clip.none, children: [
                        Container(width: 48, height: 48, decoration: BoxDecoration(shape: BoxShape.circle, color: c.$4.bg), child: Center(child: MedIcon(c.$3, size: 22, color: c.$4.fg))),
                        if ((m.unread[c.$1] ?? 0) > 0) Positioned(top: -3, right: -3, child: RedBadge(count: m.unread[c.$1]!, size: 17, borderColor: T.surface)),
                      ]),
                      const SizedBox(height: 7),
                      Text(c.$2, style: TextStyle(fontSize: 11.5, color: T.ink, fontWeight: FontWeight.w500)),
                    ]),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 18),
          Padding(padding: const EdgeInsets.only(left: 4, bottom: 10), child: Text('私聊', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: T.ink))),
          if (m.conversations.isEmpty)
            Padding(padding: const EdgeInsets.all(24), child: Center(child: Text('暂无私聊消息', style: TextStyle(color: T.inkSubtle, fontSize: 13)))),
          Container(
            decoration: BoxDecoration(color: T.surface, borderRadius: BorderRadius.circular(16), boxShadow: T.shadowSm),
            child: Column(children: [
              for (int i = 0; i < m.conversations.length; i++) ...[
                InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatPage(channel: m.conversations[i].channel, title: m.conversations[i].name, peerSeed: m.conversations[i].seed))),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(children: [
                      Stack(clipBehavior: Clip.none, children: [
                        MedAvatar(size: 46, seed: m.conversations[i].seed, label: m.conversations[i].name),
                        if (m.conversations[i].unread > 0) Positioned(top: -2, right: -2, child: RedBadge(count: m.conversations[i].unread, size: 16, borderColor: T.surface)),
                      ]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(m.conversations[i].name, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: T.ink))),
                            Text(_time(m.conversations[i].ts), style: TextStyle(fontSize: 11, color: T.inkSubtle)),
                          ]),
                          const SizedBox(height: 3),
                          Text(m.conversations[i].last, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: T.inkMuted)),
                        ]),
                      ),
                    ]),
                  ),
                ),
                if (i < m.conversations.length - 1) Divider(height: 1, color: T.divider, indent: 72),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  static String _time(int ts) {
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    if (d.year == now.year && d.month == now.month && d.day == now.day) return '${two(d.hour)}:${two(d.minute)}';
    return '${two(d.month)}-${two(d.day)}';
  }
}
