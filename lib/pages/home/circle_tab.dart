import 'package:flutter/material.dart';
import '../../data/models.dart';
import '../../theme/med_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/med_icons.dart';
import '../simple_pages.dart';

/// Sub-tab bar shared by 健康圈 / 问诊社区 tabs (active: 18/800 + teal underline).
class SubTabBar extends StatelessWidget {
  final List<String> tabs;
  final int index;
  final ValueChanged<int> onChanged;
  const SubTabBar({super.key, required this.tabs, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: MedTheme.surface,
        border: Border(bottom: BorderSide(color: MedTheme.divider)),
      ),
      child: Row(
        children: [
          for (int i = 0; i < tabs.length; i++) ...[
            if (i > 0) const SizedBox(width: 22),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(i),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 180),
                      style: TextStyle(
                        fontSize: i == index ? 18 : 14,
                        fontWeight: i == index ? FontWeight.w800 : FontWeight.w500,
                        color: i == index ? MedTheme.ink : MedTheme.inkMuted,
                      ),
                      child: Text(tabs[i]),
                    ),
                  ),
                  if (i == index)
                    Positioned(
                      bottom: -2,
                      child: Container(
                        width: 22,
                        height: 3,
                        decoration: BoxDecoration(
                          color: MedTheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 健康圈 tab — pill buttons, 健康圈子 card, 我关注的健康圈 list.
class CircleTab extends StatefulWidget {
  const CircleTab({super.key});

  @override
  State<CircleTab> createState() => _CircleTabState();
}

class _CircleTabState extends State<CircleTab> {
  int _sub = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SubTabBar(
          tabs: const ['健康圈子', '帖子列表', '我的收藏'],
          index: _sub,
          onChanged: (i) => setState(() => _sub = i),
        ),
        Expanded(
          child: _sub == 0
              ? _main(context)
              : SimpleEmpty(
                  title: _sub == 1 ? '帖子列表' : '我收藏的帖子',
                  icon: _sub == 1 ? MedIcons.doc : MedIcons.bookmark,
                ),
        ),
      ],
    );
  }

  Widget _main(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _gradientPill(
                context,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MedIcon(MedIcons.grid, size: 14, color: Colors.white),
                    SizedBox(width: 6),
                    Text('健康圈子',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                  ],
                ),
                gradient: const LinearGradient(colors: [MedTheme.primary, MedTheme.violet]),
                shadow: MedTheme.primary.withValues(alpha: 0.27),
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const SimplePage(title: '健康圈子'))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    gradient: const LinearGradient(colors: [Color(0xFF67E8F9), Color(0xFF38BDF8)]),
                    boxShadow: MedTheme.shadowMd,
                  ),
                  child: const Text('健康圈 28 / 发帖 27',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            decoration: BoxDecoration(
              color: MedTheme.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: MedTheme.shadowSm,
            ),
            child: Column(
              children: [
                const Text('健康圈子',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: MedTheme.ink)),
                const SizedBox(height: 10),
                const Text('浏览全部健康圈分类 · 探索你感兴趣的社区',
                    style: TextStyle(fontSize: 13, color: MedTheme.inkSubtle)),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const SimplePage(title: '健康圈子分类'))),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 11),
                    decoration: BoxDecoration(
                      color: MedTheme.accent,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                            color: MedTheme.accent.withValues(alpha: 0.33),
                            blurRadius: 14,
                            offset: const Offset(0, 6)),
                      ],
                    ),
                    child: const Text('去浏览分类',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: MedTheme.ink)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('我关注的健康圈',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: MedTheme.ink)),
              Text('${CmsHome.followedCircles.length} 个',
                  style: const TextStyle(fontSize: 12, color: MedTheme.inkSubtle)),
            ],
          ),
          const SizedBox(height: 12),
          for (final c in CmsHome.followedCircles) ...[
            _circleRow(context, c),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _gradientPill(BuildContext context,
      {required Widget child, required Gradient gradient, required Color shadow, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [BoxShadow(color: shadow, blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: child,
      ),
    );
  }

  Widget _circleRow(BuildContext context, CircleItem c) {
    return Material(
      color: MedTheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () =>
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => SimplePage(title: c.name))),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: MedTheme.shadowSm,
          ),
          child: Row(
            children: [
              MedPlaceholder(width: 58, height: 58, seed: c.seed, radius: 12, imageAsset: c.image),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: MedTheme.ink)),
                    const SizedBox(height: 4),
                    Text(c.sub,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, color: MedTheme.inkSubtle, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 问诊社区 tab — 3 × 3 hot-category grid and hot-topic pills with bookmark.
class ForumTab extends StatefulWidget {
  const ForumTab({super.key});

  @override
  State<ForumTab> createState() => _ForumTabState();
}

class _ForumTabState extends State<ForumTab> {
  int _sub = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SubTabBar(
          tabs: const ['问诊社区话题', '讨论列表', '我的收藏'],
          index: _sub,
          onChanged: (i) => setState(() => _sub = i),
        ),
        Expanded(
          child: _sub == 0
              ? _main(context)
              : SimpleEmpty(
                  title: _sub == 1 ? '讨论列表' : '我收藏的话题',
                  icon: _sub == 1 ? MedIcons.doctorChat : MedIcons.bookmark,
                ),
        ),
      ],
    );
  }

  Widget _main(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const SimplePage(title: '全部话题'))),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [MedTheme.primary, MedTheme.violet]),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                          color: MedTheme.primary.withValues(alpha: 0.27),
                          blurRadius: 16,
                          offset: const Offset(0, 6)),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MedIcon(MedIcons.grid, size: 14, color: Colors.white),
                      SizedBox(width: 6),
                      Text('全部话题',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    gradient: const LinearGradient(colors: [Color(0xFFFF8A5B), Color(0xFFF2704A)]),
                    boxShadow: MedTheme.shadowMd,
                  ),
                  child: const Text('话题 19 / 发帖 19',
                      maxLines: 1,
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text('热门问诊', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: MedTheme.ink)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: CmsHome.forumCategories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 72,
            ),
            itemBuilder: (context, i) {
              final it = CmsHome.forumCategories[i];
              return GestureDetector(
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => SimplePage(title: it.label))),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MedPlaceholder(seed: it.seed, radius: 14),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: MedTheme.primary,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: const [
                            BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 3)),
                          ],
                        ),
                        child: Text(it.label,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 22),
          const Text('热门话题', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: MedTheme.ink)),
          const SizedBox(height: 12),
          for (final t in CmsHome.hotTopics) ...[
            _topicPill(context, t),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _topicPill(BuildContext context, HotTopic t) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SimplePage(title: '#${t.title}#'))),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: t.gradient),
          borderRadius: BorderRadius.circular(14),
          boxShadow: MedTheme.shadowSm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text('# ${t.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700)),
            ),
            GestureDetector(
              onTap: () {
                setState(() => t.favourite = !t.favourite);
                showToast(context, t.favourite ? '已收藏话题' : '已取消收藏');
              },
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: t.favourite
                    ? const Icon(Icons.bookmark, size: 18, color: Colors.white)
                    : const MedIcon(MedIcons.bookmark, size: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
