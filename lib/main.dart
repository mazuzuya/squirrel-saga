import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/cache.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audio_manager.dart';
import 'game_assets.dart';
import 'levels.dart' show areas;
import 'level_models.dart';
import 'skins.dart';
import 'squirrel_game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SquirrelApp());
}

class SquirrelApp extends StatefulWidget {
  const SquirrelApp({super.key});

  @override
  State<SquirrelApp> createState() => _SquirrelAppState();
}

class _SquirrelAppState extends State<SquirrelApp> {
  SquirrelGame? game;
  bool loading = true;
  _GamePopup? _activePopup = _GamePopup.tutorial;
  bool _wasPausedBeforePopup = false;
  final FocusNode focusNode = FocusNode();

  bool leftHeld = false;
  bool rightHeld = false;
  void _applyMove() => game?.setMove((rightHeld ? 1 : 0) + (leftHeld ? -1 : 0));
  void _joyMove(int dir) => game?.setMove(dir);
  void _joyClimb(int dir) => game?.setClimb(dir);

  void _openPopup(_GamePopup popup) {
    _wasPausedBeforePopup = game?.paused ?? false;
    game?.paused = true;
    game?.audio.play('ui');
    setState(() => _activePopup = popup);
  }

  void _closePopup() {
    game?.paused = _wasPausedBeforePopup;
    game?.audio.play('ui');
    setState(() => _activePopup = null);
    _requestGameFocus();
  }

  void _togglePause() {
    if (game == null || _activePopup != null || game!.isResultOpen) return;
    final wasPaused = game!.paused;
    game!.audio.play('pause');
    setState(() => game!.paused = !game!.paused);
    if (wasPaused) _requestGameFocus();
  }

  void _requestGameFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _activePopup == null) focusNode.requestFocus();
    });
  }

  Future<void> _retryBoot() async {
    setState(() => loading = true);
    await _boot();
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _boot();
  }

  Future<void> _boot() async {
    final images = Images();
    late final GameLibrary lib;
    try {
      lib = await loadLibrary(images);
    } catch (e, stack) {
      debugPrint('[Squirrel Saga] loadLibrary gagal: $e');
      debugPrint('$stack');
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
      return;
    }
    final g = SquirrelGame(lib);
    g.setSkin(0);
    g.loadArea(0);
    g.paused = _activePopup != null;
    setState(() {
      game = g;
      loading = false;
    });
    await AudioManager.instance.init();
    await AudioManager.instance.startBgm();
    focusNode.requestFocus();
  }

  KeyEventResult _onKey(KeyEvent event) {
    if (game == null) return KeyEventResult.ignored;
    if (_activePopup != null) return KeyEventResult.handled;
    final down = event is KeyDownEvent || event is KeyRepeatEvent;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      leftHeld = down;
      _applyMove();
    } else if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD) {
      rightHeld = down;
      _applyMove();
    } else if (key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.keyW) {
      game!.setJumpHeld(down);
    } else if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.keyS ||
        key == LogicalKeyboardKey.keyE ||
        key == LogicalKeyboardKey.keyK) {
      game!.setClimb(down ? 1 : 0);
    } else if (key == LogicalKeyboardKey.keyJ ||
        key == LogicalKeyboardKey.keyX) {
      if (down) game!.attack();
    } else if (key == LogicalKeyboardKey.escape) {
      if (down) _togglePause();
    } else if ((key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter) &&
        down) {
      if (game!.isResultOpen) {
        if (game!.won) {
          game!.restart();
        } else {
          game!.advance();
        }
      }
    } else if (key == LogicalKeyboardKey.keyR && down) {
      game!.restart();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _appTheme,
        home: const Scaffold(body: _StartupScreen()),
      );
    }
    if (game == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _appTheme,
        home: Scaffold(body: _StartupScreen(onRetry: _retryBoot)),
      );
    }
    final hudRightWidth = (MediaQuery.sizeOf(context).width * 0.28).clamp(
      0.0,
      168.0,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _appTheme,
      home: Scaffold(
        backgroundColor: const Color(0xff08091b),
        body: KeyboardListener(
          autofocus: true,
          focusNode: focusNode,
          onKeyEvent: _onKey,
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) {
              if (_activePopup == null && game?.paused != true) {
                focusNode.requestFocus();
              }
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                GameWidget(game: game!),
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    focusNode.requestFocus();
                    if (game!.isResultOpen) {
                      game!.audio.play('ui');
                      if (game!.won) {
                        game!.restart();
                      } else {
                        game!.advance();
                      }
                    }
                  },
                ),
                Positioned(
                  left: 18,
                  bottom: 18,
                  child: SafeArea(
                    child: _Joystick(onMove: _joyMove, onClimb: _joyClimb),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: _PsButtons(game: game!),
                ),
                Positioned(
                  top: 12 + (64 - 36) / 2,
                  right: hudRightWidth + 26,
                  child: _TopGameActions(
                    onSquirrel: () => _openPopup(_GamePopup.squirrels),
                    onMaps: () => _openPopup(_GamePopup.maps),
                    onHelp: () => _openPopup(_GamePopup.tutorial),
                    paused: game!.paused,
                    onPause: _togglePause,
                  ),
                ),
                if (game!.paused && _activePopup == null)
                  _PauseOverlay(
                    onResume: _togglePause,
                    onHelp: () => _openPopup(_GamePopup.tutorial),
                    onMaps: () => _openPopup(_GamePopup.maps),
                  ),
                if (_activePopup != null)
                  _GamePopupView(
                    popup: _activePopup!,
                    game: game!,
                    onClose: _closePopup,
                    onSelectSkin: (id) {
                      game!.setSkin(id);
                      _closePopup();
                    },
                    onSelectArea: (index) {
                      game!.loadArea(index);
                      _wasPausedBeforePopup = false;
                      _closePopup();
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final ThemeData _appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xff0a101a),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xff75e0ca),
    brightness: Brightness.dark,
    surface: const Color(0xff141e2b),
  ),
  fontFamily: 'Roboto',
);

class _StartupScreen extends StatelessWidget {
  const _StartupScreen({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final failed = onRetry != null;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff111d29), Color(0xff080d16)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x2275e0ca),
                border: Border.all(color: const Color(0x6675e0ca)),
              ),
              child: const Icon(
                Icons.pets_rounded,
                color: Color(0xff8be7d2),
                size: 27,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'SQUIRREL SAGA',
              style: TextStyle(
                color: Color(0xfff0f4f2),
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              failed
                  ? 'Aset belum berhasil dimuat'
                  : 'Menyiapkan petualangan...',
              style: const TextStyle(color: Color(0xff9aaab7), fontSize: 12),
            ),
            const SizedBox(height: 20),
            if (failed)
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 17),
                label: const Text('COBA LAGI'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xff9cebd9),
                  side: const BorderSide(color: Color(0x5575e0ca)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
            else
              const SizedBox(
                width: 100,
                child: LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Color(0x333c5260),
                  color: Color(0xff75e0ca),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Joystick extends StatefulWidget {
  const _Joystick({required this.onMove, required this.onClimb});
  final void Function(int) onMove;
  final void Function(int) onClimb;

  @override
  State<_Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<_Joystick> {
  static const double size = 105;
  static const double radius = 36.4;
  Offset _knob = Offset.zero;
  int _lastMove = 0;
  int _lastClimb = 0;

  void _update(Offset local) {
    final center = Offset(size / 2, size / 2);
    var d = local - center;
    if (d.distance > radius) d = d * (radius / d.distance);
    setState(() => _knob = d);
    const dead = 11.2;
    int move = 0, climb = 0;
    if (d.distance > dead) {
      if (d.dx.abs() >= d.dy.abs()) {
        move = d.dx > 0 ? 1 : -1;
      } else {
        climb = d.dy > 0 ? -1 : 1;
      }
    }
    if (move != _lastMove) {
      _lastMove = move;
      widget.onMove(move);
    }
    if (climb != _lastClimb) {
      _lastClimb = climb;
      widget.onClimb(climb);
    }
  }

  void _end() {
    setState(() => _knob = Offset.zero);
    if (_lastMove != 0) {
      _lastMove = 0;
      widget.onMove(0);
    }
    if (_lastClimb != 0) {
      _lastClimb = 0;
      widget.onClimb(0);
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: GestureDetector(
      onPanStart: (d) => _update(d.localPosition),
      onPanUpdate: (d) => _update(d.localPosition),
      onPanEnd: (_) => _end(),
      onPanCancel: () => _end(),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xa9121c29),
          border: Border.all(color: const Color(0x6675e0ca), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const CustomPaint(painter: _JoystickGuidePainter()),
            Center(
              child: Transform.translate(
                offset: _knob,
                child: Container(
                  width: 39.2,
                  height: 39.2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xffb2f2df), Color(0xff5ccbb8)],
                    ),
                    border: Border.all(color: const Color(0x99e8fff6)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x4475e0ca),
                        blurRadius: 9,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 5,
                      height: 5,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xffeffff8),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 6,
              child: Text(
                'MOVE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0x997f9c9b),
                  fontSize: 7,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _JoystickGuidePainter extends CustomPainter {
  const _JoystickGuidePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final ringRadius = size.width * .37;
    canvas.drawCircle(
      center,
      ringRadius,
      Paint()
        ..color = const Color(0x227da6a0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final axisLength = size.width * .15;
    final axisPaint = Paint()
      ..color = const Color(0x1c9cc5bb)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(center.dx - axisLength, center.dy),
      Offset(center.dx + axisLength, center.dy),
      axisPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - axisLength),
      Offset(center.dx, center.dy + axisLength),
      axisPaint,
    );
    final tickPaint = Paint()..color = const Color(0x5588aaa4);
    for (final direction in const [
      Offset(0, -1),
      Offset(1, 0),
      Offset(0, 1),
      Offset(-1, 0),
    ]) {
      canvas.drawCircle(center + direction * ringRadius, 1.4, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _JoystickGuidePainter oldDelegate) => false;
}

class _PsButtons extends StatelessWidget {
  const _PsButtons({required this.game});
  final SquirrelGame game;

  static const _mint = Color(0xff8de4cf);
  static const _warm = Color(0xffffcf87);

  Widget _pad(
    String symbol,
    Color color,
    VoidCallback? onDown,
    VoidCallback? onUp,
  ) => _GameControlButton(
    label: symbol,
    accent: color,
    onDown: onDown == null
        ? null
        : () {
            game.audio.play('ui');
            onDown();
          },
    onUp: onUp,
  );

  Widget _slot(Widget? button) =>
      SizedBox(width: 54, height: 42, child: button ?? const SizedBox.shrink());

  Widget _gridRow(Widget? left, Widget? center, Widget? right, double margin) =>
      Padding(
        padding: EdgeInsets.only(right: margin),
        child: SizedBox(
          width: 174,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_slot(left), _slot(center), _slot(right)],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _gridRow(
              null,
              _pad(
                'PANJAT',
                _mint,
                () => game.setClimb(1),
                () => game.setClimb(0),
              ),
              null,
              30,
            ),
            const SizedBox(height: 6),
            _gridRow(
              _pad('ATTACK', _warm, () => game.attack(), null),
              null,
              _pad(
                'AKSI',
                _mint,
                () => game.setAction(true),
                () => game.setAction(false),
              ),
              20,
            ),
            const SizedBox(height: 6),
            _gridRow(
              null,
              _pad(
                'JUMP',
                _warm,
                () => game.setJumpHeld(true),
                () => game.setJumpHeld(false),
              ),
              null,
              20,
            ),
          ],
        ),
      ),
    ),
  );
}

class _GameControlButton extends StatefulWidget {
  const _GameControlButton({
    required this.label,
    required this.accent,
    required this.onDown,
    required this.onUp,
  });

  final String label;
  final Color accent;
  final VoidCallback? onDown;
  final VoidCallback? onUp;

  @override
  State<_GameControlButton> createState() => _GameControlButtonState();
}

class _GameControlButtonState extends State<_GameControlButton> {
  bool _pressed = false;

  void _press() {
    if (_pressed) return;
    setState(() => _pressed = true);
    widget.onDown?.call();
  }

  void _release() {
    if (!_pressed) return;
    setState(() => _pressed = false);
    widget.onUp?.call();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapDown: (_) => _press(),
    onTapUp: (_) => _release(),
    onTapCancel: _release,
    child: AnimatedScale(
      scale: _pressed ? .94 : 1,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        width: 54,
        height: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _pressed
                ? [
                    widget.accent.withValues(alpha: .38),
                    const Color(0xff17242d),
                  ]
                : [const Color(0xff26343d), const Color(0xff151f29)],
          ),
          border: Border.all(
            color: _pressed
                ? widget.accent.withValues(alpha: .85)
                : const Color(0xff40525b),
          ),
          boxShadow: _pressed
              ? const []
              : const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: 5,
              top: 11,
              bottom: 11,
              child: Container(
                width: 2,
                decoration: BoxDecoration(
                  color: widget.accent.withValues(alpha: _pressed ? .95 : .65),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Center(
              child: Text(
                widget.label,
                style: TextStyle(
                  color: _pressed
                      ? const Color(0xfff2f5ef)
                      : const Color(0xffd7e0df),
                  fontWeight: FontWeight.w800,
                  fontSize: 8,
                  letterSpacing: .35,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

enum _GamePopup { tutorial, squirrels, maps }

class _TopGameActions extends StatelessWidget {
  const _TopGameActions({
    required this.onSquirrel,
    required this.onMaps,
    required this.onHelp,
    required this.paused,
    required this.onPause,
  });

  final VoidCallback onSquirrel;
  final VoidCallback onMaps;
  final VoidCallback onHelp;
  final bool paused;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: const Color(0x80131d29),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: const Color(0x33607888)),
    ),
    child: Row(
      children: [
        _TopGameAction(
          icon: Icons.pets_rounded,
          label: 'SAGA',
          onTap: onSquirrel,
        ),
        const SizedBox(width: 1),
        _TopGameAction(icon: Icons.map_outlined, label: 'MAPS', onTap: onMaps),
        const SizedBox(width: 1),
        _TopGameAction(
          icon: Icons.help_outline_rounded,
          label: 'CARA MAIN',
          onTap: onHelp,
        ),
        const SizedBox(width: 1),
        _TopGameAction(
          icon: paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
          label: paused ? 'LANJUT' : 'JEDA',
          onTap: onPause,
        ),
      ],
    ),
  );
}

class _TopGameAction extends StatelessWidget {
  const _TopGameAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Ink(
          width: 30,
          height: 30,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: const Color(0xffd3e5e3), size: 16),
        ),
      ),
    ),
  );
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({
    required this.onResume,
    required this.onHelp,
    required this.onMaps,
  });

  final VoidCallback onResume;
  final VoidCallback onHelp;
  final VoidCallback onMaps;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: ColoredBox(
      color: const Color(0xb8091119),
      child: Center(
        child: Container(
          width: 310,
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          decoration: BoxDecoration(
            color: const Color(0xf0141e2b),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0x5575e0ca)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 28,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.pause_circle_outline_rounded,
                color: Color(0xff8de4cf),
                size: 38,
              ),
              const SizedBox(height: 9),
              const Text(
                'JEDA SEJENAK',
                style: TextStyle(
                  color: Color(0xfff1f4ee),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .6,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Tarik napas, petualangan menunggu.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xff9eacb8), fontSize: 11),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: FilledButton.icon(
                  onPressed: onResume,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('LANJUTKAN'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xff83dec9),
                    foregroundColor: const Color(0xff0c181a),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _PauseAction(
                      label: 'CARA MAIN',
                      icon: Icons.help_outline_rounded,
                      onTap: onHelp,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PauseAction extends StatelessWidget {
  const _PauseAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 16),
    label: Text(
      label,
      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
    ),
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xffc5d1d5),
      side: const BorderSide(color: Color(0x446f8792)),
      padding: const EdgeInsets.symmetric(horizontal: 7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
    ),
  );
}

class _GamePopupView extends StatelessWidget {
  const _GamePopupView({
    required this.popup,
    required this.game,
    required this.onClose,
    required this.onSelectSkin,
    required this.onSelectArea,
  });

  final _GamePopup popup;
  final SquirrelGame game;
  final VoidCallback onClose;
  final ValueChanged<int> onSelectSkin;
  final ValueChanged<int> onSelectArea;

  @override
  Widget build(BuildContext context) {
    final isTutorial = popup == _GamePopup.tutorial;
    final title = switch (popup) {
      _GamePopup.tutorial => 'CARA BERMAIN',
      _GamePopup.squirrels => 'PILIH SQUIRREL',
      _GamePopup.maps => 'PILIH MAP',
    };
    final subtitle = switch (popup) {
      _GamePopup.tutorial => 'Panduan singkat petualangan Luma',
      _GamePopup.squirrels => 'Setiap squirrel punya kemampuan spesial.',
      _GamePopup.maps => 'Pilih area untuk langsung dijelajahi.',
    };
    final icon = switch (popup) {
      _GamePopup.tutorial => Icons.auto_stories_rounded,
      _GamePopup.squirrels => Icons.pets_rounded,
      _GamePopup.maps => Icons.map_rounded,
    };

    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xe6080d14),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Container(
                  width: 620,
                  height: MediaQuery.sizeOf(context).height * .86,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: const Color(0xff141e2b),
                    border: Border.all(color: const Color(0x55798d98)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x55000000),
                        blurRadius: 22,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 12, 12),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(11),
                                color: const Color(0x2275e0ca),
                              ),
                              child: Icon(
                                icon,
                                color: const Color(0xff8ef0df),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      color: Color(0xfff2f4ee),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: .55,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    subtitle,
                                    style: const TextStyle(
                                      color: Color(0xff9caab5),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Tutup',
                              onPressed: onClose,
                              icon: const Icon(Icons.close_rounded),
                              color: const Color(0xffc2cce0),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0x223b4d5a)),
                      Expanded(child: _buildContent()),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                        child: SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: FilledButton.icon(
                            onPressed: onClose,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xff83dec9),
                              foregroundColor: const Color(0xff0c181a),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                            icon: Icon(
                              isTutorial
                                  ? Icons.play_arrow_rounded
                                  : Icons.check_rounded,
                            ),
                            label: Text(
                              isTutorial ? 'MULAI PETUALANGAN' : 'SELESAI',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                letterSpacing: .45,
                              ),
                            ),
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
      ),
    );
  }

  Widget _buildContent() => switch (popup) {
    _GamePopup.tutorial => _tutorialContent(),
    _GamePopup.squirrels => _skinContent(),
    _GamePopup.maps => _mapContent(),
  };

  Widget _tutorialContent() {
    const tips = [
      _GuideTip(
        Icons.gamepad_rounded,
        'GERAK',
        'Joystick kiri atau tombol panah/A-D untuk bergerak. Arah atas/bawah juga menjalankan aksi; dekat batang bercahaya, tahan untuk memanjat.',
        Color(0xff5bded0),
      ),
      _GuideTip(
        Icons.north_rounded,
        'LOMPAT & MELAYANG',
        'Tekan JUMP atau Space/W/↑ untuk melompat. Tahan tombol lompat saat di udara untuk melayang; melayang memakai stamina.',
        Color(0xff85d7ff),
      ),
      _GuideTip(
        Icons.touch_app_rounded,
        'PANJAT & AKSI',
        'Tahan PANJAT saat dekat batang bercahaya. Tekan AKSI atau panah bawah/S/E/K di dekat objek untuk menggali, menarik tuas, memakai mesin, atau mengaktifkan landmark.',
        Color(0xffe887d1),
      ),
      _GuideTip(
        Icons.flash_on_rounded,
        'SERANG',
        'Tekan ATTACK atau J/X untuk menyerang ke arah hadap. Melompat dan mendarat tepat di atas musuh juga bisa mengalahkannya.',
        Color(0xffff9870),
      ),
      _GuideTip(
        Icons.key_rounded,
        'BUKA PORTAL',
        'Kumpulkan jumlah kunci yang diminta, aktifkan landmark, dan kalahkan penjaga jalur. Portal terbuka setelah semua syarat area terpenuhi.',
        Color(0xffffd262),
      ),
      _GuideTip(
        Icons.explore_rounded,
        'MEKANIK AREA',
        'Setiap map punya tantangan berbeda: arus angin, jamur pantul, sulur ayun, teleporter, platform bergerak, atau lantai rapuh. Baca petunjuk area untuk mengetahui triknya.',
        Color(0xff82c5ff),
      ),
      _GuideTip(
        Icons.search_rounded,
        'KUNCI KHUSUS',
        'Kunci tersembunyi perlu digali. Kunci beku, beracun, atau gear harus dibawa ke objek yang sesuai lalu tekan AKSI.',
        Color(0xffb9ec80),
      ),
      _GuideTip(
        Icons.favorite_rounded,
        'JAGA LUMA',
        'Hati menunjukkan nyawa; stamina pulih saat berpijak di platform. Hindari musuh dan bahaya area. Jika jatuh atau kehabisan nyawa, Luma kembali ke checkpoint.',
        Color(0xffff7189),
      ),
      _GuideTip(
        Icons.star_rounded,
        'BONUS & KEYBOARD',
        'Emblem daun memberi bonus skor. R untuk mengulang area, Esc untuk jeda, dan Enter untuk lanjut setelah portal pulih. Timer hanya muncul di area tertentu.',
        Color(0xffb6a1ff),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 460 ? 2 : 1;
        final cardWidth = columns == 2
            ? (constraints.maxWidth - 10) / 2
            : constraints.maxWidth;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final tip in tips)
                SizedBox(
                  width: cardWidth,
                  child: _GuideCard(tip: tip),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _skinContent() => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 460 ? 2 : 1;
      return GridView.builder(
        padding: const EdgeInsets.all(14),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          mainAxisExtent: 178,
        ),
        itemCount: skins.length,
        itemBuilder: (context, index) {
          final skin = skins[index];
          return _SkinCard(
            skin: skin,
            game: game,
            selected: skin.id == game.skinId,
            onTap: () => onSelectSkin(skin.id),
          );
        },
      );
    },
  );

  Widget _mapContent() => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 460 ? 2 : 1;
      return GridView.builder(
        padding: const EdgeInsets.all(14),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          mainAxisExtent: 154,
        ),
        itemCount: areas.length,
        itemBuilder: (context, index) {
          final area = areas[index];
          return _MapCard(
            area: area,
            index: index,
            selected: index == game.areaIndex,
            backdrop: game.lib.backdrops[_backdropName(area.backdrop)],
            onTap: () => onSelectArea(index),
          );
        },
      );
    },
  );
}

String _backdropName(String key) => switch (key) {
  'FOREST_BACKDROP' => 'forest',
  'CAVERN_BACKDROP' => 'cavern',
  'CORE_BACKDROP' => 'core',
  _ => 'forest',
};

class _SkinCard extends StatelessWidget {
  const _SkinCard({
    required this.skin,
    required this.game,
    required this.selected,
    required this.onTap,
  });
  final Skin skin;
  final SquirrelGame game;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _hexColor(skin.color);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: selected ? .30 : .14),
                const Color(0xff182331),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: selected ? color : color.withValues(alpha: .25),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: color.withValues(alpha: .32),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _AuraPainter(color: color, active: selected),
                ),
              ),
              Positioned(
                top: 8,
                left: 10,
                child: Text(
                  '#${skin.id.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              if (selected)
                const Positioned(
                  top: 7,
                  right: 8,
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xffb9ffea),
                    size: 18,
                  ),
                ),
              Positioned(
                top: 19,
                left: 0,
                right: 0,
                height: 83,
                child: _SkinSprite(game: game, skinId: skin.id, tint: color),
              ),
              Positioned(
                left: 11,
                right: 11,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skin.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xfff5f7ed),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      skin.buff,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color.withValues(alpha: .9),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkinSprite extends StatelessWidget {
  const _SkinSprite({
    required this.game,
    required this.skinId,
    required this.tint,
  });
  final SquirrelGame game;
  final int skinId;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final sheet = game.lib.trySheet(
      skinId == 0 ? 'movement' : 'skin${skinId.toString().padLeft(2, '0')}',
    );
    final frame =
        sheet?.frame('run_1') ??
        sheet?.frame('idle_1') ??
        sheet?.animation('run')?.first ??
        sheet?.animation('idle')?.first;
    return CustomPaint(painter: _SpritePainter(sheet?.image, frame, tint));
  }
}

class _SpritePainter extends CustomPainter {
  const _SpritePainter(this.image, this.frame, this.tint);
  final ui.Image? image;
  final Frame? frame;
  final Color tint;
  @override
  void paint(ui.Canvas canvas, Size size) {
    if (image == null || frame == null) return;
    final source = ui.Rect.fromLTWH(frame!.x, frame!.y, frame!.w, frame!.h);
    final target = ui.Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 + 5),
      width: size.height * 1.03,
      height: size.height * 1.03,
    );
    canvas.drawCircle(
      target.center,
      target.width * .34,
      Paint()..color = tint.withValues(alpha: .14),
    );
    canvas.drawImageRect(
      image!,
      source,
      target,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(covariant _SpritePainter oldDelegate) =>
      image != oldDelegate.image || tint != oldDelegate.tint;
}

class _AuraPainter extends CustomPainter {
  const _AuraPainter({required this.color, required this.active});
  final Color color;
  final bool active;
  @override
  void paint(ui.Canvas canvas, Size size) {
    final p = Paint()..color = color.withValues(alpha: active ? .16 : .07);
    for (var i = 0; i < 4; i++)
      canvas.drawCircle(
        Offset(size.width * (.18 + i * .25), size.height * .25),
        18 + i * 8,
        p,
      );
  }

  @override
  bool shouldRepaint(covariant _AuraPainter oldDelegate) =>
      color != oldDelegate.color || active != oldDelegate.active;
}

class _MapCard extends StatelessWidget {
  const _MapCard({
    required this.area,
    required this.index,
    required this.selected,
    required this.backdrop,
    required this.onTap,
  });
  final Area area;
  final int index;
  final bool selected;
  final ui.Image? backdrop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _hexColor(area.colors.last);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? color : const Color(0x443d5665),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: [
              if (selected)
                BoxShadow(color: color.withValues(alpha: .25), blurRadius: 16),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _MapPreviewPainter(
                    area: area,
                    image: backdrop,
                    accent: color,
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, const Color(0xee0b1420)],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 9,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xaa0b1420),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'AREA ${index + 1}',
                    style: TextStyle(
                      color: color,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .8,
                    ),
                  ),
                ),
              ),
              if (selected)
                const Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xffb9ffea),
                    size: 18,
                  ),
                ),
              Positioned(
                left: 11,
                right: 10,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      area.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xfff4f7ed),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      area.mechanic,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapPreviewPainter extends CustomPainter {
  const _MapPreviewPainter({
    required this.area,
    required this.image,
    required this.accent,
  });
  final Area area;
  final ui.Image? image;
  final Color accent;
  @override
  void paint(ui.Canvas canvas, Size size) {
    final base = Color.lerp(
      const Color(0xff0b1528),
      _hexColor(area.colors[1]),
      .55,
    )!;
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    if (image != null)
      canvas.drawImageRect(
        image!,
        ui.Rect.fromLTWH(
          0,
          0,
          image!.width.toDouble(),
          image!.height.toDouble(),
        ),
        Offset.zero & size,
        Paint()..color = const Color(0x99ffffff),
      );
    final scaleX = size.width / 4700;
    final scaleY = size.height / 1500;
    final paint = Paint()..color = accent.withValues(alpha: .75);
    for (final platform in area.platforms.take(7))
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            platform.x * scaleX,
            platform.y * scaleY,
            math.max(12, platform.w * scaleX),
            math.max(4, platform.h * scaleY),
          ),
          const Radius.circular(3),
        ),
        paint,
      );
    canvas.drawCircle(
      Offset(area.portal['x']! * scaleX, area.portal['y']! * scaleY),
      7,
      Paint()
        ..color = const Color(0xffd6a5ff)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawCircle(
      Offset(area.portal['x']! * scaleX, area.portal['y']! * scaleY),
      4,
      Paint()..color = const Color(0xfff0d8ff),
    );
  }

  @override
  bool shouldRepaint(covariant _MapPreviewPainter oldDelegate) =>
      area != oldDelegate.area || image != oldDelegate.image;
}

class _GuideTip {
  const _GuideTip(this.icon, this.title, this.detail, this.color);

  final IconData icon;
  final String title;
  final String detail;
  final Color color;
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({required this.tip});

  final _GuideTip tip;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xff192431),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0x333c515e)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(tip.icon, color: tip.color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tip.title,
                style: TextStyle(
                  color: tip.color,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tip.detail,
                style: const TextStyle(
                  color: Color(0xffd0d9eb),
                  fontSize: 10,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Color _hexColor(String value) =>
    Color(int.parse('ff${value.substring(1)}', radix: 16));
