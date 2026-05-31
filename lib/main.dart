import 'package:flutter/material.dart';

import 'components/State.dart';
import 'components/game_controller.dart';
import 'components/start_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ant Squash',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF7A1A),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF08111F),
      ),
      home: const GameRoot(),
    );
  }
}

class GameRoot extends StatefulWidget {
  const GameRoot({super.key});

  @override
  State<GameRoot> createState() => _GameRootState();
}

class _GameRootState extends State<GameRoot> {
  GamePhase _phase = GamePhase.start;
  String _playerName = '';

  void _startGame(String playerName) {
    setState(() {
      _playerName = playerName;
      _phase = GamePhase.playing;
    });
  }

  void _backToStart() {
    setState(() {
      _phase = GamePhase.start;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0.06, 0.03),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offsetAnimation, child: child),
        );
      },
      child: _phase == GamePhase.start
          ? StartScreen(key: const ValueKey('start'), onStart: _startGame)
          : GameController(
              key: ValueKey(_playerName),
              playerName: _playerName,
              onExitToStart: _backToStart,
            ),
    );
  }
}
