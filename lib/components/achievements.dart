import 'dart:math';

import 'package:flutter/material.dart';

import 'Enemy.dart';
import 'stats.dart';

class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.target,
    required this.progress,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int target;

  /// Current progress, combining lifetime totals with the run in progress.
  final int Function(LifetimeStats lifetime, RunStats run) progress;

  bool isSatisfied(LifetimeStats lifetime, RunStats run) =>
      progress(lifetime, run) >= target;
}

class Achievements {
  Achievements._();

  static final List<Achievement> all = [
    Achievement(
      id: 'first_blood',
      title: 'First Squash',
      description: 'Squash your first ant.',
      icon: Icons.bug_report_rounded,
      target: 1,
      progress: (l, r) => l.totalSquashed + r.squashed,
    ),
    Achievement(
      id: 'exterminator',
      title: 'Exterminator',
      description: 'Squash 100 ants in total.',
      icon: Icons.pest_control_rounded,
      target: 100,
      progress: (l, r) => l.totalSquashed + r.squashed,
    ),
    Achievement(
      id: 'plague',
      title: 'Plague Doctor',
      description: 'Squash 1,000 ants in total.',
      icon: Icons.coronavirus_rounded,
      target: 1000,
      progress: (l, r) => l.totalSquashed + r.squashed,
    ),
    Achievement(
      id: 'combo_5',
      title: 'Warming Up',
      description: 'Reach a 5x combo chain.',
      icon: Icons.bolt_rounded,
      target: 5,
      progress: (l, r) => max(l.bestCombo, r.bestCombo),
    ),
    Achievement(
      id: 'combo_10',
      title: 'On Fire',
      description: 'Reach a 10x combo chain.',
      icon: Icons.local_fire_department_rounded,
      target: 10,
      progress: (l, r) => max(l.bestCombo, r.bestCombo),
    ),
    Achievement(
      id: 'combo_20',
      title: 'Unstoppable',
      description: 'Reach a 20x combo chain.',
      icon: Icons.whatshot_rounded,
      target: 20,
      progress: (l, r) => max(l.bestCombo, r.bestCombo),
    ),
    Achievement(
      id: 'score_50',
      title: 'Cake Guard',
      description: 'Score 50 points in one run.',
      icon: Icons.cake_rounded,
      target: 50,
      progress: (l, r) => max(l.bestScore, r.score),
    ),
    Achievement(
      id: 'score_150',
      title: 'Sweet Defender',
      description: 'Score 150 points in one run.',
      icon: Icons.shield_rounded,
      target: 150,
      progress: (l, r) => max(l.bestScore, r.score),
    ),
    Achievement(
      id: 'score_300',
      title: 'Legend of the Cake',
      description: 'Score 300 points in one run.',
      icon: Icons.emoji_events_rounded,
      target: 300,
      progress: (l, r) => max(l.bestScore, r.score),
    ),
    Achievement(
      id: 'speed_demon',
      title: 'Quick Hands',
      description: 'Squash 25 fast ants.',
      icon: Icons.flash_on_rounded,
      target: 25,
      progress: (l, r) => l.fastSquashed + r.count(AntType.fast),
    ),
    Achievement(
      id: 'tank_buster',
      title: 'Tank Buster',
      description: 'Squash 10 tank ants.',
      icon: Icons.fitness_center_rounded,
      target: 10,
      progress: (l, r) => l.tanksSquashed + r.count(AntType.tank),
    ),
    Achievement(
      id: 'queen_slayer',
      title: 'Queen Slayer',
      description: 'Squash a queen ant.',
      icon: Icons.workspace_premium_rounded,
      target: 1,
      progress: (l, r) => l.queensSquashed + r.count(AntType.queen),
    ),
    Achievement(
      id: 'flawless',
      title: 'Flawless',
      description: 'Score 30 points without the cake getting hit.',
      icon: Icons.verified_rounded,
      target: 30,
      progress: (l, r) => r.damageTaken == 0 ? r.score : 0,
    ),
    Achievement(
      id: 'veteran',
      title: 'Seasoned Hunter',
      description: 'Play 10 games.',
      icon: Icons.military_tech_rounded,
      target: 10,
      progress: (l, r) => l.gamesPlayed + (r.seconds > 0 ? 1 : 0),
    ),
  ];

  static Achievement? byId(String id) {
    for (final a in all) {
      if (a.id == id) return a;
    }
    return null;
  }
}
