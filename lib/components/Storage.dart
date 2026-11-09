import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.name,
    required this.score,
    required this.date,
  });

  final String name;
  final int score;
  final DateTime date;

  Map<String, dynamic> toJson() => {
    'name': name,
    'score': score,
    'date': date.toIso8601String(),
  };

  static LeaderboardEntry? fromJson(Object? json) {
    if (json is! Map) {
      return null;
    }
    final name = json['name'];
    final score = json['score'];
    final date = DateTime.tryParse('${json['date']}');
    if (name is! String || score is! int || date == null) {
      return null;
    }
    return LeaderboardEntry(name: name, score: score, date: date);
  }
}

class GameStorage {
  GameStorage._();

  static const int maxLeaderboardEntries = 10;
  static const String _kLastName = 'last_player_name';
  static const String _kLeaderboard = 'leaderboard';
  static const String _kSound = 'sound_enabled';

  static SharedPreferences? _prefs;

  static String? lastPlayerName;
  static bool soundEnabled = true;
  static List<LeaderboardEntry> leaderboard = <LeaderboardEntry>[];

  static int get highScore => leaderboard.isEmpty ? 0 : leaderboard.first.score;

  /// Loads persisted data. Safe to call if storage is unavailable.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _prefs = prefs;
      lastPlayerName = prefs.getString(_kLastName);
      soundEnabled = prefs.getBool(_kSound) ?? true;
      final raw = prefs.getString(_kLeaderboard);
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          leaderboard = decoded
              .map(LeaderboardEntry.fromJson)
              .whereType<LeaderboardEntry>()
              .toList();
          _sort();
        }
      }
    } catch (_) {
      // Fall back to in-memory defaults.
    }
  }

  static void _sort() {
    leaderboard.sort((a, b) => b.score.compareTo(a.score));
    if (leaderboard.length > maxLeaderboardEntries) {
      leaderboard = leaderboard.sublist(0, maxLeaderboardEntries);
    }
  }

  static void rememberPlayer(String name) {
    lastPlayerName = name;
    _prefs?.setString(_kLastName, name);
  }

  static void setSoundEnabled(bool value) {
    soundEnabled = value;
    _prefs?.setBool(_kSound, value);
  }

  /// Records a finished run. Returns true if it is a new high score.
  static bool saveScore(String playerName, int score) {
    lastPlayerName = playerName;
    _prefs?.setString(_kLastName, playerName);
    if (score <= 0) {
      return false;
    }
    final isNewBest = score > highScore;
    leaderboard.add(
      LeaderboardEntry(name: playerName, score: score, date: DateTime.now()),
    );
    _sort();
    _prefs?.setString(
      _kLeaderboard,
      jsonEncode(leaderboard.map((e) => e.toJson()).toList()),
    );
    return isNewBest;
  }
}
