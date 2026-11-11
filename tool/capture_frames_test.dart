// Renders real frames of the game for the README (GIFs and screenshots).
//
// Run with:  FRAMES_DIR=build/frames flutter test tool/capture_frames_test.dart
// Then stitch the frames with tool/make_media.py.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:ant_squash_flutter/components/Storage.dart';
import 'package:ant_squash_flutter/components/achievements.dart';
import 'package:ant_squash_flutter/components/image_provider.dart';
import 'package:ant_squash_flutter/components/stats.dart';
import 'package:ant_squash_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _fontDir = String.fromEnvironment(
  'FONT_DIR',
  defaultValue:
      '/home/HAMI/snap/flutter/common/flutter/bin/cache/artifacts/material_fonts',
);
final _out = Platform.environment['FRAMES_DIR'] ?? 'build/frames';
const _frame = Duration(microseconds: 66667); // 15 fps

final _boundaryKey = GlobalKey();
final _counters = <String, int>{};

Future<void> _loadFonts() async {
  Future<ByteData> read(String name) async {
    final bytes = await File('$_fontDir/$name').readAsBytes();
    return ByteData.view(bytes.buffer);
  }

  final roboto = FontLoader('Roboto');
  for (final f in [
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
    'Roboto-Black.ttf',
    'Roboto-Light.ttf',
  ]) {
    roboto.addFont(read(f));
  }
  await roboto.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(read('MaterialIcons-Regular.otf'));
  await icons.load();
}

Future<void> _shot(WidgetTester t, String scene) async {
  final n = _counters.update(scene, (v) => v + 1, ifAbsent: () => 0);
  final dir = Directory('$_out/$scene')..createSync(recursive: true);
  final file = File('${dir.path}/${n.toString().padLeft(4, '0')}.png');
  await t.runAsync(() async {
    final boundary =
        _boundaryKey.currentContext!.findRenderObject()
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await file.writeAsBytes(data!.buffer.asUint8List());
  });
}

/// Pumps [frames] frames, capturing each one into [scene].
Future<void> _record(WidgetTester t, String scene, int frames) async {
  for (var i = 0; i < frames; i++) {
    await t.pump(_frame);
    await _shot(t, scene);
  }
}

final _antFinder = find.byWidgetPredicate((w) {
  if (w is! Image) return false;
  final image = w.image;
  return image is AssetImage && image.assetName == GameAssets.ant;
});

final _cakeFinder = find.byWidgetPredicate((w) {
  if (w is! Image) return false;
  final image = w.image;
  return image is AssetImage && image.assetName == GameAssets.cake;
});

/// Taps the ant closest to the cake, but only once it gets near, so that
/// several ants stay on screen and the footage looks lively.
Future<void> _tapAnAnt(WidgetTester t, {double reach = 185}) async {
  final count = _antFinder.evaluate().length;
  if (count == 0 || _cakeFinder.evaluate().isEmpty) return;
  final cake = t.getCenter(_cakeFinder.first);
  final size = t.view.physicalSize / t.view.devicePixelRatio;
  Offset? best;
  var bestDistance = double.infinity;
  for (var i = 0; i < count; i++) {
    final p = t.getCenter(_antFinder.at(i));
    if (p.dx < 12 || p.dx > size.width - 12) continue;
    if (p.dy < 150 || p.dy > size.height - 40) continue;
    final d = (p - cake).distance;
    if (d < reach && d < bestDistance) {
      bestDistance = d;
      best = p;
    }
  }
  if (best != null) {
    await t.tapAt(best + const Offset(3, 3));
  }
}

void _demoData() {
  GameStorage.stats = LifetimeStats()
    ..gamesPlayed = 23
    ..totalSquashed = 1284
    ..totalScore = 3920
    ..bestScore = 412
    ..bestCombo = 23
    ..fastSquashed = 311
    ..tanksSquashed = 97
    ..queensSquashed = 12
    ..secondsPlayed = 4980;
  GameStorage.unlocked = {
    'first_blood',
    'exterminator',
    'plague',
    'combo_5',
    'combo_10',
    'combo_20',
    'score_50',
    'score_150',
    'score_300',
    'speed_demon',
    'tank_buster',
    'queen_slayer',
    'veteran',
  };
  final names = [
    ('Hammas', 412),
    ('Sara', 377),
    ('Zain', 341),
    ('Maya', 296),
    ('Omar', 254),
    ('Lina', 211),
    ('Ali', 188),
    ('Noor', 163),
    ('Sam', 120),
    ('Eli', 97),
  ];
  final now = DateTime(2026, 11, 9);
  GameStorage.leaderboard = [
    for (var i = 0; i < names.length; i++)
      LeaderboardEntry(
        name: names[i].$1,
        score: names[i].$2,
        date: now.subtract(Duration(days: i * 2)),
      ),
  ];
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('capture README media', (tester) async {
    // Silence platform channels (haptics, audio).
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);

    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    GameStorage.leaderboard = [];
    GameStorage.unlocked = {};
    GameStorage.stats = LifetimeStats();
    await GameStorage.init();
    // No audio plugin in the test environment; this also skips haptics.
    GameStorage.soundEnabled = false;

    // A phone-shaped, high-density screen with status/navigation bar insets.
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2.0;
    tester.view.padding = const FakeViewPadding(top: 96, bottom: 56);
    tester.view.viewPadding = const FakeViewPadding(top: 96, bottom: 56);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      RepaintBoundary(key: _boundaryKey, child: const MyApp()),
    );
    await tester.runAsync(() async {
      final context = tester.element(find.byType(MaterialApp));
      for (final a in [GameAssets.ant, GameAssets.cake, GameAssets.explosion]) {
        await precacheImage(AssetImage(a), context);
      }
    });
    await tester.pump(const Duration(milliseconds: 100));

    // ---------------------------------------------------------- start screen
    await tester.enterText(find.byType(TextField), 'Hammas');
    await tester.pump(const Duration(milliseconds: 300));
    await _record(tester, 'menu', 45);
    await _shot(tester, 'shot_start');

    // -------------------------------------------------------------- gameplay
    await tester.tap(find.text('START HUNTING'));
    await tester.pump(const Duration(milliseconds: 600));
    var captured = 0;
    final warmupFrames = int.parse(Platform.environment['WARMUP'] ?? '420');
    final playFrames = int.parse(Platform.environment['PLAY'] ?? '170');
    for (var i = 0; i < warmupFrames + playFrames; i++) {
      await tester.pump(_frame);
      if (i % 2 == 0) await _tapAnAnt(tester);
      if (i >= warmupFrames) {
        await _shot(tester, 'play');
        captured++;
        if (captured == 90) await _shot(tester, 'shot_play');
      }
    }

    // ----------------------------------------------------------------- pause
    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump(const Duration(milliseconds: 400));
    await _shot(tester, 'shot_pause');
    await tester.tap(find.text('RESUME'));
    await tester.pump(const Duration(milliseconds: 200));

    // ------------------------------------------------------------- game over
    for (
      var i = 0;
      i < 4000 && find.text('GAME OVER').evaluate().isEmpty;
      i++
    ) {
      await tester.pump(_frame);
    }
    expect(find.text('GAME OVER'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 900));
    await _shot(tester, 'shot_gameover');

    // ---------------------------------------------------------- hall of fame
    await tester.tap(find.text('Main Menu'));
    await tester.pump(const Duration(milliseconds: 700));
    _demoData();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Stats'));
    await _record(tester, 'hall', 10);
    await _record(tester, 'hall', 12);
    await _shot(tester, 'shot_stats');
    await tester.tap(find.text('Achievements').first);
    await _record(tester, 'hall', 14);
    await _shot(tester, 'shot_achievements');
    await _record(tester, 'hall', 10);
    await tester.tap(find.text('Top 10').first);
    await _record(tester, 'hall', 14);
    await _shot(tester, 'shot_top10');
    await _record(tester, 'hall', 14);

    // Sanity check that achievements exist in the catalogue.
    expect(Achievements.all, isNotEmpty);
  }, timeout: const Timeout(Duration(minutes: 20)));
}
