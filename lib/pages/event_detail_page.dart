import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/events_store.dart';
import '../theme/med_theme.dart';
import '../widgets/common.dart';
import '../widgets/med_icons.dart';

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
  bool _viewed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_viewed) return;
      _viewed = true;
      context.read<EventsStore>().bumpView(widget.eventId); // each open = +1 view
    });
    _timer = Timer.periodic(const Duration(milliseconds: 3800), (_) {
      if (mounted) setState(() => _slide++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<EventsStore>();
    final ev = store.get(widget.eventId);
    if (ev == null) {
      return const Scaffold(
        appBar: SubHeader(title: '活动详情'),
        body: Center(child: Text('活动不存在')),
      );
    }
    final covers = ev.cover != null ? [ev.cover!] : ['${ev.seed}-a', '${ev.seed}-b', '${ev.seed}-c'];
    final hasReal = ev.cover != null;
    final idx = _slide % covers.length;
    final signups = ev.signups;
    final joined = store.joined(ev.id);

    return Scaffold(
      backgroundColor: MedTheme.bg,
      appBar: const SubHeader(title: '活动详情'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cover carousel
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                    child: GestureDetector(
                      onTap: () => _openLightbox(context, covers, idx, hasReal),
                      child: Container(
                        height: 180,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14), boxShadow: MedTheme.shadowMd),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 500),
                                child: hasReal
                                    ? Image.asset(covers[idx], key: ValueKey(covers[idx]), fit: BoxFit.cover)
                                    : MedPlaceholder(key: ValueKey(covers[idx]), seed: covers[idx], radius: 0),
                              ),
                              const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Color(0x00000000), Color(0x4D000000)],
                                    stops: [0.55, 1],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle, color: Colors.black.withValues(alpha: 0.4)),
                                  child: const Icon(Icons.fullscreen, size: 16, color: Colors.white),
                                ),
                              ),
                              if (covers.length > 1) ...[
                                Positioned(
                                  top: 10,
                                  left: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text('${idx + 1} / ${covers.length}',
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                                Positioned(
                                  bottom: 10,
                                  left: 0,
                                  right: 0,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      for (int i = 0; i < covers.length; i++)
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 300),
                                          margin: const EdgeInsets.symmetric(horizontal: 3),
                                          width: i == idx ? 16 : 5,
                                          height: 5,
                                          decoration: BoxDecoration(
                                            color: i == idx ? Colors.white : Colors.white.withValues(alpha: 0.55),
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Title + meta
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ev.title,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700, color: MedTheme.ink, height: 1.45)),
                        const SizedBox(height: 12),
                        _metaRow(MedIcons.clock, MedTheme.primary, '活动时间', '${ev.date} · ${ev.time}'),
                        _metaRow(MedIcons.pin, MedTheme.pink, '活动地点', ev.place),
                        _metaRow(MedIcons.user, MedTheme.violet, '发布者', ev.author, last: true),
                      ],
                    ),
                  ),

                  // Detail body
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('活动详情',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: MedTheme.ink)),
                        const SizedBox(height: 10),
                        Text(ev.detail,
                            style: const TextStyle(fontSize: 14, color: MedTheme.inkMuted, height: 1.75)),
                      ],
                    ),
                  ),

                  // Signups
                  _card(
                    margin: const EdgeInsets.fromLTRB(14, 10, 14, 20),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('已报名',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: MedTheme.ink)),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 12, color: MedTheme.inkSubtle),
                                children: [
                                  const TextSpan(text: '共 '),
                                  TextSpan(
                                      text: '${signups.length}',
                                      style: const TextStyle(color: MedTheme.primary, fontWeight: FontWeight.w700)),
                                  TextSpan(text: ' 人 · ${ev.baseViews} 次浏览'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (signups.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('暂无报名 · 抢先一位吧',
                                style: TextStyle(fontSize: 12, color: MedTheme.inkSubtle)),
                          )
                        else
                          _signupAvatars(signups),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom CTA
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
            decoration: const BoxDecoration(
              color: MedTheme.surface,
              border: Border(top: BorderSide(color: MedTheme.divider)),
            ),
            child: SafeArea(
              top: false,
              child: GestureDetector(
                onTap: () {
                  final now = store.toggleJoin(ev.id);
                  showToast(context, now ? '报名成功' : '已撤销报名');
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 50,
                  decoration: BoxDecoration(
                    color: joined ? Colors.white : MedTheme.mint,
                    borderRadius: BorderRadius.circular(999),
                    border: joined ? Border.all(color: MedTheme.pink, width: 1.5) : null,
                    boxShadow: joined
                        ? null
                        : [
                            BoxShadow(
                                color: MedTheme.mint.withValues(alpha: 0.33),
                                blurRadius: 16,
                                offset: const Offset(0, 6))
                          ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MedIcon(joined ? MedIcons.close : MedIcons.send,
                          size: 16, color: joined ? MedTheme.pink : MedTheme.ink),
                      const SizedBox(width: 8),
                      Text(joined ? '撤销报名' : '立即报名',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: joined ? MedTheme.pink : MedTheme.ink)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child, EdgeInsets? margin, EdgeInsets? padding}) {
    return Container(
      margin: margin ?? const EdgeInsets.fromLTRB(14, 10, 14, 0),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(color: MedTheme.surface, borderRadius: BorderRadius.circular(14)),
      child: child,
    );
  }

  Widget _metaRow(MedIconData icon, Color color, String label, String value, {bool last = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: MedIcon(icon, size: 14, color: color)),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(label, style: const TextStyle(fontSize: 13, color: MedTheme.inkSubtle)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, color: MedTheme.ink, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _signupAvatars(List<String> signups) {
    const size = 30.0;
    const overlap = 10.0;
    final shown = signups.take(10).toList();
    final extra = signups.length - shown.length;
    final count = shown.length + (extra > 0 ? 1 : 0);
    return SizedBox(
      height: size + 4,
      width: count * (size - overlap) + overlap + 4,
      child: Stack(
        children: [
          for (int i = 0; i < shown.length; i++)
            Positioned(
              left: i * (size - overlap),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: MedTheme.surface,
                      border: Border.all(color: shown[i] == 'me' ? MedTheme.mint : Colors.white, width: 1.5),
                    ),
                    child: MedAvatar(
                      size: size,
                      seed: shown[i] == 'me' ? 'me' : shown[i],
                      label: shown[i] == 'me' ? 'M' : shown[i],
                    ),
                  ),
                  if (shown[i] == 'me')
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: MedTheme.mint,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Center(child: MedIcon(MedIcons.check, size: 7, color: Colors.white, stroke: 3)),
                      ),
                    ),
                ],
              ),
            ),
          if (extra > 0)
            Positioned(
              left: shown.length * (size - overlap),
              child: Container(
                width: size + 3,
                height: size + 3,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MedTheme.divider,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text('+$extra',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: MedTheme.inkMuted)),
              ),
            ),
        ],
      ),
    );
  }

  void _openLightbox(BuildContext context, List<String> covers, int initial, bool real) {
    _timer?.cancel();
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (_) => _CoverLightbox(covers: covers, initial: initial, real: real),
    ).then((_) {
      if (!mounted) return;
      _timer = Timer.periodic(const Duration(milliseconds: 3800), (_) {
        if (mounted) setState(() => _slide++);
      });
    });
  }
}

class _CoverLightbox extends StatefulWidget {
  final List<String> covers;
  final int initial;
  final bool real;
  const _CoverLightbox({required this.covers, required this.initial, required this.real});

  @override
  State<_CoverLightbox> createState() => _CoverLightboxState();
}

class _CoverLightboxState extends State<_CoverLightbox> {
  late final PageController _pc = PageController(initialPage: widget.initial);
  late int _idx = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pc,
            itemCount: widget.covers.length,
            onPageChanged: (i) => setState(() => _idx = i),
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: widget.real
                      ? Image.asset(widget.covers[i], fit: BoxFit.cover)
                      : MedPlaceholder(seed: widget.covers[i], radius: 0),
                ),
              ),
            ),
          ),
          Positioned(
            top: 14,
            left: 14,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('${_idx + 1} / ${widget.covers.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          Positioned(
            top: 14,
            right: 14,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  child: const Center(child: MedIcon(MedIcons.close, size: 18, color: Colors.white)),
                ),
              ),
            ),
          ),
          const Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Text('双指缩放 · 左右滑动切换',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
