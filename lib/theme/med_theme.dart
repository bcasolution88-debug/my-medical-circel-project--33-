import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Tint {
  final Color bg;
  final Color fg;
  const Tint(this.bg, this.fg);
}

/// Design tokens (day = `med/medTheme.js`, night = `med/medDark.js`).
class MedTokens {
  final bool dark;
  final Color primary, primaryDeep, primarySoft, violet, violetSoft, accent, accentDeep;
  final Color mint, mintSoft, pink, sky, bg, surface, card, divider, ink, inkMuted, inkSubtle;
  final Tint tintIndigo, tintViolet, tintPink, tintSky, tintMint, tintAmber, tintRose, tintSlate, tintMessage;
  final List<BoxShadow> shadowSm, shadowMd, shadowLg;

  const MedTokens({
    required this.dark,
    required this.primary,
    required this.primaryDeep,
    required this.primarySoft,
    required this.violet,
    required this.violetSoft,
    required this.accent,
    required this.accentDeep,
    required this.mint,
    required this.mintSoft,
    required this.pink,
    required this.sky,
    required this.bg,
    required this.surface,
    required this.card,
    required this.divider,
    required this.ink,
    required this.inkMuted,
    required this.inkSubtle,
    required this.tintIndigo,
    required this.tintViolet,
    required this.tintPink,
    required this.tintSky,
    required this.tintMint,
    required this.tintAmber,
    required this.tintRose,
    required this.tintSlate,
    required this.tintMessage,
    required this.shadowSm,
    required this.shadowMd,
    required this.shadowLg,
  });

  static const danger = Color(0xFFEF4444);

  static const light = MedTokens(
    dark: false,
    primary: Color(0xFF12A594),
    primaryDeep: Color(0xFF0B7A6E),
    primarySoft: Color(0xFFE6F6F2),
    violet: Color(0xFF0EA5B7),
    violetSoft: Color(0xFFE3F5F7),
    accent: Color(0xFFFFB37A),
    accentDeep: Color(0xFFFF8A5B),
    mint: Color(0xFF1DB980),
    mintSoft: Color(0xFFDDF6EA),
    pink: Color(0xFFFF7F66),
    sky: Color(0xFF2DB4E0),
    bg: Color(0xFFF2F8F6),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    divider: Color(0xFFE3EEEA),
    ink: Color(0xFF13322D),
    inkMuted: Color(0xFF4A645E),
    inkSubtle: Color(0xFF8BA39D),
    tintIndigo: Tint(Color(0xFFE6F6F2), Color(0xFF12A594)),
    tintViolet: Tint(Color(0xFFE3F5F7), Color(0xFF0EA5B7)),
    tintPink: Tint(Color(0xFFFFEDE7), Color(0xFFF2704A)),
    tintSky: Tint(Color(0xFFE2F4FB), Color(0xFF1C9AC8)),
    tintMint: Tint(Color(0xFFDDF6EA), Color(0xFF17A06F)),
    tintAmber: Tint(Color(0xFFFFF3E0), Color(0xFFE08A1E)),
    tintRose: Tint(Color(0xFFFFEAEA), Color(0xFFE8595A)),
    tintSlate: Tint(Color(0xFFEDF3F1), Color(0xFF4A645E)),
    tintMessage: Tint(Color(0xFFD6F1EF), Color(0xFF0E8C8F)),
    shadowSm: [
      BoxShadow(color: Color(0x0F134A40), blurRadius: 3, offset: Offset(0, 1)),
      BoxShadow(color: Color(0x0A134A40), blurRadius: 2, offset: Offset(0, 1)),
    ],
    shadowMd: [BoxShadow(color: Color(0x17134A40), blurRadius: 18, offset: Offset(0, 6))],
    shadowLg: [BoxShadow(color: Color(0x24134A40), blurRadius: 40, offset: Offset(0, 16))],
  );

  static const night = MedTokens(
    dark: true,
    primary: Color(0xFF3FD3BD),
    primaryDeep: Color(0xFFA9F0E4),
    primarySoft: Color(0xFF0F3530),
    violet: Color(0xFF3CC8DA),
    violetSoft: Color(0xFF0E3239),
    accent: Color(0xFFFFB37A),
    accentDeep: Color(0xFFFF9466),
    mint: Color(0xFF34D399),
    mintSoft: Color(0xFF0B3A2A),
    pink: Color(0xFFFF8C75),
    sky: Color(0xFF5CC8EE),
    bg: Color(0xFF0A1816),
    surface: Color(0xFF11231F),
    card: Color(0xFF11231F),
    divider: Color(0xFF1D3833),
    ink: Color(0xFFE4F3EF),
    inkMuted: Color(0xFFA3BFB8),
    inkSubtle: Color(0xFF6A8780),
    tintIndigo: Tint(Color(0xFF0F3530), Color(0xFF6EE2CF)),
    tintViolet: Tint(Color(0xFF0E3239), Color(0xFF74D9E6)),
    tintPink: Tint(Color(0xFF3D1D16), Color(0xFFFFAA94)),
    tintSky: Tint(Color(0xFF0D2E3C), Color(0xFF86D6F2)),
    tintMint: Tint(Color(0xFF0B3A2A), Color(0xFF6EE7B7)),
    tintAmber: Tint(Color(0xFF3B2A10), Color(0xFFFFC979)),
    tintRose: Tint(Color(0xFF3E1A1C), Color(0xFFFF9C9D)),
    tintSlate: Tint(Color(0xFF16302B), Color(0xFFB9D2CB)),
    tintMessage: Tint(Color(0xFF0F3530), Color(0xFF6EE2CF)),
    shadowSm: [BoxShadow(color: Color(0x73000000), blurRadius: 2, offset: Offset(0, 1))],
    shadowMd: [BoxShadow(color: Color(0x80000000), blurRadius: 16, offset: Offset(0, 6))],
    shadowLg: [BoxShadow(color: Color(0x99000000), blurRadius: 36, offset: Offset(0, 16))],
  );

  LinearGradient get primaryButtonGradient => LinearGradient(colors: [primary, violet]);
  LinearGradient get fabGradient => LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [accent, accentDeep]);
  static const LinearGradient logoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2CC7A9), Color(0xFF12A594), Color(0xFF0E8C8F)],
    stops: [0, 0.55, 1],
  );

  ThemeData themeData() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: violet,
        surface: surface,
        brightness: dark ? Brightness.dark : Brightness.light,
      ),
      scaffoldBackgroundColor: bg,
      splashFactory: InkRipple.splashFactory,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: ink,
        displayColor: ink,
        fontFamilyFallback: const ['Nunito', 'PingFang SC', 'Noto Sans SC', 'Hiragino Sans GB', 'Microsoft YaHei', 'sans-serif'],
      ),
      dividerColor: divider,
      cardTheme: CardThemeData(color: card, elevation: 0, margin: EdgeInsets.zero),
      appBarTheme: AppBarTheme(backgroundColor: surface, foregroundColor: ink, elevation: 0, scrolledUnderElevation: 0),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: surface),
      dialogTheme: DialogThemeData(backgroundColor: surface),
    );
  }
}

/// Theme controller — persists `theme_mode` like the prototype (`localStorage.theme_mode`).
class ThemeStore extends ChangeNotifier {
  bool _dark = false;
  bool get dark => _dark;
  MedTokens get tokens => _dark ? MedTokens.night : MedTokens.light;

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _dark = p.getString('theme_mode') == 'dark';
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggle() async {
    _dark = !_dark;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('theme_mode', _dark ? 'dark' : 'light');
    } catch (_) {}
  }
}

/// Inherited access to the active tokens: `final T = MedTheme.of(context);`
class MedTheme extends InheritedWidget {
  final MedTokens tokens;
  const MedTheme({super.key, required this.tokens, required super.child});

  static MedTokens of(BuildContext context) {
    final w = context.dependOnInheritedWidgetOfExactType<MedTheme>();
    return w?.tokens ?? MedTokens.light;
  }

  @override
  bool updateShouldNotify(MedTheme old) => old.tokens != tokens;
}
