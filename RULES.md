# Tennis — Rules

_Court-club tennis: drag along the baseline, time your swings, real tennis scoring. This document is the authoritative source of truth._

## 1. Objective
Win the set: be the first to win 4 games with a 2-game margin (or win the tiebreak at 3–3).

## 2. Setup
- 2 players: bottom side (Player 1) and top side (Player 2).
- Each player has a name (renameable), a court-side color, a racket style and shares the match ball style.
- Player 1 serves first. The server alternates every game.
- Modes: vs Computer (Easy / Medium / Hard) or 2-player pass-and-play.

## 3. Turn order
- Points are played in order: serve → rally → point decided → next serve.
- The server is announced before every point ("Ayesha to serve…").
- The human server taps SERVE; the computer server serves automatically after a short visible delay with a ball toss.
- After each game the serve passes to the other player.

## 4. Legal moves
- Drag horizontally to slide your player along your baseline.
- Tap HIT (or tap the court on your half) to swing when the ball is in your hitting window (near your baseline, moving toward you).
- A centered hit (|ball − player| small) is a fast, well-aimed return; an edge hit is weaker and may shank wide.
- Serves always land — there are no double faults (family-friendly rule).

## 5. Illegal moves
- Swinging when the ball is on the opponent's half or moving away does nothing (gentle "not yet" feedback, no penalty).
- Swinging during serve / point-settling is ignored — input is locked outside rallies.

## 6. Captures
N/A — no captures in tennis.

## 7. Special rules
- **Deuce & Advantage:** at 40–40 the score is Deuce; a player must win two consecutive points (Advantage → Game).
- **Tiebreak:** at 3 games all, a 7-point tiebreak decides the set (first to 7, win by 2). Points are counted 1, 2, 3… and the serve still alternates (every 2 points, simplified to every point boundary the engine handles).
- **Out:** a ball that leaves the court sideways is OUT — the point goes to the other player.

## 8. Scoring
- Points: 0 → 15 → 30 → 40 → Game (win by 2 points).
- Games: first to 4 games, win by 2.
- Tiebreak at 3–3: first to 7 points, win by 2.
- The scoreboard always shows current points and games.

## 9. Winning conditions
Win the set: 4 games with a 2-game margin, or win the 3–3 tiebreak.

## 10. Draw conditions
N/A — a tennis set always produces a winner.

## 11. AI strategy
The computer opponent (top side in vs-computer mode) plays visibly: it slides to track the ball, serves with a tossed ball, and returns with aim.
- **Easy:** slow footwork, misses ~30% of reachable balls, soft safe returns down the middle.
- **Medium:** decent footwork, misses ~12%, mixes placement, occasional faster shots.
- **Hard:** fast footwork, misses ~3%, aims at the corners, serves and returns faster. (Pro feature.)
The AI never teleports and never hits a ball the animation doesn't show — every AI action is visible and narrated.

## 12. Edge cases
- Ball exactly on a line: counts IN (generous line calls, family game).
- Simultaneous contact impossible: only the side the ball is moving toward can hit it.
- App backgrounded mid-rally: the match freezes (engine pause) and resumes exactly; the watchdog re-arms any phase timer lost.
- Restart mid-match: scores reset, Player 1 serves first, no stuck state.

## 13. Test cases
1. Serve → rally → human hits → AI returns → point completes → banner shows → next serve announced. No freeze.
2. Human lets the ball pass the baseline → point awarded to opponent, crowd reacts.
3. Ball hit wide past the sideline → "OUT", point to the other player.
4. 40–40 → Deuce → Advantage → Game transitions display correctly.
5. 3–3 games → tiebreak banner → tiebreak points counted to 7, win by 2 → set won.
6. Computer serves: toss animation plays, narration shows, ball launches.
7. Computer's turn never auto-skips: its paddle visibly tracks the ball and swings.
8. Background the app mid-rally → resume → rally continues (or point settles cleanly).
9. Hard mode is locked for free players; Easy/Medium always available.
10. Rename both players → restart app → names persist in order.
