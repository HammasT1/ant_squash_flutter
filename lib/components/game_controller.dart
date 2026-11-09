import 'dart:async';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';

import 'Enemy.dart';
import 'EnemySpawner.dart';
import 'Player.dart';
import 'ScoreText.dart';
import 'Storage.dart';
import 'achievements.dart';
import 'audio_service.dart';
import 'stats.dart';
import 'ui_kit.dart';
import 'health_bar.dart';
import 'profile_screen.dart';
import 'image_provider.dart';

class GameController extends StatefulWidget {
  const GameController({
    super.key,
    required this.playerName,
    required this.onExitToStart,
  });

  final String playerName;
  final VoidCallback onExitToStart;

  @override
  State<GameController> createState() => _GameControllerState();
}

class _FloatingText {
  _FloatingText({required this.position, required this.text, this.color});

  final Offset position;
  final String text;
  final Color? color;
  double age = 0;

  static const double lifetime = 0.9;
  bool get expired => age >= lifetime;
}

class _TapRipple {
  _TapRipple({required this.position, required this.hit});

  final Offset position;
  final bool hit;
  double age = 0;

  static const double lifetime = 0.35;
  double get progress => (age / lifetime).clamp(0.0, 1.0);
  bool get expired => age >= lifetime;
}

class _GameControllerState extends State<GameController>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const int _maxHealth = 5;
  static const double _comboWindow = 1.0;
  static const int _squashesPerLevel = 3;
  static const int _maxMultiplier = 5;
  final List<_FloatingText> _floaters = <_FloatingText>[];
  final List<_TapRipple> _ripples = <_TapRipple>[];
  final Stopwatch _stopwatch = clock.stopwatch();
  Duration _lastFrame = Duration.zero;
  double _clock = 0;
  double _lastSquashAt = -100;
  int _combo = 0;
  int _bestCombo = 0;
  bool _paused = false;
  bool _newHighScore = false;
  RunStats _run = RunStats();
  bool _committed = false;
  final List<Achievement> _newlyUnlocked = <Achievement>[];
  final List<Achievement> _toastQueue = <Achievement>[];
  Achievement? _activeToast;
  final Random _random = Random();
  late final EnemySpawner _spawner;
  late final AnimationController _ambientController;
  final List<EnemyAnt> _ants = <EnemyAnt>[];

  Timer? _spawnTimer;
  Timer? _frameTimer;
  bool _loopStarted = false;
  bool _queuedArenaStart = false;
  bool _gameOver = false;
  bool _damageFlash = false;
  int _score = 0;
  int _health = _maxHealth;
  int _nextEnemyId = 0;
  Size _arenaSize = Size.zero;
  late SweetCake _cake;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _spawner = EnemySpawner(_random);
    _cake = SweetCake(center: Offset.zero, size: 160);
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _pause();
    }
  }

  void _pause() {
    if (_paused || _gameOver || !_loopStarted) {
      return;
    }
    setState(() => _paused = true);
  }

  void _resume() {
    if (!_paused) {
      return;
    }
    // Skip the time spent paused so the next frame has a normal delta.
    _lastFrame = _stopwatch.elapsed;
    setState(() => _paused = false);
  }

  int get _multiplier =>
      min(1 + (max(_combo, 1) - 1) ~/ _squashesPerLevel, _maxMultiplier);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _finishRun();
    _spawnTimer?.cancel();
    _frameTimer?.cancel();
    _ambientController.dispose();
    super.dispose();
  }

  void _startLoop(Size size) {
    if (_loopStarted) {
      return;
    }
    _loopStarted = true;
    _arenaSize = size;
    _cake = SweetCake(
      center: size.center(Offset.zero),
      size: max(150, size.shortestSide * 0.27),
    );
    _spawnTimer = Timer.periodic(
      const Duration(milliseconds: 760),
      (_) => _spawnAnt(),
    );
    _stopwatch.start();
    _lastFrame = _stopwatch.elapsed;
    _frameTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      final now = _stopwatch.elapsed;
      final dt = ((now - _lastFrame).inMicroseconds / 1e6).clamp(0.0, 0.05);
      _lastFrame = now;
      _tick(dt);
    });
    if (mounted) {
      setState(() {});
    }
  }

  void _spawnAnt() {
    if (!mounted || _gameOver || !_loopStarted || _paused) {
      return;
    }
    if (_ants.length > 18) {
      return;
    }
    setState(() {
      _ants.add(
        _spawner.spawn(
          arenaSize: _arenaSize,
          target: _cake.center,
          id: _nextEnemyId++,
          score: _score,
        ),
      );
    });
  }

  void _tick(double dt) {
    if (!mounted || _gameOver || !_loopStarted || _paused) {
      return;
    }

    _clock += dt;
    _run.seconds += dt;
    if (_combo > 0 && _clock - _lastSquashAt > _comboWindow) {
      _combo = 0;
    }
    for (final f in _floaters) {
      f.age += dt;
    }
    _floaters.removeWhere((f) => f.expired);
    for (final r in _ripples) {
      r.age += dt;
    }
    _ripples.removeWhere((r) => r.expired);

    final hits = <EnemyAnt>[];
    for (final ant in _ants) {
      if (ant.hitFlash > 0) {
        ant.hitFlash = max(0, ant.hitFlash - dt);
      }
      if (ant.squashed) {
        ant.squashAge += dt;
        continue;
      }

      ant.position = ant.position + ant.velocity * dt;
      ant.wobble += dt * 8;

      final centerDistance = (ant.center - _cake.center).distance;
      final cakeRadius = _cake.size * 0.42;
      if (centerDistance <= cakeRadius + ant.size * 0.3) {
        hits.add(ant);
      }

      final outsideBounds =
          ant.position.dx < -ant.size * 2 ||
          ant.position.dy < -ant.size * 2 ||
          ant.position.dx > _arenaSize.width + ant.size * 2 ||
          ant.position.dy > _arenaSize.height + ant.size * 2;
      if (outsideBounds) {
        hits.add(ant);
      }
    }

    for (final ant in hits) {
      if (_ants.contains(ant) && !ant.squashed) {
        _loseHealth();
      }
      _ants.remove(ant);
    }

    _ants.removeWhere((ant) => ant.readyToRemove);
    if (hits.isNotEmpty ||
        _ants.isNotEmpty ||
        _floaters.isNotEmpty ||
        _ripples.isNotEmpty ||
        _gameOver) {
      setState(() {});
    }
  }

  void _loseHealth() {
    if (_gameOver) {
      return;
    }
    _health -= 1;
    _run.damageTaken += 1;
    _damageFlash = true;
    _combo = 0;
    if (_health <= 0) {
      _gameOver = true;
      _newHighScore = GameStorage.saveScore(widget.playerName, _score);
      _finishRun();
      _spawnTimer?.cancel();
      _frameTimer?.cancel();
      GameAudio.play(GameSound.gameOver);
      GameAudio.haptic(heavy: true);
      return;
    }
    GameAudio.play(GameSound.hit);
    GameAudio.haptic(heavy: true);
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) {
        setState(() {
          _damageFlash = false;
        });
      }
    });
  }

  void _squashAnt(EnemyAnt ant) {
    if (_gameOver || _paused || ant.squashed) {
      return;
    }
    if (ant.hp > 1) {
      // Multi-hit ant: absorb the tap and flash.
      setState(() {
        ant.hp -= 1;
        ant.hitFlash = 0.15;
      });
      GameAudio.play(GameSound.combo);
      GameAudio.haptic();
      return;
    }

    final multiplierBefore = _multiplier;
    setState(() {
      ant.hp = 0;
      ant.squashed = true;
      ant.squashAge = 0;

      _combo = (_clock - _lastSquashAt <= _comboWindow) ? _combo + 1 : 1;
      _lastSquashAt = _clock;
      _bestCombo = max(_bestCombo, _combo);

      final points = ant.type.basePoints * _multiplier;
      _score += points;
      _run
        ..score = _score
        ..squashed += 1
        ..bestCombo = _bestCombo
        ..byType[ant.type] = _run.count(ant.type) + 1;

      final label = _multiplier > 1
          ? '+$points  x$_multiplier COMBO!'
          : '+$points';
      _floaters.add(
        _FloatingText(
          position: ant.center,
          text: label,
          color: _multiplier > 1 ? const Color(0xFFFFD36A) : Colors.white,
        ),
      );

      if (ant.type == AntType.queen) {
        for (var i = 0; i < 3; i++) {
          final offset = Offset(
            (_random.nextDouble() - 0.5) * ant.size,
            (_random.nextDouble() - 0.5) * ant.size,
          );
          _ants.add(
            _spawner.build(
              type: AntType.normal,
              start: ant.position + offset,
              target: _cake.center,
              id: _nextEnemyId++,
              score: _score,
              size: 48,
            ),
          );
        }
        _floaters.add(
          _FloatingText(
            position: ant.center - const Offset(0, 28),
            text: 'Babies!',
            color: const Color(0xFFFF9B4D),
          ),
        );
      }
    });
    GameAudio.play(
      _multiplier > multiplierBefore ? GameSound.combo : GameSound.squash,
    );
    GameAudio.haptic();
    _checkAchievements();
  }

  /// Unlocks any achievement the current run has just satisfied.
  void _checkAchievements() {
    for (final a in Achievements.all) {
      if (GameStorage.unlocked.contains(a.id)) continue;
      if (a.isSatisfied(GameStorage.stats, _run)) {
        GameStorage.unlock(a.id);
        _newlyUnlocked.add(a);
        _toastQueue.add(a);
      }
    }
    _showNextToast();
  }

  void _showNextToast() {
    if (_activeToast != null || _toastQueue.isEmpty || !mounted) return;
    setState(() => _activeToast = _toastQueue.removeAt(0));
    GameAudio.play(GameSound.combo);
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      setState(() => _activeToast = null);
      Future.delayed(const Duration(milliseconds: 250), _showNextToast);
    });
  }

  /// Banks the run into lifetime stats exactly once.
  void _finishRun() {
    if (_committed || _run.seconds <= 0) return;
    _committed = true;
    _checkAchievementsSilently();
    GameStorage.commitRun(_run);
  }

  void _checkAchievementsSilently() {
    for (final a in Achievements.all) {
      if (GameStorage.unlocked.contains(a.id)) continue;
      if (a.isSatisfied(GameStorage.stats, _run)) {
        GameStorage.unlock(a.id);
        _newlyUnlocked.add(a);
      }
    }
  }

  /// Extra touch radius around every ant so near-misses still count.
  static const double _tapSlop = 22;
  static const double _minHitRadius = 38;

  /// Taps are handled on the whole arena (on touch-down, multi-touch safe)
  /// and snapped to the closest ant within a forgiving radius.
  void _onArenaPointerDown(PointerDownEvent event) {
    if (_gameOver || _paused || !_loopStarted) {
      return;
    }
    final point = event.localPosition;
    EnemyAnt? best;
    var bestRatio = double.infinity;
    for (final ant in _ants) {
      if (ant.squashed) continue;
      // Aim slightly ahead of the ant, since it keeps moving while you tap.
      final aim = ant.center + ant.velocity * 0.06;
      final radius = max(ant.size * 0.5, _minHitRadius) + _tapSlop;
      final ratio = (point - aim).distance / radius;
      if (ratio <= 1 && ratio < bestRatio) {
        best = ant;
        bestRatio = ratio;
      }
    }
    setState(
      () => _ripples.add(_TapRipple(position: point, hit: best != null)),
    );
    if (best != null) {
      _squashAnt(best);
    }
  }

  void _togglePause() {
    if (_paused) {
      _resume();
    } else {
      _pause();
    }
  }

  void _restartRun() {
    _finishRun();
    _spawnTimer?.cancel();
    _frameTimer?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    setState(() {
      _ants.clear();
      _floaters.clear();
      _ripples.clear();
      _score = 0;
      _health = _maxHealth;
      _combo = 0;
      _bestCombo = 0;
      _clock = 0;
      _lastSquashAt = -100;
      _lastFrame = Duration.zero;
      _nextEnemyId = 0;
      _paused = false;
      _gameOver = false;
      _damageFlash = false;
      _newHighScore = false;
      _run = RunStats();
      _committed = false;
      _newlyUnlocked.clear();
      _toastQueue.clear();
      _activeToast = null;
      _loopStarted = false;
      _queuedArenaStart = false;
    });
  }

  void _restart() {
    widget.onExitToStart();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          if (!_loopStarted &&
              !_queuedArenaStart &&
              size.width > 0 &&
              size.height > 0) {
            _queuedArenaStart = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _queuedArenaStart = false;
              if (mounted && !_loopStarted) {
                _startLoop(size);
              }
            });
          }

          return Stack(
            children: [
              const Positioned.fill(child: AnimatedBackdrop()),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: ScoreText(
                              playerName: widget.playerName,
                              score: _score,
                            ),
                          ),
                          const SizedBox(width: 10),
                          HealthBar(
                            currentHealth: _health,
                            maxHealth: _maxHealth,
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            tooltip: _paused ? 'Resume' : 'Pause',
                            onPressed: _gameOver || !_loopStarted
                                ? null
                                : _togglePause,
                            icon: Icon(
                              _paused
                                  ? Icons.play_arrow_rounded
                                  : Icons.pause_rounded,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.08),
                              ),
                            ),
                            child: Listener(
                              behavior: HitTestBehavior.opaque,
                              onPointerDown: _onArenaPointerDown,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  if (_loopStarted)
                                    Positioned(
                                      left: 0,
                                      top: 0,
                                      right: 0,
                                      bottom: 0,
                                      child: _buildArenaGlow(),
                                    ),
                                  if (_loopStarted)
                                    Positioned(
                                      left: _cake.topLeft.dx,
                                      top: _cake.topLeft.dy,
                                      child: _buildCake(),
                                    ),
                                  for (final ant in _ants)
                                    Positioned(
                                      left: ant.position.dx,
                                      top: ant.position.dy,
                                      child: IgnorePointer(
                                        child: _buildAnt(ant),
                                      ),
                                    ),
                                  for (final r in _ripples)
                                    Positioned(
                                      left: r.position.dx - 40,
                                      top: r.position.dy - 40,
                                      width: 80,
                                      height: 80,
                                      child: IgnorePointer(
                                        child: Center(
                                          child: Container(
                                            width: 16 + 56 * r.progress,
                                            height: 16 + 56 * r.progress,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color:
                                                    (r.hit
                                                            ? AppColors.gold
                                                            : Colors.white)
                                                        .withValues(
                                                          alpha:
                                                              0.6 *
                                                              (1 - r.progress),
                                                        ),
                                                width: 3,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  for (final f in _floaters)
                                    Positioned(
                                      left: f.position.dx - 60,
                                      top:
                                          f.position.dy -
                                          20 -
                                          (f.age / _FloatingText.lifetime) * 40,
                                      width: 120,
                                      child: IgnorePointer(
                                        child: Opacity(
                                          opacity:
                                              (1 -
                                                      f.age /
                                                          _FloatingText
                                                              .lifetime)
                                                  .clamp(0.0, 1.0),
                                          child: Text(
                                            f.text,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: f.color ?? Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 16,
                                              shadows: const [
                                                Shadow(
                                                  color: Colors.black87,
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  Positioned(
                                    top: 64,
                                    left: 16,
                                    right: 16,
                                    child: IgnorePointer(
                                      child: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        transitionBuilder: (child, anim) =>
                                            FadeTransition(
                                              opacity: anim,
                                              child: SlideTransition(
                                                position: Tween<Offset>(
                                                  begin: const Offset(0, -0.4),
                                                  end: Offset.zero,
                                                ).animate(anim),
                                                child: child,
                                              ),
                                            ),
                                        child: _activeToast == null
                                            ? const SizedBox.shrink(
                                                key: ValueKey('none'),
                                              )
                                            : _buildAchievementToast(
                                                _activeToast!,
                                              ),
                                      ),
                                    ),
                                  ),
                                  if (_combo >= 2 && !_gameOver)
                                    Positioned(
                                      top: 12,
                                      left: 0,
                                      right: 0,
                                      child: IgnorePointer(
                                        child: Center(child: _buildComboChip()),
                                      ),
                                    ),
                                  Positioned(
                                    left: 18,
                                    right: 18,
                                    bottom: 18,
                                    child: AnimatedOpacity(
                                      opacity: _damageFlash ? 1 : 0.0,
                                      duration: const Duration(
                                        milliseconds: 120,
                                      ),
                                      child: const _DamageBanner(),
                                    ),
                                  ),
                                  if (_clock < 7 || _gameOver)
                                    Positioned(
                                      left: 18,
                                      right: 18,
                                      bottom: 18,
                                      child: IgnorePointer(
                                        child: _buildTipCard(),
                                      ),
                                    ),
                                  if (_paused && !_gameOver)
                                    Positioned.fill(
                                      child: _buildPauseOverlay(),
                                    ),
                                  if (_gameOver)
                                    Positioned.fill(
                                      child: _buildGameOverOverlay(),
                                    ),
                                  if (!_loopStarted)
                                    const Positioned.fill(
                                      child: Center(
                                        child: SizedBox(
                                          width: 42,
                                          height: 42,
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildArenaGlow() {
    return AnimatedBuilder(
      animation: _ambientController,
      builder: (context, child) {
        final t = _ambientController.value;
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(sin(t * pi * 2) * 0.08, cos(t * pi * 2) * 0.08),
              radius: 1.15,
              colors: [
                const Color(0xFF4D3A1C).withOpacity(0.34),
                const Color(0xFF1A2434).withOpacity(0.78),
                const Color(0xFF08111F).withOpacity(0.95),
              ],
              stops: const [0, 0.65, 1],
            ),
          ),
          child: child,
        );
      },
    );
  }

  Widget _buildCake() {
    return AnimatedBuilder(
      animation: _ambientController,
      builder: (context, child) {
        final t = _ambientController.value;
        final pulse = 1 + sin(t * pi * 2) * 0.035;
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: _cake.size * 0.95,
              height: _cake.size * 0.95,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFD36A).withOpacity(0.22),
                    const Color(0xFFFFA63D).withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Transform.scale(
              scale: pulse,
              child: Image.asset(
                GameAssets.cake,
                width: _cake.size,
                height: _cake.size,
                fit: BoxFit.contain,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnt(EnemyAnt ant) {
    final animationDuration = ant.squashed
        ? const Duration(milliseconds: 180)
        : const Duration(milliseconds: 120);

    return AnimatedOpacity(
      duration: animationDuration,
      opacity: ant.squashed ? 0.95 : 1.0,
      child: AnimatedScale(
        duration: animationDuration,
        scale: ant.squashed ? 0.5 : 1.0,
        child: Transform.rotate(
          angle: ant.squashed ? 0 : ant.rotation(),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (ant.squashed)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.45, end: 1.35),
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) {
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Image.asset(
                    GameAssets.explosion,
                    width: ant.size * 1.4,
                    height: ant.size * 1.4,
                    fit: BoxFit.contain,
                  ),
                ),
              if (!ant.squashed)
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    _antSprite(ant),
                    if (ant.type.hp > 1)
                      Positioned(
                        bottom: -6,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < ant.type.hp; i++)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i < ant.hp
                                      ? const Color(0xFFFF5252)
                                      : Colors.white24,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _antSprite(EnemyAnt ant) {
    Widget sprite = Image.asset(
      GameAssets.ant,
      width: ant.size,
      height: ant.size,
      fit: BoxFit.contain,
    );
    final tint = ant.hitFlash > 0 ? Colors.white : ant.type.tint;
    if (tint != null) {
      sprite = ColorFiltered(
        colorFilter: ColorFilter.mode(
          tint.withValues(alpha: ant.hitFlash > 0 ? 0.8 : 0.45),
          BlendMode.srcATop,
        ),
        child: sprite,
      );
    }
    return sprite;
  }

  Widget _buildComboChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFA63D), Color(0xFFFF6A3D)],
        ),
      ),
      child: Text(
        'Combo $_combo  •  x$_multiplier',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPauseOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: GlassCard(
              radius: 28,
              padding: const EdgeInsets.all(24),
              highlight: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.pause_circle_rounded,
                    size: 56,
                    color: AppColors.gold,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'PAUSED',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: 'RESUME',
                      icon: Icons.play_arrow_rounded,
                      onPressed: _resume,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: SecondaryButton(
                      label: 'Restart',
                      icon: Icons.replay_rounded,
                      onPressed: _restartRun,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: SecondaryButton(
                      label: 'Quit to Menu',
                      icon: Icons.home_rounded,
                      onPressed: widget.onExitToStart,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementToast(Achievement a) {
    return Center(
      key: ValueKey(a.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AppColors.surface.withValues(alpha: 0.95),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.25),
              blurRadius: 18,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.accentGradient,
              ),
              child: Icon(a.icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ACHIEVEMENT UNLOCKED',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  a.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.black.withOpacity(0.24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Text(
        _gameOver
            ? 'The ants broke through. Return to the start screen to try again.'
            : 'Tap near an ant to squash it. Chain squashes for combos!',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    Widget stat(IconData icon, String value, String label) => Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.gold, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            style: const TextStyle(color: AppColors.textDim, fontSize: 11),
          ),
        ],
      ),
    );
    final seconds = _run.seconds.round();
    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.9, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: GlassCard(
                radius: 28,
                padding: const EdgeInsets.all(22),
                highlight: _newHighScore,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'GAME OVER',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                        color: AppColors.textDim,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ShaderMask(
                      shaderCallback: (r) =>
                          AppColors.accentGradient.createShader(r),
                      child: Text(
                        '$_score',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 64,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (_newHighScore)
                      const Text(
                        'NEW HIGH SCORE!',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      )
                    else
                      Text(
                        'Best: ${GameStorage.highScore}',
                        style: const TextStyle(color: AppColors.textDim),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        stat(
                          Icons.bug_report_rounded,
                          '${_run.squashed}',
                          'Squashed',
                        ),
                        stat(Icons.bolt_rounded, '$_bestCombo', 'Best combo'),
                        stat(Icons.timer_rounded, '${seconds}s', 'Survived'),
                      ],
                    ),
                    if (_newlyUnlocked.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'UNLOCKED THIS RUN',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final a in _newlyUnlocked)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AchievementTile(
                            achievement: a,
                            unlocked: true,
                            progress: a.target,
                          ),
                        ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        label: 'PLAY AGAIN',
                        icon: Icons.replay_rounded,
                        onPressed: _restartRun,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: SecondaryButton(
                        label: 'Main Menu',
                        icon: Icons.home_rounded,
                        onPressed: _restart,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DamageBanner extends StatelessWidget {
  const _DamageBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFFFF4D4D).withOpacity(0.2),
        border: Border.all(color: const Color(0xFFFF9090).withOpacity(0.3)),
      ),
      child: const Text(
        'The cake got hit!',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }
}
