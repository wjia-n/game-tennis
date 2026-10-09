import 'package:flutter/material.dart';
import 'court_themes.dart';

/// Shared club-style text + widget helpers for Tennis.
/// Physical, readable, editorial — no neon, no dashboard chrome.
class Tennis {
  static TextStyle display(double size, {required CourtThemeDef theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
        color: theme.text,
        fontFamily: 'Georgia',
        shadows: const [
          Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 4),
        ],
      );

  static TextStyle label(double size, {required CourtThemeDef theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
        color: theme.accentLight,
      );

  static TextStyle body(double size,
          {required CourtThemeDef theme, Color? color}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: color ?? theme.text,
        height: 1.35,
      );
}

/// Solid club backdrop with a soft vignette — subtle, never flashy.
class ClubBackdrop extends StatelessWidget {
  final CourtThemeDef theme;
  final Widget child;
  const ClubBackdrop({super.key, required this.theme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.4,
          colors: [
            theme.bg,
            Color.lerp(theme.bg, Colors.black, 0.35)!,
          ],
        ),
      ),
      child: child,
    );
  }
}

/// Big friendly club button.
class TennisButton extends StatelessWidget {
  final String label;
  final String? emoji;
  final VoidCallback onTap;
  final bool primary;
  final double width;
  final CourtThemeDef theme;

  const TennisButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.theme,
    this.emoji,
    this.primary = false,
    this.width = 220,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: primary ? theme.accent : Colors.black.withValues(alpha: 0.35),
          border: Border.all(
            color: primary ? theme.accentLight : theme.accent.withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              offset: const Offset(0, 4),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: primary ? const Color(0xFF2A1E08) : theme.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section card used across menu/settings/pro screens.
class ClubCard extends StatelessWidget {
  final CourtThemeDef theme;
  final Widget child;
  final EdgeInsets padding;
  const ClubCard({
    super.key,
    required this.theme,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.card.withValues(alpha: 0.92),
        border: Border.all(color: theme.accent.withValues(alpha: 0.45), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: child,
    );
  }
}
