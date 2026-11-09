import 'package:flutter/material.dart';

import 'ui_kit.dart';

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
    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'SWEET SHIELD',
            style: TextStyle(
              color: AppColors.textDim,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < maxHealth; i++)
                AnimatedScale(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  scale: i < currentHealth ? 1.0 : 0.7,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Icon(
                      i < currentHealth
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 20,
                      color: i < currentHealth
                          ? (currentHealth <= 1
                                ? AppColors.danger
                                : const Color(0xFFFF7A7A))
                          : Colors.white30,
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
