import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

/// Single source of truth for 义诊活动 (events) — list + detail + signup.
/// Ported from `postStats_v16.js` → window.eventsStore.
class EventsStore extends ChangeNotifier {
  EventsStore();

  static const _joinKey = 'event_joins_v2';
  static const _statsKey = 'event_stats';

  final Map<String, int> _joins = {}; // id -> ts
  final Map<String, int> _views = {}; // id -> extra views
  bool _loaded = false;

  /// Seed events (medical naming map applied) — user-approved submissions first, then seeds.
  static const List<HealthEvent> _seed = [
    HealthEvent(
      id: 'uev-1',
      title: '健康读书会 · 十月共读《营养的真相》',
      date: '2026-10-20',
      time: '19:30',
      place: '社区健康服务中心',
      detail: '每周一次线下共读，欢迎新朋友加入。',
      seed: 'uev-1',
      baseViews: 0,
      signups: [],
      author: 'allanliu6',
    ),
    HealthEvent(
      id: 'ev1',
      title: '示例活动一 · 社区周末义诊',
      date: '2026-12-15',
      time: '19:00',
      place: '示例地点 · 由后台配置',
      detail: '这里是活动详情示例。管理员在后台发布活动后，用户在此看到完整介绍、时间、地点与图片。',
      seed: 'ev1',
      cover: 'assets/images/home-info-1.jpg',
      baseViews: 78,
      signups: ['allanliu6', 'shier', 'mymuse60', 'myunisocial', 'weichen'],
      author: 'segi asia marketing (SAM)',
    ),
    HealthEvent(
      id: 'ev2',
      title: '示例活动二 · 高血压健康讲座',
      date: '2025-01-30',
      time: '09:00',
      place: '创新中心 3 楼',
      detail: '48 小时团队协作挑战，欢迎所有感兴趣的朋友报名组队。',
      seed: 'ev2',
      cover: 'assets/images/home-info-2.jpg',
      baseViews: 7,
      signups: ['jacky'],
      author: 'segi asia marketing (SAM)',
    ),
    HealthEvent(
      id: 'ev3',
      title: '示例活动三 · 儿童疫苗咨询日',
      date: '2025-01-13',
      time: '14:30',
      place: '图书馆多功能厅',
      detail: '分享你的健康经验和护理心得，现场有专业医师点评。',
      seed: 'ev3',
      baseViews: 3,
      signups: ['future', 'yy', 'segi'],
      author: 'segi asia marketing (SAM)',
    ),
  ];

  Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final k in prefs.getStringList(_joinKey) ?? const []) {
        _joins[k] = 1;
      }
      for (final k in prefs.getStringList(_statsKey) ?? const []) {
        final parts = k.split(':');
        if (parts.length == 2) _views[parts[0]] = int.tryParse(parts[1]) ?? 0;
      }
    } catch (_) {}
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_joinKey, _joins.keys.toList());
      await prefs.setStringList(
          _statsKey, _views.entries.map((e) => '${e.key}:${e.value}').toList());
    } catch (_) {}
  }

  List<HealthEvent> list({int? limit}) {
    final all = _seed.map(_withStats).toList();
    return limit != null ? all.take(limit).toList() : all;
  }

  HealthEvent? get(String id) {
    for (final e in _seed) {
      if (e.id == id) return _withStats(e);
    }
    return null;
  }

  bool joined(String id) => _joins.containsKey(id);

  HealthEvent _withStats(HealthEvent e) {
    final signups = e.signups.where((x) => x != 'me').toList();
    if (joined(e.id)) signups.add('me');
    return HealthEvent(
      id: e.id,
      title: e.title,
      date: e.date,
      time: e.time,
      place: e.place,
      detail: e.detail,
      seed: e.seed,
      cover: e.cover,
      baseViews: e.baseViews + (_views[e.id] ?? 0),
      signups: signups,
      author: e.author,
    );
  }

  void bumpView(String id) {
    _views[id] = (_views[id] ?? 0) + 1;
    _persist();
    notifyListeners();
  }

  bool toggleJoin(String id) {
    if (_joins.containsKey(id)) {
      _joins.remove(id);
    } else {
      _joins[id] = DateTime.now().millisecondsSinceEpoch;
    }
    _persist();
    notifyListeners();
    return _joins.containsKey(id);
  }
}

/// App-wide lightweight state (unread counts, current user, home tab).
class AppState extends ChangeNotifier {
  int serviceUnread = 2;
  int messageUnread = 3;
  String selfName = '动感地带';
  String selfId = '800133';

  void clearServiceUnread() {
    serviceUnread = 0;
    notifyListeners();
  }
}
