import 'dart:math';

import 'package:flutter/material.dart';

import 'Enemy.dart';

class EnemySpawner {
  EnemySpawner(this.random);

  final Random random;

  EnemyAnt spawn({
    required Size arenaSize,
    required Offset target,
    required int id,
    required int score,
  }) {
    final edge = random.nextInt(4);
    final size = 58 + random.nextDouble() * 16;
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

    final start = Offset(x, y);
    final delta = target - start;
    final distance = max(delta.distance, 1);
    final speed = 48 + random.nextDouble() * 34 + score * 1.2;
    final velocity = Offset(
      delta.dx / distance * speed,
      delta.dy / distance * speed,
    );

    return EnemyAnt(
      id: id,
      position: start,
      velocity: velocity,
      size: size,
      heading: atan2(velocity.dy, velocity.dx) + pi / 2,
    );
  }
}
