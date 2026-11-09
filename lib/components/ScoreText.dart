import 'package:flutter/material.dart';

import 'ui_kit.dart';

class ScoreText extends StatelessWidget {
  const ScoreText({super.key, required this.playerName, required this.score});

  final String playerName;
  final int score;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            playerName.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textDim,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 2),
          TweenAnimationBuilder<double>(
            key: ValueKey(score),
            tween: Tween(begin: 1.25, end: 1.0),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) => Transform.scale(
              scale: scale,
              alignment: Alignment.centerLeft,
              child: child,
            ),
            child: ShaderMask(
              shaderCallback: (rect) =>
                  AppColors.accentGradient.createShader(rect),
              child: Text(
                '$score',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
