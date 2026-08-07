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
    child: Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Image.asset(
              'assets/images/ui/bakery_panel.png',
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
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
  );
}
