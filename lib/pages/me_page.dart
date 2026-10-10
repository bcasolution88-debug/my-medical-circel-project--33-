import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/stores.dart';
import '../theme/med_theme.dart';
import '../widgets/common.dart';
import '../widgets/med_icons.dart';
import '../widgets/post_card.dart';
import 'auth/login_page.dart';
import 'messages/chat_page.dart';
import 'messages/feedback_page.dart';
import 'settings_page.dart';
import 'simple_pages.dart';

/// 我的 — avatar, ID, IP pill, counts, menu.
class MePage extends StatelessWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context) {
    final T = MedTheme.of(context);
    final auth = context.watch<AuthStore>();
    final msgs = context.watch<MessagesStore>();
    final u = auth.user;
    return Container(
      color: T.bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [T.primarySoft, T.bg])),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsPage())),
                  child: MedIcon(MedIcons.settings, size: 22, color: T.inkSubtle),
                ),
                const Spacer(),
                _ThemeToggle(),
              ]),
              const SizedBox(height: 8),
              if (u == null)
                Row(children: [
                  Container(padding: const EdgeInsets.all(3), decoration: BoxDecoration(shape: BoxShape.circle, color: T.surface), child: MedAvatar(size: 66, seed: 'guest', label: '?')),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('未登录', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: T.ink)),
                      const SizedBox(height: 8),
                      SizedBox(width: 140, height: 38, child: PrimaryButton(label: '登录 / 注册', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginPage())))),
                    ]),
                  ),
                ])
              else
                Row(children: [
                  Stack(clipBehavior: Clip.none, children: [
                    Container(padding: const EdgeInsets.all(3), decoration: BoxDecoration(shape: BoxShape.circle, color: T.surface), child: MedAvatar(size: 66, seed: u.seed, label: u.name, url: u.avatar)),
                    Positioned(
                      top: 0, right: 0,
                      child: Container(
                        width: 20, height: 20,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: u.gender == 'f' ? T.pink : T.sky, border: Border.all(color: T.surface, width: 2)),
                        child: Icon(u.gender == 'f' ? Icons.female : Icons.male, size: 12, color: Colors.white),
                      ),
                    ),
                  ]),
                  const SizedBox(width: 16),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(u.name, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: T.ink)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(color: T.accentDeep, borderRadius: BorderRadius.circular(999)),
                      child: Text('ID : ${u.id.replaceFirst('u-', '').toUpperCase()}', style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
                    ),
                  ]),
                ]),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: T.ink.withValues(alpha: T.dark ? 0.15 : 0.75), borderRadius: BorderRadius.circular(999)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  MedIcon(MedIcons.pin, size: 12, color: T.dark ? T.ink : Colors.white),
                  const SizedBox(width: 5),
                  Text('IP · ${u?.ip ?? '未知'}', style: TextStyle(color: T.dark ? T.ink : Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600)),
                ]),
              ),
              const SizedBox(height: 16),
              Row(children: [
                _stat(context, T, '3', '我关注的', T.tintSky),
                const SizedBox(width: 10),
                _stat(context, T, '2', '我的粉丝', T.tintMint),
                const SizedBox(width: 10),
                _stat(context, T, '5', '我的获赞', T.tintPink),
              ]),
            ]),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: T.surface, borderRadius: BorderRadius.circular(16), boxShadow: T.shadowSm),
            child: Column(children: [
              _menu(context, T, MedIcons.user, '我的主页', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyProfilePage()))),
              _menu(context, T, MedIcons.settings, '个人设置', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsPage()))),
              _menu(context, T, MedIcons.doc, '反馈信息', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FeedbackPage()))),
              _menu(context, T, MedIcons.headset, '客服中心', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatPage(channel: 'service', title: '客服中心'))), badge: msgs.serviceUnread),
              _menu(context, T, MedIcons.handshake, '开发合作', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SimplePage(title: '开发合作')))),
              _menu(context, T, MedIcons.trash, '清除缓存', () => showToast(context, '缓存已清除'), trailing: '205.44 MB'),
              _menu(context, T, MedIcons.refresh, '在线更新', () => showToast(context, '已是最新版本'), trailing: 'v 2026.09.11', last: true),
            ]),
          ),
          if (u != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: GestureDetector(
                onTap: () async {
                  await auth.logout();
                  await msgs.refresh();
                  if (context.mounted) showToast(context, '已退出登录');
                },
                child: Container(
                  height: 46, alignment: Alignment.center,
                  decoration: BoxDecoration(color: T.surface, borderRadius: BorderRadius.circular(999), border: Border.all(color: T.divider)),
                  child: Text('退出登录', style: TextStyle(color: T.pink, fontSize: 14.5, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _stat(BuildContext context, MedTokens T, String n, String label, Tint tint) => Expanded(
        child: GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SimplePage(title: label))),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(color: tint.bg, borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              Text(n, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: tint.fg)),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 11.5, color: tint.fg.withValues(alpha: 0.85))),
            ]),
          ),
        ),
      );

  Widget _menu(BuildContext context, MedTokens T, MedIconData icon, String label, VoidCallback onTap, {String? trailing, int badge = 0, bool last = false}) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: T.divider))),
          child: Row(children: [
            Container(width: 30, height: 30, decoration: BoxDecoration(shape: BoxShape.circle, color: T.primarySoft), child: Center(child: MedIcon(icon, size: 16, color: T.primary))),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(fontSize: 14.5, color: T.ink, fontWeight: FontWeight.w500))),
            if (badge > 0) ...[RedBadge(count: badge, size: 16, borderColor: T.surface), const SizedBox(width: 8)],
            if (trailing != null) ...[Text(trailing, style: TextStyle(fontSize: 12.5, color: T.inkSubtle)), const SizedBox(width: 8)],
            MedIcon(MedIcons.chevronRight, size: 16, color: T.inkSubtle),
          ]),
        ),
      );
}

class _ThemeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final T = MedTheme.of(context);
    final theme = context.watch<ThemeStore>();
    return GestureDetector(
      onTap: theme.toggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: T.surface, borderRadius: BorderRadius.circular(999), border: Border.all(color: T.divider)),
        child: Row(children: [
          Icon(theme.dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, size: 15, color: T.primary),
          const SizedBox(width: 5),
          Text(theme.dark ? '夜间' : '白天', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: T.inkMuted)),
        ]),
      ),
    );
  }
}

/// 我的主页 — blank divider-grey banner when no background image; info / posts tabs.
class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  int _tab = 1;

  @override
  Widget build(BuildContext context) {
    final T = MedTheme.of(context);
    final u = context.watch<AuthStore>().user;
    return Scaffold(
      backgroundColor: T.bg,
      appBar: const SubHeader(title: '我的主页'),
      body: Column(children: [
        Container(
          height: 130, color: T.divider,
          padding: const EdgeInsets.all(16),
          alignment: Alignment.bottomLeft,
          child: Row(children: [
            MedAvatar(size: 56, seed: u?.seed ?? 'guest', label: u?.name ?? '?', url: u?.avatar),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(u?.name ?? '未登录', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: T.ink)),
              Text(u?.ip ?? '', style: TextStyle(fontSize: 12, color: T.inkMuted)),
            ]),
          ]),
        ),
        Container(
          color: T.surface,
          child: Row(children: [
            for (int i = 0; i < 2; i++)
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _tab = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _tab == i ? T.primary : Colors.transparent, width: 2.5))),
                    child: Text(['资料', '帖子'][i], textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: _tab == i ? FontWeight.w700 : FontWeight.w500, color: _tab == i ? T.primary : T.inkMuted)),
                  ),
                ),
              ),
          ]),
        ),
        Expanded(
          child: _tab == 1
              ? (u == null ? Center(child: Text('登录后查看', style: TextStyle(color: T.inkSubtle))) : const PostsList(kind: 'mine'))
              : ListView(padding: const EdgeInsets.all(14), children: [
                  for (final row in [('昵称', u?.name ?? '-'), ('性别', u?.gender == 'f' ? '女' : '男'), ('邮箱', u?.email ?? '-'), ('IP 属地', u?.ip ?? '-')])
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(color: T.surface, borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        Text(row.$1, style: TextStyle(fontSize: 13.5, color: T.inkSubtle)),
                        const Spacer(),
                        Text(row.$2, style: TextStyle(fontSize: 13.5, color: T.ink, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                ]),
        ),
      ]),
    );
  }
}
