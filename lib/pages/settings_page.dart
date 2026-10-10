import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/api_client.dart';
import '../data/stores.dart';
import '../theme/med_theme.dart';
import '../widgets/common.dart';

/// 个人设置 — login account, 修改密码, third-party binding, 夜间模式, autoplay, data saver, API server.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _autoplay = true, _saver = false;

  @override
  Widget build(BuildContext context) {
    final T = MedTheme.of(context);
    final theme = context.watch<ThemeStore>();
    final u = context.watch<AuthStore>().user;
    return Scaffold(
      backgroundColor: T.bg,
      appBar: const SubHeader(title: '个人设置'),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        _group(T, '账号', [
          _row(T, '登录账号', trailing: Text(u?.email ?? '未登录', style: TextStyle(fontSize: 13, color: T.inkSubtle))),
          _row(T, '修改密码', trailing: Text('剩余 2 次', style: TextStyle(fontSize: 13, color: T.inkSubtle)), onTap: () => showToast(context, '请通过客服中心申请修改密码')),
          _row(T, '第三方绑定', trailing: Text('Google · Facebook', style: TextStyle(fontSize: 13, color: T.inkSubtle)), onTap: () => showToast(context, '绑定功能即将上线'), last: true),
        ]),
        const SizedBox(height: 14),
        _group(T, '显示与播放', [
          _row(T, '夜间模式', trailing: Switch(value: theme.dark, activeThumbColor: T.primary, onChanged: (_) => theme.toggle())),
          _row(T, '视频自动播放', trailing: Switch(value: _autoplay, activeThumbColor: T.primary, onChanged: (v) => setState(() => _autoplay = v))),
          _row(T, '省流量模式', trailing: Switch(value: _saver, activeThumbColor: T.primary, onChanged: (v) => setState(() => _saver = v)), last: true),
        ]),
        const SizedBox(height: 14),
        _group(T, '服务器', [
          _row(T, 'API 地址', trailing: Flexible(child: Text(ApiClient.instance.baseUrl, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: T.inkSubtle))), onTap: _editBase, last: true),
        ]),
      ]),
    );
  }

  Future<void> _editBase() async {
    final T = MedTheme.of(context);
    final c = TextEditingController(text: ApiClient.instance.baseUrl);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: T.surface,
        title: Text('API 服务器地址', style: TextStyle(color: T.ink, fontSize: 16)),
        content: TextField(controller: c, style: TextStyle(color: T.ink, fontSize: 13.5), decoration: const InputDecoration(hintText: 'https://your-host:5061')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('保存')),
        ],
      ),
    );
    if (ok == true) {
      await ApiClient.instance.setBaseOverride(c.text.trim());
      if (!mounted) return;
      setState(() {});
      context.read<HomeStore>().load();
      context.read<EventsStore>().load();
      showToast(context, '已保存，正在重新加载数据');
    }
  }

  Widget _group(MedTokens T, String title, List<Widget> rows) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text(title, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: T.inkSubtle))),
        Container(decoration: BoxDecoration(color: T.surface, borderRadius: BorderRadius.circular(16), boxShadow: T.shadowSm), child: Column(children: rows)),
      ]);

  Widget _row(MedTokens T, String label, {Widget? trailing, VoidCallback? onTap, bool last = false}) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          constraints: const BoxConstraints(minHeight: 52),
          decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: T.divider))),
          child: Row(children: [
            Text(label, style: TextStyle(fontSize: 14.5, color: T.ink, fontWeight: FontWeight.w500)),
            const Spacer(),
            if (trailing != null) trailing,
          ]),
        ),
      );
}
