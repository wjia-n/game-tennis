import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:share_plus/share_plus.dart';
import 'package:in_app_review/in_app_review.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/court_themes.dart';
import '../theme/tennis_style.dart';
import 'pro_screen.dart';

/// Settings — sound, players, appearance, support, about.
class SettingsScreen extends StatefulWidget {
  final TennisAudio audio;
  final TennisSettings settings;
  final StoreService store;
  const SettingsScreen(
      {super.key,
      required this.audio,
      required this.settings,
      required this.store});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  CourtThemeDef get _t => CourtThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  @override
  void initState() {
    super.initState();
    widget.store.lastThanks.addListener(_onThanks);
  }

  void _onThanks() {
    final msg = widget.store.lastThanks.value;
    if (msg == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: Tennis.body(15, theme: _t)),
        backgroundColor: _t.card,
        behavior: SnackBarBehavior.floating,
      ),
    );
    widget.store.lastThanks.value = null;
  }

  @override
  void dispose() {
    widget.store.lastThanks.removeListener(_onThanks);
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    final audio = widget.audio;
    return ClubBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: t.accentLight),
            onPressed: () {
              audio.click();
              Navigator.of(context).pop();
            },
          ),
          title: Text('Settings', style: Tennis.display(22, theme: t)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle('Sound', t),
                  ClubCard(
                    theme: t,
                    child: Column(
                      children: [
                        _ToggleRow(
                          theme: t,
                          label: 'Music',
                          value: s.musicOn,
                          onChanged: (v) async {
                            audio.click();
                            await s.setMusic(v);
                            audio.configure(
                                musicOn: s.musicOn,
                                sfxOn: s.sfxOn,
                                volume: s.volume);
                            if (v) {
                              audio.startMenuMusic();
                            } else {
                              audio.stopMusic();
                            }
                          },
                        ),
                        _ToggleRow(
                          theme: t,
                          label: 'Sound effects',
                          value: s.sfxOn,
                          onChanged: (v) async {
                            audio.click();
                            await s.setSfx(v);
                            audio.configure(
                                musicOn: s.musicOn,
                                sfxOn: s.sfxOn,
                                volume: s.volume);
                          },
                        ),
                        Row(
                          children: [
                            Expanded(
                                child: Text('Volume',
                                    style: Tennis.body(15, theme: t))),
                            Expanded(
                              flex: 2,
                              child: Slider(
                                value: s.volume,
                                activeColor: t.accent,
                                inactiveColor:
                                    t.accent.withValues(alpha: 0.3),
                                onChanged: (v) async {
                                  await s.setVolume(v);
                                  audio.configure(
                                      musicOn: s.musicOn,
                                      sfxOn: s.sfxOn,
                                      volume: s.volume);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionTitle('Players', t),
                  ClubCard(
                    theme: t,
                    child: Column(
                      children: [
                        _NameRow(
                          theme: t,
                          label: 'Bottom player',
                          initial: s.playerNames[0],
                          onChanged: (v) => s.setPlayerName(0, v),
                        ),
                        const SizedBox(height: 8),
                        _NameRow(
                          theme: t,
                          label: s.mode == 0 ? 'CPU opponent' : 'Top player',
                          initial: s.playerNames[1],
                          onChanged: (v) => s.setPlayerName(1, v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionTitle('Appearance', t),
                  ClubCard(
                    theme: t,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Court theme',
                            style: Tennis.body(16, theme: t)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final th in CourtThemes.all)
                              _MiniChip(
                                theme: t,
                                label:
                                    '${CourtThemes.isProTheme(th.id) && !s.isPro ? '🔒 ' : ''}${th.name}',
                                selected: s.themeId == th.id,
                                onTap: () async {
                                  audio.click();
                                  if (CourtThemes.isProTheme(th.id) &&
                                      !s.isPro) {
                                    await Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (_) => ProScreen(
                                                audio: audio,
                                                settings: s,
                                                store: widget.store)));
                                    return;
                                  }
                                  await s.setTheme(th.id);
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('Racket style',
                            style: Tennis.body(16, theme: t)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (int i = 0;
                                i < RacketStyles.names.length;
                                i++)
                              _MiniChip(
                                theme: t,
                                label:
                                    '${RacketStyles.isPro(i) && !s.isPro ? '🔒 ' : ''}${RacketStyles.names[i]}',
                                selected: s.racketStyle == i,
                                onTap: () async {
                                  audio.click();
                                  if (RacketStyles.isPro(i) && !s.isPro) {
                                    await Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (_) => ProScreen(
                                                audio: audio,
                                                settings: s,
                                                store: widget.store)));
                                    return;
                                  }
                                  await s.setRacketStyle(i);
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('Ball style',
                            style: Tennis.body(16, theme: t)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (int i = 0;
                                i < BallStyles.names.length;
                                i++)
                              _MiniChip(
                                theme: t,
                                label:
                                    '${BallStyles.isPro(i) && !s.isPro ? '🔒 ' : ''}${BallStyles.names[i]}',
                                selected: s.ballStyle == i,
                                onTap: () async {
                                  audio.click();
                                  if (BallStyles.isPro(i) && !s.isPro) {
                                    await Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (_) => ProScreen(
                                                audio: audio,
                                                settings: s,
                                                store: widget.store)));
                                    return;
                                  }
                                  await s.setBallStyle(i);
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionTitle('Support', t),
                  ClubCard(
                    theme: t,
                    child: Column(
                      children: [
                        Text(
                          'Tennis is 100% free. Tips keep new games coming!',
                          style: Tennis.body(14, theme: t),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Builder(builder: (_) {
                          final tips = [
                            widget.store.coffeeProduct,
                            widget.store.chocolateProduct,
                          ].whereType<ProductDetails>().toList();
                          if (!widget.store.storeReady) {
                            return Text(
                              widget.store.error ?? 'Loading…',
                              style: Tennis.body(13,
                                  theme: t, color: t.muted),
                              textAlign: TextAlign.center,
                            );
                          }
                          if (tips.isEmpty) {
                            return Text('Tips coming soon.',
                                style: Tennis.body(13,
                                    theme: t, color: t.muted));
                          }
                          return Wrap(
                            spacing: 10,
                            alignment: WrapAlignment.center,
                            children: [
                              for (final p in tips)
                                _MiniChip(
                                  theme: t,
                                  label: p.id == StoreService.chocolateId
                                      ? '🍫 ${p.price}'
                                      : '☕ ${p.price}',
                                  selected: false,
                                  onTap: () {
                                    audio.click();
                                    widget.store.buyTip(p);
                                  },
                                ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionTitle('About', t),
                  ClubCard(
                    theme: t,
                    child: Column(
                      children: [
                        _LinkRow(
                          theme: t,
                          icon: Icons.share,
                          label: 'Share Tennis',
                          onTap: () async {
                            audio.click();
                            // ignore: deprecated_member_use
                            await Share.share(
                                'Serve up some fun! Play Tennis with me: https://play.google.com/store/apps/details?id=com.gameswajiha.tennis');
                          },
                        ),
                        _LinkRow(
                          theme: t,
                          icon: Icons.star_rate,
                          label: 'Rate this app',
                          onTap: () async {
                            audio.click();
                            await _requestReview();
                          },
                        ),
                        _LinkRow(
                          theme: t,
                          icon: Icons.workspace_premium,
                          label: s.isPro ? 'PRO (active)' : 'Get PRO',
                          onTap: () async {
                            audio.click();
                            await Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => ProScreen(
                                        audio: audio,
                                        settings: s,
                                        store: widget.store)));
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('Credits: WAJIHA',
                              style: Tennis.label(11, theme: t)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _SectionTitle extends StatelessWidget {
  final String text;
  final CourtThemeDef theme;
  const _SectionTitle(this.text, this.theme);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: Tennis.label(13, theme: theme)),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final CourtThemeDef theme;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow(
      {required this.theme,
      required this.label,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: Tennis.body(15, theme: theme))),
        Switch(
          value: value,
          activeThumbColor: theme.accent,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Name field: saves on EVERY keystroke, commits on focus loss.
/// Names persist as one order-preserving JSON string.
class _NameRow extends StatefulWidget {
  final CourtThemeDef theme;
  final String label;
  final String initial;
  final ValueChanged<String> onChanged;
  const _NameRow(
      {required this.theme,
      required this.label,
      required this.initial,
      required this.onChanged});

  @override
  State<_NameRow> createState() => _NameRowState();
}

class _NameRowState extends State<_NameRow> {
  late final TextEditingController _c;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.initial);
    _focus = FocusNode();
    // Commit on focus loss (covers programmatic dismissal too).
    _focus.addListener(() {
      if (!_focus.hasFocus) widget.onChanged(_c.text);
    });
  }

  @override
  void didUpdateWidget(covariant _NameRow old) {
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
            // Save on every keystroke — never only on keyboard-done.
            onChanged: widget.onChanged,
            onSubmitted: (_) => _focus.unfocus(),
          ),
        ),
      ],
    );
  }
}

class _MiniChip extends StatelessWidget {
  final CourtThemeDef theme;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _MiniChip(
      {required this.theme,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        child: Text(label, style: Tennis.body(12, theme: theme)),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final CourtThemeDef theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _LinkRow(
      {required this.theme,
      required this.icon,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: theme.accentLight, size: 20),
            const SizedBox(width: 12),
            Expanded(
                child: Text(label, style: Tennis.body(15, theme: theme))),
            Icon(Icons.chevron_right, color: theme.muted),
          ],
        ),
      ),
    );
  }
}
