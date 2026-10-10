import 'package:flutter/material.dart';
import '../theme/med_theme.dart';
import '../widgets/common.dart';
import '../widgets/med_icons.dart';

/// Generic placeholder sub-page used for destinations outside the current design scope.
class SimplePage extends StatelessWidget {
  final String title;
  const SimplePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedTheme.bg,
      appBar: SubHeader(title: title),
      body: SimpleEmpty(title: title),
    );
  }
}

class SimpleEmpty extends StatelessWidget {
  final String title;
  final MedIconData icon;
  const SimpleEmpty({super.key, required this.title, this.icon = MedIcons.leafCross});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: MedTheme.primarySoft),
            child: Center(child: MedIcon(icon, size: 32, color: MedTheme.primary)),
          ),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: MedTheme.ink)),
          const SizedBox(height: 6),
          const Text('内容由后台 CMS 配置后显示', style: TextStyle(fontSize: 12.5, color: MedTheme.inkSubtle)),
        ],
      ),
    );
  }
}
