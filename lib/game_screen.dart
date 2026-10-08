import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

/// Tennis - drag along the baseline, time your swings, real tennis scoring.
class TennisScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;

  const TennisScreen({super.key, required this.players, required this.callbacks});

  @override
  State<TennisScreen> createState() => _TennisScreenState();
}

class _TennisScreenState extends State<TennisScreen> {
  final _rnd = Random();
  Timer? _timer;

  // ball (fractional court coords: x 0..1, y 0..1 top->bottom)
  double bx = 0.5, by = 0.5, vx = 0, vy = 0, speed = 0.55;
  double px = 0.5, ox = 0.5; // paddle x positions
  int lastHitter = 0; // 0 = bottom player, 1 = top player

  String phase = 'serve'; // serve | rally | point
  String banner = '';
  bool over = false;

  // scoring
  final pts = [0, 0];
  final games = [0, 0];
  final tb = [0, 0];
  bool tiebreak = false;
  int server = 0;

  static const _names = ['0', '15', '30', '40'];

  @override
  void initState() {
    super.initState();
    widget.callbacks.setActivePlayer(0);
    _timer = Timer.periodic(const Duration(milliseconds: 16), _tick);
    WidgetsBinding.instance.addPostFrameCallback((_) => _newPoint());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick(Timer t) {
    if (!mounted || over || phase != 'rally') return;
    if (ModalRoute.of(context)?.isCurrent != true) return; // frozen under dialogs
    const dt = 0.016;
    setState(() {
      bx += vx * dt;
      by += vy * dt;
      // side walls
      if (bx < 0.02) { bx = 0.02; vx = -vx; }
      if (bx > 0.98) { bx = 0.98; vx = -vx; }
      // bot (top) AI movement
      if (widget.players[1].isBot && vy < 0) {
        final target = bx.clamp(0.06, 0.94);
        final d = target - ox;
        ox += d.clamp(-0.55 * dt, 0.55 * dt);
      }
      // bot line contact
      if (by <= 0.10 && vy < 0) _topHit();
      // out sideways
      if (bx < -0.06 || bx > 1.06) {
        _point(1 - lastHitter);
        return;
      }
      // past baselines
      if (by < -0.06) { _point(0); return; }
      if (by > 1.06) { _point(1); return; }
    });
  }

  void _topHit() {
    final isBot = widget.players[1].isBot;
    final d = (bx - ox).abs();
    if (isBot) {
      if (d < 0.10 && _rnd.nextDouble() > 0.12) {
        _strike(1, (bx - ox) * 2.5);
      } // else: whiff, ball sails past
    }
    // human top player hits via court tap (_tryHit(1)); do nothing automatically
  }

  /// side: 0 = bottom player, 1 = top player
  void _tryHit(int side) {
    if (over || phase != 'rally') return;
    if (widget.players[side].isBot) return;
    final movingToward = side == 0 ? vy > 0 : vy < 0;
    if (!movingToward) return;
    final inWindow = side == 0 ? (by > 0.74 && by < 1.0) : (by < 0.26 && by > 0.0);
    if (!inWindow) return;
    final paddleX = side == 0 ? px : ox;
    final d = (bx - paddleX).abs();
    if (d < 0.055) {
      Sfx.tap();
      _strike(side, (bx - paddleX) * 4.0); // sweet spot rocket
    } else if (d < 0.11) {
      Sfx.click();
      if (_rnd.nextDouble() < 0.25) {
        _strike(side, (bx < 0.5 ? -1 : 1) * 0.85); // shanked wide!
      } else {
        _strike(side, (bx - paddleX) * 2.0);
      }
    }
    // else: total whiff, no contact
  }

  void _strike(int side, double aimX) {
    lastHitter = side;
    speed = min(speed * 1.03, 1.05);
    vx = aimX.clamp(-0.6, 0.6);
    vy = (side == 0 ? -1 : 1) * speed;
    by = side == 0 ? 0.88 : 0.12;
  }

  void _serve() {
    if (over || phase != 'serve') return;
    Sfx.tap();
    bx = 0.5;
    by = server == 0 ? 0.86 : 0.14;
    vx = (_rnd.nextDouble() - 0.5) * 0.3;
    speed = 0.55;
    vy = (server == 0 ? -1 : 1) * speed;
    lastHitter = server;
    setState(() {
      phase = 'rally';
      banner = '';
    });
    if (widget.players[server].isBot) {
      // bot already "served" via _serve; nothing extra needed
    }
  }

  void _newPoint() {
    if (over || !mounted) return;
    setState(() {
      phase = 'serve';
      banner = '';
      bx = 0.5;
      by = server == 0 ? 0.86 : 0.14;
      vx = 0; vy = 0;
    });
    widget.callbacks.setActivePlayer(server);
    if (widget.players[server].isBot) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted || over || phase != 'serve') return;
        _serve();
      });
    }
  }

  void _point(int w) {
    if (over || phase != 'rally') return;
    setState(() => phase = 'point');
    if (w == 0) {
      Sfx.win();
    } else {
      Sfx.lose();
    }
    if (tiebreak) {
      tb[w]++;
      setState(() => banner = '${widget.players[w].name} takes the point!');
      if (tb[w] >= 7 && tb[w] - tb[1 - w] >= 2) {
        _winSet(w);
        return;
      }
    } else {
      pts[w]++;
      if (pts[w] >= 4 && pts[w] - pts[1 - w] >= 2) {
        _winGame(w);
        return;
      }
      setState(() => banner = '${widget.players[w].name} wins the point!');
    }
    Future.delayed(const Duration(milliseconds: 1400), _newPoint);
  }

  void _winGame(int w) {
    games[w]++;
    pts[0] = 0; pts[1] = 0;
    server = 1 - server;
    widget.players[0].score = games[0];
    widget.players[1].score = games[1];
    widget.callbacks.refreshHud();
    Sfx.win();
    if (games[w] >= 4 && games[w] - games[1 - w] >= 2) {
      _winSet(w);
      return;
    }
    if (games[0] == 3 && games[1] == 3) {
      setState(() {
        tiebreak = true;
        banner = 'Tiebreak! First to 7. 🔥';
        phase = 'point';
      });
    } else {
      setState(() {
        banner = '${widget.players[w].name} takes the game! 🎾';
        phase = 'point';
      });
    }
    Future.delayed(const Duration(milliseconds: 1500), _newPoint);
  }

  void _winSet(int w) {
    setState(() => over = true);
    final p = widget.players[w];
    widget.callbacks.finish(
      winner: p,
      headline: '${p.name} wins the set! 🏆',
      subline: tiebreak
          ? 'Tiebreak thriller: ${tb[0]}-${tb[1]}. What a match!'
          : 'Set score ${games[0]}-${games[1]}. Champion stuff. 🎾',
    );
  }

  String get _scoreLine {
    if (tiebreak) return 'Tiebreak ${tb[0]}–${tb[1]}';
    if (pts[0] >= 3 && pts[1] >= 3) {
      final d = pts[0] - pts[1];
      if (d == 0) return 'Deuce';
      return 'Ad ${widget.players[d > 0 ? 0 : 1].name}';
    }
    return '${_names[pts[0]]} – ${_names[pts[1]]}';
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Text(_scoreLine,
              style: TextStyle(color: t.text, fontSize: 22, fontWeight: FontWeight.w900)),
          Text('Games  ${games[0]} – ${games[1]}${tiebreak ? '  •  tiebreak' : ''}',
              style: TextStyle(color: t.muted, fontSize: 13)),
          const SizedBox(height: 6),
          if (banner.isNotEmpty)
            Text(banner,
                style: TextStyle(color: t.accent, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Expanded(child: _court(t)),
          const SizedBox(height: 10),
          if (phase == 'serve' && !over)
            widget.players[server].isBot
                ? Text('${widget.players[server].name} to serve…',
                    style: TextStyle(color: t.muted, fontSize: 14))
                : WajihaButton(
                    label: 'Serve', emoji: '🎾', primary: true, onTap: _serve),
          if (phase == 'rally' && !widget.players[0].isBot)
            WajihaButton(label: 'HIT!', emoji: '🎾', primary: true, onTap: () => _tryHit(0)),
          const SizedBox(height: 4),
          if (!widget.players[0].isBot)
            Text('Drag to move • tap court or HIT to swing',
                style: TextStyle(color: t.muted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _court(GameTheme t) {
    return LayoutBuilder(
      builder: (ctx, c) {
        final w = c.maxWidth, h = c.maxHeight;
        return GestureDetector(
          onHorizontalDragUpdate: (d) {
            final lx = d.localPosition.dx / w;
            setState(() {
              if (d.localPosition.dy > h * 0.5) {
                if (!widget.players[0].isBot) px = lx.clamp(0.06, 0.94);
              } else {
                if (!widget.players[1].isBot) ox = lx.clamp(0.06, 0.94);
              }
            });
          },
          onTapDown: (d) {
            final dy = d.localPosition.dy / h;
            if (dy > 0.55) {
              _tryHit(0);
            } else if (dy < 0.45) {
              _tryHit(1);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: t.radius,
              border: Border.all(color: t.primary.withValues(alpha: 0.3), width: 2),
            ),
            child: Stack(
              children: [
                // net
                Positioned(
                  left: 10, right: 10, top: h * 0.5 - 1,
                  child: Container(height: 2, color: t.muted.withValues(alpha: 0.6)),
                ),
                // service lines
                Positioned(
                  left: 10, right: 10, top: h * 0.28 - 1,
                  child: Container(height: 1, color: t.muted.withValues(alpha: 0.25)),
                ),
                Positioned(
                  left: 10, right: 10, top: h * 0.72 - 1,
                  child: Container(height: 1, color: t.muted.withValues(alpha: 0.25)),
                ),
                // paddles
                Positioned(
                  left: ox * w - 30, top: h * 0.10 - 8,
                  child: Container(
                    width: 60, height: 16,
                    decoration: BoxDecoration(
                      color: widget.players[1].color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Positioned(
                  left: px * w - 30, top: h * 0.90 - 8,
                  child: Container(
                    width: 60, height: 16,
                    decoration: BoxDecoration(
                      color: widget.players[0].color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                // ball
                Positioned(
                  left: bx * w - 13, top: by * h - 13,
                  child: const Text('🎾', style: TextStyle(fontSize: 26)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
