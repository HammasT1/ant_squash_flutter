import 'dart:math';

import 'package:flutter/material.dart';

import 'Storage.dart';
import 'achievements.dart';
import 'image_provider.dart';
import 'profile_screen.dart';
import 'ui_kit.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key, required this.onStart});

  final ValueChanged<String> onStart;

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final AnimationController _bob;
  bool _nameError = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: GameStorage.lastPlayerName ?? '');
    _bob = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _bob.dispose();
    super.dispose();
  }

  void _start() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = true);
      return;
    }
    GameStorage.rememberPlayer(name);
    widget.onStart(name);
  }

  Future<void> _openProfile(ProfileTab tab) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ProfileScreen(initialTab: tab)),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final stats = GameStorage.stats;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackdrop()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _hero(),
                      const SizedBox(height: 18),
                      ShaderMask(
                        shaderCallback: (rect) =>
                            AppColors.accentGradient.createShader(rect),
                        child: const Text(
                          'ANT SQUASH',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 44,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Protect the sweets from the ant swarm.\nTap fast. Chain combos. Survive.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textDim, height: 1.4),
                      ),
                      const SizedBox(height: 22),
                      GlassCard(
                        radius: 28,
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            TextField(
                              controller: _controller,
                              textInputAction: TextInputAction.done,
                              textCapitalization: TextCapitalization.words,
                              maxLength: 16,
                              onChanged: (_) {
                                if (_nameError) {
                                  setState(() => _nameError = false);
                                }
                              },
                              onSubmitted: (_) => _start(),
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Your name',
                                counterText: '',
                                errorText: _nameError
                                    ? 'Enter a name to start'
                                    : null,
                                prefixIcon: const Icon(Icons.person_rounded),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.08),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: PrimaryButton(
                                label: 'START HUNTING',
                                icon: Icons.play_arrow_rounded,
                                onPressed: _start,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _MenuTile(
                              icon: Icons.emoji_events_rounded,
                              label: 'Top 10',
                              onTap: () => _openProfile(ProfileTab.leaderboard),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MenuTile(
                              icon: Icons.insights_rounded,
                              label: 'Stats',
                              onTap: () => _openProfile(ProfileTab.stats),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MenuTile(
                              icon: Icons.military_tech_rounded,
                              label:
                                  '${GameStorage.unlocked.length}/${Achievements.all.length}',
                              onTap: () =>
                                  _openProfile(ProfileTab.achievements),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MenuTile(
                              icon: GameStorage.soundEnabled
                                  ? Icons.volume_up_rounded
                                  : Icons.volume_off_rounded,
                              label: GameStorage.soundEnabled
                                  ? 'Sound'
                                  : 'Muted',
                              onTap: () => setState(
                                () => GameStorage.setSoundEnabled(
                                  !GameStorage.soundEnabled,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _Chip(
                            icon: Icons.star_rounded,
                            text: 'Best ${GameStorage.highScore}',
                          ),
                          _Chip(
                            icon: Icons.bug_report_rounded,
                            text: '${stats.totalSquashed} squashed',
                          ),
                          _Chip(
                            icon: Icons.sports_esports_rounded,
                            text: '${stats.gamesPlayed} games',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero() {
    return AnimatedBuilder(
      animation: _bob,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_bob.value);
        return SizedBox(
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.gold.withValues(alpha: 0.28),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, -8 + t * 16),
                child: Image.asset(GameAssets.cake, width: 112, height: 112),
              ),
              for (final (angle, size, phase) in const [
                (-2.5, 40.0, 0.0),
                (0.6, 34.0, 1.8),
                (2.4, 30.0, 3.4),
              ])
                _orbitingAnt(angle + sin(_bob.value * pi + phase) * 0.25, size),
            ],
          ),
        );
      },
    );
  }

  Widget _orbitingAnt(double angle, double size) {
    const radius = 84.0;
    return Transform.translate(
      offset: Offset(cos(angle) * radius, sin(angle) * radius * 0.8),
      child: Transform.rotate(
        angle: angle + pi / 2 + pi,
        child: Image.asset(GameAssets.ant, width: size, height: size),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.gold),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: Colors.white.withValues(alpha: 0.06),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.gold),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(color: AppColors.textDim, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
