import 'package:flutter/material.dart';
import '../theme/med_theme.dart';
import '../widgets/common.dart';
import '../widgets/med_icons.dart';

/// Generic placeholder sub-page for CMS-driven destinations outside the current scope.
class SimplePage extends StatelessWidget {
  final String title;
  const SimplePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final T = MedTheme.of(context);
    return Scaffold(backgroundColor: T.bg, appBar: SubHeader(title: title), body: SimpleEmpty(title: title));
  }
}

class SimpleEmpty extends StatelessWidget {
  final String title;
  final MedIconData icon;
  const SimpleEmpty({super.key, required this.title, this.icon = MedIcons.leafCross});

  @override
  Widget build(BuildContext context) {
    final T = MedTheme.of(context);
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 72, height: 72, decoration: BoxDecoration(shape: BoxShape.circle, color: T.primarySoft), child: Center(child: MedIcon(icon, size: 32, color: T.primary))),
        const SizedBox(height: 14),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: T.ink)),
        const SizedBox(height: 6),
        Text('内容由后台 CMS 配置后显示', style: TextStyle(fontSize: 12.5, color: T.inkSubtle)),
      ]),
    );
  }
}

/// 协议与规则 page (legal texts).
class LegalPage extends StatelessWidget {
  final String title;
  const LegalPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final T = MedTheme.of(context);
    return Scaffold(
      backgroundColor: T.bg,
      appBar: SubHeader(title: title),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: T.ink)),
        const SizedBox(height: 12),
        Text(
          '欢迎使用健康圈子（Health Circle）。本平台为医疗健康推广社区，用户发布的内容仅代表个人观点，不构成医疗建议。\n\n'
          '1. 用户须遵守所在地法律法规，不得发布虚假医疗信息、广告或侵权内容。\n'
          '2. 用户发布的帖子、活动与资料修改需经审核后公开展示。\n'
          '3. 平台依据区域范围设置限制注册与登录地区，服务器将对位置进行二次校验。\n'
          '4. 我们重视您的隐私，仅在提供服务所需范围内收集与使用您的信息。\n'
          '5. 本协议内容由后台「协议与规则」模块维护，以线上最新版本为准。',
          style: TextStyle(fontSize: 14, color: T.inkMuted, height: 1.75),
        ),
      ]),
    );
  }
}
