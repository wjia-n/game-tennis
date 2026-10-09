import 'dart:math';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import '../engine/tennis_engine.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/court_themes.dart';
import '../theme/tennis_style.dart';

/// Match screen: per-side player strips, scoreboard, narration banner, the
/// physical court (custom-painted), drag-to-move, tap-to-swing.
///
/// The engine owns ALL state and phases; this widget only renders and forwards
/// input. Every AI action is visible: the bot's paddle tracks the ball, its
/// serves toss a real ball, and narration names what's happening.
class GameScreen extends StatefulWidget {
  final TennisAudio audio;
  final TennisSettings settings;
  final TennisEngine engine;
  final VoidCallback onExit;

  const GameScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.engine,
    required this.onExit,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  TennisEngine get _e => widget.engine;
  CourtThemeDef get _t => CourtThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  bool _overShown = false;
  bool _reviewAsked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.audio.startGameMusic();
    _e.onEvent = _onEvent;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _e.onEvent = null;
    _e.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Backgrounded mid-rally: freeze the engine; on return the watchdog
    // re-arms any lost phase timer so the match resumes cleanly.
    if (state == AppLifecycleState.paused) {
      _e.setPaused(true);
    } else if (state == AppLifecycleState.resumed && !_e.over) {
      _e.setPaused(false);
    }
  }

  void _onEvent(TennisEvent e) {
    final a = widget.audio;
    switch (e) {
      case TennisEvent.serve:
        a.serve();
      case TennisEvent.hit:
        a.racketHit();
      case TennisEvent.bounce:
        a.ballBounce();
      case TennisEvent.pointWon:
        a.cheer();
      case TennisEvent.pointLost:
        a.gasp();
      case TennisEvent.gameWon:
        a.cheer();
      case TennisEvent.out:
        a.gasp();
      case TennisEvent.invalid:
        a.invalid();
      case TennisEvent.humanWon:
        a.win();
        _onMatchOver(humanWon: true);
      case TennisEvent.botWon:
        a.lose();
        _onMatchOver(humanWon: false);
    }
  }

  Future<void> _onMatchOver({required bool humanWon}) async {
    await widget.settings.recordMatch(
      humanWon: humanWon,
      rallyShots: _e.longestRally,
    );
    if (!mounted || _overShown) return;
    _overShown = true;
    widget.audio.click();
    // Sensible review moment: right after a finished match the human won.
    // Graceful when not from Play — never a fake dialog.
    if (humanWon && !_reviewAsked) {
      _reviewAsked = true;
      _requestReview();
    }
    if (!mounted) return;
    final w = _e.winner;
    final wName = w == null ? 'Nobody' : _e.players[w].name;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: _t.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: _t.accent, width: 2),
        ),
        title: Text(
          w == null
              ? 'Match over'
              : (humanWon ? '🏆 $wName wins the set!' : '$wName wins the set'),
          style: Tennis.display(22, theme: _t),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Final: ${_e.games[0]} – ${_e.games[1]}'
          '${_e.tiebreak ? '  (tiebreak ${_e.tb[0]}–${_e.tb[1]})' : ''}\n'
          'Longest rally: ${_e.longestRally} shots',
          style: Tennis.body(15, theme: _t),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              widget.audio.click();
              Navigator.of(context).pop();
              widget.onExit();
            },
            child: Text('Menu', style: Tennis.label(15, theme: _t)),
          ),
          TennisButton(
            label: 'Play again',
            emoji: '🎾',
            primary: true,
            width: 170,
            theme: _t,
            onTap: () {
              widget.audio.gameStart();
              Navigator.of(context).pop();
              setState(() {
                _overShown = false;
                _e.restart();
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _requestReview() async {
    final review = InAppReview.instance;
    try {
      if (await review.isAvailable()) {
        await review.requestReview();
      }
    } catch (_) {
      // Review UI unavailable on this device/build: stay silent, no fake UI.
    }
  }

  void _pauseMenu() {
    widget.audio.click();
    _e.setPaused(true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ListenableBuilder(
        listenable: widget.settings,
        builder: (_, _) => AlertDialog(
          backgroundColor: _t.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: _t.accent, width: 2),
          ),
          title: Text('Paused', style: Tennis.display(22, theme: _t)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PauseToggle(
                theme: _t,
                label: 'Music',
                value: widget.settings.musicOn,
                onChanged: (v) {
                  widget.settings.setMusic(v);
                  widget.audio.configure(
                    musicOn: v,
                    sfxOn: widget.settings.sfxOn,
                    volume: widget.settings.volume,
                  );
                  if (v) {
                    widget.audio.startGameMusic();
                  } else {
                    widget.audio.stopMusic();
                  }
                },
              ),
              _PauseToggle(
                theme: _t,
                label: 'Sound FX',
                value: widget.settings.sfxOn,
                onChanged: (v) {
                  widget.settings.setSfx(v);
                  widget.audio.configure(
                    musicOn: widget.settings.musicOn,
                    sfxOn: v,
                    volume: widget.settings.volume,
                  );
                },
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                widget.audio.click();
                Navigator.of(context).pop();
                widget.onExit();
              },
              child: Text('Quit', style: Tennis.label(15, theme: _t)),
            ),
            TextButton(
              onPressed: () {
                widget.audio.gameStart();
                Navigator.of(context).pop();
                _e.restart();
                _e.setPaused(false);
              },
              child: Text('Restart', style: Tennis.label(15, theme: _t)),
            ),
            TennisButton(
              label: 'Resume',
              primary: true,
              width: 130,
              theme: _t,
              onTap: () {
                widget.audio.click();
                Navigator.of(context).pop();
                _e.setPaused(false);
              },
            ),
          ],
        ),
      ),
    ).then((_) {
      // If the dialog was dismissed any other way, unpause.
      if (_e.paused && !_e.over) _e.setPaused(false);
    });
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
            listenable: _e,
            builder: (_, _) => Column(
              children: [
                _topBar(t),
                _PlayerStrip(theme: t, engine: _e, side: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      Text(_e.pointScoreLine(),
                          style: Tennis.display(24, theme: t)),
                      Text(_e.gamesLine(),
                          style: Tennis.body(13, theme: t, color: t.muted)),
                      const SizedBox(height: 2),
                      if (_e.banner.isNotEmpty)
                        Text(_e.banner,
                            style: Tennis.body(15,
                                theme: t, color: t.accentLight),
                            textAlign: TextAlign.center),
                    ],
                  ),
                ),
                Expanded(
                    child: _CourtView(
                  engine: _e,
                  theme: t,
                  audio: widget.audio,
                  racketStyle: widget.settings.racketStyle,
                  ballStyle: widget.settings.ballStyle,
                )),
                _PlayerStrip(theme: t, engine: _e, side: 0),
                _actionRow(t),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar(CourtThemeDef t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: t.accentLight),
            onPressed: () {
              widget.audio.click();
              widget.onExit();
            },
          ),
          Expanded(
            child: Text('🎾 Tennis',
                style: Tennis.label(15, theme: t),
                textAlign: TextAlign.center),
          ),
          IconButton(
            icon: Icon(Icons.pause, color: t.accentLight),
            onPressed: _pauseMenu,
          ),
        ],
      ),
    );
  }

  /// Serve / HIT / hint row under the bottom strip.
  Widget _actionRow(CourtThemeDef t) {
    final e = _e;
    final humanServerTurn =
        e.phase == MatchPhase.serveReady && !e.servingSideIsBot && !e.over;
    final hittingSide = e.activeSide;
    final canHit = e.phase == MatchPhase.rally &&
        !e.players[hittingSide].isBot &&
        !e.over;
    return SizedBox(
      height: 64,
      child: Center(
        child: humanServerTurn
            ? TennisButton(
                label: 'SERVE',
                emoji: '🎾',
                primary: true,
                theme: t,
                onTap: () {
                  widget.audio.click();
                  e.beginServe();
                },
              )
            : canHit
                ? TennisButton(
                    label: 'HIT!',
                    emoji: '🎾',
                    primary: true,
                    theme: t,
                    onTap: () => e.hitAttempt(hittingSide),
                  )
                : Text(
                    e.phase == MatchPhase.serveReady && e.servingSideIsBot
                        ? '${e.serverPlayer.name} is serving…'
                        : e.phase == MatchPhase.rally
                            ? 'Drag to move • tap your half or HIT to swing'
                            : '',
                    style: Tennis.body(13, theme: t, color: t.muted),
                    textAlign: TextAlign.center,
                  ),
      ),
    );
  }
}

class _PauseToggle extends StatelessWidget {
  final CourtThemeDef theme;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _PauseToggle({
    required this.theme,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child:
              Text(label, style: Tennis.body(16, theme: theme)),
        ),
        Switch(
          value: value,
          activeThumbColor: theme.accent,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Per-side player strip: name, color dot, mode/difficulty tag, and a live
/// status (SERVING / TRACKING / waiting). The active side is highlighted —
/// every AI turn is visible right here.
class _PlayerStrip extends StatelessWidget {
  final CourtThemeDef theme;
  final TennisEngine engine;
  final int side;
  const _PlayerStrip(
      {required this.theme, required this.engine, required this.side});

  @override
  Widget build(BuildContext context) {
    final p = engine.players[side];
    final isActive = engine.activeSide == side && !engine.over;
    String status;
    if (engine.over) {
      status = '';
    } else if (engine.phase == MatchPhase.serveReady && engine.server == side) {
      status = p.isBot ? '● serving…' : '● your serve';
    } else if (engine.phase == MatchPhase.serving && engine.server == side) {
      status = '● SERVING';
    } else if (engine.phase == MatchPhase.rally && engine.activeSide == side) {
      status = p.isBot ? '◉ tracking…' : '◉ your ball';
    } else {
      status = '';
    }
    final tag = p.isBot
        ? 'CPU · ${p.difficulty.name.toUpperCase()}'
        : 'YOU';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isActive
            ? theme.accent.withValues(alpha: 0.22)
            : Colors.black.withValues(alpha: 0.25),
        border: Border.all(
          color: isActive ? theme.accentLight : theme.accent.withValues(alpha: 0.3),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.color,
              border: Border.all(color: Colors.white70, width: 1.5),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(p.name,
                style: Tennis.body(15, theme: theme),
                overflow: TextOverflow.ellipsis),
          ),
          if (status.isNotEmpty)
            Text(status,
                style: Tennis.label(11, theme: theme)),
          const SizedBox(width: 8),
          Text(tag, style: Tennis.body(11, theme: theme, color: theme.muted)),
        ],
      ),
    );
  }
}

/// The court: drag to slide your player, tap your half to swing.
/// Painted custom: real court surface, lines, net, racket players, ball.
class _CourtView extends StatelessWidget {
  final TennisEngine engine;
  final CourtThemeDef theme;
  final TennisAudio audio;
  final int racketStyle;
  final int ballStyle;
  const _CourtView({
    required this.engine,
    required this.theme,
    required this.audio,
    required this.racketStyle,
    required this.ballStyle,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, c) {
        final w = c.maxWidth, h = c.maxHeight;
        return GestureDetector(
          onHorizontalDragUpdate: (d) {
            final lx = (d.localPosition.dx / w).clamp(0.0, 1.0);
            // Map screen x to court x.
            final cx = _screenToCourtX(lx, w);
            if (d.localPosition.dy > h * 0.5) {
              engine.setPaddle(0, cx);
            } else {
              engine.setPaddle(1, cx);
            }
          },
          onTapDown: (d) {
            final dy = d.localPosition.dy / h;
            audio.click();
            if (dy > 0.5) {
              engine.hitAttempt(0);
            } else {
              engine.hitAttempt(1);
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  offset: const Offset(0, 8),
                  blurRadius: 20,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: CustomPaint(
              painter: _CourtPainter(
                engine: engine,
                theme: theme,
                racketStyle: racketStyle,
                ballStyle: ballStyle,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        );
      },
    );
  }

  double _screenToCourtX(double lx, double w) {
    // Court rect: horizontal margins 8% of width.
    const m = 0.08;
    return ((lx - m) / (1 - 2 * m)).clamp(0.0, 1.0);
  }
}

class _CourtPainter extends CustomPainter {
  final TennisEngine engine;
  final CourtThemeDef theme;
  final int racketStyle;
  final int ballStyle;

  _CourtPainter({
    required this.engine,
    required this.theme,
    required this.racketStyle,
    required this.ballStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    double cx(double x) => w * (0.08 + x * 0.84);
    double cy(double y) => h * (0.04 + y * 0.92);

    // Surround.
    final surroundPaint = Paint()..color = theme.surround;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), surroundPaint);

    // Court surface.
    final courtRect = Rect.fromLTRB(cx(0), cy(0), cx(1), cy(1));
    canvas.drawRect(courtRect, Paint()..color = theme.court);

    // Service boxes alternate shade for physical depth.
    final boxPaint = Paint()..color = theme.courtDark;
    canvas.drawRect(
        Rect.fromLTRB(cx(0), cy(0), cx(0.5), cy(0.5)), boxPaint);
    canvas.drawRect(
        Rect.fromLTRB(cx(0.5), cy(0.5), cx(1), cy(1)), boxPaint);

    // Lines.
    final linePaint = Paint()
      ..color = theme.line
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    // Outer.
    canvas.drawRect(courtRect, linePaint);
    // Service lines + center marks.
    canvas.drawLine(
        Offset(cx(0), cy(0.28)), Offset(cx(1), cy(0.28)), linePaint);
    canvas.drawLine(
        Offset(cx(0), cy(0.72)), Offset(cx(1), cy(0.72)), linePaint);
    canvas.drawLine(
        Offset(cx(0.5), cy(0.28)), Offset(cx(0.5), cy(0.5)), linePaint);
    canvas.drawLine(
        Offset(cx(0.5), cy(0.5)), Offset(cx(0.5), cy(0.72)), linePaint);

    // Net band with posts and a soft shadow.
    final netY = cy(netLine);
    canvas.drawRect(
      Rect.fromLTRB(cx(0) - 6, netY + 3, cx(1) + 6, netY + 9),
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );
    canvas.drawRect(
      Rect.fromLTRB(cx(0) - 6, netY - 4, cx(1) + 6, netY + 4),
      Paint()..color = theme.net,
    );
    canvas.drawLine(
      Offset(cx(0) - 6, netY - 4),
      Offset(cx(1) + 6, netY - 4),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..strokeWidth = 2,
    );
    for (final postX in [cx(0) - 6, cx(1) + 6]) {
      canvas.drawRect(
        Rect.fromCenter(center: Offset(postX, netY), width: 7, height: 26),
        Paint()..color = theme.net,
      );
    }

    // Players as rackets at the baselines.
    _drawRacket(canvas, cx(engine.px[1]), cy(topLine), true);
    _drawRacket(canvas, cx(engine.px[0]), cy(bottomLine), false);

    // Ball (with toss lift during the serve animation).
    if (engine.ballVisible) {
      var ballY = cy(engine.by);
      if (engine.phase == MatchPhase.serving) {
        ballY -= sin(pi * engine.serveT.clamp(0.0, 1.0)) * h * 0.09;
      }
      final bx = cx(engine.bx);
      final r = w * 0.028;
      final ballBody =
          BallStyles.bodies[ballStyle.clamp(0, BallStyles.bodies.length - 1)];
      final ballSeam =
          BallStyles.seams[ballStyle.clamp(0, BallStyles.seams.length - 1)];
      // Shadow.
      canvas.drawOval(
        Rect.fromCenter(center: Offset(bx + 3, ballY + r + 6), width: r * 2.1, height: r * 0.8),
        Paint()..color = Colors.black.withValues(alpha: 0.3),
      );
      // Felt body with a highlight for roundness.
      canvas.drawCircle(Offset(bx, ballY), r, Paint()..color = ballBody);
      canvas.drawCircle(
          Offset(bx - r * 0.3, ballY - r * 0.35), r * 0.55,
          Paint()..color = Colors.white.withValues(alpha: 0.45));
      // Curved seams.
      final seam = Paint()
        ..color = ballSeam
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawArc(Rect.fromCircle(center: Offset(bx, ballY), radius: r * 0.7),
          -0.6, 1.4, false, seam);
      canvas.drawArc(Rect.fromCircle(center: Offset(bx, ballY), radius: r * 0.7),
          pi - 0.6, 1.4, false, seam);
    }
  }

  void _drawRacket(Canvas canvas, double x, double y, bool top) {
    final frame = RacketStyles.frames[racketStyle.clamp(0, RacketStyles.frames.length - 1)];
    final strings = RacketStyles.strings[racketStyle.clamp(0, RacketStyles.strings.length - 1)];
    final grip = RacketStyles.grips[racketStyle.clamp(0, RacketStyles.grips.length - 1)];
    final headR = 26.0;
    final headC = Offset(x, top ? y + headR * 0.7 : y - headR * 0.7);
    // Shadow.
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(x + 3, (top ? y + 2 : y - 2) + 4),
          width: headR * 2,
          height: 12),
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );
    // Handle.
    final handleTop = top ? headC.dy + headR * 0.8 : headC.dy - headR * 0.8;
    final handleBot = top ? handleTop + 34 : handleTop - 34;
    canvas.drawRect(
      Rect.fromCenter(
          center: Offset(x, (handleTop + handleBot) / 2), width: 12, height: 36),
      Paint()..color = grip,
    );
    // Head: frame ring + string bed.
    canvas.drawCircle(headC, headR, Paint()..color = frame);
    canvas.drawCircle(headC, headR * 0.72, Paint()..color = strings);
    // String grid.
    final grid = Paint()
      ..color = frame.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (int i = -2; i <= 2; i++) {
      final o = i * headR * 0.28;
      canvas.drawLine(Offset(headC.dx + o, headC.dy - headR * 0.7),
          Offset(headC.dx + o, headC.dy + headR * 0.7), grid);
      canvas.drawLine(Offset(headC.dx - headR * 0.7, headC.dy + o),
          Offset(headC.dx + headR * 0.7, headC.dy + o), grid);
    }
  }

  @override
  bool shouldRepaint(covariant _CourtPainter old) => true;
}
