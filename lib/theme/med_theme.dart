import 'package:flutter/material.dart';

/// 健康圈子 · 医疗推广平台主题（白天）— 青绿 / 薄荷绿主色 + 暖珊瑚点缀
/// Tokens ported from `med/medTheme.js`.
class MedTheme {
  MedTheme._();

  static const Color primary = Color(0xFF12A594);
  static const Color primaryDeep = Color(0xFF0B7A6E);
  static const Color primarySoft = Color(0xFFE6F6F2);
  static const Color violet = Color(0xFF0EA5B7);
  static const Color violetSoft = Color(0xFFE3F5F7);
  static const Color accent = Color(0xFFFFB37A);
  static const Color accentDeep = Color(0xFFFF8A5B);
  static const Color mint = Color(0xFF1DB980);
  static const Color mintSoft = Color(0xFFDDF6EA);
  static const Color pink = Color(0xFFFF7F66);
  static const Color sky = Color(0xFF2DB4E0);

  static const Color bg = Color(0xFFF2F8F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE3EEEA);

  static const Color ink = Color(0xFF13322D);
  static const Color inkMuted = Color(0xFF4A645E);
  static const Color inkSubtle = Color(0xFF8BA39D);
  static const Color danger = Color(0xFFEF4444);

  // Tint pairs {bg, fg}
  static const Tint tintIndigo = Tint(Color(0xFFE6F6F2), Color(0xFF12A594));
  static const Tint tintViolet = Tint(Color(0xFFE3F5F7), Color(0xFF0EA5B7));
  static const Tint tintPink = Tint(Color(0xFFFFEDE7), Color(0xFFF2704A));
  static const Tint tintSky = Tint(Color(0xFFE2F4FB), Color(0xFF1C9AC8));
  static const Tint tintMint = Tint(Color(0xFFDDF6EA), Color(0xFF17A06F));
  static const Tint tintAmber = Tint(Color(0xFFFFF3E0), Color(0xFFE08A1E));
  static const Tint tintRose = Tint(Color(0xFFFFEAEA), Color(0xFFE8595A));
  static const Tint tintSlate = Tint(Color(0xFFEDF3F1), Color(0xFF4A645E));
  static const Tint tintMessage = Tint(Color(0xFFD6F1EF), Color(0xFF0E8C8F));

  // Radius
  static const double rSm = 10;
  static const double rMd = 16;
  static const double rLg = 20;
  static const double rXl = 26;

  // Shadows
  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x0F134A40),
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color(0x0A134A40),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];
  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x17134A40),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];
  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color(0x24134A40),
      blurRadius: 40,
      offset: Offset(0, 16),
    ),
  ];

  static const LinearGradient logoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2CC7A9), Color(0xFF12A594), Color(0xFF0E8C8F)],
    stops: [0, 0.55, 1],
  );
  static const LinearGradient primaryButtonGradient = LinearGradient(
    colors: [primary, violet],
  );
  static const LinearGradient fabGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentDeep],
  );

  static ThemeData themeData() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: violet,
        surface: surface,
      ),
      scaffoldBackgroundColor: bg,
      splashFactory: InkRipple.splashFactory,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: ink,
        displayColor: ink,
        fontFamilyFallback: const [
          'Nunito',
          'PingFang SC',
          'Noto Sans SC',
          'Hiragino Sans GB',
          'Microsoft YaHei',
          'sans-serif',
        ],
      ),
      dividerColor: divider,
      cardTheme: const CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }
}

class Tint {
  final Color bg;
  final Color fg;
  const Tint(this.bg, this.fg);
}
