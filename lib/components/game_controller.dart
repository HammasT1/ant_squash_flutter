import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'Enemy.dart';
import 'EnemySpawner.dart';
import 'Player.dart';
import 'ScoreText.dart';
import 'Storage.dart';
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

class _GameControllerState extends State<GameController>
    with SingleTickerProviderStateMixin {
  static const int _maxHealth = 5;
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
    _spawner = EnemySpawner(_random);
    _cake = SweetCake(center: Offset.zero, size: 160);
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
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
    _frameTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _tick(0.016),
    );
    if (mounted) {
      setState(() {});
    }
  }

  void _spawnAnt() {
    if (!mounted || _gameOver || !_loopStarted) {
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
    if (!mounted || _gameOver || !_loopStarted) {
      return;
    }

    final hits = <EnemyAnt>[];
    for (final ant in _ants) {
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
    if (hits.isNotEmpty || _ants.isNotEmpty || _gameOver) {
      setState(() {});
    }
  }

  void _loseHealth() {
    if (_gameOver) {
      return;
    }
    _health -= 1;
    _damageFlash = true;
    if (_health <= 0) {
      _gameOver = true;
      GameStorage.saveScore(widget.playerName, _score);
      _spawnTimer?.cancel();
      _frameTimer?.cancel();
      return;
    }
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) {
        setState(() {
          _damageFlash = false;
        });
      }
    });
  }

  void _squashAnt(EnemyAnt ant) {
    if (_gameOver || ant.squashed) {
      return;
    }
    setState(() {
      ant.squashed = true;
      ant.squashAge = 0;
      _score += 1;
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
                Image.asset(
                  GameAssets.ant,
                  width: ant.size,
                  height: ant.size,
                  fit: BoxFit.contain,
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
            : 'Tap the ants. They get faster the longer you survive.',
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
                    onPressed: _restart,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8A2A),
                      foregroundColor: Colors.white,
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
