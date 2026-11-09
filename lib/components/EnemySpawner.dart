import 'dart:math';

import 'package:flutter/material.dart';

import 'Enemy.dart';

class EnemySpawner {
  EnemySpawner(this.random);

  final Random random;

  static const double maxSpeed = 210;

  AntType _pickType(int score) {
    final roll = random.nextDouble();
    if (score >= 40 && roll < 0.05) return AntType.queen;
    if (score >= 20 && roll < 0.2) return AntType.tank;
    if (score >= 8 && roll < 0.4) return AntType.fast;
    return AntType.normal;
  }

  EnemyAnt spawn({
    required Size arenaSize,
    required Offset target,
    required int id,
    required int score,
  }) {
    final type = _pickType(score);
    final size = (58 + random.nextDouble() * 16) * type.sizeMultiplier;
    final edge = random.nextInt(4);
    double x;
    double y;

    switch (edge) {
      case 0:
        x = random.nextDouble() * arenaSize.width;
        y = -size;
        break;
      case 1:
        x = arenaSize.width + size;
        y = random.nextDouble() * arenaSize.height;
        break;
      case 2:
        x = random.nextDouble() * arenaSize.width;
        y = arenaSize.height + size;
        break;
      default:
        x = -size;
        y = random.nextDouble() * arenaSize.height;
        break;
    }

    return build(
      type: type,
      start: Offset(x, y),
      target: target,
      id: id,
      score: score,
      size: size,
    );
  }

  /// Spawns a [type] ant at an explicit position (used for queen offspring).
  EnemyAnt build({
    required AntType type,
    required Offset start,
    required Offset target,
    required int id,
    required int score,
    double? size,
  }) {
    final antSize =
        size ?? (58 + random.nextDouble() * 16) * type.sizeMultiplier;
    final delta = target - start;
    final distance = max(delta.distance, 1);
    final baseSpeed = min(48 + random.nextDouble() * 34 + score * 1.2, 150);
    final speed = min(baseSpeed * type.speedMultiplier, maxSpeed);
    final velocity = Offset(
      delta.dx / distance * speed,
      delta.dy / distance * speed,
    );

    return EnemyAnt(
      id: id,
      type: type,
      position: start,
      velocity: velocity,
      size: antSize,
      heading: atan2(velocity.dy, velocity.dx) + pi / 2,
    );
  }
}
