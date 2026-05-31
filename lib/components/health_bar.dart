import 'package:flutter/material.dart';

class HealthBar extends StatelessWidget {
  const HealthBar({
    super.key,
    required this.currentHealth,
    required this.maxHealth,
  });

  final int currentHealth;
  final int maxHealth;

  @override
  Widget build(BuildContext context) {
    final progress = maxHealth == 0 ? 0.0 : currentHealth / maxHealth;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sweet Shield',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white70,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 14,
              value: progress.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFF2A3444),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFFFB347),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$currentHealth / $maxHealth sweets left',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
