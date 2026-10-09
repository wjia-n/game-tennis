import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/tennis_engine.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/court_themes.dart';
import '../theme/tennis_style.dart';
import 'custom_theme_screen.dart';
import 'game_screen.dart';
import 'pro_screen.dart';
import 'settings_screen.dart';

/// Main menu — Court Club edition.
/// Logo, PLAY, mode setup (vs CPU difficulty / pass-and-play), player names,
/// court theme picker, racket & ball styles, stats, tip jar, settings.
class MenuScreen extends StatefulWidget {
  final TennisAudio audio;
  final TennisSettings settings;

  const MenuScreen({super.key, required this.audio, required this.settings});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final StoreService _store = StoreService();

  TennisSettings get _s => widget.settings;
  CourtThemeDef get _t =>
      CourtThemes.byId(_s.themeId, custom: _s.customTheme);

  @override
  void initState() {
    super.initState();
    widget.audio.startMenuMusic();
    _store.init().then((_) {
      if (mounted) setState(() {});
    });
    _store.proPurchased.addListener(_onPro);
    _store.lastThanks.addListener(_onThanks);
  }

  void _onPro() {
    if (_store.proPurchased.value && mounted) {
      _s.setPro(true);
      widget.audio.win();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PRO unlocked — enjoy everything!',
              style: Tennis.body(15, theme: _t)),
          backgroundColor: _t.card,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _store.proPurchased.value = false;
    }
  }

  void _onThanks() {
    final msg = _store.lastThanks.value;
    if (msg == null || !mounted) return;
    widget.audio.win();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: Tennis.body(15, theme: _t)),
        backgroundColor: _t.card,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _store.lastThanks.value = null;
  }

  @override
  void dispose() {
    _store.proPurchased.removeListener(_onPro);
    _store.lastThanks.removeListener(_onThanks);
    _store.dispose();
    super.dispose();
  }

  /// Real in-app review flow: the Play in-app review sheet when available,
  /// otherwise fall back to opening the store listing. No fake dialogs.
  Future<void> _requestReview() async {
    final review = InAppReview.instance;
    try {
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        await review.openStoreListing(appStoreId: null);
      }
    } catch (_) {
      // Review UI unavailable on this device/build: stay silent, no fake UI.
    }
  }

  void _play() {
    widget.audio.gameStart();
    final theme = _t;
    final vsCpu = _s.mode == 0;
    final players = [
      TennisPlayer(
        name: _s.playerNames[0],
        color: theme.playerColors[0],
        isBot: false,
      ),
      TennisPlayer(
        name: _s.playerNames[1],
        color: theme.playerColors[1],
        isBot: vsCpu,
        difficulty: BotDifficulty.values[_s.difficulty.clamp(0, 2)],
      ),
    ];
    final engine = TennisEngine(players: players);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          audio: widget.audio,
          settings: _s,
          engine: engine,
          onExit: () {
            widget.audio.startMenuMusic();
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return ClubBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _s,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!_s.isPro)
                        _MenuChip(
                          theme: t,
                          icon: Icons.workspace_premium,
                          label: 'PRO',
                          onTap: () {
                            widget.audio.click();
                            _openPro();
                          },
                        ),
                      _MenuChip(
                        theme: t,
                        icon: Icons.settings,
                        label: 'Settings',
                        onTap: () {
                          widget.audio.click();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SettingsScreen(
                                audio: widget.audio,
                                settings: _s,
                                store: _store,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: t.accent, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          offset: const Offset(0, 6),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset('assets/tennis_logo.png',
                        fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 10),
                  Text('Tennis', style: Tennis.display(44, theme: t)),
                  Text('Rally. Smash. Win the set.',
                      style: Tennis.body(14, theme: t, color: t.muted)),
                  const SizedBox(height: 16),
                  TennisButton(
                    label: 'PLAY',
                    emoji: '🎾',
                    primary: true,
                    width: 240,
                    theme: t,
                    onTap: _play,
                  ),
                  const SizedBox(height: 16),
                  _ModeCard(theme: t),
                  const SizedBox(height: 14),
                  _NamesCard(theme: t, settings: _s, audio: widget.audio),
                  const SizedBox(height: 14),
                  _ThemeCard(theme: t, settings: _s, audio: widget.audio,
                      onCustom: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CustomThemeScreen(
                          audio: widget.audio,
                          settings: _s,
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 14),
                  _StyleCard(theme: t, settings: _s, audio: widget.audio),
                  const SizedBox(height: 14),
                  _StatsCard(theme: t, settings: _s),
                  const SizedBox(height: 14),
                  _SupportCard(theme: t, store: _store),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MenuIcon(
                        theme: t,
                        icon: Icons.share,
                        label: 'Share',
                        onTap: () async {
                          widget.audio.click();
                          // ignore: deprecated_member_use
                          await Share.share(
                              'Serve up some fun! Play Tennis with me: https://play.google.com/store/apps/details?id=com.gameswajiha.tennis');
                        },
                      ),
                      const SizedBox(width: 22),
                      _MenuIcon(
                        theme: t,
                        icon: Icons.star_rate,
                        label: 'Rate',
                        onTap: () async {
                          widget.audio.click();
                          await _requestReview();
                        },
                      ),
                      const SizedBox(width: 22),
                      _MenuIcon(
                        theme: t,
                        icon: Icons.workspace_premium,
                        label: 'Pro',
                        onTap: () {
                          widget.audio.click();
                          _openPro();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text('Credits: WAJIHA',
                      style: Tennis.label(11, theme: t)),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openPro() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProScreen(
          audio: widget.audio,
          settings: _s,
          store: _store,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _MenuChip extends StatelessWidget {
  final CourtThemeDef theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuChip(
      {required this.theme,
      required this.icon,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.black.withValues(alpha: 0.3),
            border: Border.all(
                color: theme.accent.withValues(alpha: 0.5), width: 1.5),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: theme.accentLight),
              const SizedBox(width: 4),
              Text(label, style: Tennis.label(11, theme: theme)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuIcon extends StatelessWidget {
  final CourtThemeDef theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuIcon(
      {required this.theme,
      required this.icon,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.3),
              border: Border.all(
                  color: theme.accent.withValues(alpha: 0.6), width: 1.5),
            ),
            child: Icon(icon, color: theme.accentLight, size: 24),
          ),
          const SizedBox(height: 4),
          Text(label, style: Tennis.label(10, theme: theme)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Mode setup: vs computer (3 difficulties) or 2-player pass-and-play.
class _ModeCard extends StatelessWidget {
  final CourtThemeDef theme;
  const _ModeCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_MenuScreenState>()!;
    final s = state._s;
    final audio = state.widget.audio;
    return ClubCard(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GAME MODE', style: Tennis.label(12, theme: theme)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ModeButton(
                  theme: theme,
                  label: '🤖 Vs CPU',
                  selected: s.mode == 0,
                  onTap: () {
                    audio.click();
                    s.setMode(0);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ModeButton(
                  theme: theme,
                  label: '👥 2 Players',
                  selected: s.mode == 1,
                  onTap: () {
                    audio.click();
                    s.setMode(1);
                  },
                ),
              ),
            ],
          ),
          if (s.mode == 0) ...[
            const SizedBox(height: 10),
            Text('CPU DIFFICULTY', style: Tennis.label(12, theme: theme)),
            const SizedBox(height: 8),
            Row(
              children: [
                for (int i = 0; i < 3; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                      child: _DiffButton(
                        theme: theme,
                        label: ['Easy', 'Medium', 'Hard'][i],
                        locked: i == 2 && !s.isPro,
                        selected: s.difficulty == i,
                        onTap: () {
                          audio.click();
                          s.setDifficulty(i);
                        },
                      ),
                    ),
                  ),
              ],
            ),
            if (!s.isPro)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Hard mode is a PRO feature 🔒',
                    style: Tennis.body(12,
                        theme: theme, color: theme.muted)),
              ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                  'Pass-and-play on this device — bottom serves first, then swap sides each game.',
                  style:
                      Tennis.body(13, theme: theme, color: theme.muted)),
            ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final CourtThemeDef theme;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeButton(
      {required this.theme,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected
              ? theme.accent
              : Colors.black.withValues(alpha: 0.3),
          border: Border.all(
              color: selected
                  ? theme.accentLight
                  : theme.accent.withValues(alpha: 0.4),
              width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: selected ? const Color(0xFF2A1E08) : theme.text,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _DiffButton extends StatelessWidget {
  final CourtThemeDef theme;
  final String label;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;
  const _DiffButton(
      {required this.theme,
      required this.label,
      required this.selected,
      required this.locked,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: selected
              ? theme.accent
              : Colors.black.withValues(alpha: 0.3),
          border: Border.all(
              color: selected
                  ? theme.accentLight
                  : theme.accent.withValues(alpha: 0.4),
              width: 1.5),
        ),
        child: Text(
          locked ? '$label 🔒' : label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: selected ? const Color(0xFF2A1E08) : theme.text,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Renameable players (both seats), persisted as one JSON string.
class _NamesCard extends StatelessWidget {
  final CourtThemeDef theme;
  final TennisSettings settings;
  final TennisAudio audio;
  const _NamesCard(
      {required this.theme, required this.settings, required this.audio});

  @override
  Widget build(BuildContext context) {
    final vsCpu = settings.mode == 0;
    return ClubCard(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PLAYERS', style: Tennis.label(12, theme: theme)),
          const SizedBox(height: 10),
          _NameField(
            theme: theme,
            label: 'Bottom player',
            initial: settings.playerNames[0],
            onDone: (v) {
              audio.click();
              settings.setPlayerName(0, v);
            },
          ),
          const SizedBox(height: 8),
          _NameField(
            theme: theme,
            label: vsCpu ? 'CPU opponent' : 'Top player',
            initial: settings.playerNames[1],
            onDone: (v) {
              audio.click();
              settings.setPlayerName(1, v);
            },
          ),
        ],
      ),
    );
  }
}

class _NameField extends StatefulWidget {
  final CourtThemeDef theme;
  final String label;
  final String initial;
  final ValueChanged<String> onDone;
  const _NameField(
      {required this.theme,
      required this.label,
      required this.initial,
      required this.onDone});

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  late final TextEditingController _c;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.initial);
    _focus = FocusNode();
    // Commit on focus loss (covers programmatic dismissal too).
    _focus.addListener(() {
      if (!_focus.hasFocus) widget.onDone(_c.text);
    });
  }

  @override
  void didUpdateWidget(covariant _NameField old) {
    super.didUpdateWidget(old);
    if (old.initial != widget.initial && _c.text != widget.initial) {
      _c.text = widget.initial;
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(widget.label,
              style: Tennis.body(13,
                  theme: widget.theme, color: widget.theme.muted)),
        ),
        Expanded(
          child: TextField(
            controller: _c,
            focusNode: _focus,
            style: Tennis.body(15, theme: widget.theme),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: widget.theme.accent.withValues(alpha: 0.4)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: widget.theme.accentLight),
              ),
              fillColor: Colors.black.withValues(alpha: 0.25),
              filled: true,
            ),
            // Save on EVERY keystroke — never only on keyboard-done.
            onChanged: widget.onDone,
            onSubmitted: (_) => _focus.unfocus(),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
/// Court theme picker: 12+ real-court themes + custom creator (PRO).
class _ThemeCard extends StatelessWidget {
  final CourtThemeDef theme;
  final TennisSettings settings;
  final TennisAudio audio;
  final VoidCallback onCustom;
  const _ThemeCard(
      {required this.theme,
      required this.settings,
      required this.audio,
      required this.onCustom});

  @override
  Widget build(BuildContext context) {
    final items = [
      ...CourtThemes.all,
      if (settings.isPro) settings.customTheme,
    ];
    return ClubCard(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text('COURT THEMES',
                      style: Tennis.label(12, theme: theme))),
              GestureDetector(
                onTap: () {
                  audio.click();
                  onCustom();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: theme.accent.withValues(alpha: 0.6)),
                  ),
                  child: Text(
                      settings.isPro ? '🎨 My Court' : '🎨 My Court 🔒',
                      style: Tennis.label(11, theme: theme)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.15,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final t = items[i];
              final locked = !settings.isPro &&
                  (t.id == 'custom' || CourtThemes.isProTheme(t.id));
              final selected = settings.themeId == t.id;
              return GestureDetector(
                onTap: () {
                  audio.click();
                  if (t.id == 'custom') {
                    onCustom();
                    return;
                  }
                  settings.setTheme(t.id);
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: t.court,
                    border: Border.all(
                      color: selected
                          ? theme.accentLight
                          : Colors.black.withValues(alpha: 0.3),
                      width: selected ? 3 : 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(
                            locked ? '🔒' : t.name,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: t.text,
                              shadows: const [
                                Shadow(
                                    color: Colors.black54,
                                    offset: Offset(0, 1),
                                    blurRadius: 3),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Racket + ball style pickers.
class _StyleCard extends StatelessWidget {
  final CourtThemeDef theme;
  final TennisSettings settings;
  final TennisAudio audio;
  const _StyleCard(
      {required this.theme, required this.settings, required this.audio});

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RACKET STYLE', style: Tennis.label(12, theme: theme)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i < RacketStyles.names.length; i++)
                _StyleChip(
                  theme: theme,
                  label: RacketStyles.names[i],
                  swatch: RacketStyles.frames[i],
                  locked:
                      !settings.isPro && RacketStyles.isPro(i),
                  selected: settings.racketStyle == i,
                  onTap: () {
                    audio.click();
                    settings.setRacketStyle(i);
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text('BALL STYLE', style: Tennis.label(12, theme: theme)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i < BallStyles.names.length; i++)
                _StyleChip(
                  theme: theme,
                  label: BallStyles.names[i],
                  swatch: BallStyles.bodies[i],
                  locked: !settings.isPro && BallStyles.isPro(i),
                  selected: settings.ballStyle == i,
                  onTap: () {
                    audio.click();
                    settings.setBallStyle(i);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StyleChip extends StatelessWidget {
  final CourtThemeDef theme;
  final String label;
  final Color swatch;
  final bool locked;
  final bool selected;
  final VoidCallback onTap;
  const _StyleChip({
    required this.theme,
    required this.label,
    required this.swatch,
    required this.locked,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected
              ? theme.accent.withValues(alpha: 0.35)
              : Colors.black.withValues(alpha: 0.25),
          border: Border.all(
            color: selected
                ? theme.accentLight
                : theme.accent.withValues(alpha: 0.35),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: swatch,
                border: Border.all(color: Colors.white70, width: 1),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              locked ? '$label 🔒' : label,
              style: Tennis.body(12, theme: theme),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _StatsCard extends StatelessWidget {
  final CourtThemeDef theme;
  final TennisSettings settings;
  const _StatsCard({required this.theme, required this.settings});

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      theme: theme,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(theme: theme, value: '${settings.matchesPlayed}', label: 'MATCHES'),
          _Stat(theme: theme, value: '${settings.wins}', label: 'WON'),
          _Stat(
              theme: theme,
              value: '${settings.longestRally}',
              label: 'BEST RALLY'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final CourtThemeDef theme;
  final String value;
  final String label;
  const _Stat(
      {required this.theme, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Tennis.display(26, theme: theme)),
        Text(label, style: Tennis.label(10, theme: theme)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
/// Tip jar card on the menu (real store products only).
class _SupportCard extends StatelessWidget {
  final CourtThemeDef theme;
  final StoreService store;
  const _SupportCard({required this.theme, required this.store});

  @override
  Widget build(BuildContext context) {
    final tips = [
      store.coffeeProduct,
      store.chocolateProduct,
    ].whereType<ProductDetails>().toList();
    if (!store.storeReady || tips.isEmpty) return const SizedBox.shrink();
    return ClubCard(
      theme: theme,
      child: Column(
        children: [
          Text('☕ Tip the Maker', style: Tennis.label(13, theme: theme)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (final p in tips)
                GestureDetector(
                  onTap: () => store.buyTip(p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.black.withValues(alpha: 0.3),
                      border: Border.all(
                          color:
                              theme.accent.withValues(alpha: 0.6),
                          width: 1.5),
                    ),
                    child: Text(
                      '${p.id == StoreService.chocolateId ? '🍫' : '☕'} ${p.price}',
                      style: Tennis.label(13, theme: theme),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
