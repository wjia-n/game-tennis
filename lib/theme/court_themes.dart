import 'package:flutter/material.dart';

/// Court theme, racket-style and ball-style catalogs for Tennis.
///
/// Art direction: real physical courts — grass, clay, hard courts — rendered
/// with realistic lighting and material feel. No neon, no cyberpunk, no
/// glowing AI aesthetics. Variety comes from real court surfaces, surround
/// colors, line paint, and club-style UI accents.
class CourtThemeDef {
  final String id;
  final String name;
  final Color court; // playing surface
  final Color courtDark; // service-box alternate shade
  final Color surround; // outer run-off area
  final Color line; // painted lines
  final Color net; // net band
  final Color bg; // app background
  final Color card; // card surfaces
  final Color accent; // club gold / brass
  final Color accentLight;
  final Color text;
  final Color muted;
  final List<Color> playerColors;
  final List<String> playerColorNames;

  const CourtThemeDef({
    required this.id,
    required this.name,
    required this.court,
    required this.courtDark,
    required this.surround,
    required this.line,
    required this.net,
    required this.bg,
    required this.card,
    required this.accent,
    required this.accentLight,
    required this.text,
    required this.muted,
    required this.playerColors,
    required this.playerColorNames,
  });
}

class CourtThemes {
  /// First 4 are the FREE starter courts. The rest are PRO.
  static const List<String> freeThemeIds = [
    'wimbledon',
    'roland',
    'usopen',
    'ausopen',
  ];

  static const List<CourtThemeDef> all = [
    CourtThemeDef(
      id: 'wimbledon',
      name: 'Wimbledon Grass',
      court: Color(0xFF4C8A3D),
      courtDark: Color(0xFF3F7533),
      surround: Color(0xFF2E5A26),
      line: Color(0xFFF5F2E8),
      net: Color(0xFF22301E),
      bg: Color(0xFF1E3320),
      card: Color(0xFF2A4530),
      accent: Color(0xFFD4AF37),
      accentLight: Color(0xFFF0D77A),
      text: Color(0xFFF5F2E8),
      muted: Color(0xFFB9C7AE),
      playerColors: [Color(0xFFF5F2E8), Color(0xFF7A1F2B)],
      playerColorNames: ['All-White', 'Strawberry'],
    ),
    CourtThemeDef(
      id: 'roland',
      name: 'Roland Clay',
      court: Color(0xFFB4562F),
      courtDark: Color(0xFF9C4826),
      surround: Color(0xFF6E3319),
      line: Color(0xFFF7EFE2),
      net: Color(0xFF3A2114),
      bg: Color(0xFF331E12),
      card: Color(0xFF4A2C1B),
      accent: Color(0xFFE8B04B),
      accentLight: Color(0xFFF7D08A),
      text: Color(0xFFF7EFE2),
      muted: Color(0xFFD9BFA6),
      playerColors: [Color(0xFFF7EFE2), Color(0xFF2E4A7A)],
      playerColorNames: ['Chalk', 'Musketeer'],
    ),
    CourtThemeDef(
      id: 'usopen',
      name: 'New York Hard',
      court: Color(0xFF3A6EA5),
      courtDark: Color(0xFF2F5C8A),
      surround: Color(0xFF3E7A44),
      line: Color(0xFFFFFFFF),
      net: Color(0xFF1C2E40),
      bg: Color(0xFF1B2A3A),
      card: Color(0xFF26405A),
      accent: Color(0xFFF2C14E),
      accentLight: Color(0xFFF9DC8E),
      text: Color(0xFFF4F7FA),
      muted: Color(0xFFA9BED4),
      playerColors: [Color(0xFFF2C14E), Color(0xFFC0392B)],
      playerColorNames: ['Flushing', 'Empire'],
    ),
    CourtThemeDef(
      id: 'ausopen',
      name: 'Melbourne Hard',
      court: Color(0xFF2E5FB8),
      courtDark: Color(0xFF274F9C),
      surround: Color(0xFF2A8A7E),
      line: Color(0xFFFFFFFF),
      net: Color(0xFF1A2A44),
      bg: Color(0xFF152A38),
      card: Color(0xFF1F3D52),
      accent: Color(0xFFFFD54F),
      accentLight: Color(0xFFFFE58A),
      text: Color(0xFFF4F8FA),
      muted: Color(0xFFA9C4D4),
      playerColors: [Color(0xFFFFD54F), Color(0xFF00838F)],
      playerColorNames: ['Summer', 'Yarra'],
    ),
    CourtThemeDef(
      id: 'desert',
      name: 'Desert Dusk',
      court: Color(0xFFC47A3D),
      courtDark: Color(0xFFA86632),
      surround: Color(0xFF7A4A24),
      line: Color(0xFFFBF3E4),
      net: Color(0xFF3A2412),
      bg: Color(0xFF33200F),
      card: Color(0xFF4A2F18),
      accent: Color(0xFFE8B04B),
      accentLight: Color(0xFFF7D08A),
      text: Color(0xFFFBF3E4),
      muted: Color(0xFFD9BFA0),
      playerColors: [Color(0xFFFBF3E4), Color(0xFF7A1F2B)],
      playerColorNames: ['Mirage', 'Saguaro'],
    ),
    CourtThemeDef(
      id: 'indoor',
      name: 'Indoor Carpet',
      court: Color(0xFF2F6E68),
      courtDark: Color(0xFF265C57),
      surround: Color(0xFF1A3A37),
      line: Color(0xFFF2EFE4),
      net: Color(0xFF122624),
      bg: Color(0xFF12211F),
      card: Color(0xFF1E3835),
      accent: Color(0xFFD4AF37),
      accentLight: Color(0xFFF0D77A),
      text: Color(0xFFF2EFE4),
      muted: Color(0xFFA9C2B4),
      playerColors: [Color(0xFFF2EFE4), Color(0xFFC47A3D)],
      playerColorNames: ['Arena', 'Carpet'],
    ),
    CourtThemeDef(
      id: 'night',
      name: 'Night Session',
      court: Color(0xFF2A3A5E),
      courtDark: Color(0xFF22304E),
      surround: Color(0xFF141D33),
      line: Color(0xFFF0F4FA),
      net: Color(0xFF0C1220),
      bg: Color(0xFF0C1424),
      card: Color(0xFF182540),
      accent: Color(0xFFF2C14E),
      accentLight: Color(0xFFF9DC8E),
      text: Color(0xFFF0F4FA),
      muted: Color(0xFF9AA9C4),
      playerColors: [Color(0xFFF2C14E), Color(0xFF5DADE2)],
      playerColorNames: ['Floodlight', 'Midnight'],
    ),
    CourtThemeDef(
      id: 'coast',
      name: 'Sea Breeze',
      court: Color(0xFF3FA7A0),
      courtDark: Color(0xFF358C86),
      surround: Color(0xFF22605B),
      line: Color(0xFFFBF6EA),
      net: Color(0xFF143B38),
      bg: Color(0xFF14302D),
      card: Color(0xFF1F4A45),
      accent: Color(0xFFF2C14E),
      accentLight: Color(0xFFF9DC8E),
      text: Color(0xFFFBF6EA),
      muted: Color(0xFFAFD4C8),
      playerColors: [Color(0xFFFBF6EA), Color(0xFFC0392B)],
      playerColorNames: ['Foam', 'Coral'],
    ),
    CourtThemeDef(
      id: 'brick',
      name: 'Crimson Brick',
      court: Color(0xFFA03A2E),
      courtDark: Color(0xFF863026),
      surround: Color(0xFF5A1F18),
      line: Color(0xFFF7EFE2),
      net: Color(0xFF331310),
      bg: Color(0xFF2E1512),
      card: Color(0xFF46221C),
      accent: Color(0xFFE8B04B),
      accentLight: Color(0xFFF7D08A),
      text: Color(0xFFF7EFE2),
      muted: Color(0xFFD4AFA2),
      playerColors: [Color(0xFFF7EFE2), Color(0xFF2E4A7A)],
      playerColorNames: ['Chalk', 'Iron'],
    ),
    CourtThemeDef(
      id: 'forest',
      name: 'Forest Lawn',
      court: Color(0xFF3D7A34),
      courtDark: Color(0xFF32662B),
      surround: Color(0xFF22451E),
      line: Color(0xFFF5F2E8),
      net: Color(0xFF182A15),
      bg: Color(0xFF182A16),
      card: Color(0xFF24401F),
      accent: Color(0xFFD4AF37),
      accentLight: Color(0xFFF0D77A),
      text: Color(0xFFF5F2E8),
      muted: Color(0xFFB3C7A6),
      playerColors: [Color(0xFFF5F2E8), Color(0xFFD4AF37)],
      playerColorNames: ['Dew', 'Trophy'],
    ),
    CourtThemeDef(
      id: 'sand',
      name: 'Beach Sand',
      court: Color(0xFFE0C284),
      courtDark: Color(0xFFCDAE70),
      surround: Color(0xFF8A7448),
      line: Color(0xFF3A2E1C),
      net: Color(0xFF4A3A24),
      bg: Color(0xFF4A3A24),
      card: Color(0xFF6B5736),
      accent: Color(0xFF7A1F2B),
      accentLight: Color(0xFFB04856),
      text: Color(0xFF2E2414),
      muted: Color(0xFF6B5C40),
      playerColors: [Color(0xFF7A1F2B), Color(0xFF2E5A44)],
      playerColorNames: ['Sunset', 'Palm'],
    ),
    CourtThemeDef(
      id: 'chalk',
      name: 'Chalk White',
      court: Color(0xFFEFE8D8),
      courtDark: Color(0xFFDCD2BC),
      surround: Color(0xFF9A8F76),
      line: Color(0xFF4A4234),
      net: Color(0xFF3A3428),
      bg: Color(0xFF3A3428),
      card: Color(0xFF54493A),
      accent: Color(0xFF8A6A1E),
      accentLight: Color(0xFFC49A3A),
      text: Color(0xFF2E2A20),
      muted: Color(0xFF6B6250),
      playerColors: [Color(0xFF7A1F2B), Color(0xFF2E5A88)],
      playerColorNames: ['Crimson', 'Cobalt'],
    ),
    CourtThemeDef(
      id: 'copper',
      name: 'Copper Canyon',
      court: Color(0xFFB0653A),
      courtDark: Color(0xFF94542F),
      surround: Color(0xFF63371E),
      line: Color(0xFFFAF0DC),
      net: Color(0xFF38200F),
      bg: Color(0xFF2E1B0E),
      card: Color(0xFF452A16),
      accent: Color(0xFFD4AF37),
      accentLight: Color(0xFFF0D77A),
      text: Color(0xFFFAF0DC),
      muted: Color(0xFFD4B89A),
      playerColors: [Color(0xFFFAF0DC), Color(0xFF2A6E5E)],
      playerColorNames: ['Sandstone', 'Turquoise'],
    ),
    CourtThemeDef(
      id: 'royal',
      name: 'Royal Navy',
      court: Color(0xFF2E4A7A),
      courtDark: Color(0xFF263E66),
      surround: Color(0xFF182845),
      line: Color(0xFFF2EFE4),
      net: Color(0xFF0E1830),
      bg: Color(0xFF0E1830),
      card: Color(0xFF1A2C52),
      accent: Color(0xFFD4AF37),
      accentLight: Color(0xFFF0D77A),
      text: Color(0xFFF2EFE4),
      muted: Color(0xFF9AA9C4),
      playerColors: [Color(0xFFD4AF37), Color(0xFFC0392B)],
      playerColorNames: ['Regal', 'Guard'],
    ),
  ];

  static CourtThemeDef byId(String id, {CourtThemeDef? custom}) {
    if (id == 'custom') return custom ?? all.first;
    return all.firstWhere((t) => t.id == id, orElse: () => all.first);
  }

  static bool isProTheme(String id) =>
      !freeThemeIds.contains(id) && id != 'custom';
}

/// Racket styles: frame / strings / grip colors. 0-3 = FREE, 4+ = PRO.
class RacketStyles {
  static const names = [
    'Classic Wood',
    'Graphite Pro',
    'Crimson Ace',
    'Royal Blue',
    'Forest Drive',
    'Champagne',
    'Ivory Smash',
    'Sunset Volley',
  ];
  static const descriptions = [
    'Warm laminated ash, natural gut',
    'Matte black carbon, pro strings',
    'Deep red frame, white gut',
    'Navy frame, gold trim',
    'Pine green, leather grip',
    'Brushed gold, ivory strings',
    'Cream frame, brass pins',
    'Burnt orange, dark gut',
  ];
  static const frames = [
    Color(0xFF8A5A2E),
    Color(0xFF2A2A30),
    Color(0xFFA31621),
    Color(0xFF1D3A7A),
    Color(0xFF2E5A34),
    Color(0xFFC9A227),
    Color(0xFFEFE3C8),
    Color(0xFFC4642A),
  ];
  static const strings = [
    Color(0xFFF5EFE0),
    Color(0xFFD8DCE4),
    Color(0xFFF5EFE0),
    Color(0xFFD4AF37),
    Color(0xFFF5EFE0),
    Color(0xFFFBF6E9),
    Color(0xFF8A6A1E),
    Color(0xFF3A2A1E),
  ];
  static const grips = [
    Color(0xFF5A3A1E),
    Color(0xFF1A1A1E),
    Color(0xFF5A3A1E),
    Color(0xFF1A2A4A),
    Color(0xFF3A2A1A),
    Color(0xFF6E5514),
    Color(0xFF8A6A42),
    Color(0xFF5A2A14),
  ];

  static const freeCount = 4;
  static bool isPro(int index) => index >= freeCount;
}

/// Ball styles: felt body + seam colors. 0-4 = FREE, 5+ = PRO.
class BallStyles {
  static const names = [
    'Classic Felt',
    'Championship White',
    'Clay Orange',
    'Ocean Teal',
    'Rose Pink',
    'Midnight',
    'Golden',
    'Vintage Cream',
  ];
  static const bodies = [
    Color(0xFFD8DE3A),
    Color(0xFFF5F2E8),
    Color(0xFFE07B2E),
    Color(0xFF2EA7A0),
    Color(0xFFE88AA0),
    Color(0xFF2A3A5E),
    Color(0xFFE8B83A),
    Color(0xFFEFE0BC),
  ];
  static const seams = [
    Color(0xFFF5F2E8),
    Color(0xFFB9B4A4),
    Color(0xFFFBF3E4),
    Color(0xFFFBF6EA),
    Color(0xFFFBF0F4),
    Color(0xFFF2C14E),
    Color(0xFFFBF3D8),
    Color(0xFF8A6A42),
  ];

  static const freeCount = 5;
  static bool isPro(int index) => index >= freeCount;
}
