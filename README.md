<div align="center">

<img src="docs/banner.svg" alt="Ant Squash banner" width="100%"/>

<br/>

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-^3.9.2-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-FF7A1A?style=for-the-badge)](#-getting-started)

<img src="https://readme-typing-svg.demolab.com?font=Fira+Code&weight=600&size=20&pause=1000&color=FF7A1A&center=true&vCenter=true&width=520&lines=Defend+the+cake.;Tap+fast.+Squash+ants.;Beat+your+high+score." alt="Typing animation"/>

</div>

---

## 🎮 About

**Ant Squash** is a fast-paced arcade game built with Flutter. Hungry ants swarm toward a cake in the middle of the screen. Tap them before they reach it. Every ant that gets through damages the cake, and when its health runs out, the game is over.

<div align="center">
  <img src="assets/images/ant.png" height="90" alt="Ant"/>
  &nbsp;&nbsp;➜&nbsp;&nbsp;
  <img src="assets/images/cake.png" height="90" alt="Cake"/>
  &nbsp;&nbsp;💥&nbsp;&nbsp;
  <img src="assets/images/explosion.png" height="90" alt="Explosion"/>
</div>

## ✨ Features

| | |
|---|---|
| 🐜 **Four ant types** | Normal, fast, tank and queen ants, each with its own speed, size, health and points |
| 🔥 **Combo multiplier** | Squash ants within a second of each other to build a combo, up to **x5** |
| 👆 **Forgiving taps** | Touch-down input with a generous hit radius, aim assist for moving ants, multi-touch and tap ripples |
| 🍰 **Cake health system** | Five hearts; every ant that reaches the cake costs one |
| 🏆 **Leaderboard** | Persistent top 10 scores with name and date |
| 📊 **Lifetime stats** | Games played, ants squashed, best combo, time played and more |
| 🎖️ **14 achievements** | Progress bars, in-game unlock popups and a recap on the game-over screen |
| 🔊 **Sound and haptics** | Squash, hit, combo and game-over sounds with vibration feedback, plus a mute toggle |
| ⏸️ **Pause** | Pause button, restart and quit options, and auto-pause when the app goes to the background |
| 🎨 **Polished UI** | Dark Material 3 theme, animated backdrop, glass cards and animated transitions |

## 🕹️ How to Play

1. Enter your name on the start screen and press **Start Hunting**.
2. Tap near an ant to squash it. You don't have to hit it exactly.
3. Chain squashes within about a second to build a combo and multiply your points.
4. Don't let ants reach the cake. Each one that does costs **1 heart** (out of 5).
5. When the cake is gone, review your run, check what you unlocked, and play again.

### 🐜 Ant types

| Ant | Appears at score | Taps to kill | Base points | Notes |
|---|---|---|---|---|
| Normal | 0 | 1 | 1 | The standard worker |
| Fast (blue) | 8 | 1 | 2 | Small and quick |
| Tank (purple) | 20 | 3 | 3 | Large and slow, shows hit-point dots |
| Queen (gold) | 40 | 2 | 5 | Spawns 3 baby ants when squashed |

Points are multiplied by your current combo level: it rises by one for every 3 squashes in a chain, up to x5. Getting hit resets the combo.

### 🎖️ Achievements

Squash totals (1 / 100 / 1,000), combo chains (5 / 10 / 20), single-run scores (50 / 150 / 300), 25 fast ants, 10 tank ants, a queen, a flawless 30 points without the cake being hit, and playing 10 games. Open **Stats** or the achievements tile on the start screen to see your progress.

## 🚀 Getting Started

**Prerequisites:** [Flutter SDK](https://docs.flutter.dev/get-started/install) with Dart `^3.9.2`.

```bash
# Clone the repository
git clone https://github.com/<your-username>/ant_squash_flutter.git
cd ant_squash_flutter

# Install dependencies
flutter pub get

# Run the game
flutter run
```

Pick a target with `flutter run -d chrome`, `-d linux`, `-d windows`, `-d macos`, or a connected Android/iOS device.

### 📦 Download the APK

[![Build APK](https://github.com/<your-username>/ant_squash_flutter/actions/workflows/build-apk.yml/badge.svg)](../../actions/workflows/build-apk.yml)

APKs are built automatically by GitHub Actions on every push to `main`, on pull requests, and on manual runs (**Actions → Build APK → Run workflow**). Download them from the run's **Artifacts** section.

To publish a release with the APKs attached, push a version tag:

```bash
git tag v1.0.0
git push origin v1.0.0
```

> Release builds are currently signed with the debug key. Configure a proper keystore before publishing to the Play Store.

## 🗂️ Project Structure

```
lib/
├── main.dart                  # App entry, theme and screen switching
└── components/
    ├── start_screen.dart      # Start screen: name entry and menu
    ├── profile_screen.dart    # Hall of Fame: stats, achievements, top 10
    ├── game_controller.dart   # Game loop, input, collisions, HUD and overlays
    ├── Enemy.dart             # Ant model and ant types
    ├── EnemySpawner.dart      # Spawn logic, type selection and speed cap
    ├── achievements.dart      # Achievement definitions and progress rules
    ├── stats.dart             # Per-run and lifetime stat counters
    ├── Storage.dart           # Persistence (shared_preferences)
    ├── audio_service.dart     # Sound effects and haptics
    ├── ui_kit.dart            # Shared colors, backdrop, cards and buttons
    ├── health_bar.dart        # Cake heart display
    ├── ScoreText.dart         # Score display
    ├── Player.dart            # Cake model
    └── image_provider.dart    # Asset paths
assets/images/                 # Ant, cake and explosion sprites
assets/sounds/                 # Generated sound effects (WAV)
test/                          # Widget and unit tests
.github/workflows/             # CI: APK build and release
```

## 🛠️ Built With

- [Flutter](https://flutter.dev) – UI toolkit
- [Dart](https://dart.dev) – language
- [shared_preferences](https://pub.dev/packages/shared_preferences) – scores, stats and settings storage
- [audioplayers](https://pub.dev/packages/audioplayers) – sound effects
- Material 3 with a custom dark colour scheme

## 🧪 Testing

```bash
flutter test      # widget and unit tests
flutter analyze   # static analysis
```

## 🗺️ Roadmap

- [x] Persistent high scores and a local leaderboard
- [x] Enemy variety and combo scoring
- [x] Sound effects and haptics
- [x] Achievements and lifetime stats
- [ ] Power-ups (freeze, bug spray, extra heart)
- [ ] Background music
- [ ] Game modes (time attack, survival)
- [ ] Global online leaderboard

## 🤝 Contributing

Contributions are welcome. Fork the repo, create a feature branch, and open a pull request.

---

<div align="center">

Made with 💙 and Flutter by **Muhammad Hammas Rasheed**

</div>
