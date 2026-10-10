import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models.dart';
import '../data/stores.dart';
import '../theme/med_theme.dart';
import '../widgets/common.dart';
import '../widgets/med_icons.dart';
import '../widgets/post_card.dart';
import '../widgets/video_box.dart';
import 'auth/login_page.dart';
import 'event_detail_page.dart';
import 'messages/chat_page.dart';

/// 帖子详情 / 话题详情 — header (avatar · gender · time · location · ❤ fav · follow · chat),
/// body, poll, video, image grid, stats row with 👍 like, disclaimer, comments sheet.
class PostDetailPage extends StatefulWidget {
  final String postId;
  const PostDetailPage({super.key, required this.postId});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  bool _following = false;
  int? _voted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<PostsStore>().fetchDetail(widget.postId));
  }

  bool _requireLogin() {
    if (context.read<AuthStore>().loggedIn) return true;
    showToast(context, '请先登录');
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginPage()));
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final T = MedTheme.of(context);
    final store = context.watch<PostsStore>();
    final p = store.get(widget.postId);
    final me = context.watch<AuthStore>().user;
    final title = p?.kind == 'forum' ? '话题详情' : '帖子详情';
    if (p == null) {
      return Scaffold(backgroundColor: T.bg, appBar: SubHeader(title: title), body: Center(child: CircularProgressIndicator(color: T.primary)));
    }
    final isSelf = me != null && me.id == p.author;

    return Scaffold(
      backgroundColor: T.bg,
      appBar: SubHeader(title: title),
      body: Stack(children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 90),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: T.surface, borderRadius: BorderRadius.circular(16), boxShadow: T.shadowSm),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  MedAvatar(size: 42, seed: p.authorSeed, label: p.authorName),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Flexible(child: Text(p.authorName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: T.ink))),
                        const SizedBox(width: 4),
                        Icon(p.gender == 'f' ? Icons.female : Icons.male, size: 14, color: p.gender == 'f' ? T.pink : T.sky),
                      ]),
                      const SizedBox(height: 2),
                      Text('${p.timeLabel} · ${p.location}', style: TextStyle(fontSize: 11, color: T.inkSubtle)),
                    ]),
                  ),
                  // favourite heart with count badge
                  _favBtn(T, p),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      if (!_requireLogin()) return;
                      setState(() => _following = !_following);
                      showToast(context, _following ? '已关注' : '已取消关注');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: _following ? null : T.primaryButtonGradient,
                        color: _following ? T.divider : null,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(_following ? '已关注' : '关注', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _following ? T.inkMuted : Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // private chat — disabled when author is me
                  Opacity(
                    opacity: isSelf ? 0.45 : 1,
                    child: GestureDetector(
                      onTap: isSelf
                          ? null
                          : () {
                              if (!_requireLogin()) return;
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatPage(channel: 'user:${p.author}', title: p.authorName, peerSeed: p.authorSeed)));
                            },
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: T.primarySoft),
                        child: Center(child: MedIcon(MedIcons.doctorChat, size: 17, color: T.primary)),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                if (p.kind == 'circle' && p.circleName.isNotEmpty) _chip(T, p.circleName, T.primarySoft, T.primary),
                if (p.kind == 'forum' && p.topic.isNotEmpty) _chip(T, '# ${p.topic} #', T.violetSoft, T.violet),
                const SizedBox(height: 10),
                SelectableText(p.text, style: TextStyle(fontSize: 15, color: T.ink, height: 1.65)),
                if (p.poll != null) ...[const SizedBox(height: 14), _poll(T, p.poll!)],
                if (p.video.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  ClipRRect(borderRadius: BorderRadius.circular(12), child: AspectRatio(aspectRatio: 16 / 9, child: VideoBox(source: p.video, seed: '${p.id}-v'))),
                ],
                if (p.images.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  PostImageGrid(
                    images: p.images,
                    onTap: (i) => showDialog(context: context, barrierColor: Colors.black, builder: (_) => ImageLightbox(images: p.images, initial: i)),
                  ),
                ],
                const SizedBox(height: 16),
                Divider(color: T.divider, height: 1),
                const SizedBox(height: 12),
                Row(children: [
                  _statIcon(T, MedIcons.doctorChat, '${p.comments} 评论'),
                  const SizedBox(width: 16),
                  _statIcon(T, MedIcons.eye, '${p.views} 浏览'),
                  const Spacer(),
                  GestureDetector(
                    onTap: () async {
                      if (!_requireLogin()) return;
                      try {
                        await store.toggleLike(p.id);
                      } catch (e) {
                        if (context.mounted) showToast(context, '操作失败：$e');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: p.liked ? T.tintPink.bg : T.bg, borderRadius: BorderRadius.circular(999)),
                      child: Row(children: [
                        MedIcon(MedIcons.like, size: 15, color: p.liked ? T.pink : T.inkMuted),
                        const SizedBox(width: 5),
                        Text('${p.likes}', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: p.liked ? T.pink : T.inkMuted)),
                      ]),
                    ),
                  ),
                ]),
              ]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: T.tintAmber.bg, borderRadius: BorderRadius.circular(12)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.info_outline_rounded, size: 16, color: T.tintAmber.fg),
                const SizedBox(width: 8),
                Expanded(child: Text('免责声明：本帖内容仅代表作者个人观点，不构成医疗建议。如有不适请及时就医。', style: TextStyle(fontSize: 11.5, color: T.tintAmber.fg, height: 1.5))),
              ]),
            ),
            const SizedBox(height: 16),
            CommentsSection(postId: p.id, requireLogin: _requireLogin),
          ],
        ),
      ]),
    );
  }

  Widget _favBtn(MedTokens T, Post p) => GestureDetector(
        onTap: () async {
          if (!_requireLogin()) return;
          try {
            await context.read<PostsStore>().toggleFav(p.id);
            if (mounted) showToast(context, p.faved ? '已取消收藏' : '已收藏');
          } catch (e) {
            if (mounted) showToast(context, '操作失败：$e');
          }
        },
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(shape: BoxShape.circle, color: p.faved ? T.tintPink.bg : T.bg),
            child: Center(child: p.faved ? Icon(Icons.favorite, size: 17, color: T.pink) : MedIcon(MedIcons.heart, size: 17, color: T.inkMuted)),
          ),
          if (p.favs > 0)
            Positioned(
              top: -4, right: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: T.pink, borderRadius: BorderRadius.circular(999), border: Border.all(color: T.surface, width: 1.5)),
                child: Text('${p.favs}', style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800)),
              ),
            ),
        ]),
      );

  Widget _chip(MedTokens T, String label, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(label, style: TextStyle(fontSize: 11.5, color: fg, fontWeight: FontWeight.w700)),
      );

  Widget _statIcon(MedTokens T, MedIconData icon, String v) => Row(children: [
        MedIcon(icon, size: 14, color: T.inkSubtle),
        const SizedBox(width: 4),
        Text(v, style: TextStyle(fontSize: 12, color: T.inkSubtle)),
      ]);

  Widget _poll(MedTokens T, Poll poll) {
    final total = poll.total + (_voted != null ? 1 : 0);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: T.bg, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.poll_outlined, size: 16, color: T.primary),
          const SizedBox(width: 6),
          Text(poll.question, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: T.ink)),
        ]),
        const SizedBox(height: 10),
        for (int i = 0; i < poll.options.length; i++) ...[
          GestureDetector(
            onTap: _voted != null ? null : () => _requireLogin() ? setState(() => _voted = i) : null,
            child: Builder(builder: (_) {
              final votes = poll.options[i].votes + (_voted == i ? 1 : 0);
              final pct = total == 0 ? 0.0 : votes / total;
              return Stack(children: [
                Container(height: 36, decoration: BoxDecoration(color: T.surface, borderRadius: BorderRadius.circular(8))),
                if (_voted != null)
                  FractionallySizedBox(
                    widthFactor: pct,
                    child: Container(height: 36, decoration: BoxDecoration(color: _voted == i ? T.primarySoft : T.divider, borderRadius: BorderRadius.circular(8))),
                  ),
                SizedBox(
                  height: 36,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(children: [
                      Container(
                        width: 18, height: 18, alignment: Alignment.center,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: _voted == i ? T.primary : T.divider),
                        child: Text(String.fromCharCode(65 + i), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _voted == i ? Colors.white : T.inkMuted)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(poll.options[i].text, style: TextStyle(fontSize: 13, color: T.ink))),
                      if (_voted != null) Text('${(pct * 100).round()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: T.inkMuted)),
                    ]),
                  ),
                ),
              ]);
            }),
          ),
          if (i < poll.options.length - 1) const SizedBox(height: 6),
        ],
        const SizedBox(height: 8),
        Text('$total 人参与${_voted == null ? ' · 点击选项投票' : ''}', style: TextStyle(fontSize: 11, color: T.inkSubtle)),
      ]),
    );
  }
}

/// Comments list + composer.
class CommentsSection extends StatefulWidget {
  final String postId;
  final bool Function() requireLogin;
  const CommentsSection({super.key, required this.postId, required this.requireLogin});

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  List<Comment>? _items;
  String? _error;
  final _ctl = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await context.read<PostsStore>().comments(widget.postId);
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = '评论加载失败');
    }
  }

  Future<void> _send() async {
    if (!widget.requireLogin()) return;
    final text = _ctl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      final c = await context.read<PostsStore>().addComment(widget.postId, text);
      _ctl.clear();
      setState(() => _items = [...?_items, c]);
    } catch (e) {
      if (mounted) showToast(context, '发送失败：$e');
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final T = MedTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: T.surface, borderRadius: BorderRadius.circular(16), boxShadow: T.shadowSm),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('评论 ${_items?.length ?? ''}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: T.ink)),
        const SizedBox(height: 12),
        if (_items == null && _error == null) Center(child: Padding(padding: const EdgeInsets.all(12), child: CircularProgressIndicator(color: T.primary, strokeWidth: 2))),
        if (_error != null) Text(_error!, style: TextStyle(color: T.inkSubtle, fontSize: 12.5)),
        if (_items != null && _items!.isEmpty) Text('暂无评论，来说两句吧', style: TextStyle(color: T.inkSubtle, fontSize: 12.5)),
        for (final c in _items ?? const <Comment>[]) ...[
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            MedAvatar(size: 30, seed: c.authorSeed, label: c.authorName),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(c.authorName, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: T.inkMuted)),
                  const SizedBox(width: 8),
                  Text(_ago(c.ts), style: TextStyle(fontSize: 11, color: T.inkSubtle)),
                ]),
                const SizedBox(height: 3),
                Text(c.text, style: TextStyle(fontSize: 13.5, color: T.ink, height: 1.5)),
              ]),
            ),
          ]),
          const SizedBox(height: 14),
        ],
        Row(children: [
          Expanded(
            child: TextField(
              controller: _ctl,
              style: TextStyle(fontSize: 13.5, color: T.ink),
              decoration: InputDecoration(
                hintText: '写下你的评论…',
                hintStyle: TextStyle(color: T.inkSubtle, fontSize: 13),
                filled: true,
                fillColor: T.bg,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sending ? null : _send,
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: T.primaryButtonGradient),
              child: Center(child: _sending ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const MedIcon(MedIcons.send, size: 16, color: Colors.white)),
            ),
          ),
        ]),
      ]),
    );
  }

  static String _ago(int ts) {
    final d = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts));
    if (d.inMinutes < 1) return '刚刚';
    if (d.inHours < 1) return '${d.inMinutes} 分钟前';
    if (d.inDays < 1) return '${d.inHours} 小时前';
    return '${d.inDays} 天前';
  }
}
