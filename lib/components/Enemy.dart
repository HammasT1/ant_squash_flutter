import 'dart:math';

import 'package:flutter/material.dart';

enum AntType { normal, fast, tank, queen }

extension AntTypeStats on AntType {
  int get hp => switch (this) {
    AntType.normal => 1,
    AntType.fast => 1,
    AntType.tank => 3,
    AntType.queen => 2,
  };

  double get speedMultiplier => switch (this) {
    AntType.normal => 1.0,
    AntType.fast => 1.8,
    AntType.tank => 0.6,
    AntType.queen => 0.55,
  };

  double get sizeMultiplier => switch (this) {
    AntType.normal => 1.0,
    AntType.fast => 0.72,
    AntType.tank => 1.3,
    AntType.queen => 1.6,
  };

  int get basePoints => switch (this) {
    AntType.normal => 1,
    AntType.fast => 2,
    AntType.tank => 3,
    AntType.queen => 5,
  };

  /// Tint applied to the shared ant sprite, or null for the original colors.
  Color? get tint => switch (this) {
    AntType.normal => null,
    AntType.fast => const Color(0xFF4DB8FF),
    AntType.tank => const Color(0xFFB04DFF),
    AntType.queen => const Color(0xFFFFD02E),
  };
}

class EnemyAnt {
  EnemyAnt({
    required this.id,
    required this.position,
    required this.velocity,
    required this.size,
    required this.heading,
    this.type = AntType.normal,
  }) : hp = type.hp;

  final int id;
  final AntType type;
  Offset position;
  Offset velocity;
  final double size;
  final double heading;
  int hp;
  double wobble = 0;
  double hitFlash = 0;
  bool squashed = false;
  double squashAge = 0;

  Offset get center => position + Offset(size / 2, size / 2);

  bool get readyToRemove => squashed && squashAge > 0.24;

  double rotation() => heading + sin(wobble + id * 0.3) * 0.18;
}
