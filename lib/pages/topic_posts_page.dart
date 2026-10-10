import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models.dart';
import '../data/stores.dart';
import '../theme/med_theme.dart';
import '../widgets/common.dart';
import '../widgets/med_icons.dart';
import '../widgets/post_card.dart';
import 'publish_page.dart';

/// 话题列表 — gradient hero (chip, #topic#, subtitle), 收藏 / 分享, post cards.
class TopicPostsPage extends StatefulWidget {
  final HotTopic topic;
  const TopicPostsPage({super.key, required this.topic});

  @override
  State<TopicPostsPage> createState() => _TopicPostsPageState();
}

class _TopicPostsPageState extends State<TopicPostsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<PostsStore>().load('forum'));
  }

  @override
  Widget build(BuildContext context) {
    final T = MedTheme.of(context);
    final store = context.watch<PostsStore>();
    final mine = store.byKind('forum').where((p) => p.topic == widget.topic.title).toList();
    final shown = mine.isNotEmpty ? mine : store.byKind('forum');
    final t = widget.topic;
    return Scaffold(
      backgroundColor: T.bg,
      appBar: const SubHeader(title: '话题列表'),
      body: ListView(padding: const EdgeInsets.fromLTRB(14, 10, 14, 90), children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(gradient: LinearGradient(colors: t.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(18), boxShadow: T.shadowMd),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(6)), child: const Text('健康入门', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700))),
            const SizedBox(height: 10),
            Text('#${t.title}#', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.3)),
            const SizedBox(height: 6),
            Text('与病友、医生一起讨论 · ${shown.length} 篇讨论', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
            const SizedBox(height: 14),
            Row(children: [
              _btn(T, t.favourite ? '× 取消收藏' : '+ 收藏', () {
                setState(() => t.favourite = !t.favourite);
                showToast(context, t.favourite ? '已收藏话题' : '已取消收藏');
              }, filled: true),
              const SizedBox(width: 10),
              _btn(T, '分享', () => showToast(context, '分享卡片已生成'), filled: false),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        if (shown.isEmpty) Padding(padding: const EdgeInsets.all(30), child: Center(child: store.loadingKind['forum'] == true ? CircularProgressIndicator(color: T.primary) : Text('暂无讨论', style: TextStyle(color: T.inkSubtle)))),
        for (final p in shown) ...[PostCard(post: p), const SizedBox(height: 12)],
      ]),
      floatingActionButton: GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PublishPage(kind: 'forum'))),
        child: Container(
          width: 52, height: 52,
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: T.fabGradient, boxShadow: [BoxShadow(color: T.accent.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 8))]),
          child: const Center(child: MedIcon(MedIcons.plus, size: 28, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _btn(MedTokens T, String label, VoidCallback onTap, {required bool filled}) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: filled ? Colors.white : Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(999)),
          child: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: filled ? T.primaryDeep : Colors.white)),
        ),
      );
}
