import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/court_themes.dart';

/// Persisted settings + stats for Tennis. Survives app restarts.
///
/// Stores: audio toggles, player names (2 slots, ONE JSON string — Android's
/// SharedPreferences stores StringLists as an unordered StringSet, so a
/// StringList would scramble name order), theme/appearance choices (incl.
/// custom court colors), mode setup (vs AI difficulty / pass-and-play), Pro
/// unlock state, and lifetime stats.
class TennisSettings extends ChangeNotifier {
  static const _kMusic = 'tennis_music_on';
  static const _kSfx = 'tennis_sfx_on';
  static const _kVolume = 'tennis_volume';
  static const _kMode = 'tennis_mode'; // 0 = vs computer, 1 = pass-and-play
  static const _kDifficulty = 'tennis_bot_difficulty'; // 0 easy, 1 med, 2 hard
  static const _kLegacyNames = 'tennis_player_names'; // legacy unordered key
  /// Order-safe player-name storage: a single JSON string.
  static const _kNamesJson = 'tennis_player_names_json';
  static const _kTheme = 'tennis_theme_id';
  static const _kRacket = 'tennis_racket_style';
  static const _kBall = 'tennis_ball_style';
  static const _kWins = 'tennis_wins';
  static const _kMatches = 'tennis_matches_played';
  static const _kLongestRally = 'tennis_longest_rally';
  static const _kIsPro = 'tennis_is_pro';
  static const _kCustomPrefix = 'tennis_custom_';

  static const defaultNames = ['You', 'Nova'];

  /// Encode the 2 player names as one JSON string (order-preserving).
  static String encodePlayerNames(List<String> names) => jsonEncode(names);

  static String _cleanName(int i, Object? v) {
    final s = v is String ? v.trim() : '';
    return s.isEmpty ? defaultNames[i] : s;
  }

  /// Decode persisted names; falls back to defaults on missing/corrupt data.
  static List<String> decodePlayerNames(String? raw) {
    if (raw == null) return List.of(defaultNames);
    try {
      final d = jsonDecode(raw);
      if (d is List && d.length == 2) {
        return [for (int i = 0; i < 2; i++) _cleanName(i, d[i])];
      }
    } catch (_) {}
    return List.of(defaultNames);
  }

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;
  int mode = 0; // 0 = vs computer, 1 = pass-and-play
  int difficulty = 1; // medium default
  List<String> playerNames = List.of(defaultNames);
  String themeId = 'wimbledon';
  int racketStyle = 0;
  int ballStyle = 0;
  int wins = 0;
  int matchesPlayed = 0;
  int longestRally = 0; // most shots in one rally
  bool isPro = false;

  /// Custom theme colors (ARGB ints). Defaults mirror Wimbledon Grass.
  Map<String, int> customColors = Map.of(_defaultCustomColors);

  static const Map<String, int> _defaultCustomColors = {
    'court': 0xFF4C8A3D,
    'courtDark': 0xFF3F7533,
    'surround': 0xFF2E5A26,
    'line': 0xFFF5F2E8,
    'bg': 0xFF1E3320,
    'card': 0xFF2A4530,
    'accent': 0xFFD4AF37,
    'pc0': 0xFFF5F2E8,
    'pc1': 0xFF7A1F2B,
  };

  /// Builds the user-designed custom theme from stored colors.
  CourtThemeDef get customTheme {
    Color c(String k) => Color(customColors[k] ?? 0xFF000000);
    return CourtThemeDef(
      id: 'custom',
      name: 'My Court',
      court: c('court'),
      courtDark: c('courtDark'),
      surround: c('surround'),
      line: c('line'),
      net: const Color(0xFF22301E),
      bg: c('bg'),
      card: c('card'),
      accent: c('accent'),
      accentLight: c('accent'),
      text: const Color(0xFFF5F2E8),
      muted: const Color(0xFFB9C7AE),
      playerColors: [c('pc0'), c('pc1')],
      playerColorNames: const ['One', 'Two'],
    );
  }

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    volume = p.getDouble(_kVolume) ?? 0.8;
    mode = (p.getInt(_kMode) ?? 0).clamp(0, 1);
    difficulty = (p.getInt(_kDifficulty) ?? 1).clamp(0, 2);
    // Player names: prefer the order-safe JSON key. Fall back to the legacy
    // StringList key once (one-time migration); it may already be scrambled
    // on Android, which is exactly the bug this replaces.
    final namesRaw = p.getString(_kNamesJson);
    if (namesRaw != null) {
      playerNames = decodePlayerNames(namesRaw);
    } else {
      final legacy = p.getStringList(_kLegacyNames);
      playerNames = (legacy != null && legacy.length == 2)
          ? [for (int i = 0; i < 2; i++) _cleanName(i, legacy[i])]
          : List.of(defaultNames);
    }
    themeId = p.getString(_kTheme) ?? 'wimbledon';
    racketStyle = (p.getInt(_kRacket) ?? 0).clamp(0, RacketStyles.names.length - 1);
    ballStyle = (p.getInt(_kBall) ?? 0).clamp(0, BallStyles.names.length - 1);
    wins = p.getInt(_kWins) ?? 0;
    matchesPlayed = p.getInt(_kMatches) ?? 0;
    longestRally = p.getInt(_kLongestRally) ?? 0;
    isPro = p.getBool(_kIsPro) ?? false;
    for (final k in _defaultCustomColors.keys) {
      customColors[k] =
          p.getInt('$_kCustomPrefix$k') ?? _defaultCustomColors[k]!;
    }
    _enforceFreeLimits(silent: true);
    notifyListeners();
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setBool(_kMusic, musicOn);
    await p.setBool(_kSfx, sfxOn);
    await p.setDouble(_kVolume, volume);
    await p.setInt(_kMode, mode);
    await p.setInt(_kDifficulty, difficulty);
    await p.setString(_kNamesJson, encodePlayerNames(playerNames));
    await p.remove(_kLegacyNames); // drop the legacy unordered key for good
    await p.setString(_kTheme, themeId);
    await p.setInt(_kRacket, racketStyle);
    await p.setInt(_kBall, ballStyle);
    await p.setInt(_kWins, wins);
    await p.setInt(_kMatches, matchesPlayed);
    await p.setInt(_kLongestRally, longestRally);
    await p.setBool(_kIsPro, isPro);
    for (final e in customColors.entries) {
      await p.setInt('$_kCustomPrefix${e.key}', e.value);
    }
  }

  /// Free-tier limits: clamp pro-only choices back when not Pro.
  /// Called after load and whenever Pro status could have changed.
  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    if (themeId == 'custom' || CourtThemes.isProTheme(themeId)) {
      themeId = 'wimbledon';
      changed = true;
    }
    if (RacketStyles.isPro(racketStyle)) {
      racketStyle = 0;
      changed = true;
    }
    if (BallStyles.isPro(ballStyle)) {
      ballStyle = 0;
      changed = true;
    }
    if (difficulty > 1) {
      difficulty = 1;
      changed = true;
    }
    if (changed && !silent) {
      notifyListeners();
      _save();
    }
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _save();
  }

  Future<void> setCustomColor(String key, int argb) async {
    if (!isPro) return; // custom theme creator is a Pro feature
    if (!_defaultCustomColors.containsKey(key)) return;
    customColors[key] = argb;
    notifyListeners();
    await _save();
  }

  Future<void> resetCustomColors() async {
    customColors = Map.of(_defaultCustomColors);
    notifyListeners();
    await _save();
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  Future<void> setMode(int v) async {
    mode = v.clamp(0, 1);
    notifyListeners();
    await _save();
  }

  Future<void> setDifficulty(int v) async {
    v = v.clamp(0, 2);
    // Hard mode is a Pro feature.
    if (!isPro && v > 1) return;
    difficulty = v;
    notifyListeners();
    await _save();
  }

  Future<void> setPlayerName(int index, String name) async {
    if (index < 0 || index > 1) return;
    final clean = name.trim();
    playerNames[index] = clean.isEmpty ? defaultNames[index] : clean;
    notifyListeners();
    await _save();
  }

  Future<void> setTheme(String id) async {
    // Pro-only themes (incl. the custom theme creator) require Pro;
    // silently ignore otherwise (UI shows lock).
    if (!isPro && (id == 'custom' || CourtThemes.isProTheme(id))) return;
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setRacketStyle(int v) async {
    v = v.clamp(0, RacketStyles.names.length - 1);
    if (!isPro && RacketStyles.isPro(v)) return;
    racketStyle = v;
    notifyListeners();
    await _save();
  }

  Future<void> setBallStyle(int v) async {
    v = v.clamp(0, BallStyles.names.length - 1);
    if (!isPro && BallStyles.isPro(v)) return;
    ballStyle = v;
    notifyListeners();
    await _save();
  }

  /// Record a finished match. [humanWon] true if a human player won.
  /// [rallyShots] updates the longest-rally stat.
  Future<void> recordMatch({required bool humanWon, int rallyShots = 0}) async {
    matchesPlayed++;
    if (humanWon) wins++;
    if (rallyShots > longestRally) longestRally = rallyShots;
    notifyListeners();
    await _save();
  }
}
