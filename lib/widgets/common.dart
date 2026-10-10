import 'package:flutter/material.dart';
import '../data/api_client.dart';
import '../theme/med_theme.dart';
import 'med_icons.dart';

int hashOf(String? s) {
  int h = 0;
  final str = s ?? 'x';
  for (int i = 0; i < str.length; i++) {
    h = (h * 31 + str.codeUnitAt(i)) % 9973;
  }
  return h;
}

/// Resolve an API-provided image reference to a widget-ready provider.
ImageProvider? imageProviderFor(String? src) {
  if (src == null || src.isEmpty) return null;
  if (src.startsWith('http')) return NetworkImage(src);
  if (src.startsWith('/uploads/')) return NetworkImage(ApiClient.instance.resolve(src));
  if (src.startsWith('/assets/')) return AssetImage(src.substring(1));
  if (src.startsWith('assets/')) return AssetImage(src);
  return null; // seed → placeholder
}

const List<List<Color>> _placeholderPals = [
  [Color(0xFFBFEDE2), Color(0xFF7ED6C2)],
  [Color(0xFFC7EEF3), Color(0xFF86D3DE)],
  [Color(0xFFD3F3E2), Color(0xFF8EDDB6)],
  [Color(0xFFFFE1CC), Color(0xFFFFC09A)],
  [Color(0xFFCFEAF6), Color(0xFF8CCBE8)],
  [Color(0xFFE2F2D6), Color(0xFFAEDB8E)],
  [Color(0xFFFFE3DD), Color(0xFFFFB3A3)],
  [Color(0xFFD6F1EC), Color(0xFF9ADFD1)],
];

/// Soft "illustration" tile with faint medical motif — `med/medArt.jsx` Placeholder.
/// If `image` resolves to a real image it is shown instead.
class MedPlaceholder extends StatelessWidget {
  final double? width, height;
  final String seed;
  final double radius;
  final bool circle;
  final String? image;

  const MedPlaceholder({super.key, this.width, this.height, required this.seed, this.radius = 10, this.circle = false, this.image});

  @override
  Widget build(BuildContext context) {
    final k = hashOf(seed);
    final pal = _placeholderPals[k % _placeholderPals.length];
    final motif = MedIcons.placeholderMotifs[k % MedIcons.placeholderMotifs.length];
    final shape = circle ? const CircleBorder() : RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
    final provider = imageProviderFor(image);
    final dark = MedTheme.of(context).dark;

    return SizedBox(
      width: width,
      height: height,
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: LayoutBuilder(builder: (context, c) {
          final h = c.maxHeight.isFinite ? c.maxHeight : 100.0;
          final w = c.maxWidth.isFinite ? c.maxWidth : h;
          final big = (h * 0.42).clamp(18.0, 72.0);
          if (provider != null) {
            return Image(image: provider, fit: BoxFit.cover, errorBuilder: (_, _, _) => _gradient(pal, w, h, big, motif, dark));
          }
          return _gradient(pal, w, h, big, motif, dark);
        }),
      ),
    );
  }

  Widget _gradient(List<Color> pal, double w, double h, double big, MedIconData motif, bool dark) {
    final colors = dark ? pal.map((c) => Color.lerp(c, const Color(0xFF0A1816), 0.45)!).toList() : pal;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors))),
        Positioned(right: -w * 0.12, top: -h * 0.18, child: _circle(w * 0.62, 0.28)),
        Positioned(left: -w * 0.10, bottom: -h * 0.22, child: _circle(w * 0.48, 0.18)),
        Center(child: Opacity(opacity: 0.55, child: MedIcon(motif, size: big, color: Colors.white, stroke: 1.8))),
      ],
    );
  }

  Widget _circle(double s, double a) => Container(width: s, height: s, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: a)));
}

const List<List<Color>> _avatarPals = [
  [Color(0xFFD6F3EC), Color(0xFF0B7A6E)],
  [Color(0xFFD9F1F5), Color(0xFF0B7A8A)],
  [Color(0xFFFFE6D8), Color(0xFFC2582E)],
  [Color(0xFFE3F4DA), Color(0xFF3F7F2A)],
  [Color(0xFFDCEFFA), Color(0xFF1C6FA0)],
  [Color(0xFFFFE3E3), Color(0xFFB4444A)],
  [Color(0xFFF3EDDC), Color(0xFF8A6420)],
  [Color(0xFFE0F0EE), Color(0xFF2E6A63)],
];

/// Pastel circle with deep-tone initial (or uploaded image).
class MedAvatar extends StatelessWidget {
  final double size;
  final String seed;
  final String? label, url;
  final Color? ring;
  const MedAvatar({super.key, this.size = 36, required this.seed, this.label, this.ring, this.url});

  @override
  Widget build(BuildContext context) {
    final pal = _avatarPals[hashOf(seed) % _avatarPals.length];
    final text = (label ?? seed).trim();
    final initial = text.isEmpty ? '?' : text.substring(0, 1).toUpperCase();
    final provider = imageProviderFor(url);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: pal[0],
        border: ring != null ? Border.all(color: ring!, width: 2) : null,
        image: provider != null ? DecorationImage(image: provider, fit: BoxFit.cover) : null,
      ),
      child: provider == null
          ? Text(initial, style: TextStyle(color: pal[1], fontWeight: FontWeight.w800, fontSize: size * 0.42, height: 1))
          : null,
    );
  }
}

/// Overlapping avatars row.
class LikerAvatars extends StatelessWidget {
  final List<String> likers;
  final List<String>? labels;
  final double size;
  final int max;
  const LikerAvatars({super.key, required this.likers, this.labels, this.size = 22, this.max = 6});

  @override
  Widget build(BuildContext context) {
    final T = MedTheme.of(context);
    if (likers.isEmpty) return const SizedBox.shrink();
    final shown = likers.take(max).toList();
    final overlap = size * 0.36;
    final children = <Widget>[];
    for (int i = 0; i < shown.length; i++) {
      children.add(Positioned(
        left: i * (size - overlap),
        child: Container(
          decoration: BoxDecoration(shape: BoxShape.circle, color: T.surface),
          padding: const EdgeInsets.all(1.5),
          child: MedAvatar(size: size, seed: shown[i], label: labels != null && i < labels!.length ? labels![i] : shown[i]),
        ),
      ));
    }
    if (likers.length > max) {
      children.add(Positioned(
        left: shown.length * (size - overlap),
        child: Container(
          height: size + 3,
          constraints: BoxConstraints(minWidth: size + 3),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: T.divider, borderRadius: BorderRadius.circular(size), border: Border.all(color: T.surface, width: 1.5)),
          child: Text('+${likers.length - max}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: T.inkMuted)),
        ),
      ));
    }
    final count = shown.length + (likers.length > max ? 1 : 0);
    return SizedBox(width: count * (size - overlap) + overlap + 3, height: size + 3, child: Stack(children: children));
  }
}

/// Section header: 17/700 title + "全部 ⊞" action.
class SectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onAction;
  final String? actionLabel;
  final MedIconData actionIcon;
  final EdgeInsets padding;
  const SectionTitle({super.key, required this.title, this.onAction, this.actionLabel = '全部', this.actionIcon = MedIcons.grid, this.padding = const EdgeInsets.fromLTRB(18, 18, 18, 10)});

  @override
  Widget build(BuildContext context) {
    final T = MedTheme.of(context);
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: T.ink)),
          if (onAction != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onAction,
              child: Row(children: [
                if (actionLabel != null) Text(actionLabel!, style: TextStyle(fontSize: 13, color: T.inkSubtle)),
                if (actionLabel != null) const SizedBox(width: 4),
                MedIcon(actionIcon, size: actionLabel == null ? 20 : 12, color: actionLabel == null ? T.ink : T.inkSubtle),
              ]),
            ),
        ],
      ),
    );
  }
}

/// White pill with ‹ back and ⌂ home buttons.
class NavPill extends StatelessWidget {
  final VoidCallback? onBack, onHome;
  const NavPill({super.key, this.onBack, this.onHome});

  @override
  Widget build(BuildContext context) {
    final T = MedTheme.of(context);
    return Container(
      height: 34,
      decoration: BoxDecoration(color: T.surface, borderRadius: BorderRadius.circular(999), border: Border.all(color: T.divider), boxShadow: T.shadowSm),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onBack ?? () => Navigator.of(context).maybePop(),
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: MedIcon(MedIcons.chevronLeft, size: 18, color: T.ink)),
        ),
        Container(width: 1, height: 18, color: T.divider),
        InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onHome ?? () => Navigator.of(context).popUntil((r) => r.isFirst),
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: MedIcon(MedIcons.home, size: 18, color: T.ink)),
        ),
      ]),
    );
  }
}

/// Sub-page header: NavPill + centred title (+ optional trailing).
class SubHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? trailing;
  const SubHeader({super.key, required this.title, this.trailing});

  @override
  Size get preferredSize => const Size.fromHeight(55);

  @override
  Widget build(BuildContext context) {
    final T = MedTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: T.surface, border: Border(bottom: BorderSide(color: T.divider))),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 34,
          child: Stack(alignment: Alignment.center, children: [
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: T.ink)),
            const Align(alignment: Alignment.centerLeft, child: NavPill()),
            if (trailing != null) Align(alignment: Alignment.centerRight, child: trailing!),
          ]),
        ),
      ),
    );
  }
}

/// Red unread badge.
class RedBadge extends StatelessWidget {
  final int count;
  final double size;
  final Color? borderColor;
  const RedBadge({super.key, required this.count, this.size = 18, this.borderColor});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final T = MedTheme.of(context);
    return Container(
      height: size,
      constraints: BoxConstraints(minWidth: size),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: MedTokens.danger, borderRadius: BorderRadius.circular(size / 2), border: Border.all(color: borderColor ?? T.bg, width: 2)),
      child: Text(count > 99 ? '99+' : '$count', style: TextStyle(color: Colors.white, fontSize: size * 0.58, fontWeight: FontWeight.w700, height: 1)),
    );
  }
}

/// Primary gradient pill button.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final Widget? icon;
  const PrimaryButton({super.key, required this.label, this.onTap, this.loading = false, this.icon});

  @override
  Widget build(BuildContext context) {
    final T = MedTheme.of(context);
    final disabled = onTap == null;
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        decoration: BoxDecoration(
          gradient: disabled ? null : T.primaryButtonGradient,
          color: disabled ? T.divider : null,
          borderRadius: BorderRadius.circular(999),
          boxShadow: disabled ? null : [BoxShadow(color: T.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Center(
          child: loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  if (icon != null) ...[icon!, const SizedBox(width: 8)],
                  Text(label, style: TextStyle(color: disabled ? T.inkSubtle : Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                ]),
        ),
      ),
    );
  }
}

/// Error / empty state with retry.
class ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorRetry({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final T = MedTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.cloud_off_rounded, size: 44, color: T.inkSubtle),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: T.inkMuted, fontSize: 13.5)),
          const SizedBox(height: 14),
          SizedBox(width: 140, child: PrimaryButton(label: '重试', onTap: onRetry)),
        ]),
      ),
    );
  }
}

/// Toast helper.
void showToast(BuildContext context, String message) {
  final T = MedTheme.of(context);
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message, textAlign: TextAlign.center, style: TextStyle(color: T.dark ? T.bg : Colors.white)),
    behavior: SnackBarBehavior.floating,
    backgroundColor: T.ink.withValues(alpha: 0.92),
    duration: const Duration(milliseconds: 1600),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    margin: const EdgeInsets.fromLTRB(60, 0, 60, 90),
  ));
}

/// Brand logo tile (`MedLogo`).
class MedLogo extends StatelessWidget {
  final double size;
  const MedLogo({super.key, this.size = 58});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: MedTokens.logoGradient,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [BoxShadow(color: const Color(0xFF12A594).withValues(alpha: 0.35), blurRadius: 28, offset: const Offset(0, 12))],
      ),
      child: CustomPaint(painter: _LogoPainter()),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 48;
    canvas.scale(s);
    canvas.drawCircle(const Offset(37, 11), 5, Paint()..color = const Color(0xF2FFB37A));
    canvas.drawPath(
        SvgPath.parse('M24 38.5 12.6 27.7a7.6 7.6 0 0 1 10.7-10.8l.7.7.7-.7a7.6 7.6 0 0 1 10.7 10.8z'), Paint()..color = Colors.white);
    final p = Paint()
      ..color = const Color(0xFF12A594)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(24, 21.5), const Offset(24, 30), p);
    canvas.drawLine(const Offset(19.8, 25.7), const Offset(28.2, 25.7), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
