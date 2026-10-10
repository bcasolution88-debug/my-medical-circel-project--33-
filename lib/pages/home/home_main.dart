import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/events_store.dart';
import '../../data/models.dart';
import '../../theme/med_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/events_signup_list.dart';
import '../../widgets/med_icons.dart';
import '../events_page.dart';
import '../simple_pages.dart';

/// 首页 main tab content — carousel, feature grid, 热门健康圈, 热门问诊, 活动报名 (circular covers).
class HomeMain extends StatelessWidget {
  final VoidCallback goForumTab;
  final VoidCallback goCircleTab;
  const HomeMain({super.key, required this.goForumTab, required this.goCircleTab});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HomeCarousel(),
          const FeatureGrid(),
          SectionTitle(
            title: '热门健康圈',
            onAction: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SimplePage(title: '健康圈子')),
            ),
          ),
          HotCircles(onTap: (t) => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SimplePage(title: t.label)),
              )),
          SectionTitle(title: '热门问诊', onAction: goForumTab),
          HotForums(onTap: goForumTab),
          // 活动报名 — same list + behaviour as 义诊活动; covers rendered as CIRCLES
          const EventsSignupList(roundCover: true),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Carousel (auto-rotating)
// ────────────────────────────────────────────────────────────
class HomeCarousel extends StatefulWidget {
  const HomeCarousel({super.key});

  @override
  State<HomeCarousel> createState() => _HomeCarouselState();
}

class _HomeCarouselState extends State<HomeCarousel> {
  int _idx = 0;
  Timer? _timer;
  final _slides = CmsHome.carousel;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
      if (!mounted) return;
      setState(() => _idx = (_idx + 1) % _slides.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cur = _slides[_idx];
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: GestureDetector(
        onHorizontalDragEnd: (d) {
          if (d.primaryVelocity == null) return;
          setState(() {
            _idx = d.primaryVelocity! < 0
                ? (_idx + 1) % _slides.length
                : (_idx - 1 + _slides.length) % _slides.length;
          });
        },
        child: Container(
          height: 152,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: MedTheme.shadowMd,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  child: MedPlaceholder(
                    key: ValueKey(cur.seed),
                    seed: cur.seed,
                    radius: 0,
                    imageAsset: cur.image,
                  ),
                ),
                // Decorative bubbles
                Positioned(
                  top: -30,
                  right: -20,
                  child: _bubble(140, 0.12),
                ),
                Positioned(
                  bottom: -50,
                  left: -20,
                  child: _bubble(130, 0.08),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cur.title,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                          shadows: [Shadow(color: Color(0x4D000000), blurRadius: 8, offset: Offset(0, 2))],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cur.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.9),
                          letterSpacing: 2,
                          shadows: const [Shadow(color: Color(0x4D000000), blurRadius: 4, offset: Offset(0, 1))],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 0; i < _slides.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _idx ? 16 : 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: i == _idx ? Colors.white : Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bubble(double size, double alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: alpha),
        ),
      );
}

// ────────────────────────────────────────────────────────────
// 4 × 2 feature grid — 46 px circular icon tiles
// ────────────────────────────────────────────────────────────
class _FeatureItem {
  final String id;
  final MedIconData icon;
  final String label;
  final Tint tint;
  const _FeatureItem(this.id, this.icon, this.label, this.tint);
}

class FeatureGrid extends StatelessWidget {
  const FeatureGrid({super.key});

  static const _items = [
    _FeatureItem('videoPosts', MedIcons.playCross, '视频帖', MedTheme.tintViolet),
    _FeatureItem('news', MedIcons.clipboard, '健康资讯', MedTheme.tintIndigo),
    _FeatureItem('events', MedIcons.stethoscope, '义诊活动', MedTheme.tintRose),
    _FeatureItem('shorts', MedIcons.heartPulse, '健康科普', MedTheme.tintSky),
    _FeatureItem('sites', MedIcons.hospital, '医疗导航', MedTheme.tintMint),
    _FeatureItem('circleHub', MedIcons.shieldPlus, '健康圈子', MedTheme.tintAmber),
    _FeatureItem('recommend', MedIcons.pill, '健康好物', MedTheme.tintPink),
    _FeatureItem('messages', MedIcons.doctorChat, '消息信息', MedTheme.tintMessage),
  ];

  void _go(BuildContext context, _FeatureItem it) {
    if (it.id == 'events') {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EventsPage()));
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => SimplePage(title: it.label)));
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<AppState>().messageUnread;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 18, 10, 6),
      child: Column(
        children: [
          for (int row = 0; row < 2; row++) ...[
            if (row > 0) const SizedBox(height: 16),
            Row(
              children: [
                for (int col = 0; col < 4; col++)
                  Expanded(
                    child: _tile(context, _items[row * 4 + col],
                        badge: _items[row * 4 + col].id == 'messages' ? unread : 0),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, _FeatureItem it, {int badge = 0}) {
    final fg = it.tint.fg;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _go(context, it),
      child: Column(
        children: [
          SizedBox(
            width: 56,
            height: 50,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [fg, fg.withValues(alpha: 0.87)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: fg.withValues(alpha: 0.27),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(child: MedIcon(it.icon, size: 21, color: Colors.white)),
                ),
                if (badge > 0)
                  Positioned(
                    top: -1,
                    right: 0,
                    child: RedBadge(count: badge),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            it.label,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: MedTheme.ink, height: 1.2),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Hot Circles — 4 × 2 square tiles, label as plain text below
// ────────────────────────────────────────────────────────────
class HotCircles extends StatelessWidget {
  final void Function(HomeTile) onTap;
  const HotCircles({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = CmsHome.hotCircles.take(8).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 12,
          childAspectRatio: 78 / 118,
        ),
        itemBuilder: (context, i) {
          final it = items[i];
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onTap(it),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: MedPlaceholder(seed: it.seed, radius: 12, imageAsset: it.image),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 32,
                  child: Text(
                    it.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: MedTheme.ink, height: 1.3),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Hot Forums — 3 × 2 grid with pill-tag labels
// ────────────────────────────────────────────────────────────
class HotForums extends StatelessWidget {
  final VoidCallback onTap;
  const HotForums({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = CmsHome.hotForums;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          mainAxisExtent: 108,
        ),
        itemBuilder: (context, i) {
          final it = items[i];
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MedPlaceholder(height: 72, seed: it.seed, radius: 16),
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: it.tint ?? MedTheme.violet,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const MedIcon(MedIcons.flower, size: 11, color: Colors.white),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          it.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
