import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models.dart';
import '../data/stores.dart';
import '../pages/event_detail_page.dart';
import '../pages/events_page.dart';
import '../theme/med_theme.dart';
import 'common.dart';
import 'med_icons.dart';

/// 活动报名 title + live event cards — shared by 义诊活动 page and the 首页 bottom section.
/// `roundCover` = true renders the 76 px cover as a CIRCLE (design change request).
class EventsSignupList extends StatelessWidget {
  final int? limit;
  final bool roundCover;
  final bool showHeader;
  const EventsSignupList({super.key, this.limit, this.roundCover = false, this.showHeader = true});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<EventsStore>();
    final T = MedTheme.of(context);
    final list = store.list(limit: limit);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader)
          SectionTitle(
            title: '活动报名',
            actionLabel: null,
            actionIcon: MedIcons.chart,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            onAction: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EventsPage())),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
          child: store.loading && list.isEmpty
              ? Padding(padding: const EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: T.primary)))
              : store.error != null && list.isEmpty
                  ? ErrorRetry(message: store.error!, onRetry: store.load)
                  : Column(children: [
                      for (int i = 0; i < list.length; i++) ...[
                        if (i > 0) const SizedBox(height: 14),
                        EventCard(event: list[i], roundCover: roundCover),
                      ],
                    ]),
        ),
      ],
    );
  }
}

class EventCard extends StatelessWidget {
  final HealthEvent event;
  final bool roundCover;
  const EventCard({super.key, required this.event, this.roundCover = false});

  @override
  Widget build(BuildContext context) {
    final T = MedTheme.of(context);
    final ev = event;
    const coverSize = 76.0;

    return Material(
      color: T.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailPage(eventId: ev.id))),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), boxShadow: T.shadowSm),
          child: Row(
            children: [
              // 1. Cover — 76 × 76; circular on 首页 / 义诊活动 list (`roundCover`)
              MedPlaceholder(width: coverSize, height: coverSize, seed: ev.seed, radius: 12, circle: roundCover, image: ev.cover),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(ev.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: T.ink, height: 1.4)),
                    const SizedBox(height: 6),
                    Row(children: [
                      if (ev.signups.isNotEmpty) ...[
                        LikerAvatars(
                          likers: ev.signupUsers.take(4).map((u) => u.seed).toList(),
                          labels: ev.signupUsers.take(4).map((u) => u.name).toList(),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text('${ev.signups.length} 人已报名', style: TextStyle(fontSize: 11.5, color: T.inkSubtle)),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      Text(ev.date, style: TextStyle(fontSize: 11, color: T.inkSubtle)),
                      const SizedBox(width: 12),
                      MedIcon(MedIcons.eye, size: 12, color: T.inkSubtle),
                      const SizedBox(width: 3),
                      Text('${ev.views}', style: TextStyle(fontSize: 11, color: T.inkSubtle)),
                    ]),
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
