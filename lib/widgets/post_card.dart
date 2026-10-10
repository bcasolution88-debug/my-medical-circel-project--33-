import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models.dart';
import '../data/stores.dart';
import '../pages/post_detail_page.dart';
import '../theme/med_theme.dart';
import 'common.dart';
import 'med_icons.dart';

/// Post card used in 帖子列表 / 讨论列表 / 我的收藏.
class PostCard extends StatelessWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final T = MedTheme.of(context);
    final p = post;
    return Material(
      color: T.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PostDetailPage(postId: p.id))),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: T.shadowSm),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              MedAvatar(size: 36, seed: p.authorSeed, label: p.authorName),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(child: Text(p.authorName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: T.ink))),
                    const SizedBox(width: 4),
                    Icon(p.gender == 'f' ? Icons.female : Icons.male, size: 13, color: p.gender == 'f' ? T.pink : T.sky),
                    if (p.recommended) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: T.tintAmber.bg, borderRadius: BorderRadius.circular(4)),
                        child: Text('推荐', style: TextStyle(fontSize: 10, color: T.tintAmber.fg, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 2),
                  Text('${p.timeLabel} · ${p.location}', style: TextStyle(fontSize: 11, color: T.inkSubtle)),
                ]),
              ),
              if (p.kind == 'circle' && p.circleName.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: T.primarySoft, borderRadius: BorderRadius.circular(999)),
                  child: Text(p.circleName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5, color: T.primary, fontWeight: FontWeight.w600)),
                ),
              if (p.kind == 'forum' && p.topic.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: T.violetSoft, borderRadius: BorderRadius.circular(999)),
                  child: Text('#${p.topic.length > 8 ? '${p.topic.substring(0, 8)}…' : p.topic}', style: TextStyle(fontSize: 10.5, color: T.violet, fontWeight: FontWeight.w600)),
                ),
            ]),
            const SizedBox(height: 10),
            Text(p.text, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: T.ink, height: 1.55)),
            if (p.images.isNotEmpty) ...[
              const SizedBox(height: 10),
              PostImageGrid(images: p.images, hasVideo: p.video.isNotEmpty, compact: true),
            ],
            const SizedBox(height: 10),
            Row(children: [
              _stat(T, MedIcons.doctorChat, '${p.comments}'),
              const SizedBox(width: 14),
              _stat(T, MedIcons.eye, '${p.views}'),
              const SizedBox(width: 14),
              _stat(T, MedIcons.like, '${p.likes}', color: p.liked ? T.pink : null),
              const Spacer(),
              _stat(T, MedIcons.heart, '${p.favs}', color: p.faved ? T.pink : null),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _stat(MedTokens T, MedIconData icon, String v, {Color? color}) => Row(children: [
        MedIcon(icon, size: 14, color: color ?? T.inkSubtle),
        const SizedBox(width: 4),
        Text(v, style: TextStyle(fontSize: 12, color: color ?? T.inkSubtle)),
      ]);
}

/// 1 / 2 / 3-column image grid with optional play badge.
class PostImageGrid extends StatelessWidget {
  final List<String> images;
  final bool hasVideo, compact;
  final void Function(int)? onTap;
  const PostImageGrid({super.key, required this.images, this.hasVideo = false, this.compact = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cols = images.length == 1 ? 1 : images.length == 2 || images.length == 4 ? 2 : 3;
    final shown = compact ? images.take(cols == 1 ? 1 : cols * 2).toList() : images;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: shown.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, crossAxisSpacing: 6, mainAxisSpacing: 6, childAspectRatio: cols == 1 ? 16 / 9 : 1),
      itemBuilder: (_, i) => GestureDetector(
        onTap: onTap != null ? () => onTap!(i) : null,
        child: Stack(fit: StackFit.expand, children: [
          MedPlaceholder(seed: shown[i], radius: 10, image: shown[i]),
          if (hasVideo && i == 0)
            Center(
              child: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.85)),
                child: const Icon(Icons.play_arrow_rounded, color: Color(0xFF12A594), size: 22),
              ),
            ),
          if (compact && i == shown.length - 1 && images.length > shown.length)
            Container(
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: Text('+${images.length - shown.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
            ),
        ]),
      ),
    );
  }
}

/// Generic posts list bound to a store kind, with loading / error / empty states.
class PostsList extends StatefulWidget {
  final String kind;
  final EdgeInsets padding;
  const PostsList({super.key, required this.kind, this.padding = const EdgeInsets.fromLTRB(14, 14, 14, 30)});

  @override
  State<PostsList> createState() => _PostsListState();
}

class _PostsListState extends State<PostsList> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<PostsStore>().load(widget.kind));
  }

  @override
  Widget build(BuildContext context) {
    final T = MedTheme.of(context);
    final store = context.watch<PostsStore>();
    final posts = store.byKind(widget.kind);
    final loading = store.loadingKind[widget.kind] == true;
    if (loading && posts.isEmpty) return Center(child: CircularProgressIndicator(color: T.primary));
    if (store.error != null && posts.isEmpty) return ErrorRetry(message: store.error!, onRetry: () => store.load(widget.kind));
    if (posts.isEmpty) {
      return Center(child: Text('暂无内容', style: TextStyle(color: T.inkSubtle)));
    }
    return RefreshIndicator(
      color: T.primary,
      onRefresh: () => store.load(widget.kind),
      child: ListView.separated(
        padding: widget.padding,
        itemCount: posts.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) => PostCard(post: posts[i]),
      ),
    );
  }
}
