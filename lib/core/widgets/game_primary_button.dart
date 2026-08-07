import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class GamePrimaryButton extends StatefulWidget {
  const GamePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool compact;

  @override
  State<GamePrimaryButton> createState() => _GamePrimaryButtonState();
}

class _GamePrimaryButtonState extends State<GamePrimaryButton> {
  bool _pressed = false;

  void _activate() {
    if (!WidgetsBinding.instance.runtimeType.toString().contains(
      'TestWidgetsFlutterBinding',
    )) {
      unawaited(() async {
        try {
          await FlameAudio.play('sfx/button.wav', volume: .62);
        } catch (_) {}
      }());
    }
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: widget.onPressed != null,
    label: widget.label,
    child: AnimatedOpacity(
      opacity: widget.onPressed == null ? .55 : 1,
      duration: const Duration(milliseconds: 160),
      child: AnimatedScale(
        scale: _pressed ? .94 : 1,
        duration: const Duration(milliseconds: 90),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: widget.onPressed == null
              ? null
              : (_) => setState(() => _pressed = true),
          onTapCancel: widget.onPressed == null
              ? null
              : () => setState(() => _pressed = false),
          onTapUp: widget.onPressed == null
              ? null
              : (_) => setState(() => _pressed = false),
          onTap: widget.onPressed == null ? null : _activate,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: widget.compact ? 148 : 230,
              minHeight: widget.compact ? 54 : 66,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: Image.asset(
                      'assets/images/ui/primary_button.png',
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.compact ? 20 : 30,
                    vertical: widget.compact ? 13 : 17,
                  ),
                  child: Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.cocoa,
                      fontSize: widget.compact ? 17 : 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .3,
                      shadows: const [
                        Shadow(color: Colors.white70, blurRadius: 2),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
