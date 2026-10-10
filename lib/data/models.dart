import 'package:flutter/material.dart';
import '../theme/med_theme.dart';

class HealthEvent {
  final String id;
  final String title;
  final String date;
  final String time;
  final String place;
  final String detail;
  final String seed;
  final String? cover; // asset path (CMS-uploaded), null => placeholder
  final int baseViews;
  final List<String> signups;
  final String author;

  const HealthEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.place,
    required this.detail,
    required this.seed,
    this.cover,
    this.baseViews = 0,
    this.signups = const [],
    required this.author,
  });
}

class CarouselSlide {
  final String seed;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final String? image;
  const CarouselSlide({
    required this.seed,
    required this.title,
    required this.subtitle,
    required this.gradient,
    this.image,
  });
}

class HomeTile {
  final String id;
  final String label;
  final String seed;
  final Color? tint;
  final String? image;
  const HomeTile({required this.id, required this.label, required this.seed, this.tint, this.image});
}

class HotTopic {
  final String title;
  final List<Color> gradient;
  bool favourite;
  HotTopic(this.title, this.gradient, {this.favourite = false});
}

class CircleItem {
  final String name;
  final String sub;
  final String seed;
  final String? image;
  const CircleItem(this.name, this.sub, this.seed, {this.image});
}

/// CMS content for 首页 (ported from cmsData_v3.js with medical naming map applied)
class CmsHome {
  CmsHome._();

  static const carousel = [
    CarouselSlide(
      seed: 'home-hero-1',
      title: '示例主题一',
      subtitle: '本周精选',
      gradient: [Color(0xFF7ED6C2), Color(0xFFBFEDE2)],
    ),
    CarouselSlide(
      seed: 'home-hero-2',
      title: '示例主题二',
      subtitle: '开学季推荐',
      gradient: [Color(0xFF86D3DE), Color(0xFFC7EEF3)],
    ),
    CarouselSlide(
      seed: 'home-hero-3',
      title: '示例主题三',
      subtitle: '热门活动',
      gradient: [Color(0xFF8EDDB6), Color(0xFFD3F3E2)],
    ),
  ];

  static const hotForums = [
    HomeTile(id: 'course', label: '健康入门', seed: 'hf-course', tint: Color(0xFFF2704A)),
    HomeTile(id: 'abroad', label: '慢病管理', seed: 'hf-abroad', tint: MedTheme.sky),
    HomeTile(id: 'major', label: '专科问诊', seed: 'hf-major', tint: MedTheme.violet),
    HomeTile(id: 'video', label: '科普视频', seed: 'hf-video', tint: MedTheme.violet),
    HomeTile(id: 'stream', label: '医生直播', seed: 'hf-stream', tint: MedTheme.sky),
    HomeTile(id: 'digital', label: '智慧医疗', seed: 'hf-digital', tint: MedTheme.violet),
  ];

  static const hotCircles = [
    HomeTile(id: 'gym', label: '科学运动康复', seed: 'hc-gym'),
    HomeTile(id: 'study', label: 'Healthy Life Made Easy', seed: 'hc-study'),
    HomeTile(id: 'car', label: '中医养生馆', seed: 'hc-car'),
    HomeTile(id: 'res', label: '健康知识分享', seed: 'hc-res'),
    HomeTile(id: 'yy', label: '宝妈育儿', seed: 'hc-yy'),
    HomeTile(id: 'team', label: 'CARE TOGETHER 互助', seed: 'hc-team'),
    HomeTile(id: 'web', label: '智慧医疗交流', seed: 'hc-web'),
    HomeTile(id: 'art', label: '家庭医生', seed: 'hc-art'),
  ];

  static const forumCategories = [
    HomeTile(id: 'c1', label: '健康入门', seed: 'fc-1'),
    HomeTile(id: 'c2', label: '慢病管理', seed: 'fc-2'),
    HomeTile(id: 'c3', label: '专科问诊', seed: 'fc-3'),
    HomeTile(id: 'c4', label: '科普视频', seed: 'fc-4'),
    HomeTile(id: 'c5', label: '医生直播', seed: 'fc-5'),
    HomeTile(id: 'c6', label: '智慧医疗', seed: 'fc-6'),
    HomeTile(id: 'c7', label: '健康书单', seed: 'fc-7'),
    HomeTile(id: 'c8', label: '健康头条', seed: 'fc-8'),
    HomeTile(id: 'c9', label: '跨境就医', seed: 'fc-9'),
  ];

  static final hotTopics = [
    HotTopic('如何科学地开始减重计划', const [Color(0xFF12A594), Color(0xFF0EA5B7)], favourite: true),
    HotTopic('第一次体检，需要注意什么', const [Color(0xFF2DB4E0), Color(0xFF0EA5B7)], favourite: true),
    HotTopic('如何养成规律作息提升免疫力', const [Color(0xFF1DB980), Color(0xFF12A594)]),
    HotTopic('高血压日常用药经验', const [Color(0xFFFF8A5B), Color(0xFFFFB37A)]),
    HotTopic('糖尿病饮食控制分享', const [Color(0xFF0EA5B7), Color(0xFF2DB4E0)]),
  ];

  static const followedCircles = [
    CircleItem('健康知识分享', '分享你的健康小妙招', 'hc-res', image: 'assets/images/home-info-1.jpg'),
    CircleItem('科学运动康复', '一起科学运动，远离慢病', 'hc-gym', image: 'assets/images/home-info-2.jpg'),
    CircleItem('智慧医疗交流', '专注于健康知识、科普与就医经验交流的健康圈', 'hc-web', image: 'assets/images/home-info-3.jpg'),
    CircleItem('中医养生馆', '四季养生、食疗调理，一起交流经验', 'hc-car'),
    CircleItem('CARE TOGETHER 互助', '病友互助，一起加油', 'hc-team'),
  ];
}
