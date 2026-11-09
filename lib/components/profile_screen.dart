import 'dart:math';

import 'package:flutter/material.dart';

import 'Storage.dart';
import 'achievements.dart';
import 'stats.dart';
import 'ui_kit.dart';

enum ProfileTab { stats, achievements, leaderboard }

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.initialTab = ProfileTab.stats});

  final ProfileTab initialTab;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: ProfileTab.values.length,
      initialIndex: initialTab.index,
      child: Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(child: AnimatedBackdrop()),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const Text(
                          'Hall of Fame',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const TabBar(
                    dividerColor: Colors.transparent,
                    indicatorColor: AppColors.accent,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    tabs: [
                      Tab(text: 'Stats'),
                      Tab(text: 'Achievements'),
                      Tab(text: 'Top 10'),
                    ],
                  ),
                  const Expanded(
                    child: TabBarView(
                      children: [
                        _StatsTab(),
                        _AchievementsTab(),
                        _LeaderboardTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String formatDuration(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  if (h > 0) return '${h}h ${m}m';
  if (m > 0) return '${m}m ${s}s';
  return '${s}s';
}

class _StatsTab extends StatelessWidget {
  const _StatsTab();

  @override
  Widget build(BuildContext context) {
    final s = GameStorage.stats;
    final tiles = <(IconData, String, String)>[
      (Icons.sports_esports_rounded, 'Games played', '${s.gamesPlayed}'),
      (Icons.emoji_events_rounded, 'Best score', '${s.bestScore}'),
      (Icons.bug_report_rounded, 'Ants squashed', '${s.totalSquashed}'),
      (Icons.bolt_rounded, 'Best combo', '${s.bestCombo}'),
      (Icons.stars_rounded, 'Average score', s.averageScore.toStringAsFixed(1)),
      (Icons.timer_rounded, 'Time played', formatDuration(s.secondsPlayed)),
      (Icons.flash_on_rounded, 'Fast ants', '${s.fastSquashed}'),
      (Icons.fitness_center_rounded, 'Tank ants', '${s.tanksSquashed}'),
      (Icons.workspace_premium_rounded, 'Queens', '${s.queensSquashed}'),
      (
        Icons.military_tech_rounded,
        'Achievements',
        '${GameStorage.unlocked.length}/${Achievements.all.length}',
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = max(2, (constraints.maxWidth / 190).floor());
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 104,
          ),
          itemCount: tiles.length,
          itemBuilder: (context, i) {
            final (icon, label, value) = tiles[i];
            return GlassCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: AppColors.gold, size: 22),
                  const Spacer(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _AchievementsTab extends StatelessWidget {
  const _AchievementsTab();

  @override
  Widget build(BuildContext context) {
    final all = Achievements.all;
    final unlockedCount = GameStorage.unlocked.length;
    final empty = RunStats();
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: all.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        if (i == 0) {
          return GlassCard(
            highlight: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$unlockedCount of ${all.length} unlocked',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    minHeight: 10,
                    value: unlockedCount / all.length,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                  ),
                ),
              ],
            ),
          );
        }
        final a = all[i - 1];
        final done = GameStorage.unlocked.contains(a.id);
        final progress = min(a.progress(GameStorage.stats, empty), a.target);
        return AchievementTile(
          achievement: a,
          unlocked: done,
          progress: progress,
        );
      },
    );
  }
}

class AchievementTile extends StatelessWidget {
  const AchievementTile({
    super.key,
    required this.achievement,
    required this.unlocked,
    required this.progress,
  });

  final Achievement achievement;
  final bool unlocked;
  final int progress;

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    return Opacity(
      opacity: unlocked ? 1 : 0.7,
      child: GlassCard(
        highlight: unlocked,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: unlocked ? AppColors.accentGradient : null,
                color: unlocked ? null : Colors.white12,
              ),
              child: Icon(
                unlocked ? a.icon : Icons.lock_rounded,
                color: unlocked ? Colors.white : Colors.white54,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    a.description,
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontSize: 12.5,
                    ),
                  ),
                  if (!unlocked && a.target > 1) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              minHeight: 6,
                              value: progress / a.target,
                              backgroundColor: Colors.white12,
                              valueColor: const AlwaysStoppedAnimation(
                                AppColors.gold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$progress/${a.target}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textDim,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (unlocked)
              const Icon(Icons.check_circle_rounded, color: AppColors.gold),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardTab extends StatelessWidget {
  const _LeaderboardTab();

  @override
  Widget build(BuildContext context) {
    final entries = GameStorage.leaderboard;
    if (entries.isEmpty) {
      return const Center(
        child: Text(
          'No scores yet.\nGo squash some ants!',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textDim),
        ),
      );
    }
    const medals = [Color(0xFFFFC94D), Color(0xFFC9D1DB), Color(0xFFD08A4E)];
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final e = entries[i];
        final d = e.date;
        final date =
            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        return GlassCard(
          highlight: i == 0,
          radius: 18,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: i < 3 ? medals[i] : Colors.white12,
                foregroundColor: i < 3 ? Colors.black : Colors.white,
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      date,
                      style: const TextStyle(
                        color: AppColors.textDim,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${e.score}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
