import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/api_client.dart';
import '../data/models.dart';
import '../data/stores.dart';
import '../theme/med_theme.dart';
import '../widgets/common.dart';
import '../widgets/med_icons.dart';
import 'auth/login_page.dart';

/// 发布健康圈帖 / 发布问诊社区帖 — text ≤ 2000, images, video, poll, two-column picker,
/// pre-checked rules checkbox, draft persistence (restored until a successful publish).
class PublishPage extends StatefulWidget {
  final String kind; // circle | forum
  const PublishPage({super.key, required this.kind});

  @override
  State<PublishPage> createState() => _PublishPageState();
}

class _PublishPageState extends State<PublishPage> {
  final _text = TextEditingController();
  final List<String> _images = [];
  final List<Uint8List> _localPreviews = [];
  String _video = '';
  bool _rules = true, _busy = false;
  String? _group, _target;
  Poll? _poll;

  String get _draftKey => 'draft_${widget.kind}';
  bool get isCircle => widget.kind == 'circle';

  @override
  void initState() {
    super.initState();
    _restoreDraft();
    _text.addListener(_saveDraft);
  }

  Future<void> _restoreDraft() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_draftKey);
      if (raw == null) return;
      final j = jsonDecode(raw);
      setState(() {
        _text.text = j['text'] ?? '';
        _images.addAll(List<String>.from(j['images'] ?? const []));
        _video = j['video'] ?? '';
        _rules = j['rules'] ?? true;
        _group = j['group'];
        _target = j['target'];
        _poll = j['poll'] is Map ? Poll.fromJson(j['poll']) : null;
      });
      if (mounted) showToast(context, '已恢复未发送草稿');
    } catch (_) {}
  }

  Future<void> _saveDraft() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_draftKey, jsonEncode({'text': _text.text, 'images': _images, 'video': _video, 'rules': _rules, 'group': _group, 'target': _target, 'poll': _poll?.toJson()}));
    } catch (_) {}
  }

  Future<void> _clearDraft() async {
    try {
      (await SharedPreferences.getInstance()).remove(_draftKey);
    } catch (_) {}
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource src) async {
    try {
      final x = await ImagePicker().pickImage(source: src, maxWidth: 1600, imageQuality: 80);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      if (bytes.length > 500 * 1024 && mounted) showToast(context, '图片已压缩至 ≤ 500 KB');
      final url = await ApiClient.instance.upload(bytes);
      setState(() {
        _images.add(url);
        _localPreviews.add(bytes);
      });
      _saveDraft();
    } catch (e) {
      if (mounted) showToast(context, '上传失败：$e');
    }
  }

  void _sourceSheet({required bool video}) {
    final T = MedTheme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        decoration: BoxDecoration(color: T.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(22))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(video ? '选择视频来源' : '选择图片来源', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: T.ink)),
          const SizedBox(height: 14),
          _srcRow(T, Icons.photo_camera_outlined, video ? '拍摄视频' : '拍照', () {
            Navigator.pop(context);
            video ? _attachVideo() : _pickImage(ImageSource.camera);
          }),
          _srcRow(T, Icons.photo_library_outlined, video ? '从相册选择（≤ 5 MB / ≤ 60 s）' : '从相册选择', () {
            Navigator.pop(context);
            video ? _attachVideo() : _pickImage(ImageSource.gallery);
          }),
        ]),
      ),
    );
  }

  void _attachVideo() {
    // Prototype: attach the sample video (video upload > 5 MB is re-encoded server-side in production).
    setState(() => _video = 'sample');
    _saveDraft();
    showToast(context, '已添加视频（示例）');
  }

  Widget _srcRow(MedTokens T, IconData icon, String label, VoidCallback onTap) => ListTile(
        leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: T.primarySoft, shape: BoxShape.circle), child: Icon(icon, size: 18, color: T.primary)),
        title: Text(label, style: TextStyle(fontSize: 14, color: T.ink)),
        onTap: onTap,
      );

  Future<void> _openPicker() async {
    final cms = context.read<HomeStore>().cms;
    final groups = isCircle ? cms.circleTaxonomy : cms.forumTaxonomy;
    final r = await showModalBottomSheet<(String, String)>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => TwoColPickerSheet(groups: groups, title: isCircle ? '选择健康圈' : '选择话题', initialGroup: _group),
    );
    if (r != null) {
      setState(() {
        _group = r.$1;
        _target = r.$2;
      });
      _saveDraft();
    }
  }

  Future<void> _editPoll() async {
    final q = TextEditingController(text: _poll?.question ?? '');
    final opts = [for (final o in _poll?.options ?? const <PollOption>[]) TextEditingController(text: o.text)];
    while (opts.length < 2) {
      opts.add(TextEditingController());
    }
    final T = MedTheme.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          backgroundColor: T.surface,
          title: Text('添加投票', style: TextStyle(color: T.ink, fontSize: 16, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: q, style: TextStyle(color: T.ink), decoration: const InputDecoration(labelText: '投票问题')),
              for (int i = 0; i < opts.length; i++) TextField(controller: opts[i], style: TextStyle(color: T.ink), decoration: InputDecoration(labelText: '选项 ${String.fromCharCode(65 + i)}')),
              if (opts.length < 4)
                TextButton(onPressed: () => set(() => opts.add(TextEditingController())), child: const Text('+ 添加选项')),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确定')),
          ],
        ),
      ),
    );
    if (ok == true) {
      final options = opts.map((c) => c.text.trim()).where((s) => s.isNotEmpty).map((s) => PollOption(s, 0)).toList();
      setState(() => _poll = q.text.trim().isEmpty || options.length < 2 ? null : Poll(q.text.trim(), options));
      _saveDraft();
    }
  }

  Future<void> _publish() async {
    if (!context.read<AuthStore>().loggedIn) {
      showToast(context, '请先登录');
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginPage()));
      return;
    }
    if (_target == null) {
      showToast(context, isCircle ? '请选择要发布到的健康圈' : '请选择话题');
      return;
    }
    if (_text.text.trim().isEmpty) {
      showToast(context, '请输入内容');
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read<PostsStore>().publish({
        'kind': widget.kind,
        'text': _text.text.trim(),
        'images': _images,
        'video': _video,
        'poll': _poll?.toJson(),
        if (isCircle) 'circleName': _target,
        if (isCircle) 'circleSeed': 'hc-${hashOf(_target)}',
        if (isCircle) 'circleSub': _group,
        if (!isCircle) 'topic': _target,
      });
      await _clearDraft();
      if (!mounted) return;
      showToast(context, '已提交，审核通过后公开展示');
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showToast(context, '提交失败，内容已保留，请稍后重试');
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final T = MedTheme.of(context);
    final canPublish = _rules && !_busy;
    return Scaffold(
      backgroundColor: T.bg,
      appBar: SubHeader(title: isCircle ? '发布健康圈帖' : '发布问诊社区帖'),
      body: Column(children: [
        Expanded(
          child: ListView(padding: const EdgeInsets.all(14), children: [
            // target picker
            GestureDetector(
              onTap: _openPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: T.surface, borderRadius: BorderRadius.circular(14), boxShadow: T.shadowSm),
                child: Row(children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(color: T.primarySoft, borderRadius: BorderRadius.circular(10)),
                    child: Center(child: MedIcon(isCircle ? MedIcons.heartPulse : MedIcons.doctorChat, size: 18, color: T.primary)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_target ?? (isCircle ? '选择健康圈' : '选择话题'), style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: _target == null ? T.inkSubtle : T.ink)),
                      if (_group != null) Text(_group!, style: TextStyle(fontSize: 11.5, color: T.inkSubtle)),
                    ]),
                  ),
                  MedIcon(MedIcons.chevronRight, size: 16, color: T.inkSubtle),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: T.surface, borderRadius: BorderRadius.circular(14), boxShadow: T.shadowSm),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                TextField(
                  controller: _text,
                  maxLines: 8,
                  minLines: 5,
                  maxLength: 2000,
                  style: TextStyle(fontSize: 14.5, color: T.ink, height: 1.6),
                  decoration: InputDecoration(
                    hintText: isCircle ? '分享你的健康心得、经验或问题…' : '描述你的问题，让医生和病友更好地帮助你…',
                    hintStyle: TextStyle(color: T.inkSubtle, fontSize: 14),
                    border: InputBorder.none,
                    counterStyle: TextStyle(color: T.inkSubtle, fontSize: 11),
                  ),
                ),
                if (_images.isNotEmpty || _video.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (int i = 0; i < _images.length; i++)
                      Stack(children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: i < _localPreviews.length
                              ? Image.memory(_localPreviews[i], width: 84, height: 84, fit: BoxFit.cover)
                              : MedPlaceholder(width: 84, height: 84, seed: _images[i], image: _images[i]),
                        ),
                        Positioned(
                          top: 2, right: 2,
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _images.removeAt(i);
                              if (i < _localPreviews.length) _localPreviews.removeAt(i);
                              _saveDraft();
                            }),
                            child: Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withValues(alpha: 0.55)), child: const Icon(Icons.close, size: 12, color: Colors.white)),
                          ),
                        ),
                      ]),
                    if (_video.isNotEmpty)
                      Stack(children: [
                        Container(width: 84, height: 84, decoration: BoxDecoration(color: T.ink, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.play_circle_outline, color: Colors.white, size: 30)),
                        Positioned(
                          top: 2, right: 2,
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _video = '';
                              _saveDraft();
                            }),
                            child: Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withValues(alpha: 0.55)), child: const Icon(Icons.close, size: 12, color: Colors.white)),
                          ),
                        ),
                      ]),
                  ]),
                ],
                if (_poll != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: T.bg, borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      Icon(Icons.poll_outlined, size: 16, color: T.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text('${_poll!.question} · ${_poll!.options.length} 个选项', style: TextStyle(fontSize: 12.5, color: T.ink))),
                      GestureDetector(onTap: () => setState(() => _poll = null), child: Icon(Icons.close, size: 16, color: T.inkSubtle)),
                    ]),
                  ),
                ],
                const SizedBox(height: 10),
                Row(children: [
                  _tool(T, Icons.image_outlined, '图片', () => _sourceSheet(video: false)),
                  _tool(T, Icons.videocam_outlined, '视频', () => _sourceSheet(video: true)),
                  _tool(T, Icons.poll_outlined, '投票', _editPoll),
                ]),
              ]),
            ),
            const SizedBox(height: 14),
            Row(children: [
              GestureDetector(
                onTap: () => setState(() {
                  _rules = !_rules;
                  _saveDraft();
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 18, height: 18,
                  decoration: BoxDecoration(color: _rules ? T.primary : T.surface, borderRadius: BorderRadius.circular(5), border: Border.all(color: _rules ? T.primary : T.inkSubtle, width: 1.5)),
                  child: _rules ? const Center(child: MedIcon(MedIcons.check, size: 11, color: Colors.white, stroke: 3)) : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text('我已阅读并遵守《社区发布规则》，不发布虚假医疗信息', style: TextStyle(fontSize: 12, color: T.inkMuted))),
            ]),
          ]),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: BoxDecoration(color: T.surface, border: Border(top: BorderSide(color: T.divider))),
          child: SafeArea(top: false, child: PrimaryButton(label: '确定发布', loading: _busy, onTap: canPublish ? _publish : null)),
        ),
      ]),
    );
  }

  Widget _tool(MedTokens T, IconData icon, String label, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 10),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(color: T.bg, borderRadius: BorderRadius.circular(999)),
            child: Row(children: [Icon(icon, size: 16, color: T.primary), const SizedBox(width: 5), Text(label, style: TextStyle(fontSize: 12.5, color: T.ink, fontWeight: FontWeight.w600))]),
          ),
        ),
      );
}

/// Two-column bottom sheet (~58% height): left level-1 categories (100 px), right rows.
class TwoColPickerSheet extends StatefulWidget {
  final List<TaxonomyGroup> groups;
  final String title;
  final String? initialGroup;
  const TwoColPickerSheet({super.key, required this.groups, required this.title, this.initialGroup});

  @override
  State<TwoColPickerSheet> createState() => _TwoColPickerSheetState();
}

class _TwoColPickerSheetState extends State<TwoColPickerSheet> {
  late int _g = widget.groups.indexWhere((g) => g.label == widget.initialGroup).clamp(0, widget.groups.length - 1);

  @override
  Widget build(BuildContext context) {
    final T = MedTheme.of(context);
    final h = MediaQuery.of(context).size.height * 0.58;
    final groups = widget.groups;
    return Container(
      height: h,
      decoration: BoxDecoration(color: T.bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(22))),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
          child: Row(children: [
            Text(widget.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: T.ink)),
            const Spacer(),
            IconButton(icon: Icon(Icons.close, color: T.inkSubtle), onPressed: () => Navigator.pop(context)),
          ]),
        ),
        Expanded(
          child: groups.isEmpty
              ? Center(child: Text('暂无分类', style: TextStyle(color: T.inkSubtle)))
              : Row(children: [
                  SizedBox(
                    width: 100,
                    child: ListView.builder(
                      itemCount: groups.length,
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () => setState(() => _g = i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          color: i == _g ? T.surface : Colors.transparent,
                          child: Text(groups[i].label, style: TextStyle(fontSize: 13, fontWeight: i == _g ? FontWeight.w700 : FontWeight.w500, color: i == _g ? T.primary : T.inkMuted)),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: T.surface,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: groups[_g].items.length,
                        separatorBuilder: (_, _) => Divider(height: 1, color: T.divider, indent: 58),
                        itemBuilder: (_, i) {
                          final name = groups[_g].items[i];
                          return InkWell(
                            onTap: () => Navigator.pop(context, (groups[_g].label, name)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(children: [
                                MedPlaceholder(width: 34, height: 34, seed: 'hc-${hashOf(name)}', radius: 8),
                                const SizedBox(width: 12),
                                Expanded(child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, color: T.ink))),
                                MedIcon(MedIcons.chevronRight, size: 14, color: T.inkSubtle),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ]),
        ),
      ]),
    );
  }
}
