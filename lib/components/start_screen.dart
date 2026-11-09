import 'package:flutter/material.dart';

import 'Storage.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key, required this.onStart});

  final ValueChanged<String> onStart;

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: GameStorage.lastPlayerName ?? '');
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _start() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      return;
    }
    GameStorage.rememberPlayer(name);
    widget.onStart(name);
  }

  void _showLeaderboard() {
    final entries = GameStorage.leaderboard;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF101A2A),
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top ${GameStorage.maxLeaderboardEntries}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                if (entries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('No scores yet. Go squash some ants!'),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: entries.length,
                      itemBuilder: (context, i) {
                        final e = entries[i];
                        final d = e.date;
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: i == 0
                                ? const Color(0xFFFFB347)
                                : Colors.white12,
                            foregroundColor: i == 0
                                ? Colors.black
                                : Colors.white,
                            child: Text('${i + 1}'),
                          ),
                          title: Text(e.name),
                          subtitle: Text(
                            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
                          ),
                          trailing: Text(
                            '${e.score}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final t = _pulseController.value;
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(
                          const Color(0xFF090F1C),
                          const Color(0xFF2A163D),
                          t,
                        )!,
                        Color.lerp(
                          const Color(0xFF1A2540),
                          const Color(0xFF0B1E2D),
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
              child: Stack(
                children: [
                  _floatingOrb(
                    alignment: const Alignment(-0.85, -0.7),
                    size: 240,
                    color: const Color(0xFFFF9B4D).withOpacity(0.16),
                    begin: -18,
                    end: 18,
                  ),
                  _floatingOrb(
                    alignment: const Alignment(0.9, -0.2),
                    size: 180,
                    color: const Color(0xFFFFD37A).withOpacity(0.12),
                    begin: 20,
                    end: -20,
                  ),
                  _floatingOrb(
                    alignment: const Alignment(0.0, 0.8),
                    size: 280,
                    color: const Color(0xFF69D2FF).withOpacity(0.1),
                    begin: -14,
                    end: 14,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.92, end: 1.0),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) {
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.14),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 30,
                            offset: Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ScaleTransition(
                            scale: Tween<double>(begin: 0.96, end: 1.04)
                                .animate(
                                  CurvedAnimation(
                                    parent: _pulseController,
                                    curve: Curves.easeInOut,
                                  ),
                                ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFA63D),
                                    Color(0xFFFF6A3D),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'ANT SQUASH',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Protect the sweets from the ant swarm.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Tap the ants before they reach the cake.\nEvery hit earns points, every miss costs health.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: Colors.white70, height: 1.35),
                          ),
                          const SizedBox(height: 22),
                          TextField(
                            controller: _controller,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _start(),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Enter your name',
                              labelStyle: const TextStyle(
                                color: Colors.white70,
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.08),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: FilledButton(
                              onPressed: _start,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFFF8A2A),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: const Text(
                                'Start Hunting',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'High score: ${GameStorage.highScore}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.white54),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton.icon(
                                onPressed: _showLeaderboard,
                                icon: const Icon(Icons.emoji_events_rounded),
                                label: const Text('Leaderboard'),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: () => setState(
                                  () => GameStorage.setSoundEnabled(
                                    !GameStorage.soundEnabled,
                                  ),
                                ),
                                icon: Icon(
                                  GameStorage.soundEnabled
                                      ? Icons.volume_up_rounded
                                      : Icons.volume_off_rounded,
                                ),
                                label: Text(
                                  GameStorage.soundEnabled
                                      ? 'Sound on'
                                      : 'Sound off',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _floatingOrb({
    required Alignment alignment,
    required double size,
    required Color color,
    required double begin,
    required double end,
  }) {
    return Align(
      alignment: alignment,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: begin, end: end),
        duration: const Duration(seconds: 6),
        curve: Curves.easeInOut,
        builder: (context, offset, child) {
          return Transform.translate(offset: Offset(0, offset), child: child);
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(color: color, blurRadius: 70, spreadRadius: 10),
            ],
          ),
        ),
      ),
    );
  }
}
