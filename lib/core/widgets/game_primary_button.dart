import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../../features/progress/application/progress_controller.dart';
import '../../services/audio/game_audio_service.dart';

final gameButtonAudioProvider = Provider<GameAudioService>((ref) {
  if (WidgetsBinding.instance.runtimeType.toString().contains(
    'TestWidgetsFlutterBinding',
  )) {
    return GameAudioService(player: (_) async {});
  }
  return GameAudioService.flame();
});

class GamePrimaryButton extends ConsumerStatefulWidget {
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
  ConsumerState<GamePrimaryButton> createState() => _GamePrimaryButtonState();
}

class _GamePrimaryButtonState extends ConsumerState<GamePrimaryButton> {
  bool _pressed = false;

  void _activate() {
    final audio = ref.read(gameButtonAudioProvider);
    audio.soundEnabled = ref
        .read(progressControllerProvider)
        .data
        .settings
        .soundEnabled;
    unawaited(audio.play('button'));
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(
      progressControllerProvider.select(
        (state) => state.data.settings.soundEnabled,
      ),
    );
    return Semantics(
      button: true,
      enabled: widget.onPressed != null,
      label: widget.label,
      child: AnimatedOpacity(
        opacity: widget.onPressed == null ? .55 : 1,
        duration: const Duration(milliseconds: 160),
        child: AnimatedScale(
          scale: _pressed ? .94 : 1,
          duration: const Duration(milliseconds: 90),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(28),
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onHighlightChanged: (pressed) =>
                  setState(() => _pressed = pressed),
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
      ),
    );
  }
}
