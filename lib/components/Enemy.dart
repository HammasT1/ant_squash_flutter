import 'dart:math';

import 'package:flutter/material.dart';

class EnemyAnt {
  EnemyAnt({
    required this.id,
    required this.position,
    required this.velocity,
    required this.size,
    required this.heading,
  });

  final int id;
  Offset position;
  Offset velocity;
  final double size;
  final double heading;
  double wobble = 0;
  bool squashed = false;
  double squashAge = 0;

  Offset get center => position + Offset(size / 2, size / 2);

  bool get readyToRemove => squashed && squashAge > 0.24;

  double rotation() => heading + sin(wobble + id * 0.3) * 0.18;
}
