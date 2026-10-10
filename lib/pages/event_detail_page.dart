import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models.dart';
import '../data/stores.dart';
import '../theme/med_theme.dart';
import '../widgets/common.dart';
import '../widgets/med_icons.dart';
import 'auth/login_page.dart';

/// 活动详情 — cover carousel (tap for fullscreen zoom), meta, detail, signups, join CTA.
class EventDetailPage extends StatefulWidget {
  final String eventId;
  const EventDetailPage({super.key, required this.eventId});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  int _slide = 0;
  Timer? _timer;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<EventsStore>().fetchDetail(widget.eventId));
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 3800), (_) {
      if (mounted) setState(() => _slide++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _toggleJoin(HealthEvent ev) async {
    if (!context.read<AuthStore>().loggedIn) {
      showToast(context, '请先登录');
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginPage()));
      return;
    }
    setState(() => _busy = true);
    try {
      final joined = await context.read<EventsStore>().toggleJoin(ev.id);
      if (mounted) showToast(context, joined ? '报名成功' : '已撤销报名');
    } catch (e) {
      if (mounted) showToast(context, '操作失败：$e');
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final T = MedTheme.of(context);
    final store = context.watch<EventsStore>();
    final ev = store.get(widget.eventId);
    if (ev == null) {
      return Scaffold(
        backgroundColor: T.bg,
        appBar: const SubHeader(title: '活动详情'),
        body: store.error != null
            ? ErrorRetry(message: store.error!, onRetry: () => store.fetchDetail(widget.eventId))
            : Center(child: CircularProgressIndicator(color: T.primary)),
      );
    }
    final covers = ev.cover != null ? [ev.cover!] : ['${ev.seed}-a', '${ev.seed}-b', '${ev.seed}-c'];
    final idx = _slide % covers.length;
    final signups = ev.signupUsers;
    final joined = ev.joined;
    final me = context.watch<AuthStore>().user;

    return Scaffold(
      backgroundColor: T.bg,
      appBar: const SubHeader(title: '活动详情'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                    child: GestureDetector(
                      onTap: () => _openLightbox(context, covers, idx),
                      child: Container(
                        height: 180,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), boxShadow: T.shadowMd),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(fit: StackFit.expand, children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              child: MedPlaceholder(key: ValueKey(covers[idx]), seed: covers[idx], radius: 0, image: ev.cover),
                            ),
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00000000), Color(0x4D000000)], stops: [0.55, 1]),
                              ),
                            ),
                            Positioned(
                              top: 10, right: 10,
                              child: Container(
                                width: 30, height: 30,
                                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withValues(alpha: 0.4)),
                                child: const Icon(Icons.fullscreen, size: 16, color: Colors.white),
                              ),
                            ),
                            if (covers.length > 1) ...[
                              Positioned(
                                top: 10, left: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(999)),
                                  child: Text('${idx + 1} / ${covers.length}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                                ),
                              ),
                              Positioned(
                                bottom: 10, left: 0, right: 0,
                                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  for (int i = 0; i < covers.length; i++)
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      margin: const EdgeInsets.symmetric(horizontal: 3),
                                      width: i == idx ? 16 : 5, height: 5,
                                      decoration: BoxDecoration(color: i == idx ? Colors.white : Colors.white.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(3)),
                                    ),
                                ]),
                              ),
                            ],
                          ]),
                        ),
                      ),
                    ),
                  ),
                  _card(T, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(ev.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: T.ink, height: 1.45)),
                    const SizedBox(height: 12),
                    _metaRow(T, MedIcons.clock, T.primary, '活动时间', '${ev.date} · ${ev.time}'),
                    _metaRow(T, MedIcons.pin, T.pink, '活动地点', ev.place),
                    _metaRow(T, MedIcons.user, T.violet, '发布者', ev.authorName, last: true),
                  ])),
                  _card(T, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('活动详情', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: T.ink)),
                    const SizedBox(height: 10),
                    Text(ev.detail, style: TextStyle(fontSize: 14, color: T.inkMuted, height: 1.75)),
                  ])),
                  _card(
                    T,
                    margin: const EdgeInsets.fromLTRB(14, 10, 14, 20),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('已报名', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: T.ink)),
                        RichText(
                          text: TextSpan(style: TextStyle(fontSize: 12, color: T.inkSubtle), children: [
                            const TextSpan(text: '共 '),
                            TextSpan(text: '${signups.length}', style: TextStyle(color: T.primary, fontWeight: FontWeight.w700)),
                            TextSpan(text: ' 人 · ${ev.views} 次浏览'),
                          ]),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      if (signups.isEmpty)
                        Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('暂无报名 · 抢先一位吧', style: TextStyle(fontSize: 12, color: T.inkSubtle)))
                      else
                        _signupAvatars(T, signups, me?.id),
                    ]),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
            decoration: BoxDecoration(color: T.surface, border: Border(top: BorderSide(color: T.divider))),
            child: SafeArea(
              top: false,
              child: GestureDetector(
                onTap: _busy ? null : () => _toggleJoin(ev),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 50,
                  decoration: BoxDecoration(
                    color: joined ? T.surface : T.mint,
                    borderRadius: BorderRadius.circular(999),
                    border: joined ? Border.all(color: T.pink, width: 1.5) : null,
                    boxShadow: joined ? null : [BoxShadow(color: T.mint.withValues(alpha: 0.33), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    if (_busy)
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: joined ? T.pink : T.ink))
                    else
                      MedIcon(joined ? MedIcons.close : MedIcons.send, size: 16, color: joined ? T.pink : const Color(0xFF13322D)),
                    const SizedBox(width: 8),
                    Text(joined ? '撤销报名' : '立即报名', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: joined ? T.pink : const Color(0xFF13322D))),
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(MedTokens T, {required Widget child, EdgeInsets? margin, EdgeInsets? padding}) => Container(
        margin: margin ?? const EdgeInsets.fromLTRB(14, 10, 14, 0),
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(color: T.surface, borderRadius: BorderRadius.circular(14)),
        child: child,
      );

  Widget _metaRow(MedTokens T, MedIconData icon, Color color, String label, String value, {bool last = false}) => Padding(
        padding: EdgeInsets.only(bottom: last ? 0 : 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: MedIcon(icon, size: 14, color: color)),
          const SizedBox(width: 8),
          SizedBox(width: 60, child: Text(label, style: TextStyle(fontSize: 13, color: T.inkSubtle))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 13, color: T.ink, fontWeight: FontWeight.w500))),
        ]),
      );

  Widget _signupAvatars(MedTokens T, List<AppUser> signups, String? meId) {
    const size = 30.0, overlap = 10.0;
    final shown = signups.take(10).toList();
    final extra = signups.length - shown.length;
    final count = shown.length + (extra > 0 ? 1 : 0);
    return SizedBox(
      height: size + 4,
      width: count * (size - overlap) + overlap + 4,
      child: Stack(children: [
        for (int i = 0; i < shown.length; i++)
          Positioned(
            left: i * (size - overlap),
            child: Stack(clipBehavior: Clip.none, children: [
              Container(
                decoration: BoxDecoration(shape: BoxShape.circle, color: T.surface, border: Border.all(color: shown[i].id == meId ? T.mint : T.surface, width: 1.5)),
                child: MedAvatar(size: size, seed: shown[i].seed, label: shown[i].name, url: shown[i].avatar),
              ),
              if (shown[i].id == meId)
                Positioned(
                  bottom: -2, right: -2,
                  child: Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: T.mint, border: Border.all(color: T.surface, width: 1.5)),
                    child: const Center(child: MedIcon(MedIcons.check, size: 7, color: Colors.white, stroke: 3)),
                  ),
                ),
            ]),
          ),
        if (extra > 0)
          Positioned(
            left: shown.length * (size - overlap),
            child: Container(
              width: size + 3, height: size + 3, alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, color: T.divider, border: Border.all(color: T.surface, width: 1.5)),
              child: Text('+$extra', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: T.inkMuted)),
            ),
          ),
      ]),
    );
  }

  void _openLightbox(BuildContext context, List<String> covers, int initial) {
    _timer?.cancel();
    final ev = context.read<EventsStore>().get(widget.eventId);
    showDialog(context: context, barrierColor: Colors.black, builder: (_) => ImageLightbox(images: covers, initial: initial, realImage: ev?.cover))
        .then((_) => mounted ? _startTimer() : null);
  }
}

/// Fullscreen image viewer with pinch zoom + swipe.
class ImageLightbox extends StatefulWidget {
  final List<String> images;
  final int initial;
  final String? realImage;
  const ImageLightbox({super.key, required this.images, required this.initial, this.realImage});

  @override
  State<ImageLightbox> createState() => _ImageLightboxState();
}

class _ImageLightboxState extends State<ImageLightbox> {
  late final PageController _pc = PageController(initialPage: widget.initial);
  late int _idx = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(children: [
        PageView.builder(
          controller: _pc,
          itemCount: widget.images.length,
          onPageChanged: (i) => setState(() => _idx = i),
          itemBuilder: (_, i) => InteractiveViewer(
            minScale: 1, maxScale: 4,
            child: Center(child: AspectRatio(aspectRatio: 16 / 10, child: MedPlaceholder(seed: widget.images[i], radius: 0, image: widget.realImage ?? (imageProviderFor(widget.images[i]) != null ? widget.images[i] : null)))),
          ),
        ),
        Positioned(
          top: 14, left: 14,
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
              child: Text('${_idx + 1} / ${widget.images.length}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
        Positioned(
          top: 14, right: 14,
          child: SafeArea(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.15)),
                child: const Center(child: MedIcon(MedIcons.close, size: 18, color: Colors.white)),
              ),
            ),
          ),
        ),
        const Positioned(bottom: 30, left: 0, right: 0, child: Text('双指缩放 · 左右滑动切换', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12))),
      ]),
    );
  }
}
