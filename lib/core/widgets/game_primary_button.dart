import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class GamePrimaryButton extends StatelessWidget {
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
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onPressed != null,
    label: label,
    child: AnimatedOpacity(
      opacity: onPressed == null ? .55 : 1,
      duration: const Duration(milliseconds: 160),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 20 : 30,
              vertical: compact ? 13 : 17,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xE8FFD35A), Color(0xE8FFA72F)],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x44000000),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: AppColors.cocoa, size: 25),
                  const SizedBox(width: 10),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.cocoa,
                    fontSize: compact ? 17 : 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .3,
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
