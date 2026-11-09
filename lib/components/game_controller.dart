import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'Enemy.dart';
import 'EnemySpawner.dart';
import 'Player.dart';
import 'ScoreText.dart';
import 'Storage.dart';
import 'audio_service.dart';
import 'health_bar.dart';
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

class _GameControllerState extends State<GameController>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const int _maxHealth = 5;
  static const double _comboWindow = 1.0;
  static const int _squashesPerLevel = 3;
  static const int _maxMultiplier = 5;
  final List<_FloatingText> _floaters = <_FloatingText>[];
  final Stopwatch _stopwatch = Stopwatch();
  Duration _lastFrame = Duration.zero;
  double _clock = 0;
  double _lastSquashAt = -100;
  int _combo = 0;
  int _bestCombo = 0;
  bool _paused = false;
  bool _newHighScore = false;
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
    if (_combo > 0 && _clock - _lastSquashAt > _comboWindow) {
      _combo = 0;
    }
    for (final f in _floaters) {
      f.age += dt;
    }
    _floaters.removeWhere((f) => f.expired);

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
        _gameOver) {
      setState(() {});
    }
  }

  void _loseHealth() {
    if (_gameOver) {
      return;
    }
    _health -= 1;
    _damageFlash = true;
    _combo = 0;
    if (_health <= 0) {
      _gameOver = true;
      _newHighScore = GameStorage.saveScore(widget.playerName, _score);
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
  }

  void _togglePause() {
    if (_paused) {
      _resume();
    } else {
      _pause();
    }
  }

  void _restartRun() {
    _spawnTimer?.cancel();
    _frameTimer?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    setState(() {
      _ants.clear();
      _floaters.clear();
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
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _ambientController,
                  builder: (context, child) {
                    final t = _ambientController.value;
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.lerp(
                              const Color(0xFF09101D),
                              const Color(0xFF1C2D4D),
                              t,
                            )!,
                            Color.lerp(
                              const Color(0xFF10263C),
                              const Color(0xFF291633),
                              t,
                            )!,
                            const Color(0xFF08111F),
                          ],
                        ),
                      ),
                      child: child,
                    );
                  },
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _ambientController,
                    builder: (context, child) {
                      final t = _ambientController.value;
                      return Stack(
                        children: [
                          _ambientBlob(
                            left: -70,
                            top: 80 + sin(t * pi * 2) * 20,
                            size: 220,
                            color: const Color(0xFFFF7E33).withOpacity(0.13),
                          ),
                          _ambientBlob(
                            right: -50,
                            top: 160 + cos(t * pi * 2) * 24,
                            size: 180,
                            color: const Color(0xFFFFD36A).withOpacity(0.1),
                          ),
                          _ambientBlob(
                            left: 70,
                            bottom: 100 + sin(t * pi * 2 * 1.2) * 18,
                            size: 150,
                            color: const Color(0xFF59D8FF).withOpacity(0.08),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
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
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 170,
                            child: HealthBar(
                              currentHealth: _health,
                              maxHealth: _maxHealth,
                            ),
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
                                    child: GestureDetector(
                                      onTap: () => _squashAnt(ant),
                                      behavior: HitTestBehavior.opaque,
                                      child: _buildAnt(ant),
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
                                            (1 - f.age / _FloatingText.lifetime)
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
                                    duration: const Duration(milliseconds: 120),
                                    child: const _DamageBanner(),
                                  ),
                                ),
                                Positioned(
                                  left: 18,
                                  right: 18,
                                  bottom: 18,
                                  child: _buildTipCard(),
                                ),
                                if (_paused && !_gameOver)
                                  Positioned.fill(child: _buildPauseOverlay()),
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
      color: Colors.black.withOpacity(0.65),
      child: Center(
        child: Container(
          width: min(360, _arenaSize.width - 40),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: const Color(0xFF101A2A).withOpacity(0.96),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.pause_circle_rounded,
                size: 52,
                color: Color(0xFFFFA63D),
              ),
              const SizedBox(height: 10),
              Text(
                'Paused',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _resume,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8A2A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Resume'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _restartRun,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Restart'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: widget.onExitToStart,
                  child: const Text('Quit to Menu'),
                ),
              ),
            ],
          ),
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
            : 'Tap the ants. Chain squashes for combo points!',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.9, end: 1.0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
            width: min(430, _arenaSize.width - 40),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: const Color(0xFF101A2A).withOpacity(0.96),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black87,
                  blurRadius: 30,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  size: 52,
                  color: Color(0xFFFFA63D),
                ),
                const SizedBox(height: 12),
                Text(
                  'Game Over',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Final score: $_score',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white70),
                ),
                if (_newHighScore) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'New high score!',
                    style: TextStyle(
                      color: Color(0xFFFFD36A),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  'Best combo: $_bestCombo',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white54),
                ),
                const SizedBox(height: 6),
                Text(
                  'Best score: ${GameStorage.highScore}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white54),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _restartRun,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8A2A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Play Again',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _restart,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Back to Start Screen',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ambientBlob({
    double? left,
    double? right,
    double? top,
    double? bottom,
    required double size,
    required Color color,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(color: color, blurRadius: 85, spreadRadius: 10),
          ],
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
