import 'package:ant_squash_flutter/components/Storage.dart';
import 'package:ant_squash_flutter/components/achievements.dart';
import 'package:ant_squash_flutter/components/stats.dart';
import 'package:ant_squash_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    GameStorage.leaderboard = [];
    GameStorage.unlocked = {};
    GameStorage.stats = LifetimeStats();
    await GameStorage.init();
  });

  testWidgets('shows the start screen', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('ANT SQUASH'), findsOneWidget);
    expect(find.text('START HUNTING'), findsOneWidget);
    expect(find.text('Your name'), findsOneWidget);
  });

  testWidgets('plays a round, pauses and opens the hall of fame', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MyApp());
    await tester.enterText(find.byType(TextField), 'Tester');
    await tester.tap(find.text('START HUNTING'));
    await tester.pump(const Duration(milliseconds: 500));
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    // Pause and resume.
    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump();
    expect(find.text('PAUSED'), findsOneWidget);
    await tester.tap(find.text('RESUME'));
    await tester.pump();
    expect(find.text('PAUSED'), findsNothing);

    // Let the ants win.
    for (
      var i = 0;
      i < 1500 && find.text('GAME OVER').evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('GAME OVER'), findsOneWidget);
    expect(GameStorage.stats.gamesPlayed, 1);

    await tester.tap(find.text('Main Menu'));
    await tester.pump(const Duration(seconds: 1));
    await tester.ensureVisible(find.text('Stats'));
    await tester.pump();
    await tester.tap(find.text('Stats'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Games played'), findsOneWidget);
  });

  test('achievements unlock from lifetime and run progress', () {
    final stats = LifetimeStats()..totalSquashed = 99;
    final run = RunStats()..squashed = 1;
    final a = Achievements.byId('exterminator')!;
    expect(a.isSatisfied(stats, RunStats()), isFalse);
    expect(a.isSatisfied(stats, run), isTrue);
  });
}
