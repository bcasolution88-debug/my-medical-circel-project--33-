import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import 'models.dart';

final api = ApiClient.instance;

/// Authentication / session.
class AuthStore extends ChangeNotifier {
  AppUser? user;
  bool loading = true;
  bool onboarded = false;

  bool get loggedIn => user != null;

  Future<void> load() async {
    await api.init();
    try {
      final p = await SharedPreferences.getInstance();
      onboarded = p.getBool('auth_onboarded') ?? false;
    } catch (_) {}
    if (api.isAuthed) {
      try {
        final j = await api.get('/api/auth/me');
        user = AppUser.fromJson(j['user']);
      } catch (e) {
        if (e is ApiException && e.status == 401) await api.setToken(null);
      }
    }
    loading = false;
    notifyListeners();
  }

  Future<void> setOnboarded() async {
    onboarded = true;
    notifyListeners();
    try {
      (await SharedPreferences.getInstance()).setBool('auth_onboarded', true);
    } catch (_) {}
  }

  Future<String> sendCode(String email) async {
    final j = await api.post('/api/auth/send-code', {'email': email});
    return (j['devCode'] ?? '').toString();
  }

  Future<void> register(String email, String code, String password) async {
    final j = await api.post('/api/auth/register', {'email': email, 'code': code, 'password': password});
    await api.setToken(j['token']);
    user = AppUser.fromJson(j['user']);
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final j = await api.post('/api/auth/login', {'email': email, 'password': password});
    await api.setToken(j['token']);
    user = AppUser.fromJson(j['user']);
    notifyListeners();
  }

  Future<void> logout() async {
    await api.setToken(null);
    user = null;
    notifyListeners();
  }
}

/// Geo-fence state for login / register.
enum GeoState { checking, inside, outside, unknown }

class GeoFenceResult {
  final GeoState state;
  final double distanceM, radiusM;
  final String name, blockedMessage;
  const GeoFenceResult(this.state, {this.distanceM = 0, this.radiusM = 0, this.name = '', this.blockedMessage = ''});
}

/// Home CMS content.
class HomeStore extends ChangeNotifier {
  HomeCms cms = HomeCms.fallback;
  bool loaded = false;
  String? error;

  Future<void> load() async {
    try {
      cms = HomeCms.fromJson(await api.get('/api/home'));
      error = null;
    } catch (e) {
      error = '无法连接服务器，已显示离线内容';
    }
    loaded = true;
    notifyListeners();
  }
}

/// 义诊活动 — list + detail + signup.
class EventsStore extends ChangeNotifier {
  List<HealthEvent> items = [];
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    try {
      final j = await api.get('/api/events');
      items = (j['items'] as List).map((e) => HealthEvent.fromJson(e)).toList();
      error = null;
    } catch (e) {
      error = e is ApiException ? e.message : '活动加载失败，请检查网络';
    }
    loading = false;
    notifyListeners();
  }

  List<HealthEvent> list({int? limit}) => limit != null ? items.take(limit).toList() : items;

  HealthEvent? get(String id) {
    for (final e in items) {
      if (e.id == id) return e;
    }
    return null;
  }

  Future<HealthEvent?> fetchDetail(String id) async {
    try {
      final e = HealthEvent.fromJson(await api.get('/api/events/$id'));
      _replace(e);
      return e;
    } catch (_) {
      return get(id);
    }
  }

  Future<bool> toggleJoin(String id) async {
    final j = await api.post('/api/events/$id/join');
    _replace(HealthEvent.fromJson(j['event']));
    return j['joined'] == true;
  }

  Future<void> submit(Map<String, dynamic> body) => api.post('/api/events', body);

  void _replace(HealthEvent e) {
    final i = items.indexWhere((x) => x.id == e.id);
    if (i >= 0) {
      items[i] = e;
    } else {
      items.insert(0, e);
    }
    notifyListeners();
  }
}

/// Posts (circle / forum / video) + comments; likes & favourites are single sources of truth.
class PostsStore extends ChangeNotifier {
  final Map<String, Post> _byId = {};
  final Map<String, List<String>> _lists = {};
  final Map<String, bool> loadingKind = {};
  String? error;

  List<Post> byKind(String kind) => (_lists[kind] ?? const []).map((id) => _byId[id]).whereType<Post>().toList();
  Post? get(String id) => _byId[id];

  Future<void> load(String kind) async {
    loadingKind[kind] = true;
    notifyListeners();
    try {
      final j = await api.get('/api/posts', query: kind == 'fav' ? {'fav': '1'} : kind == 'mine' ? {'mine': '1'} : {'kind': kind});
      final posts = (j['items'] as List).map((e) => Post.fromJson(e)).toList();
      for (final p in posts) {
        _byId[p.id] = p;
      }
      _lists[kind] = posts.map((p) => p.id).toList();
      error = null;
    } catch (e) {
      error = e is ApiException ? e.message : '帖子加载失败，请检查网络';
    }
    loadingKind[kind] = false;
    notifyListeners();
  }

  Future<Post?> fetchDetail(String id) async {
    try {
      final p = Post.fromJson(await api.get('/api/posts/$id'));
      _byId[id] = p;
      notifyListeners();
      return p;
    } catch (_) {
      return _byId[id];
    }
  }

  Future<void> toggleLike(String id) async {
    final p = Post.fromJson(await api.post('/api/posts/$id/like'));
    _byId[id] = p;
    notifyListeners();
  }

  Future<void> toggleFav(String id) async {
    final p = Post.fromJson(await api.post('/api/posts/$id/fav'));
    _byId[id] = p;
    notifyListeners();
  }

  Future<List<Comment>> comments(String id) async {
    final j = await api.get('/api/posts/$id/comments');
    return (j['items'] as List).map((e) => Comment.fromJson(e)).toList();
  }

  Future<Comment> addComment(String id, String text) async {
    final c = Comment.fromJson(await api.post('/api/posts/$id/comments', {'text': text}));
    final p = _byId[id];
    if (p != null) {
      _byId[id] = Post.fromJson({
        ..._postToJson(p),
        'comments': p.comments + 1,
      });
      notifyListeners();
    }
    return c;
  }

  Future<void> publish(Map<String, dynamic> body) => api.post('/api/posts', body);

  Map<String, dynamic> _postToJson(Post p) => {
        'id': p.id, 'kind': p.kind, 'author': p.author, 'authorName': p.authorName, 'authorSeed': p.authorSeed, 'gender': p.gender,
        'ts': p.ts, 'location': p.location, 'text': p.text, 'images': p.images, 'video': p.video, 'poll': p.poll?.toJson(),
        'circle_name': p.circleName, 'circle_seed': p.circleSeed, 'circle_sub': p.circleSub, 'topic': p.topic, 'views': p.views,
        'likes': p.likes, 'favs': p.favs, 'comments': p.comments, 'liked': p.liked, 'faved': p.faved, 'recommended': p.recommended ? 1 : 0, 'status': p.status,
      };
}

/// Messages — unread summary, channels, private chats.
class MessagesStore extends ChangeNotifier {
  Map<String, int> unread = {};
  List<Conversation> conversations = [];
  int total = 0;
  Timer? _poll;

  int get serviceUnread => unread['service'] ?? 0;

  void startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 15), (_) => refresh());
    refresh();
  }

  void stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  Future<void> refresh() async {
    if (!api.isAuthed) {
      unread = {};
      conversations = [];
      total = 0;
      notifyListeners();
      return;
    }
    try {
      final j = await api.get('/api/messages/summary');
      unread = Map<String, int>.from((j['unread'] as Map).map((k, v) => MapEntry(k.toString(), (v as num).toInt())));
      conversations = (j['conversations'] as List).map((e) => Conversation.fromJson(e)).toList();
      total = (j['total'] ?? 0) as int;
      notifyListeners();
    } catch (_) {}
  }

  Future<List<ChatMessage>> channel(String ch) async {
    final j = await api.get('/api/messages/$ch');
    unread.remove(ch);
    total = unread.values.fold(0, (a, b) => a + b);
    notifyListeners();
    return (j['items'] as List).map((e) => ChatMessage.fromJson(e)).toList();
  }

  Future<String?> send(String ch, String text) async {
    final j = await api.post('/api/messages/$ch', {'text': text});
    return j['reply'] as String?;
  }

  Future<void> recall(String ch, String id) => api.delete('/api/messages/$ch/$id');

  Future<void> feedback(String text) => api.post('/api/feedback', {'text': text});

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }
}
