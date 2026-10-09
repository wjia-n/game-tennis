import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// Tennis match engine — owns ALL match state, phases, ball physics, AI and
/// timers. The UI only renders and forwards input. A watchdog recovers any
/// phase found without a live timer, so stuck states are impossible by
/// construction.
///
/// Court coordinates are fractional: x 0..1 (left..right), y 0..1 (top..bottom).
/// Side 0 = bottom player, side 1 = top player.

// ---------------------------------------------------------------- geometry
const double topLine = 0.10;
const double bottomLine = 0.90;
const double netLine = 0.50;
const double sideMargin = 0.06;

// ------------------------------------------------------------------ phases
/// Turn phases owned entirely by the engine. The UI only renders.
enum MatchPhase {
  serveReady, // ball parked; waiting for the server to serve
  serving, // visible ball-toss serve animation
  rally, // live ball
  pointSettling, // point decided; banner shows; next point is coming
  matchOver,
}

/// 0 = easy, 1 = medium, 2 = hard (RULES.md §11).
enum BotDifficulty { easy, medium, hard }

class TennisPlayer {
  String name;
  final Color color;
  final bool isBot;
  final BotDifficulty difficulty;

  TennisPlayer({
    required this.name,
    required this.color,
    this.isBot = false,
    this.difficulty = BotDifficulty.medium,
  });
}

enum TennisEvent {
  serve,
  hit,
  bounce,
  pointWon, // a human won the point
  pointLost, // a bot (or rival human) won the point
  gameWon,
  out,
  invalid,
  humanWon,
  botWon,
}

// ------------------------------------------------------------------- engine
class TennisEngine extends ChangeNotifier {
  final List<TennisPlayer> players;

  int server = 0;
  MatchPhase phase = MatchPhase.serveReady;

  // Ball.
  double bx = 0.5, by = bottomLine, vx = 0, vy = 0;
  bool ballVisible = true;
  double serveT = 0; // 0..1 toss animation during [serving]
  int lastHitter = 0;

  // Paddles (x positions; y is fixed at the baselines).
  final px = [0.5, 0.5];

  // Scoring (RULES.md §8): points 0/15/30/40, games to 4, tiebreak at 3-3.
  final pts = [0, 0];
  final games = [0, 0];
  final tb = [0, 0];
  bool tiebreak = false;
  int _tbServeCount = 0;

  bool over = false;
  int? winner;
  String banner = '';
  int rallyShots = 0; // shots in the current rally
  int longestRally = 0; // shots in the longest rally this match
  int pointCount = 0;

  // AI contact bookkeeping: decide once per ball approach.
  int _contactEpoch = 0;
  int _decidedEpoch = -1;
  bool _aiWillMiss = false;

  double _speed = 0.55;
  bool _crossedNet = false;

  final _rand = Random();
  Timer? _timer; // single phase-transition timer
  Timer? _physics; // 60fps ball/AI integration
  Timer? _watchdog; // stuck-state recovery
  bool _disposed = false;
  bool paused = false;

  static const _serveAnimMs = 850;
  static const _settleMs = 1700;
  static const _botServeDelayMs = 1200;

  /// UI hook for sounds / haptics. Set by the screen.
  void Function(TennisEvent event)? onEvent;

  TennisEngine({required this.players}) {
    _resetBallToServer();
    banner = _serveBanner();
    _physics = Timer.periodic(const Duration(milliseconds: 16), _tick);
    _watchdog = Timer.periodic(const Duration(seconds: 3), (_) => _recover());
    _afterPhase();
  }

  // ------------------------------------------------------------- accessors
  TennisPlayer get serverPlayer => players[server];
  bool get servingSideIsBot => players[server].isBot;

  /// Side the action is on: the server during serve phases, otherwise the
  /// side the ball is travelling toward.
  int get activeSide {
    if (phase == MatchPhase.serveReady || phase == MatchPhase.serving) {
      return server;
    }
    if (phase == MatchPhase.rally) return vy > 0 ? 0 : 1;
    return lastHitter;
  }

  String pointScoreLine() {
    if (tiebreak) return 'Tiebreak ${tb[0]}–${tb[1]}';
    if (pts[0] >= 3 && pts[1] >= 3) {
      final d = pts[0] - pts[1];
      if (d == 0) return 'Deuce';
      return 'Ad ${players[d > 0 ? 0 : 1].name}';
    }
    const names = ['0', '15', '30', '40'];
    return '${names[pts[0].clamp(0, 3)]} – ${names[pts[1].clamp(0, 3)]}';
  }

  String gamesLine() =>
      'Games  ${games[0]} – ${games[1]}${tiebreak ? '  •  tiebreak' : ''}';

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _physics?.cancel();
    _watchdog?.cancel();
    super.dispose();
  }

  void _arm(Duration d, void Function() fn) {
    if (_disposed || paused) return;
    _timer?.cancel();
    _timer = Timer(d, () {
      _timer = null;
      if (!_disposed && !paused) fn();
    });
  }

  /// Pause: freeze the phase timer and the physics loop. Resume re-arms.
  void setPaused(bool v) {
    if (paused == v || _disposed) return;
    paused = v;
    if (v) {
      _timer?.cancel();
      _timer = null;
    } else {
      _recover();
    }
    notifyListeners();
  }

  /// Watchdog: if the single phase timer ever dies without progress, recover.
  /// Makes stuck states impossible by construction. Respects [paused].
  void _recover() {
    if (_disposed || over || paused || _timer != null) return;
    switch (phase) {
      case MatchPhase.serveReady:
        if (servingSideIsBot) _beginServe();
      case MatchPhase.serving:
        _launchServe(); // toss animation lost: launch immediately
      case MatchPhase.rally:
        if (vx == 0 && vy == 0) {
          // Dead ball with no timer: re-launch from the last hitter.
          _strike(lastHitter, (_rand.nextDouble() - 0.5) * 0.4, 1.0);
        }
      case MatchPhase.pointSettling:
        _nextPoint();
      case MatchPhase.matchOver:
        break;
    }
  }

  /// Called whenever we enter serveReady: bots serve themselves.
  void _afterPhase() {
    if (over || phase != MatchPhase.serveReady) return;
    if (servingSideIsBot) {
      _arm(const Duration(milliseconds: _botServeDelayMs), _beginServe);
    }
  }

  // ------------------------------------------------------------- serve flow
  String _serveBanner() => '${serverPlayer.name} to serve…';

  void _resetBallToServer() {
    final sx = px[server];
    bx = sx.clamp(0.15, 0.85);
    by = server == 0 ? bottomLine : topLine;
    vx = 0;
    vy = 0;
    serveT = 0;
    ballVisible = true;
  }

  /// Human server taps SERVE. Guarded: correct phase, human server, not over.
  void beginServe() {
    if (over || phase != MatchPhase.serveReady || servingSideIsBot) {
      onEvent?.call(TennisEvent.invalid);
      return;
    }
    _beginServe();
  }

  void _beginServe() {
    if (over || phase != MatchPhase.serveReady) return;
    phase = MatchPhase.serving;
    serveT = 0;
    banner = '${serverPlayer.name} serves!';
    onEvent?.call(TennisEvent.serve);
    notifyListeners();
    _arm(const Duration(milliseconds: _serveAnimMs), _launchServe);
  }

  void _launchServe() {
    if (over || phase != MatchPhase.serving) return;
    final d = players[server].difficulty;
    _speed = switch (d) {
      BotDifficulty.easy => 0.50,
      BotDifficulty.medium => 0.58,
      BotDifficulty.hard => 0.66,
    };
    if (!servingSideIsBot) _speed = 0.58;
    // Serve from alternating deuce/ad side; aim at the receiver's box.
    final fromLeft = (pointCount % 2 == 0);
    final sx = fromLeft ? 0.32 : 0.68;
    px[server] = sx;
    bx = sx;
    by = server == 0 ? bottomLine : topLine;
    final target = 0.5 + (_rand.nextDouble() - 0.5) * 0.5;
    vx = ((target - bx) * 1.4).clamp(-0.45, 0.45);
    vy = (server == 0 ? -1 : 1) * _speed;
    lastHitter = server;
    rallyShots = 0;
    _contactEpoch++;
    _crossedNet = false;
    phase = MatchPhase.rally;
    onEvent?.call(TennisEvent.hit);
    notifyListeners();
  }

  // ------------------------------------------------------------------ input
  /// Slide a paddle. Human sides only; bots move themselves.
  void setPaddle(int side, double x) {
    if (over || players[side].isBot) return;
    px[side] = x.clamp(0.08, 0.92);
    if (phase == MatchPhase.serveReady && server == side) {
      // Server walks: keep the parked ball glued to them.
      _resetBallToServer();
    }
    notifyListeners();
  }

  /// Human swing attempt. Returns true if contact was made.
  bool hitAttempt(int side) {
    if (over || phase != MatchPhase.rally) {
      onEvent?.call(TennisEvent.invalid);
      return false;
    }
    if (players[side].isBot) return false;
    final toward = side == 0 ? vy > 0 : vy < 0;
    if (!toward) {
      onEvent?.call(TennisEvent.invalid);
      return false;
    }
    final inWindow =
        side == 0 ? (by > 0.70 && by <= 1.02) : (by < 0.30 && by >= -0.02);
    if (!inWindow) {
      onEvent?.call(TennisEvent.invalid);
      return false;
    }
    final d = (bx - px[side]).abs();
    if (d < 0.06) {
      // Sweet spot: fast, aimed away from the opponent.
      _strike(side, _aimAway(side, 0.45), 1.15);
      return true;
    } else if (d < 0.13) {
      if (_rand.nextDouble() < 0.22) {
        // Shanked wide!
        _strikeWide(side);
      } else {
        _strike(side, _aimAway(side, 0.28), 0.9);
      }
      return true;
    }
    onEvent?.call(TennisEvent.invalid);
    return false;
  }

  double _aimAway(int side, double mag) {
    final opp = px[1 - side];
    final dir = opp >= 0.5 ? -1.0 : 1.0;
    final jitter = (_rand.nextDouble() - 0.5) * 0.2;
    return (dir * mag + jitter).clamp(-0.6, 0.6);
  }

  void _strike(int side, double aimX, double power) {
    lastHitter = side;
    rallyShots++;
    if (rallyShots > longestRally) longestRally = rallyShots;
    _speed = (_speed * 1.015 + 0.008).clamp(0.45, 1.05);
    vx = aimX.clamp(-0.6, 0.6);
    vy = (side == 0 ? -1 : 1) * _speed * power;
    by = side == 0 ? bottomLine - 0.02 : topLine + 0.02;
    _contactEpoch++;
    _crossedNet = false;
    onEvent?.call(TennisEvent.hit);
    notifyListeners();
  }

  /// A shank: the ball sails past the sideline — OUT when it leaves.
  void _strikeWide(int side) {
    lastHitter = side;
    rallyShots++;
    _speed = (_speed * 1.01).clamp(0.45, 1.0);
    vx = (bx < 0.5 ? -1 : 1) * (0.55 + _rand.nextDouble() * 0.2);
    vy = (side == 0 ? -1 : 1) * _speed * 0.9;
    by = side == 0 ? bottomLine - 0.02 : topLine + 0.02;
    _contactEpoch++;
    _crossedNet = false;
    onEvent?.call(TennisEvent.hit);
    notifyListeners();
  }

  // ---------------------------------------------------------------- physics
  void _tick(Timer t) {
    if (_disposed || paused || over) return;
    const dt = 0.016;
    switch (phase) {
      case MatchPhase.serving:
        serveT += dt / (_serveAnimMs / 1000);
        if (serveT >= 1) {
          _launchServe();
          return;
        }
        notifyListeners();
      case MatchPhase.rally:
        _integrate(dt);
      case MatchPhase.serveReady:
      case MatchPhase.pointSettling:
      case MatchPhase.matchOver:
        break;
    }
  }

  void _integrate(double dt) {
    bx += vx * dt;
    by += vy * dt;

    // Net crossing: felt-thud rhythm as the ball crosses mid-court.
    if (!_crossedNet &&
        ((lastHitter == 0 && by <= netLine) ||
            (lastHitter == 1 && by >= netLine))) {
      _crossedNet = true;
      onEvent?.call(TennisEvent.bounce);
    }

    // Sidelines: outside the doubles lines the ball is OUT.
    if (bx < 0.02 || bx > 0.98) {
      _point(1 - lastHitter, out: true);
      return;
    }

    // Baselines: contact zone or the ball sails past.
    if (vy < 0 && by <= topLine + 0.03) {
      _sideContact(1);
    } else if (vy > 0 && by >= bottomLine - 0.03) {
      _sideContact(0);
    }
    if (by < -0.05) {
      _point(0, out: false); // sailed past the top baseline
      return;
    }
    if (by > 1.05) {
      _point(1, out: false); // sailed past the bottom baseline
      return;
    }

    // AI footwork: the bot visibly tracks the ball when it's coming.
    for (int s = 0; s < 2; s++) {
      if (!players[s].isBot) continue;
      final approaching = s == 0 ? vy > 0 : vy < 0;
      if (approaching) {
        final d = players[s].difficulty;
        final speed = switch (d) {
          BotDifficulty.easy => 0.38,
          BotDifficulty.medium => 0.62,
          BotDifficulty.hard => 0.95,
        };
        final noise = switch (d) {
          BotDifficulty.easy => 0.10,
          BotDifficulty.medium => 0.05,
          BotDifficulty.hard => 0.015,
        };
        final target =
            (bx + (_rand.nextDouble() - 0.5) * noise).clamp(0.08, 0.92);
        final delta = target - px[s];
        final maxStep = speed * dt;
        px[s] += delta.clamp(-maxStep, maxStep);
      }
    }
    notifyListeners();
  }

  /// Ball has reached a side's contact zone. Bots decide hit/miss once per
  /// approach (visible swing); humans must call [hitAttempt] in time.
  void _sideContact(int side) {
    if (phase != MatchPhase.rally) return;
    if (!players[side].isBot) return; // humans swing via hitAttempt
    if (_decidedEpoch == _contactEpoch) return; // decided already
    _decidedEpoch = _contactEpoch;
    final d = players[side].difficulty;
    final missChance = switch (d) {
      BotDifficulty.easy => 0.30,
      BotDifficulty.medium => 0.12,
      BotDifficulty.hard => 0.03,
    };
    _aiWillMiss = _rand.nextDouble() < missChance;
    if (_aiWillMiss) {
      // Whiff: the paddle visibly stays short; the ball sails past.
      banner = '${players[side].name} can\'t reach it!';
      notifyListeners();
      return;
    }
    final dToBall = (bx - px[side]).abs();
    if (dToBall > 0.16) {
      // Too far — the bot couldn't get there in time.
      _aiWillMiss = true;
      banner = '${players[side].name} can\'t reach it!';
      notifyListeners();
      return;
    }
    // Visible return with difficulty-flavored aim and pace.
    final humanX = px[1 - side];
    final corner = humanX >= 0.5 ? -0.42 : 0.42;
    double aim;
    double power;
    switch (d) {
      case BotDifficulty.easy:
        aim = (_rand.nextDouble() - 0.5) * 0.3; // soft, central
        power = 0.85;
      case BotDifficulty.medium:
        aim = corner * 0.6 + (_rand.nextDouble() - 0.5) * 0.25;
        power = 1.0;
      case BotDifficulty.hard:
        aim = corner + (_rand.nextDouble() - 0.5) * 0.12; // paints lines
        power = 1.12;
    }
    _strike(side, aim.clamp(-0.6, 0.6), power);
  }

  // ---------------------------------------------------------------- scoring
  void _point(int w, {required bool out}) {
    if (over || phase != MatchPhase.rally) return;
    phase = MatchPhase.pointSettling;
    vx = 0;
    vy = 0;
    pointCount++;
    final humanWonPoint = !players[w].isBot;
    // Crowd reads the room: cheer for a human point, gasp otherwise.
    // An OUT call always gasps first.
    if (out) onEvent?.call(TennisEvent.out);
    onEvent?.call(humanWonPoint ? TennisEvent.pointWon : TennisEvent.pointLost);

    if (tiebreak) {
      tb[w]++;
      if (tb[w] >= 7 && tb[w] - tb[1 - w] >= 2) {
        _winSet(w);
        return;
      }
      banner = out
          ? 'OUT! Point to ${players[w].name}.'
          : '${players[w].name} takes the point!';
      _tbServeCount++;
      if (_tbServeCount % 2 == 1) server = 1 - server; // alternate every 2
    } else {
      pts[w]++;
      if (pts[w] >= 4 && pts[w] - pts[1 - w] >= 2) {
        _winGame(w);
        return;
      }
      banner = out
          ? 'OUT! Point to ${players[w].name}.'
          : '${players[w].name} takes the point!';
    }
    notifyListeners();
    _arm(const Duration(milliseconds: _settleMs), _nextPoint);
  }

  void _winGame(int w) {
    games[w]++;
    pts[0] = 0;
    pts[1] = 0;
    server = 1 - server; // serve alternates every game (RULES.md §3)
    onEvent?.call(TennisEvent.gameWon);
    if (games[w] >= 4 && games[w] - games[1 - w] >= 2) {
      _winSet(w);
      return;
    }
    if (games[0] == 3 && games[1] == 3) {
      tiebreak = true;
      _tbServeCount = 0;
      banner = 'Tiebreak! First to 7. 🔥';
    } else {
      banner = 'Game — ${players[w].name}! 🎾';
    }
    phase = MatchPhase.pointSettling;
    notifyListeners();
    _arm(const Duration(milliseconds: _settleMs), _nextPoint);
  }

  void _winSet(int w) {
    over = true;
    phase = MatchPhase.matchOver;
    winner = w;
    banner = '${players[w].name} wins the set! 🏆';
    notifyListeners();
    onEvent?.call(players[w].isBot ? TennisEvent.botWon : TennisEvent.humanWon);
  }

  void _nextPoint() {
    if (over) return;
    phase = MatchPhase.serveReady;
    rallyShots = 0;
    _resetBallToServer();
    banner = _serveBanner();
    notifyListeners();
    _afterPhase();
  }

  /// Fresh match: scores reset, Player 1 serves first.
  void restart() {
    _timer?.cancel();
    paused = false;
    pts[0] = 0;
    pts[1] = 0;
    games[0] = 0;
    games[1] = 0;
    tb[0] = 0;
    tb[1] = 0;
    tiebreak = false;
    _tbServeCount = 0;
    server = 0;
    over = false;
    winner = null;
    rallyShots = 0;
    longestRally = 0;
    pointCount = 0;
    _contactEpoch = 0;
    _decidedEpoch = -1;
    _speed = 0.55;
    px[0] = 0.5;
    px[1] = 0.5;
    phase = MatchPhase.serveReady;
    _resetBallToServer();
    banner = _serveBanner();
    notifyListeners();
    _afterPhase();
  }
}
