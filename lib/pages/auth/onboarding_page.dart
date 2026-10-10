import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/stores.dart';
import '../../theme/med_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/med_icons.dart';
import 'login_page.dart';

/// 引导图 — three glass rows cycling every 2.6 s; 跳过 top-right; 立即体验 pill.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _active = 0;
  Timer? _t;

  static const _rows = [
    (MedIcons.heartPulse, Color(0xFF12A594), '兴趣健康圈', '找到同好'),
    (MedIcons.doctorChat, Color(0xFF0EA5B7), '问诊社区话题', '畅所欲言'),
    (MedIcons.stethoscope, Color(0xFFFF8A5B), '义诊活动', '健康守护'),
  ];

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 2600), (_) => mounted ? setState(() => _active = (_active + 1) % 3) : null);
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _finish() {
    context.read<AuthStore>().setOnboarded();
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    const T = MedTokens.light;
    return MedTheme(
      tokens: T,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFDDF4EE), Color(0xFFF2F8F6), Color(0xFFFFEADF)]),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: _finish, child: Text('跳过', style: TextStyle(color: T.inkMuted, fontSize: 14, fontWeight: FontWeight.w600))),
                ),
                const Spacer(),
                const MedLogo(size: 64),
                const SizedBox(height: 18),
                Text('欢迎来到健康圈子', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: T.ink, letterSpacing: 1)),
                const SizedBox(height: 8),
                Text('让健康更有温度，让关怀触手可及', style: TextStyle(fontSize: 13, color: T.inkMuted)),
                const SizedBox(height: 36),
                for (int i = 0; i < _rows.length; i++) ...[
                  AnimatedScale(
                    scale: _active == i ? 1.03 : 1,
                    duration: const Duration(milliseconds: 450),
                    curve: const Cubic(.34, 1.56, .64, 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: _active == i ? 0.85 : 0.55),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
                        boxShadow: _active == i ? T.shadowMd : null,
                      ),
                      child: Row(children: [
                        Container(
                          width: 46, height: 46,
                          decoration: BoxDecoration(color: _rows[i].$2, borderRadius: BorderRadius.circular(14)),
                          child: Center(child: MedIcon(_rows[i].$1, size: 24, color: Colors.white)),
                        ),
                        const SizedBox(width: 14),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_rows[i].$3, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: T.ink)),
                          const SizedBox(height: 2),
                          Text(_rows[i].$4, style: TextStyle(fontSize: 12.5, color: T.inkMuted)),
                        ]),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const Spacer(),
                PrimaryButton(label: '立即体验', onTap: _finish),
                const SizedBox(height: 30),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
