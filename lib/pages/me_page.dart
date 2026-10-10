import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/events_store.dart';
import '../theme/med_theme.dart';
import '../widgets/common.dart';
import '../widgets/med_icons.dart';
import 'simple_pages.dart';

/// 我的 — avatar, ID, IP pill, counts, menu.
class MePage extends StatelessWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Container(
      color: MedTheme.bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [MedTheme.primarySoft, MedTheme.bg],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const SimplePage(title: '个人设置'))),
                      child: const MedIcon(MedIcons.settings, size: 22, color: MedTheme.inkSubtle),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                            child: MedAvatar(size: 66, seed: 'me', label: app.selfName),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: MedTheme.sky,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.male, size: 12, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(app.selfName,
                              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: MedTheme.ink)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: MedTheme.accentDeep,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text('ID : ${app.selfId}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: MedTheme.ink.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MedIcon(MedIcons.pin, size: 12, color: Colors.white),
                        SizedBox(width: 5),
                        Text('IP · Shah Alam · Malaysia',
                            style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _stat(context, '3', '我关注的', MedTheme.tintSky),
                      const SizedBox(width: 10),
                      _stat(context, '2', '我的粉丝', MedTheme.tintMint),
                      const SizedBox(width: 10),
                      _stat(context, '5', '我的获赞', MedTheme.tintPink),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: MedTheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: MedTheme.shadowSm,
              ),
              child: Column(
                children: [
                  _menu(context, MedIcons.user, '我的主页'),
                  _menu(context, MedIcons.settings, '个人设置'),
                  _menu(context, MedIcons.doc, '反馈信息'),
                  _menu(context, MedIcons.headset, '客服中心', badge: app.serviceUnread),
                  _menu(context, MedIcons.send, '开发合作'),
                  _menu(context, MedIcons.trash, '清除缓存', trailing: '205.44 MB'),
                  _menu(context, MedIcons.refresh, '在线更新', trailing: 'v 2026.09.11', last: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String n, String label, Tint tint) {
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SimplePage(title: label))),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: tint.bg, borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              Text(n, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: tint.fg)),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 11.5, color: tint.fg.withValues(alpha: 0.85))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menu(BuildContext context, MedIconData icon, String label,
      {String? trailing, int badge = 0, bool last = false}) {
    return InkWell(
      onTap: () {
        if (label == '客服中心') context.read<AppState>().clearServiceUnread();
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => SimplePage(title: label)));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: last ? null : const Border(bottom: BorderSide(color: MedTheme.divider)),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: MedTheme.primarySoft),
              child: Center(child: MedIcon(icon, size: 16, color: MedTheme.primary)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 14.5, color: MedTheme.ink, fontWeight: FontWeight.w500)),
            ),
            if (badge > 0) ...[
              RedBadge(count: badge, size: 16, borderColor: MedTheme.surface),
              const SizedBox(width: 8),
            ],
            if (trailing != null) ...[
              Text(trailing, style: const TextStyle(fontSize: 12.5, color: MedTheme.inkSubtle)),
              const SizedBox(width: 8),
            ],
            const MedIcon(MedIcons.chevronRight, size: 16, color: MedTheme.inkSubtle),
          ],
        ),
      ),
    );
  }
}
