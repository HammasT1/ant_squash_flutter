class GameStorage {
  GameStorage._();

  static String? lastPlayerName;
  static int highScore = 0;

  static void rememberPlayer(String name) {
    lastPlayerName = name;
  }

  static void saveScore(String playerName, int score) {
    lastPlayerName = playerName;
    if (score > highScore) {
      highScore = score;
    }
  }
}
