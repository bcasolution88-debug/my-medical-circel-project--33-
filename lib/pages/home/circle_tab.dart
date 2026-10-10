import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models.dart';
import '../../data/stores.dart';
import '../../theme/med_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/med_icons.dart';
import '../../widgets/post_card.dart';
import '../circle_detail_page.dart';
import '../simple_pages.dart';
import '../topic_posts_page.dart';

/// Sub-tab bar shared by 健康圈 / 问诊社区 tabs (active: 18/800 + teal underline).
class SubTabBar extends StatelessWidget {
  final List<String> tabs;
  final int index;
  final ValueChanged<int> onChanged;
  const SubTabBar({super.key, required this.tabs, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final T = MedTheme.of(context);
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(color: T.surface, border: Border(bottom: BorderSide(color: T.divider))),
      child: Row(children: [
        for (int i = 0; i < tabs.length; i++) ...[
          if (i > 0) const SizedBox(width: 22),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(i),
            child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  style: TextStyle(fontSize: i == index ? 18 : 14, fontWeight: i == index ? FontWeight.w800 : FontWeight.w500, color: i == index ? T.ink : T.inkMuted),
                  child: Text(tabs[i]),
                ),
              ),
              if (i == index) Positioned(bottom: -2, child: Container(width: 22, height: 3, decoration: BoxDecoration(color: T.primary, borderRadius: BorderRadius.circular(2)))),
            ]),
          ),
        ],
      ]),
    );
  }
}

Widget gradientPill(BuildContext context, {required Widget child, required Gradient gradient, required Color shadow, VoidCallback? onTap}) => GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(40), boxShadow: [BoxShadow(color: shadow, blurRadius: 16, offset: const Offset(0, 6))]),
        child: child,
      ),
    );

/// 健康圈 tab.
class CircleTab extends StatefulWidget {
  const CircleTab({super.key});

  @override
  State<CircleTab> createState() => _CircleTabState();
}

class _CircleTabState extends State<CircleTab> {
  int _sub = 0;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SubTabBar(tabs: const ['健康圈子', '帖子列表', '我的收藏'], index: _sub, onChanged: (i) => setState(() => _sub = i)),
      Expanded(child: switch (_sub) { 0 => _main(context), 1 => const PostsList(kind: 'circle'), _ => const PostsList(kind: 'fav') }),
    ]);
  }

  Widget _main(BuildContext context) {
    final T = MedTheme.of(context);
    final cms = context.watch<HomeStore>().cms;
    final postCount = context.watch<PostsStore>().byKind('circle').length;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          gradientPill(
            context,
            child: const Row(mainAxisSize: MainAxisSize.min, children: [MedIcon(MedIcons.grid, size: 14, color: Colors.white), SizedBox(width: 6), Text('健康圈子', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700))]),
            gradient: T.primaryButtonGradient,
            shadow: T.primary.withValues(alpha: 0.27),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SimplePage(title: '健康圈子'))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(40), gradient: const LinearGradient(colors: [Color(0xFF67E8F9), Color(0xFF38BDF8)]), boxShadow: T.shadowMd),
              child: Text('健康圈 ${cms.hotCircles.length + cms.followedCircles.length} / 发帖 ${postCount > 0 ? postCount : 27}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          decoration: BoxDecoration(color: T.surface, borderRadius: BorderRadius.circular(18), boxShadow: T.shadowSm),
          child: Column(children: [
            Text('健康圈子', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: T.ink)),
            const SizedBox(height: 10),
            Text('浏览全部健康圈分类 · 探索你感兴趣的社区', style: TextStyle(fontSize: 13, color: T.inkSubtle)),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SimplePage(title: '健康圈子分类'))),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 11),
                decoration: BoxDecoration(color: T.accent, borderRadius: BorderRadius.circular(999), boxShadow: [BoxShadow(color: T.accent.withValues(alpha: 0.33), blurRadius: 14, offset: const Offset(0, 6))]),
                child: const Text('去浏览分类', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF13322D))),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 22),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('我关注的健康圈', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: T.ink)),
          Text('${cms.followedCircles.length} 个', style: TextStyle(fontSize: 12, color: T.inkSubtle)),
        ]),
        const SizedBox(height: 12),
        for (final c in cms.followedCircles) ...[_circleRow(context, T, c), const SizedBox(height: 12)],
      ]),
    );
  }

  Widget _circleRow(BuildContext context, MedTokens T, HomeTile c) => Material(
        color: T.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CircleDetailPage(tile: c))),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), boxShadow: T.shadowSm),
            child: Row(children: [
              MedPlaceholder(width: 58, height: 58, seed: c.seed, radius: 12, image: c.image),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: T.ink)),
                  const SizedBox(height: 4),
                  Text(c.sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: T.inkSubtle, height: 1.4)),
                ]),
              ),
            ]),
          ),
        ),
      );
}

/// 问诊社区 tab.
class ForumTab extends StatefulWidget {
  const ForumTab({super.key});

  @override
  State<ForumTab> createState() => _ForumTabState();
}

class _ForumTabState extends State<ForumTab> {
  int _sub = 0;
  final Set<String> _favTopics = {};

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SubTabBar(tabs: const ['问诊社区话题', '讨论列表', '我的收藏'], index: _sub, onChanged: (i) => setState(() => _sub = i)),
      Expanded(child: switch (_sub) { 0 => _main(context), 1 => const PostsList(kind: 'forum'), _ => const PostsList(kind: 'fav') }),
    ]);
  }

  Widget _main(BuildContext context) {
    final T = MedTheme.of(context);
    final cms = context.watch<HomeStore>().cms;
    final forumCount = context.watch<PostsStore>().byKind('forum').length;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          gradientPill(
            context,
            child: const Row(mainAxisSize: MainAxisSize.min, children: [MedIcon(MedIcons.grid, size: 14, color: Colors.white), SizedBox(width: 6), Text('全部话题', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700))]),
            gradient: T.primaryButtonGradient,
            shadow: T.primary.withValues(alpha: 0.27),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SimplePage(title: '全部话题'))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(40), gradient: const LinearGradient(colors: [Color(0xFFFF8A5B), Color(0xFFF2704A)]), boxShadow: T.shadowMd),
              child: Text('话题 ${cms.hotTopics.length + 14} / 发帖 ${forumCount > 0 ? forumCount : 19}', maxLines: 1, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
        const SizedBox(height: 22),
        Text('热门问诊', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: T.ink)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cms.forumCategories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, mainAxisExtent: 72),
          itemBuilder: (_, i) {
            final it = cms.forumCategories[i];
            return GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SimplePage(title: it.label))),
              child: Stack(fit: StackFit.expand, children: [
                MedPlaceholder(seed: it.seed, radius: 14, image: it.image),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: T.primary, borderRadius: BorderRadius.circular(999), boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 3))]),
                    child: Text(it.label, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            );
          },
        ),
        const SizedBox(height: 22),
        Text('热门话题', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: T.ink)),
        const SizedBox(height: 12),
        for (final t in cms.hotTopics) ...[_topicPill(context, T, t), const SizedBox(height: 10)],
      ]),
    );
  }

  Widget _topicPill(BuildContext context, MedTokens T, HotTopic t) {
    final fav = _favTopics.contains(t.title) || t.favourite;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TopicPostsPage(topic: t))),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        decoration: BoxDecoration(gradient: LinearGradient(colors: t.gradient), borderRadius: BorderRadius.circular(14), boxShadow: T.shadowSm),
        child: Row(children: [
          Expanded(child: Text('# ${t.title}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700))),
          GestureDetector(
            onTap: () {
              setState(() {
                t.favourite = !fav;
                fav ? _favTopics.remove(t.title) : _favTopics.add(t.title);
              });
              showToast(context, t.favourite ? '已收藏话题' : '已取消收藏');
            },
            child: Padding(padding: const EdgeInsets.all(4), child: fav ? const Icon(Icons.bookmark, size: 18, color: Colors.white) : const MedIcon(MedIcons.bookmark, size: 18, color: Colors.white)),
          ),
        ]),
      ),
    );
  }
}
