import 'package:flutter/material.dart';

class ScoreText extends StatelessWidget {
  const ScoreText({super.key, required this.playerName, required this.score});

  final String playerName;
  final int score;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Protect the cake, $playerName',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(0xFFFFE7C2),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Score $score',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
