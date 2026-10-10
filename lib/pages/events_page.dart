import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/med_theme.dart';
import '../widgets/common.dart';
import '../widgets/events_signup_list.dart';
import '../widgets/med_icons.dart';
import 'simple_pages.dart';

/// 义诊活动 — carousel + signup list (circular covers) + 发起活动 FAB.
class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedTheme.bg,
      appBar: const SubHeader(title: '活动列表'),
      body: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _EventsCarousel(),
            EventsSignupList(roundCover: true),
            SizedBox(height: 60),
          ],
        ),
      ),
      floatingActionButton: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SimplePage(title: '发起活动')),
        ),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFB923C), Color(0xFFF97316)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF97316).withValues(alpha: 0.5),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(child: MedIcon(MedIcons.plus, size: 28, color: Colors.white, stroke: 2.5)),
        ),
      ),
    );
  }
}

class _EventsCarousel extends StatefulWidget {
  const _EventsCarousel();

  @override
  State<_EventsCarousel> createState() => _EventsCarouselState();
}

class _EventsCarouselState extends State<_EventsCarousel> {
  static const _slides = [
    ('ev-slide-1', '义诊活动', '公益义诊 · 健康守护'),
    ('ev-slide-2', '健康讲座', '名医面对面'),
    ('ev-slide-3', '疫苗咨询', '儿童健康日'),
  ];
  int _idx = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 3800), (_) {
      if (mounted) setState(() => _idx = (_idx + 1) % _slides.length);
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
      child: Container(
        height: 150,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), boxShadow: MedTheme.shadowMd),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: MedPlaceholder(key: ValueKey(cur.$1), seed: cur.$1, radius: 0),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0x40000000)],
                    stops: [0.4, 1],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cur.$2,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: Colors.white,
                          shadows: [Shadow(color: Color(0x26000000), blurRadius: 8, offset: Offset(0, 2))],
                        )),
                    const SizedBox(height: 6),
                    Text(cur.$3,
                        style: TextStyle(
                            fontSize: 12, letterSpacing: 1, color: Colors.white.withValues(alpha: 0.9))),
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
    );
  }
}
