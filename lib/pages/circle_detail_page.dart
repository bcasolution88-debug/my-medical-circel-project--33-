import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models.dart';
import '../data/stores.dart';
import '../theme/med_theme.dart';
import '../widgets/common.dart';
import '../widgets/med_icons.dart';
import '../widgets/post_card.dart';
import 'publish_page.dart';

/// 健康圈详情 — hero with 关注 / 分享; post list filtered to this circle.
class CircleDetailPage extends StatefulWidget {
  final HomeTile tile;
  const CircleDetailPage({super.key, required this.tile});

  @override
  State<CircleDetailPage> createState() => _CircleDetailPageState();
}

class _CircleDetailPageState extends State<CircleDetailPage> {
  bool _followed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<PostsStore>().load('circle'));
  }

  @override
  Widget build(BuildContext context) {
    final T = MedTheme.of(context);
    final store = context.watch<PostsStore>();
    final posts = store.byKind('circle').where((p) => p.circleName == widget.tile.label).toList();
    final all = store.byKind('circle');
    final shown = posts.isNotEmpty ? posts : all;
    return Scaffold(
      backgroundColor: T.bg,
      appBar: SubHeader(title: widget.tile.label),
      body: ListView(padding: const EdgeInsets.fromLTRB(14, 10, 14, 90), children: [
        Container(
          height: 150,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), boxShadow: T.shadowMd),
          clipBehavior: Clip.antiAlias,
          child: Stack(fit: StackFit.expand, children: [
            MedPlaceholder(seed: widget.tile.seed, radius: 0, image: widget.tile.image),
            const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00000000), Color(0x80000000)]))),
            Positioned(
              left: 18, right: 18, bottom: 16,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.tile.label, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                    if (widget.tile.sub.isNotEmpty) Text(widget.tile.sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
                  ]),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    setState(() => _followed = !_followed);
                    showToast(context, _followed ? '已关注健康圈' : '已取消关注');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(color: _followed ? Colors.white.withValues(alpha: 0.25) : Colors.white, borderRadius: BorderRadius.circular(999)),
                    child: Text(_followed ? '取消关注' : '关注', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _followed ? Colors.white : T.primary)),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => showToast(context, '分享卡片已生成'),
                  child: Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.25)), child: const Center(child: MedIcon(MedIcons.send, size: 15, color: Colors.white))),
                ),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Text(posts.isNotEmpty ? '圈内帖子 ${posts.length}' : '推荐帖子', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: T.ink)),
        const SizedBox(height: 10),
        if (shown.isEmpty) Padding(padding: const EdgeInsets.all(30), child: Center(child: store.loadingKind['circle'] == true ? CircularProgressIndicator(color: T.primary) : Text('暂无帖子', style: TextStyle(color: T.inkSubtle)))),
        for (final p in shown) ...[PostCard(post: p), const SizedBox(height: 12)],
      ]),
      floatingActionButton: GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PublishPage(kind: 'circle'))),
        child: Container(
          width: 52, height: 52,
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: T.fabGradient, boxShadow: [BoxShadow(color: T.accent.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 8))]),
          child: const Center(child: MedIcon(MedIcons.plus, size: 28, color: Colors.white)),
        ),
      ),
    );
  }
}
