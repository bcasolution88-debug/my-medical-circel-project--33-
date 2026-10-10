import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/stores.dart';
import '../theme/med_theme.dart';
import '../widgets/common.dart';
import '../widgets/med_icons.dart';
import 'auth/login_page.dart';
import 'home/circle_tab.dart';
import 'home/home_main.dart';
import 'me_page.dart';
import 'messages/chat_page.dart';
import 'publish_page.dart';
import 'simple_pages.dart';

enum HomeTab { home, circle, forum }

/// Root shell — 首页 (top tabs 首页 / 健康圈 / 问诊社区) + 我的, bottom nav, publish FAB.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  HomeTab _tab = HomeTab.home;
  bool _me = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeStore>().load();
      context.read<EventsStore>().load();
      context.read<MessagesStore>().startPolling();
    });
  }

  void _goTab(String id) => setState(() {
        _me = id == 'me';
        if (!_me) _tab = HomeTab.values.byName(id);
      });

  @override
  Widget build(BuildContext context) {
    final T = MedTheme.of(context);
    return Scaffold(
      backgroundColor: T.bg,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          if (!_me) HomeTopBar(active: _tab, onChanged: (t) => setState(() => _tab = t)),
          Expanded(
            child: _me
                ? const MePage()
                : switch (_tab) {
                    HomeTab.home => HomeMain(goForumTab: () => setState(() => _tab = HomeTab.forum), goCircleTab: () => setState(() => _tab = HomeTab.circle)),
                    HomeTab.circle => const CircleTab(),
                    HomeTab.forum => const ForumTab(),
                  },
          ),
        ]),
      ),
      bottomNavigationBar: BottomNav(active: _me ? 'me' : _tab.name, onTap: _goTab, onPublish: () => _openPublishSheet(context)),
    );
  }

  void _openPublishSheet(BuildContext context) {
    if (!context.read<AuthStore>().loggedIn) {
      showToast(context, '请先登录后发布');
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginPage()));
      return;
    }
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, barrierColor: const Color(0x590F172A), builder: (_) => const PublishSheet());
  }
}

class HomeTopBar extends StatelessWidget {
  final HomeTab active;
  final ValueChanged<HomeTab> onChanged;
  const HomeTopBar({super.key, required this.active, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final T = MedTheme.of(context);
    final theme = context.watch<ThemeStore>();
    final svcUnread = context.watch<MessagesStore>().serviceUnread;
    const tabs = [(HomeTab.home, '首页'), (HomeTab.circle, '健康圈'), (HomeTab.forum, '问诊社区')];
    return Container(
      color: T.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
      child: Row(children: [
        Expanded(
          child: Row(children: [
            for (int i = 0; i < tabs.length; i++) ...[
              if (i > 0) const SizedBox(width: 20),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(tabs[i].$1),
                child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 150),
                      style: TextStyle(fontSize: active == tabs[i].$1 ? 17 : 14.5, fontWeight: active == tabs[i].$1 ? FontWeight.w700 : FontWeight.w500, color: active == tabs[i].$1 ? T.ink : T.inkMuted),
                      child: Text(tabs[i].$2),
                    ),
                  ),
                  if (active == tabs[i].$1) Positioned(bottom: -2, child: Container(width: 22, height: 3, decoration: BoxDecoration(color: T.primary, borderRadius: BorderRadius.circular(2)))),
                ]),
              ),
            ],
          ]),
        ),
        _iconBtn(T, MedIcons.headset, badge: svcUnread, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatPage(channel: 'service', title: '客服中心')))),
        _iconBtn(T, MedIcons.scan, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SimplePage(title: '扫一扫')))),
        // Light / dark theme toggle — persisted (theme_mode)
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: theme.toggle,
          child: SizedBox(width: 34, height: 34, child: Center(child: theme.dark ? Icon(Icons.light_mode_outlined, size: 22, color: T.ink) : MedIcon(MedIcons.moon, size: 22, color: T.ink))),
        ),
        _iconBtn(T, MedIcons.search, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SimplePage(title: '搜索')))),
      ]),
    );
  }

  Widget _iconBtn(MedTokens T, MedIconData icon, {int badge = 0, VoidCallback? onTap}) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 34, height: 34,
          child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
            MedIcon(icon, size: 22, color: T.ink),
            if (badge > 0) Positioned(top: 2, right: 0, child: RedBadge(count: badge, size: 16, borderColor: T.surface)),
          ]),
        ),
      );
}

class BottomNav extends StatelessWidget {
  final String active;
  final ValueChanged<String> onTap;
  final VoidCallback onPublish;
  const BottomNav({super.key, required this.active, required this.onTap, required this.onPublish});

  @override
  Widget build(BuildContext context) {
    final T = MedTheme.of(context);
    final items = [
      ('home', '首页', MedIcons.home),
      ('circle', '健康圈', MedIcons.heartPulse),
      ('publish', '发布', MedIcons.plus),
      ('forum', '问诊社区', MedIcons.doctorChat),
      ('me', '我的', MedIcons.user),
    ];
    return Container(
      decoration: BoxDecoration(color: T.surface, border: Border(top: BorderSide(color: T.divider)), boxShadow: const [BoxShadow(color: Color(0x0A0F172A), blurRadius: 12, offset: Offset(0, -1))]),
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: SafeArea(
        top: false,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (final it in items) Expanded(child: it.$1 == 'publish' ? _publishBtn(T) : _navBtn(T, it.$1, it.$2, it.$3)),
        ]),
      ),
    );
  }

  Widget _publishBtn(MedTokens T) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPublish,
        child: Transform.translate(
          offset: const Offset(0, -14),
          child: Align(
            alignment: Alignment.bottomCenter,
            heightFactor: 1,
            child: Container(
              width: 52, height: 52,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: T.fabGradient, boxShadow: [BoxShadow(color: T.accent.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 8))]),
              child: const Center(child: MedIcon(MedIcons.plus, size: 28, color: Colors.white)),
            ),
          ),
        ),
      );

  Widget _navBtn(MedTokens T, String id, String label, MedIconData icon) {
    final isActive = active == id;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 32, height: 32,
            decoration: BoxDecoration(color: isActive ? T.primarySoft : Colors.transparent, borderRadius: BorderRadius.circular(16)),
            child: Center(child: MedIcon(icon, size: 22, color: isActive ? T.primary : T.inkSubtle)),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500, color: isActive ? T.primary : T.inkSubtle)),
        ]),
      ),
    );
  }
}

/// Publish sheet — 健康圈 + 问诊社区 buttons.
class PublishSheet extends StatelessWidget {
  const PublishSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final T = MedTheme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      decoration: BoxDecoration(color: T.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 32, offset: Offset(0, -12))]),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: T.divider, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 18),
        Text('发布到', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: T.ink)),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: _option(context, T, MedIcons.heartPulse, '健康圈', 'circle', T.tintIndigo)),
          const SizedBox(width: 14),
          Expanded(child: _option(context, T, MedIcons.doctorChat, '问诊社区', 'forum', T.tintViolet)),
        ]),
      ]),
    );
  }

  Widget _option(BuildContext context, MedTokens T, MedIconData icon, String title, String kind, Tint tint) => GestureDetector(
        onTap: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => PublishPage(kind: kind)));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(color: tint.bg, borderRadius: BorderRadius.circular(18)),
          child: Column(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(shape: BoxShape.circle, color: tint.fg), child: Center(child: MedIcon(icon, size: 24, color: T.dark ? T.bg : Colors.white))),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: tint.fg)),
          ]),
        ),
      );
}
