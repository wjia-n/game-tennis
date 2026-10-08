import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const TennisApp());

class TennisApp extends StatelessWidget {
  const TennisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      variant: ShellVariant.retroCabinet,
      title: 'Tennis',
      tagline: 'Rally, smash and win on grass and clay courts',
      emoji: '🎾',
      slug: 'tennis',
      howToPlay:
          '• Drag to slide along the baseline. Tap HIT (or the court) to swing!\n• Time your swing as the ball reaches you — centered hits are rockets.\n• Real tennis scoring: 15-30-40, deuce, games. First to 4 games takes the set.\n• 3-3 goes to a 7-point tiebreak. Solo? The bot has a wicked backhand. 🤖',
      playerOptions: const [1, 2],
      supportsBots: true,
      gameBuilder: (ctx, players, cb) => TennisScreen(players: players, callbacks: cb),
    );
  }
}
