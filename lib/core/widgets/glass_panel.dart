import 'package:flutter/material.dart';

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.radius = 28,
    this.tint = const Color(0xB8FFF9ED),
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color tint;

  @override
  Widget build(BuildContext context) => Padding(
    padding: margin ?? EdgeInsets.zero,
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xF0643422), Color(0xF0321916)],
        ),
        border: Border.all(color: const Color(0x80F8D590), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x500F0906),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0x20FFD989),
            blurRadius: 2,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [tint.withValues(alpha: .12), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: padding ?? const EdgeInsets.all(28),
              child: Theme(
                data: Theme.of(context).copyWith(
                  textTheme: Theme.of(context).textTheme.apply(
                    bodyColor: Colors.white,
                    displayColor: Colors.white,
                  ),
                  iconTheme: const IconThemeData(color: Color(0xFFFFD76A)),
                  dividerColor: const Color(0x66FFF1CF),
                  listTileTheme: const ListTileThemeData(
                    textColor: Colors.white,
                    iconColor: Color(0xFFFFD76A),
                  ),
                ),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(color: Colors.white),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
