import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models.dart';
import '../../data/stores.dart';
import '../../theme/med_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/med_icons.dart';
import '../auth/login_page.dart';

/// Chat UI for 客服中心 / 私聊 / 系统通知 / 平台分享.
/// Own messages are recallable within 3 minutes (long-press).
class ChatPage extends StatefulWidget {
  final String channel;
  final String title;
  final String? peerSeed;
  const ChatPage({super.key, required this.channel, required this.title, this.peerSeed});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<ChatMessage>? _items;
  String? _error;
  final _ctl = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  bool get _readOnly => widget.channel == 'sysnotify' || widget.channel == 'share';
  bool get _isUser => widget.channel.startsWith('user:');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!context.read<AuthStore>().loggedIn) {
      setState(() => _error = '请先登录');
      return;
    }
    try {
      final items = await context.read<MessagesStore>().channel(widget.channel);
      if (!mounted) return;
      setState(() {
        _items = items;
        _error = null;
      });
      _jump();
    } catch (e) {
      if (mounted) setState(() => _error = '消息加载失败');
    }
  }

  void _jump() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });

  Future<void> _send() async {
    final text = _ctl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await context.read<MessagesStore>().send(widget.channel, text);
      _ctl.clear();
      await _load();
    } catch (e) {
      if (mounted) showToast(context, '发送失败：$e');
    }
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _recall(ChatMessage m) async {
    final T = MedTheme.of(context);
    final within = DateTime.now().millisecondsSinceEpoch - m.ts <= 3 * 60 * 1000;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
        decoration: BoxDecoration(color: T.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(22))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: Icon(Icons.undo_rounded, color: within ? T.pink : T.inkSubtle),
            title: Text(within ? '撤回这条消息' : '超过 3 分钟，无法撤回', style: TextStyle(color: within ? T.ink : T.inkSubtle)),
            onTap: within ? () => Navigator.pop(context, true) : null,
          ),
          ListTile(leading: Icon(Icons.copy_rounded, color: T.inkMuted), title: Text('复制', style: TextStyle(color: T.ink)), onTap: () => Navigator.pop(context, false)),
        ]),
      ),
    );
    if (ok == true && mounted) {
      try {
        await context.read<MessagesStore>().recall(widget.channel, m.id);
        await _load();
        if (mounted) showToast(context, '已撤回');
      } catch (e) {
        if (mounted) showToast(context, '$e');
      }
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final T = MedTheme.of(context);
    final me = context.watch<AuthStore>().user;
    return Scaffold(
      backgroundColor: T.bg,
      appBar: SubHeader(title: widget.title),
      body: Column(children: [
        Expanded(
          child: _error != null
              ? Center(
                  child: _error == '请先登录'
                      ? SizedBox(width: 160, child: PrimaryButton(label: '去登录', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginPage()))))
                      : ErrorRetry(message: _error!, onRetry: _load))
              : _items == null
                  ? Center(child: CircularProgressIndicator(color: T.primary))
                  : _items!.isEmpty
                      ? Center(child: Text('暂无消息', style: TextStyle(color: T.inkSubtle)))
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.all(14),
                          itemCount: _items!.length,
                          itemBuilder: (_, i) => _bubble(T, _items![i], me),
                        ),
        ),
        if (!_readOnly && _error == null)
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(color: T.surface, border: Border(top: BorderSide(color: T.divider))),
            child: SafeArea(
              top: false,
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _ctl,
                    style: TextStyle(fontSize: 14, color: T.ink),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: _isUser ? '发送私信…' : '请输入您的问题…',
                      hintStyle: TextStyle(color: T.inkSubtle, fontSize: 13.5),
                      filled: true,
                      fillColor: T.bg,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sending ? null : _send,
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(shape: BoxShape.circle, gradient: T.primaryButtonGradient),
                    child: Center(child: _sending ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const MedIcon(MedIcons.send, size: 17, color: Colors.white)),
                  ),
                ),
              ]),
            ),
          ),
      ]),
    );
  }

  Widget _bubble(MedTokens T, ChatMessage m, AppUser? me) {
    final mine = m.mine;
    final system = m.sender == 'system';
    if (system) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: T.surface, borderRadius: BorderRadius.circular(14), boxShadow: T.shadowSm),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 26, height: 26, decoration: BoxDecoration(shape: BoxShape.circle, color: T.tintMint.bg), child: Center(child: MedIcon(MedIcons.shieldPlus, size: 14, color: T.tintMint.fg))),
              const SizedBox(width: 8),
              Text(widget.title, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: T.inkMuted)),
              const Spacer(),
              Text(_fmt(m.ts), style: TextStyle(fontSize: 11, color: T.inkSubtle)),
            ]),
            const SizedBox(height: 8),
            Text(m.text, style: TextStyle(fontSize: 14, color: T.ink, height: 1.55)),
          ]),
        ),
      );
    }
    final avatar = mine
        ? MedAvatar(size: 34, seed: me?.seed ?? 'me', label: me?.name ?? 'M', url: me?.avatar)
        : (widget.channel == 'service'
            ? Container(width: 34, height: 34, decoration: BoxDecoration(shape: BoxShape.circle, gradient: MedTokens.logoGradient), child: const Center(child: MedIcon(MedIcons.headset, size: 17, color: Colors.white)))
            : MedAvatar(size: 34, seed: m.senderSeed, label: m.senderName));
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!mine) ...[avatar, const SizedBox(width: 8)],
          Flexible(
            child: GestureDetector(
              onLongPress: mine ? () => _recall(m) : null,
              child: Column(crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: mine ? T.primaryButtonGradient : null,
                    color: mine ? null : T.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(mine ? 16 : 4),
                      bottomRight: Radius.circular(mine ? 4 : 16),
                    ),
                    boxShadow: T.shadowSm,
                  ),
                  child: Text(m.text, style: TextStyle(fontSize: 14, color: mine ? Colors.white : T.ink, height: 1.5)),
                ),
                const SizedBox(height: 3),
                Text(_fmt(m.ts), style: TextStyle(fontSize: 10.5, color: T.inkSubtle)),
              ]),
            ),
          ),
          if (mine) ...[const SizedBox(width: 8), avatar],
        ],
      ),
    );
  }

  static String _fmt(int ts) {
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }
}
