import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../data/models.dart';
import '../data/stores.dart';
import '../theme/med_theme.dart';
import '../widgets/common.dart';
import '../widgets/med_icons.dart';
import '../widgets/video_box.dart';
import 'auth/login_page.dart';
import 'post_detail_page.dart';

/// 视频帖 — vertical snap feed. Top-right pill: play/pause · volume · screenshot · fullscreen.
/// Right rail: ❤ 收藏 · 评论 · 分享 · 详情 · 👍 点赞 · author avatar.
class VideoFeedPage extends StatefulWidget {
  const VideoFeedPage({super.key});

  @override
  State<VideoFeedPage> createState() => _VideoFeedPageState();
}

class _VideoFeedPageState extends State<VideoFeedPage> {
  final _pc = PageController();
  int _page = 0;
  bool _muted = false, _paused = false;
  final Map<String, VideoPlayerController> _ctls = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<PostsStore>().load('video'));
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _apply(Post? current) {
    for (final e in _ctls.entries) {
      final isCur = current != null && e.key == current.id;
      if (isCur) {
        e.value.setVolume(_muted ? 0 : 1);
        _paused ? e.value.pause() : e.value.play();
      } else {
        e.value.pause();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PostsStore>();
    final posts = store.byKind('video');
    final T = MedTheme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: posts.isEmpty
          ? Stack(children: [
              Center(child: store.error != null ? ErrorRetry(message: store.error!, onRetry: () => store.load('video')) : CircularProgressIndicator(color: T.primary)),
              const SafeArea(child: Padding(padding: EdgeInsets.all(14), child: NavPill())),
            ])
          : Stack(children: [
              PageView.builder(
                controller: _pc,
                scrollDirection: Axis.vertical,
                itemCount: posts.length,
                onPageChanged: (i) {
                  setState(() {
                    _page = i;
                    _paused = false;
                  });
                  _apply(posts[i]);
                },
                itemBuilder: (_, i) => _VideoSlide(
                  post: posts[i],
                  active: i == _page,
                  muted: _muted,
                  onReady: (c) {
                    _ctls[posts[i].id] = c;
                    if (i == _page) _apply(posts[i]);
                  },
                ),
              ),
              const SafeArea(child: Padding(padding: EdgeInsets.all(14), child: NavPill())),
              Positioned(
                top: 14, right: 14,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(999)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      _pillBtn(_paused ? Icons.play_arrow_rounded : Icons.pause_rounded, () {
                        setState(() => _paused = !_paused);
                        _apply(posts[_page]);
                      }),
                      _pillBtn(_muted ? Icons.volume_off_rounded : Icons.volume_up_rounded, () {
                        setState(() => _muted = !_muted);
                        _apply(posts[_page]);
                      }),
                      _pillBtn(Icons.photo_camera_outlined, () => showToast(context, '截图已保存到相册')),
                      _pillBtn(Icons.fullscreen_rounded, () => showToast(context, '已进入全屏')),
                    ]),
                  ),
                ),
              ),
            ]),
    );
  }

  Widget _pillBtn(IconData icon, VoidCallback onTap) => IconButton(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(),
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onTap,
      );
}

class _VideoSlide extends StatelessWidget {
  final Post post;
  final bool active, muted;
  final ValueChanged<VideoPlayerController> onReady;
  const _VideoSlide({required this.post, required this.active, required this.muted, required this.onReady});

  bool _login(BuildContext context) {
    if (context.read<AuthStore>().loggedIn) return true;
    showToast(context, '请先登录');
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginPage()));
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final T = MedTheme.of(context);
    final store = context.watch<PostsStore>();
    final p = store.get(post.id) ?? post;
    return Stack(fit: StackFit.expand, children: [
      VideoBox(key: ValueKey(p.id), source: p.video, seed: '${p.id}-v', autoPlay: active, loop: true, muted: muted, onReady: onReady),
      // bottom gradient
      const Positioned(
        left: 0, right: 0, bottom: 0, height: 260,
        child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00000000), Color(0xB3000000)]))),
      ),
      // caption
      Positioned(
        left: 16, right: 80, bottom: 36,
        child: SafeArea(
          top: false,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Text('@${p.authorName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(width: 8),
              Text(p.timeLabel, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11.5)),
            ]),
            const SizedBox(height: 8),
            Text(p.text, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
            if (p.circleName.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(999)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const MedIcon(MedIcons.heartPulse, size: 12, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(p.circleName, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600)),
                ]),
              ),
            ],
          ]),
        ),
      ),
      // right rail
      Positioned(
        right: 12, bottom: 40,
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _rail(
              p.faved ? Icon(Icons.favorite, color: T.pink, size: 26) : const MedIcon(MedIcons.heart, size: 26, color: Colors.white),
              '${p.favs}',
              () => _login(context) ? store.toggleFav(p.id) : null,
            ),
            _rail(const MedIcon(MedIcons.doctorChat, size: 26, color: Colors.white), '${p.comments}',
                () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PostDetailPage(postId: p.id)))),
            _rail(const MedIcon(MedIcons.send, size: 24, color: Colors.white), '分享', () => showToast(context, '分享卡片已生成')),
            _rail(const MedIcon(MedIcons.doc, size: 24, color: Colors.white), '详情',
                () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PostDetailPage(postId: p.id)))),
            _rail(MedIcon(MedIcons.like, size: 26, color: p.liked ? T.pink : Colors.white), '${p.likes}',
                () => _login(context) ? store.toggleLike(p.id) : null),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
              child: MedAvatar(size: 40, seed: p.authorSeed, label: p.authorName),
            ),
          ]),
        ),
      ),
    ]);
  }

  Widget _rail(Widget icon, String label, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Column(children: [
            icon,
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}
