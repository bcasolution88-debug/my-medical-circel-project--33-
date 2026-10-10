import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/api_client.dart';
import '../../data/geo_service.dart';
import '../../data/stores.dart';
import '../../theme/med_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/med_icons.dart';
import '../app_shell.dart';
import '../simple_pages.dart';

/// Geo-fence badge above the logo: checking / inside / outside / unknown.
class GeoFenceBadge extends StatelessWidget {
  final GeoFenceResult? result;
  final VoidCallback onRetry;
  const GeoFenceBadge({super.key, required this.result, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final T = MedTheme.of(context);
    final r = result;
    Color bg, fg;
    Widget icon;
    String text;
    if (r == null || r.state == GeoState.checking) {
      bg = T.tintSlate.bg;
      fg = T.tintSlate.fg;
      icon = SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.6, color: fg));
      text = '正在定位…';
    } else if (r.state == GeoState.inside) {
      bg = T.tintMint.bg;
      fg = T.tintMint.fg;
      icon = MedIcon(MedIcons.check, size: 12, color: fg, stroke: 2.5);
      text = '服务范围内 · 距中心 ${_km(r.distanceM)} / 半径 ${_km(r.radiusM)}';
    } else if (r.state == GeoState.outside) {
      bg = T.tintRose.bg;
      fg = T.tintRose.fg;
      icon = MedIcon(MedIcons.close, size: 12, color: fg, stroke: 2.5);
      text = '不在服务范围 · 距中心 ${_km(r.distanceM)}';
    } else {
      bg = T.tintAmber.bg;
      fg = T.tintAmber.fg;
      icon = MedIcon(MedIcons.pin, size: 12, color: fg);
      text = '无法获取位置，请允许定位权限';
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        icon,
        const SizedBox(width: 6),
        Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: fg))),
        if (r != null && r.state != GeoState.checking && r.state != GeoState.inside) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: fg, borderRadius: BorderRadius.circular(999)),
              child: const Text('重新定位', style: TextStyle(fontSize: 10.5, color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ]),
    );
  }

  static String _km(double m) => m >= 1000 ? '${(m / 1000).toStringAsFixed(m >= 100000 ? 0 : 1)} km' : '${m.round()} m';
}

/// Floating-label text field.
class AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure, enabled;
  final TextInputType? keyboard;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  const AuthField({super.key, required this.controller, required this.label, this.obscure = false, this.enabled = true, this.keyboard, this.suffix, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final T = MedTheme.of(context);
    return TextField(
      controller: controller,
      obscureText: obscure,
      enabled: enabled,
      keyboardType: keyboard,
      onChanged: onChanged,
      style: TextStyle(color: T.ink, fontSize: 14.5),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: T.inkSubtle, fontSize: 13.5),
        floatingLabelStyle: TextStyle(color: T.primary, fontWeight: FontWeight.w600),
        filled: true,
        fillColor: T.surface,
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: T.divider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: T.primary, width: 1.5)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: T.divider)),
      ),
    );
  }
}

/// Agreement checkbox — pre-checked; un-checking blocks actions with a shake.
class AgreementRow extends StatelessWidget {
  final bool checked;
  final ValueChanged<bool> onChanged;
  final Animation<double> shake;
  const AgreementRow({super.key, required this.checked, required this.onChanged, required this.shake});

  @override
  Widget build(BuildContext context) {
    final T = MedTheme.of(context);
    return AnimatedBuilder(
      animation: shake,
      builder: (_, child) => Transform.translate(offset: Offset(shake.value, 0), child: child),
      child: Row(children: [
        GestureDetector(
          onTap: () => onChanged(!checked),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 18, height: 18,
            decoration: BoxDecoration(
              color: checked ? T.primary : T.surface,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: checked ? T.primary : T.inkSubtle, width: 1.5),
            ),
            child: checked ? const Center(child: MedIcon(MedIcons.check, size: 11, color: Colors.white, stroke: 3)) : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(children: [
            Text('我已阅读并同意 ', style: TextStyle(fontSize: 12, color: T.inkMuted)),
            GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LegalPage(title: '用户协议'))),
              child: Text('《用户协议》', style: TextStyle(fontSize: 12, color: T.primary, fontWeight: FontWeight.w600)),
            ),
            Text('与', style: TextStyle(fontSize: 12, color: T.inkMuted)),
            GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LegalPage(title: '隐私政策'))),
              child: Text('《隐私政策》', style: TextStyle(fontSize: 12, color: T.primary, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
      ]),
    );
  }
}

/// Shared auth scaffold state: geo-fence + agreement shake.
mixin AuthPageMixin<W extends StatefulWidget> on State<W>, SingleTickerProviderStateMixin<W> {
  GeoFenceResult? geo;
  bool agreed = true;
  late final AnimationController shakeCtl = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  late final Animation<double> shake = TweenSequence<double>([
    for (final v in [-8.0, 8.0, -6.0, 6.0, -3.0, 3.0, 0.0]) TweenSequenceItem(tween: Tween(begin: 0, end: v), weight: 1),
  ]).animate(shakeCtl);

  bool get blocked => geo?.state == GeoState.outside;
  bool get inputsEnabled => !blocked;

  Future<void> runGeoCheck() async {
    setState(() => geo = const GeoFenceResult(GeoState.checking));
    final r = await GeoService.check();
    if (mounted) setState(() => geo = r);
  }

  bool guard(BuildContext context) {
    if (!agreed) {
      shakeCtl.forward(from: 0);
      showToast(context, '请先勾选同意用户协议与隐私政策');
      return false;
    }
    if (blocked) {
      showToast(context, geo?.blockedMessage ?? '当前地区暂未开放');
      return false;
    }
    return true;
  }

  Widget blockedNotice(MedTokens T) => blocked
      ? Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: T.tintRose.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: T.tintRose.fg.withValues(alpha: 0.35))),
          child: Row(children: [
            Icon(Icons.block_rounded, size: 18, color: T.tintRose.fg),
            const SizedBox(width: 8),
            Expanded(child: Text(geo?.blockedMessage ?? '', style: TextStyle(fontSize: 12.5, color: T.tintRose.fg, height: 1.4))),
          ]),
        )
      : const SizedBox.shrink();

  Widget socialButtons(MedTokens T, BuildContext context) => Row(children: [
        Expanded(child: _social(T, context, 'G', 'Google', const Color(0xFFEA4335))),
        const SizedBox(width: 12),
        Expanded(child: _social(T, context, 'f', 'Facebook', const Color(0xFF1877F2))),
      ]);

  Widget _social(MedTokens T, BuildContext context, String glyph, String name, Color color) => GestureDetector(
        onTap: () {
          if (!guard(context)) return;
          showToast(context, '$name 登录需先在「个人设置 → 第三方绑定」完成绑定');
        },
        child: Container(
          height: 44,
          decoration: BoxDecoration(color: T.surface, borderRadius: BorderRadius.circular(999), border: Border.all(color: T.divider)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(glyph, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(width: 8),
            Text(name, style: TextStyle(color: T.ink, fontSize: 13.5, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin, AuthPageMixin {
  final _email = TextEditingController(text: 'me@healthcircle.app');
  final _pwd = TextEditingController(text: 'Pass@2026');
  bool _showPwd = false, _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    runGeoCheck();
  }

  @override
  void dispose() {
    shakeCtl.dispose();
    _email.dispose();
    _pwd.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!guard(context)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AuthStore>().login(_email.text.trim(), _pwd.text);
      if (!mounted) return;
      context.read<MessagesStore>().refresh();
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const AppShell()), (_) => false);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = '无法连接服务器，请检查网络后重试');
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    const T = MedTokens.light;
    return MedTheme(
      tokens: T,
      child: Scaffold(
        backgroundColor: T.bg,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                if (Navigator.of(context).canPop()) const NavPill() else const SizedBox(height: 34),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const AppShell()), (_) => false),
                  child: Text('先逛逛', style: TextStyle(color: T.inkMuted, fontSize: 13.5, fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 10),
              Center(child: GeoFenceBadge(result: geo, onRetry: runGeoCheck)),
              const SizedBox(height: 22),
              const Center(child: MedLogo(size: 64)),
              const SizedBox(height: 16),
              Center(child: Text('健康圈子', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 2, color: T.ink))),
              const SizedBox(height: 4),
              Center(child: Text('HEALTH CIRCLE · 让健康更有温度', style: TextStyle(fontSize: 12, color: T.inkSubtle, letterSpacing: 1))),
              const SizedBox(height: 28),
              blockedNotice(T),
              Opacity(
                opacity: inputsEnabled ? 1 : 0.5,
                child: Column(children: [
                  AuthField(controller: _email, label: '邮箱', enabled: inputsEnabled, keyboard: TextInputType.emailAddress),
                  const SizedBox(height: 14),
                  AuthField(
                    controller: _pwd, label: '密码', obscure: !_showPwd, enabled: inputsEnabled,
                    suffix: IconButton(icon: Icon(_showPwd ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: T.inkSubtle), onPressed: () => setState(() => _showPwd = !_showPwd)),
                  ),
                ]),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => showToast(context, '请联系客服重置密码'),
                  child: Text('忘记密码', style: TextStyle(fontSize: 12.5, color: T.primary, fontWeight: FontWeight.w600)),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(fontSize: 12.5, color: T.tintRose.fg)),
              ],
              const SizedBox(height: 18),
              PrimaryButton(label: '登录', loading: _busy, onTap: inputsEnabled ? _login : null),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterPage())),
                  child: RichText(
                    text: TextSpan(style: TextStyle(fontSize: 13, color: T.inkMuted), children: [
                      const TextSpan(text: '还没有账号？'),
                      TextSpan(text: '立即注册', style: TextStyle(color: T.primary, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              Row(children: [
                Expanded(child: Divider(color: T.divider)),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('第三方登录', style: TextStyle(fontSize: 11.5, color: T.inkSubtle))),
                Expanded(child: Divider(color: T.divider)),
              ]),
              const SizedBox(height: 16),
              socialButtons(T, context),
              const SizedBox(height: 24),
              AgreementRow(checked: agreed, onChanged: (v) => setState(() => agreed = v), shake: shake),
            ]),
          ),
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin, AuthPageMixin {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _pwd = TextEditingController();
  final _pwd2 = TextEditingController();
  int _countdown = 0;
  Timer? _cd;
  bool _busy = false;
  String? _error, _devCode;

  @override
  void initState() {
    super.initState();
    runGeoCheck();
    _pwd.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _cd?.cancel();
    shakeCtl.dispose();
    for (final c in [_email, _code, _pwd, _pwd2]) {
      c.dispose();
    }
    super.dispose();
  }

  int get _strength {
    final p = _pwd.text;
    if (p.isEmpty) return 0;
    int s = 0;
    if (p.length >= 8) s++;
    if (RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p)) s++;
    if (RegExp(r'\d').hasMatch(p)) s++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) s++;
    return s.clamp(1, 3);
  }

  Future<void> _sendCode() async {
    if (!guard(context)) return;
    if (!_email.text.contains('@')) {
      showToast(context, '请输入正确的邮箱');
      return;
    }
    try {
      final dev = await context.read<AuthStore>().sendCode(_email.text.trim());
      setState(() {
        _countdown = 60;
        _devCode = dev;
        if (dev.isNotEmpty) _code.text = dev; // dev mode: backend echoes the code (no SMTP)
      });
      _cd?.cancel();
      _cd = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return t.cancel();
        setState(() => _countdown--);
        if (_countdown <= 0) t.cancel();
      });
      if (mounted) showToast(context, '验证码已发送');
    } catch (e) {
      if (mounted) showToast(context, '发送失败：$e');
    }
  }

  Future<void> _register() async {
    if (!guard(context)) return;
    if (_pwd.text != _pwd2.text) {
      setState(() => _error = '两次输入的密码不一致');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AuthStore>().register(_email.text.trim(), _code.text.trim(), _pwd.text);
      if (!mounted) return;
      context.read<MessagesStore>().refresh();
      showToast(context, '注册成功，欢迎加入健康圈子');
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const AppShell()), (_) => false);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = '无法连接服务器，请稍后重试');
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    const T = MedTokens.light;
    final strength = _strength;
    final sColor = [T.divider, T.tintRose.fg, T.tintAmber.fg, T.mint][strength];
    final sLabel = ['', '弱', '中', '强'][strength];
    return MedTheme(
      tokens: T,
      child: Scaffold(
        backgroundColor: T.bg,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Align(alignment: Alignment.centerLeft, child: NavPill()),
              const SizedBox(height: 10),
              Center(child: GeoFenceBadge(result: geo, onRetry: runGeoCheck)),
              const SizedBox(height: 22),
              const Center(child: MedLogo(size: 56)),
              const SizedBox(height: 14),
              Center(child: Text('创建账号', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1, color: T.ink))),
              const SizedBox(height: 24),
              blockedNotice(T),
              Opacity(
                opacity: inputsEnabled ? 1 : 0.5,
                child: Column(children: [
                  AuthField(controller: _email, label: '邮箱', enabled: inputsEnabled, keyboard: TextInputType.emailAddress),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: AuthField(controller: _code, label: '验证码', enabled: inputsEnabled, keyboard: TextInputType.number)),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 118,
                      height: 48,
                      child: GestureDetector(
                        onTap: _countdown > 0 || !inputsEnabled ? null : _sendCode,
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _countdown > 0 ? T.divider : T.primarySoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(_countdown > 0 ? '$_countdown s 后重发' : '获取验证码',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _countdown > 0 ? T.inkSubtle : T.primary)),
                        ),
                      ),
                    ),
                  ]),
                  if (_devCode != null && _devCode!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Align(alignment: Alignment.centerLeft, child: Text('开发模式：验证码 $_devCode 已自动填入', style: TextStyle(fontSize: 11, color: T.inkSubtle))),
                  ],
                  const SizedBox(height: 14),
                  AuthField(controller: _pwd, label: '设置密码', obscure: true, enabled: inputsEnabled),
                  const SizedBox(height: 8),
                  Row(children: [
                    for (int i = 1; i <= 3; i++) ...[
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 4,
                          decoration: BoxDecoration(color: i <= strength ? sColor : T.divider, borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      if (i < 3) const SizedBox(width: 4),
                    ],
                    const SizedBox(width: 10),
                    SizedBox(width: 24, child: Text(sLabel, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: sColor))),
                  ]),
                  const SizedBox(height: 14),
                  AuthField(controller: _pwd2, label: '确认密码', obscure: true, enabled: inputsEnabled),
                ]),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: TextStyle(fontSize: 12.5, color: T.tintRose.fg)),
              ],
              const SizedBox(height: 22),
              PrimaryButton(label: '注册', loading: _busy, onTap: inputsEnabled ? _register : null),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: RichText(
                    text: TextSpan(style: TextStyle(fontSize: 13, color: T.inkMuted), children: [
                      const TextSpan(text: '已有账号？'),
                      TextSpan(text: '去登录', style: TextStyle(color: T.primary, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AgreementRow(checked: agreed, onChanged: (v) => setState(() => agreed = v), shake: shake),
            ]),
          ),
        ),
      ),
    );
  }
}
