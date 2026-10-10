import 'package:flutter/material.dart';

Color _hex(String s, Color fallback) {
  try {
    var h = s.replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    return Color(int.parse(h, radix: 16));
  } catch (_) {
    return fallback;
  }
}

class AppUser {
  final String id, name, seed, gender, ip, email;
  final String avatar;
  const AppUser({required this.id, required this.name, required this.seed, this.gender = 'm', this.ip = '', this.email = '', this.avatar = ''});
  factory AppUser.fromJson(Map j) => AppUser(
        id: j['id'] ?? '', name: j['name'] ?? '', seed: j['seed'] ?? j['id'] ?? 'u',
        gender: j['gender'] ?? 'm', ip: j['ip'] ?? '', email: j['email'] ?? '', avatar: j['avatar'] ?? '');
}

class HealthEvent {
  final String id, title, date, time, place, detail, seed, author, authorName, status;
  final String? cover;
  final int views;
  final List<String> signups;
  final List<AppUser> signupUsers;
  final bool joined;

  const HealthEvent({
    required this.id, required this.title, required this.date, required this.time, required this.place,
    required this.detail, required this.seed, this.cover, this.views = 0, this.signups = const [],
    this.signupUsers = const [], required this.author, this.authorName = '', this.joined = false, this.status = 'approved',
  });

  factory HealthEvent.fromJson(Map j) => HealthEvent(
        id: j['id'], title: j['title'] ?? '', date: j['date'] ?? '', time: j['time'] ?? '', place: j['place'] ?? '',
        detail: j['detail'] ?? '', seed: j['seed'] ?? j['id'], cover: (j['cover'] ?? '').toString().isEmpty ? null : j['cover'],
        views: (j['views'] ?? 0) as int, signups: List<String>.from(j['signups'] ?? const []),
        signupUsers: ((j['signupUsers'] ?? const []) as List).map((e) => AppUser.fromJson(e)).toList(),
        author: j['author'] ?? '', authorName: j['authorName'] ?? j['author'] ?? '', joined: j['joined'] == true, status: j['status'] ?? 'approved');
}

class PollOption {
  final String text;
  final int votes;
  const PollOption(this.text, this.votes);
}

class Poll {
  final String question;
  final List<PollOption> options;
  const Poll(this.question, this.options);
  int get total => options.fold(0, (a, b) => a + b.votes);
  factory Poll.fromJson(Map j) => Poll(j['question'] ?? '',
      ((j['options'] ?? []) as List).map((o) => PollOption(o['text'] ?? '', (o['votes'] ?? 0) as int)).toList());
  Map<String, dynamic> toJson() => {'question': question, 'options': options.map((o) => {'text': o.text, 'votes': o.votes}).toList()};
}

class Post {
  final String id, kind, author, authorName, authorSeed, gender, location, text, video, circleName, circleSeed, circleSub, topic, status;
  final int ts, views, likes, favs, comments;
  final bool liked, faved, recommended;
  final List<String> images;
  final Poll? poll;

  const Post({
    required this.id, required this.kind, required this.author, required this.authorName, required this.authorSeed,
    this.gender = 'm', required this.ts, this.location = '', required this.text, this.images = const [], this.video = '',
    this.poll, this.circleName = '', this.circleSeed = '', this.circleSub = '', this.topic = '', this.views = 0,
    this.likes = 0, this.favs = 0, this.comments = 0, this.liked = false, this.faved = false, this.recommended = false, this.status = 'approved',
  });

  factory Post.fromJson(Map j) => Post(
        id: j['id'], kind: j['kind'] ?? 'circle', author: j['author'] ?? '', authorName: j['authorName'] ?? j['author'] ?? '',
        authorSeed: j['authorSeed'] ?? j['author_seed'] ?? 'u', gender: j['gender'] ?? 'm', ts: (j['ts'] ?? 0) as int,
        location: j['location'] ?? '', text: j['text'] ?? '', images: List<String>.from(j['images'] ?? const []),
        video: j['video'] ?? '', poll: j['poll'] is Map ? Poll.fromJson(j['poll']) : null, circleName: j['circle_name'] ?? '',
        circleSeed: j['circle_seed'] ?? '', circleSub: j['circle_sub'] ?? '', topic: j['topic'] ?? '', views: (j['views'] ?? 0) as int,
        likes: (j['likes'] ?? 0) as int, favs: (j['favs'] ?? 0) as int, comments: (j['comments'] ?? 0) as int,
        liked: j['liked'] == true, faved: j['faved'] == true, recommended: (j['recommended'] ?? 0) == 1, status: j['status'] ?? 'approved');

  String get timeLabel {
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }
}

class Comment {
  final String id, postId, author, authorName, authorSeed, text;
  final int ts;
  const Comment({required this.id, required this.postId, required this.author, required this.authorName, required this.authorSeed, required this.text, required this.ts});
  factory Comment.fromJson(Map j) => Comment(
      id: j['id'], postId: j['post_id'] ?? '', author: j['author'] ?? '', authorName: j['authorName'] ?? j['author'] ?? '',
      authorSeed: j['author_seed'] ?? j['author'] ?? 'u', text: j['text'] ?? '', ts: (j['ts'] ?? 0) as int);
}

class ChatMessage {
  final String id, channel, sender, senderName, senderSeed, text;
  final int ts;
  final bool mine;
  const ChatMessage({required this.id, required this.channel, required this.sender, required this.senderName, required this.senderSeed, required this.text, required this.ts, required this.mine});
  factory ChatMessage.fromJson(Map j) => ChatMessage(
      id: j['id'], channel: j['channel'] ?? '', sender: j['sender'] ?? '', senderName: j['senderName'] ?? j['sender'] ?? '',
      senderSeed: j['senderSeed'] ?? j['sender'] ?? 'u', text: j['text'] ?? '', ts: (j['ts'] ?? 0) as int, mine: j['mine'] == true);
}

class Conversation {
  final String channel, userId, name, seed, last;
  final int ts, unread;
  const Conversation({required this.channel, required this.userId, required this.name, required this.seed, required this.last, required this.ts, required this.unread});
  factory Conversation.fromJson(Map j) => Conversation(
      channel: j['channel'], userId: j['userId'], name: j['name'] ?? '', seed: j['seed'] ?? 'u', last: j['last'] ?? '', ts: (j['ts'] ?? 0) as int, unread: (j['unread'] ?? 0) as int);
}

class CarouselSlide {
  final String seed, title, subtitle;
  final String? image;
  const CarouselSlide({required this.seed, required this.title, required this.subtitle, this.image});
  factory CarouselSlide.fromJson(Map j) => CarouselSlide(seed: j['seed'] ?? 'x', title: j['title'] ?? '', subtitle: j['subtitle'] ?? '', image: (j['image'] ?? '').toString().isEmpty ? null : j['image']);
}

class HomeTile {
  final String id, label, seed, sub;
  final Color? tint;
  final String? image;
  const HomeTile({required this.id, required this.label, required this.seed, this.tint, this.image, this.sub = ''});
  factory HomeTile.fromJson(Map j) => HomeTile(
      id: j['id'] ?? '', label: j['label'] ?? '', seed: j['seed'] ?? j['id'] ?? 'x', sub: j['sub'] ?? '',
      tint: j['tint'] != null ? _hex(j['tint'], const Color(0xFF0EA5B7)) : null,
      image: (j['image'] ?? '').toString().isEmpty ? null : j['image']);
}

class HotTopic {
  final String title;
  final List<Color> gradient;
  bool favourite;
  HotTopic(this.title, this.gradient, {this.favourite = false});
  factory HotTopic.fromJson(Map j) => HotTopic(j['title'] ?? '',
      ((j['grad'] ?? ['#12A594', '#0EA5B7']) as List).map((c) => _hex(c.toString(), const Color(0xFF12A594))).toList());
}

class TaxonomyGroup {
  final String label;
  final List<String> items;
  const TaxonomyGroup(this.label, this.items);
  factory TaxonomyGroup.fromJson(Map j) => TaxonomyGroup(j['label'] ?? '', List<String>.from(j['items'] ?? const []));
}

/// Home CMS payload (`GET /api/home`), with an offline fallback so the UI never renders empty.
class HomeCms {
  final List<CarouselSlide> carousel;
  final List<HomeTile> hotForums, hotCircles, followedCircles, forumCategories;
  final List<HotTopic> hotTopics;
  final List<TaxonomyGroup> circleTaxonomy, forumTaxonomy;

  const HomeCms({
    required this.carousel, required this.hotForums, required this.hotCircles, required this.followedCircles,
    required this.forumCategories, required this.hotTopics, required this.circleTaxonomy, required this.forumTaxonomy,
  });

  factory HomeCms.fromJson(Map j) {
    List<T> l<T>(String k, T Function(Map) f) => ((j[k] ?? const []) as List).map((e) => f(e as Map)).toList();
    final tax = (j['taxonomy'] ?? const {}) as Map;
    return HomeCms(
      carousel: l('carousel', CarouselSlide.fromJson),
      hotForums: l('hotForums', HomeTile.fromJson),
      hotCircles: l('hotCircles', HomeTile.fromJson),
      followedCircles: l('followedCircles', HomeTile.fromJson),
      forumCategories: l('forumCategories', HomeTile.fromJson),
      hotTopics: l('hotTopics', HotTopic.fromJson),
      circleTaxonomy: ((tax['circle'] ?? const []) as List).map((e) => TaxonomyGroup.fromJson(e)).toList(),
      forumTaxonomy: ((tax['forum'] ?? const []) as List).map((e) => TaxonomyGroup.fromJson(e)).toList(),
    );
  }

  static final fallback = HomeCms(
    carousel: const [
      CarouselSlide(seed: 'home-hero-1', title: '示例主题一', subtitle: '本周精选'),
      CarouselSlide(seed: 'home-hero-2', title: '示例主题二', subtitle: '开学季推荐'),
      CarouselSlide(seed: 'home-hero-3', title: '示例主题三', subtitle: '热门活动'),
    ],
    hotForums: const [
      HomeTile(id: 'course', label: '健康入门', seed: 'hf-course', tint: Color(0xFFF2704A)),
      HomeTile(id: 'abroad', label: '慢病管理', seed: 'hf-abroad', tint: Color(0xFF2DB4E0)),
      HomeTile(id: 'major', label: '专科问诊', seed: 'hf-major', tint: Color(0xFF0EA5B7)),
      HomeTile(id: 'video', label: '科普视频', seed: 'hf-video', tint: Color(0xFF0EA5B7)),
      HomeTile(id: 'stream', label: '医生直播', seed: 'hf-stream', tint: Color(0xFF2DB4E0)),
      HomeTile(id: 'digital', label: '智慧医疗', seed: 'hf-digital', tint: Color(0xFF0EA5B7)),
    ],
    hotCircles: const [
      HomeTile(id: 'gym', label: '科学运动康复', seed: 'hc-gym'),
      HomeTile(id: 'study', label: 'Healthy Life Made Easy', seed: 'hc-study'),
      HomeTile(id: 'car', label: '中医养生馆', seed: 'hc-car'),
      HomeTile(id: 'res', label: '健康知识分享', seed: 'hc-res'),
      HomeTile(id: 'yy', label: '宝妈育儿', seed: 'hc-yy'),
      HomeTile(id: 'team', label: 'CARE TOGETHER 互助', seed: 'hc-team'),
      HomeTile(id: 'web', label: '智慧医疗交流', seed: 'hc-web'),
      HomeTile(id: 'art', label: '家庭医生', seed: 'hc-art'),
    ],
    followedCircles: const [
      HomeTile(id: 'res', label: '健康知识分享', seed: 'hc-res', image: '/assets/images/home-info-1.jpg', sub: '分享你的健康小妙招'),
      HomeTile(id: 'gym', label: '科学运动康复', seed: 'hc-gym', image: '/assets/images/home-info-2.jpg', sub: '一起科学运动，远离慢病'),
      HomeTile(id: 'web', label: '智慧医疗交流', seed: 'hc-web', image: '/assets/images/home-info-3.jpg', sub: '专注于健康知识、科普与就医经验交流的健康圈'),
    ],
    forumCategories: [for (int i = 0; i < 9; i++) HomeTile(id: 'c$i', label: const ['健康入门', '慢病管理', '专科问诊', '科普视频', '医生直播', '智慧医疗', '健康书单', '健康头条', '跨境就医'][i], seed: 'fc-$i')],
    hotTopics: [
      HotTopic('如何科学地开始减重计划', const [Color(0xFF12A594), Color(0xFF0EA5B7)]),
      HotTopic('第一次体检，需要注意什么', const [Color(0xFF2DB4E0), Color(0xFF0EA5B7)]),
      HotTopic('如何养成规律作息提升免疫力', const [Color(0xFF1DB980), Color(0xFF12A594)]),
    ],
    circleTaxonomy: const [TaxonomyGroup('健康生活', ['健康知识分享', '科学运动康复', '中医养生馆'])],
    forumTaxonomy: const [TaxonomyGroup('健康入门', ['如何科学地开始减重计划', '第一次体检，需要注意什么'])],
  );
}
