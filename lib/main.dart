import 'dart:async';

import 'package:flutter/material.dart';

import 'game/compass_logic.dart';
import 'game/game_config.dart';
import 'game/models.dart';
import 'game/storage.dart';
import 'screens/game_over_screen.dart';
import 'screens/game_screen.dart';
import 'screens/loader_screen.dart';
import 'screens/menu_screen.dart';
import 'theme.dart';

void main() {
  runApp(const DailyCompassApp());
}

enum Screen { loader, menu, game, gameover }

class DailyCompassApp extends StatelessWidget {
  const DailyCompassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Compass',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const CompassRoot(),
    );
  }
}

class CompassRoot extends StatefulWidget {
  const CompassRoot({super.key});

  @override
  State<CompassRoot> createState() => _CompassRootState();
}

class _CompassRootState extends State<CompassRoot> {
  Screen _screen = Screen.loader;
  RoutineKind _kind = CompassLogic.activeKindAt(DateTime.now());
  RoundResult? _result;
  Timer? _splash;

  @override
  void initState() {
    super.initState();
    CompassStorage.instance.ensureSeeded();
    // Wall-clock timer, not an AnimationController: animator scale is 0 on
    // CI emulators and a controller would complete instantly.
    _splash = Timer(
      const Duration(milliseconds: AppConfig.loaderDurationMs),
      () {
        if (mounted) setState(() => _screen = Screen.menu);
      },
    );
  }

  @override
  void dispose() {
    _splash?.cancel();
    super.dispose();
  }

  void _handleRoundEnd(RoundResult result) {
    if (!mounted) return;
    setState(() {
      _result = result;
      _screen = Screen.gameover;
    });
  }

  Widget _current() {
    switch (_screen) {
      case Screen.loader:
        return const LoaderScreen(key: ValueKey<String>('loader'));
      case Screen.menu:
        return MenuScreen(
          key: ValueKey<String>('menu-${_kind.name}'),
          kind: _kind,
          onStart: () => setState(() => _screen = Screen.game),
          onKindChanged: (kind) => setState(() => _kind = kind),
        );
      case Screen.game:
        return GameScreen(
          key: ValueKey<String>('game-${_kind.name}'),
          kind: _kind,
          onRoundEnd: _handleRoundEnd,
          onExit: () => setState(() => _screen = Screen.menu),
        );
      case Screen.gameover:
        final result = _result;
        if (result == null) {
          // Defensive: never strand the user on an empty result.
          return MenuScreen(
            key: const ValueKey<String>('menu-fallback'),
            kind: _kind,
            onStart: () => setState(() => _screen = Screen.game),
            onKindChanged: (kind) => setState(() => _kind = kind),
          );
        }
        return GameOverScreen(
          key: ValueKey<String>('gameover-${result.record.isoDate}'),
          result: result,
          onPlayAgain: () => setState(() {
            _kind = result.kind.other;
            _screen = Screen.game;
          }),
          onMenu: () => setState(() => _screen = Screen.menu),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: _current(),
    );
  }
}
