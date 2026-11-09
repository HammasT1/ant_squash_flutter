import 'Enemy.dart';

/// Counters for the run currently being played.
class RunStats {
  int score = 0;
  int squashed = 0;
  int bestCombo = 0;
  int damageTaken = 0;
  double seconds = 0;
  final Map<AntType, int> byType = {for (final t in AntType.values) t: 0};

  int count(AntType type) => byType[type] ?? 0;
}

/// Counters accumulated across every finished run.
class LifetimeStats {
  LifetimeStats();

  int gamesPlayed = 0;
  int totalSquashed = 0;
  int totalScore = 0;
  int bestScore = 0;
  int bestCombo = 0;
  int fastSquashed = 0;
  int tanksSquashed = 0;
  int queensSquashed = 0;
  int secondsPlayed = 0;

  void absorb(RunStats run) {
    gamesPlayed += 1;
    totalSquashed += run.squashed;
    totalScore += run.score;
    if (run.score > bestScore) bestScore = run.score;
    if (run.bestCombo > bestCombo) bestCombo = run.bestCombo;
    fastSquashed += run.count(AntType.fast);
    tanksSquashed += run.count(AntType.tank);
    queensSquashed += run.count(AntType.queen);
    secondsPlayed += run.seconds.round();
  }

  double get averageScore => gamesPlayed == 0 ? 0 : totalScore / gamesPlayed;

  Map<String, dynamic> toJson() => {
    'gamesPlayed': gamesPlayed,
    'totalSquashed': totalSquashed,
    'totalScore': totalScore,
    'bestScore': bestScore,
    'bestCombo': bestCombo,
    'fastSquashed': fastSquashed,
    'tanksSquashed': tanksSquashed,
    'queensSquashed': queensSquashed,
    'secondsPlayed': secondsPlayed,
  };

  factory LifetimeStats.fromJson(Map<dynamic, dynamic> json) {
    int read(String key) => json[key] is int ? json[key] as int : 0;
    return LifetimeStats()
      ..gamesPlayed = read('gamesPlayed')
      ..totalSquashed = read('totalSquashed')
      ..totalScore = read('totalScore')
      ..bestScore = read('bestScore')
      ..bestCombo = read('bestCombo')
      ..fastSquashed = read('fastSquashed')
      ..tanksSquashed = read('tanksSquashed')
      ..queensSquashed = read('queensSquashed')
      ..secondsPlayed = read('secondsPlayed');
  }
}
