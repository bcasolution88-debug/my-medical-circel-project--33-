import 'package:flutter/material.dart';
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

/// Soft "illustration" tile (teal / aqua / mint / apricot) with faint
/// medical motif — ported from `med/medArt.jsx` Placeholder.
class MedPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final String seed;
  final double radius;
  final bool circle;
  final String? imageAsset;

  const MedPlaceholder({
    super.key,
    this.width,
    this.height,
    required this.seed,
    this.radius = 10,
    this.circle = false,
    this.imageAsset,
  });

  @override
  Widget build(BuildContext context) {
    final k = hashOf(seed);
    final pal = _placeholderPals[k % _placeholderPals.length];
    final motif = MedIcons.placeholderMotifs[k % MedIcons.placeholderMotifs.length];
    final shape = circle
        ? const CircleBorder()
        : RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));

    return SizedBox(
      width: width,
      height: height,
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: LayoutBuilder(builder: (context, c) {
          final h = c.maxHeight.isFinite ? c.maxHeight : 100.0;
          final w = c.maxWidth.isFinite ? c.maxWidth : h;
          final big = (h * 0.42).clamp(18.0, 72.0);
          if (imageAsset != null) {
            return Image.asset(imageAsset!, fit: BoxFit.cover);
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: pal,
                  ),
                ),
              ),
              Positioned(
                right: -w * 0.12,
                top: -h * 0.18,
                child: Container(
                  width: w * 0.62,
                  height: w * 0.62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                ),
              ),
              Positioned(
                left: -w * 0.10,
                bottom: -h * 0.22,
                child: Container(
                  width: w * 0.48,
                  height: w * 0.48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
              ),
              Center(
                child: Opacity(
                  opacity: 0.55,
                  child: MedIcon(motif, size: big, color: Colors.white, stroke: 1.8),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
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

/// Pastel circle with deep-tone initial.
class MedAvatar extends StatelessWidget {
  final double size;
  final String seed;
  final String? label;
  final Color? ring;

  const MedAvatar({
    super.key,
    this.size = 36,
    required this.seed,
    this.label,
    this.ring,
  });

  @override
  Widget build(BuildContext context) {
    final pal = _avatarPals[hashOf(seed) % _avatarPals.length];
    final text = (label ?? seed).trim();
    final initial = text.isEmpty ? '?' : text.substring(0, 1).toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: pal[0],
        border: ring != null ? Border.all(color: ring!, width: 2) : null,
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: pal[1],
          fontWeight: FontWeight.w800,
          fontSize: size * 0.42,
          height: 1,
        ),
      ),
    );
  }
}

/// Overlapping avatars row (same as prototype LikerAvatars).
class LikerAvatars extends StatelessWidget {
  final List<String> likers;
  final double size;
  final int max;
  const LikerAvatars({super.key, required this.likers, this.size = 22, this.max = 6});

  @override
  Widget build(BuildContext context) {
    if (likers.isEmpty) return const SizedBox.shrink();
    final shown = likers.take(max).toList();
    final overlap = size * 0.36;
    final children = <Widget>[];
    for (int i = 0; i < shown.length; i++) {
      children.add(Positioned(
        left: i * (size - overlap),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: MedTheme.surface,
          ),
          padding: const EdgeInsets.all(1.5),
          child: MedAvatar(size: size, seed: shown[i], label: shown[i]),
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
          decoration: BoxDecoration(
            color: MedTheme.divider,
            borderRadius: BorderRadius.circular(size),
            border: Border.all(color: MedTheme.surface, width: 1.5),
          ),
          child: Text('+${likers.length - max}',
              style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700, color: MedTheme.inkMuted)),
        ),
      ));
    }
    final count = shown.length + (likers.length > max ? 1 : 0);
    return SizedBox(
      width: count * (size - overlap) + overlap + 3,
      height: size + 3,
      child: Stack(children: children),
    );
  }
}

/// Section header: 17/700 title + "全部 ⊞" action.
class SectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onAction;
  final String? actionLabel;
  final MedIconData actionIcon;
  final EdgeInsets padding;

  const SectionTitle({
    super.key,
    required this.title,
    this.onAction,
    this.actionLabel = '全部',
    this.actionIcon = MedIcons.grid,
    this.padding = const EdgeInsets.fromLTRB(18, 18, 18, 10),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700, color: MedTheme.ink)),
          if (onAction != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onAction,
              child: Row(
                children: [
                  if (actionLabel != null)
                    Text(actionLabel!,
                        style: const TextStyle(fontSize: 13, color: MedTheme.inkSubtle)),
                  if (actionLabel != null) const SizedBox(width: 4),
                  MedIcon(actionIcon, size: actionLabel == null ? 20 : 12,
                      color: actionLabel == null ? MedTheme.ink : MedTheme.inkSubtle),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// White pill with ‹ back and ⌂ home buttons (top-left of sub-pages).
class NavPill extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onHome;
  const NavPill({super.key, this.onBack, this.onHome});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: MedTheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: MedTheme.divider),
        boxShadow: MedTheme.shadowSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onBack ?? () => Navigator.of(context).maybePop(),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: MedIcon(MedIcons.chevronLeft, size: 18, color: MedTheme.ink),
            ),
          ),
          Container(width: 1, height: 18, color: MedTheme.divider),
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onHome ?? () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: MedIcon(MedIcons.home, size: 18, color: MedTheme.ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sub-page header: NavPill + centred title.
class SubHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const SubHeader({super.key, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(55);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: MedTheme.surface,
        border: Border(bottom: BorderSide(color: MedTheme.divider)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 34,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600, color: MedTheme.ink)),
              const Align(alignment: Alignment.centerLeft, child: NavPill()),
            ],
          ),
        ),
      ),
    );
  }
}

/// Red unread badge.
class RedBadge extends StatelessWidget {
  final int count;
  final double size;
  final Color borderColor;
  const RedBadge({super.key, required this.count, this.size = 18, this.borderColor = MedTheme.bg});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      height: size,
      constraints: BoxConstraints(minWidth: size),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: MedTheme.danger,
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: TextStyle(color: Colors.white, fontSize: size * 0.58, fontWeight: FontWeight.w700, height: 1),
      ),
    );
  }
}

/// Toast helper.
void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message, textAlign: TextAlign.center),
    behavior: SnackBarBehavior.floating,
    backgroundColor: MedTheme.ink.withValues(alpha: 0.9),
    duration: const Duration(milliseconds: 1600),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    margin: const EdgeInsets.fromLTRB(60, 0, 60, 90),
  ));
}
